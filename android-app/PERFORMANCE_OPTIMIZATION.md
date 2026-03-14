# BookShare Android App - Performance Optimization Guide

## Executive Summary

This document identifies critical performance issues, crash risks, and memory leaks in the BookShare Android app. The app currently suffers from:

- **ANR (Application Not Responding) risks** due to blocking operations on network threads
- **Data integrity issues** from hardcoded placeholder values
- **Security vulnerabilities** from production logging
- **Memory leaks** from unclosed resources
- **Excessive recompositions** causing UI jank

Following this guide will significantly improve app stability, responsiveness, and user experience.

---

## Table of Contents

1. [Critical Issues (P0)](#1-critical-issues-p0)
2. [High Priority Issues (P1)](#2-high-priority-issues-p1)
3. [Medium Priority Issues (P2)](#3-medium-priority-issues-p2)
4. [Low Priority Issues (P3)](#4-low-priority-issues-p3)
5. [Testing Recommendations](#5-testing-recommendations)
6. [Performance Metrics to Track](#6-performance-metrics-to-track)
7. [Implementation Checklist](#7-implementation-checklist)

---

## 1. Critical Issues (P0)

### 1.1 ANR Risk: `runBlocking` in Network Interceptors

**Severity:** CRITICAL  
**Impact:** App freezes, ANR dialogs, force closes  
**Files:**
- `app/src/main/java/com/bookstore/bookapp/di/NetworkModule.kt`
- `app/src/main/java/com/bookstore/bookapp/di/TokenAuthenticator.kt`

#### Problem

The auth interceptor and token authenticator use `runBlocking` to read tokens from DataStore. This blocks the OkHttp dispatcher thread, which can cause ANRs if DataStore access is slow (e.g., first read, disk I/O contention).

**Current Code (NetworkModule.kt lines 38-41):**
```kotlin
val token = runBlocking {
    userPreferences.accessTokenFlow.firstOrNull()
}
```

**Current Code (TokenAuthenticator.kt lines 27-48):**
```kotlin
synchronized(this) {
    return runBlocking {
        val refreshToken = userPreferences.refreshTokenFlow.firstOrNull()
        // ... refresh logic
    }
}
```

#### Why This Causes ANRs

1. `runBlocking` blocks the current thread until the coroutine completes
2. OkHttp interceptors run on OkHttp's dispatcher threads
3. DataStore reads involve disk I/O which can be slow
4. Blocking network threads can cascade to ANRs when multiple requests queue up

#### Solution

Cache the token synchronously and update it asynchronously when it changes.

**Fixed NetworkModule.kt:**
```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    private const val BASE_URL = "https://api-book-club.zenith-techsphere.com/api/v1/"
    private const val GOOGLE_BOOKS_BASE_URL = "https://www.googleapis.com/"

    @Provides
    @Singleton
    fun provideTokenHolder(userPreferences: UserPreferences): TokenHolder {
        return TokenHolder(userPreferences)
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(tokenHolder: TokenHolder): Interceptor {
        return Interceptor { chain ->
            val requestBuilder = chain.request().newBuilder()
            // Non-blocking: read from in-memory cache
            val token = tokenHolder.accessToken
            if (!token.isNullOrEmpty()) {
                requestBuilder.addHeader("Authorization", "Bearer $token")
            }
            chain.proceed(requestBuilder.build())
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        authInterceptor: Interceptor,
        tokenAuthenticator: TokenAuthenticator
    ): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            // Only log in debug builds
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }
        return OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .authenticator(tokenAuthenticator)
            .addInterceptor(loggingInterceptor)
            .addInterceptor(authInterceptor)
            .build()
    }
    
    // ... rest of the module
}
```

**New TokenHolder.kt:**
```kotlin
package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.local.UserPreferences
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TokenHolder @Inject constructor(
    userPreferences: UserPreferences
) {
    @Volatile
    var accessToken: String? = null
        private set

    @Volatile
    var refreshToken: String? = null
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    init {
        // Observe token changes and cache them in memory
        userPreferences.accessTokenFlow
            .onEach { accessToken = it }
            .launchIn(scope)

        userPreferences.refreshTokenFlow
            .onEach { refreshToken = it }
            .launchIn(scope)
    }

    fun updateTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
    }

    fun clearTokens() {
        accessToken = null
        refreshToken = null
    }
}
```

**Fixed TokenAuthenticator.kt:**
```kotlin
package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.local.UserPreferences
import com.bookstore.bookapp.data.remote.api.AuthApi
import com.bookstore.bookapp.data.remote.api.RefreshRequest
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import javax.inject.Inject
import javax.inject.Provider

class TokenAuthenticator @Inject constructor(
    private val userPreferences: UserPreferences,
    private val authApiProvider: Provider<AuthApi>,
    private val tokenHolder: TokenHolder
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        // Prevent infinite loops if the refresh call itself gets a 401
        if (response.request.url.encodedPath.endsWith("auth/refresh")) {
            tokenHolder.clearTokens()
            runBlocking { userPreferences.clearTokens() }
            return null
        }

        synchronized(this) {
            // Read from in-memory cache first (non-blocking)
            val currentRefreshToken = tokenHolder.refreshToken
            
            if (currentRefreshToken == null) {
                return null
            }

            return try {
                val authApi = authApiProvider.get()
                // This network call is expected to block, that's OK
                val refreshResponse = runBlocking {
                    authApi.refreshToken(RefreshRequest(currentRefreshToken))
                }

                // Update both in-memory cache and persistent storage
                tokenHolder.updateTokens(refreshResponse.accessToken, refreshResponse.refreshToken)
                runBlocking {
                    userPreferences.saveTokens(refreshResponse.accessToken, refreshResponse.refreshToken)
                }

                response.request.newBuilder()
                    .header("Authorization", "Bearer ${refreshResponse.accessToken}")
                    .build()
            } catch (e: Exception) {
                tokenHolder.clearTokens()
                runBlocking { userPreferences.clearTokens() }
                null
            }
        }
    }
}
```

---

### 1.2 Security: HTTP Logging in Release Builds

**Severity:** CRITICAL  
**Impact:** Tokens, passwords, and sensitive data exposed in logs  
**File:** `app/src/main/java/com/bookstore/bookapp/di/NetworkModule.kt`

#### Problem

Full HTTP body logging is enabled unconditionally, including in release builds.

**Current Code (line 56):**
```kotlin
val loggingInterceptor = HttpLoggingInterceptor().apply {
    level = HttpLoggingInterceptor.Level.BODY
}
```

#### Solution

Conditionally enable logging based on build type.

**Fixed Code:**
```kotlin
val loggingInterceptor = HttpLoggingInterceptor().apply {
    level = if (BuildConfig.DEBUG) {
        HttpLoggingInterceptor.Level.BODY
    } else {
        HttpLoggingInterceptor.Level.NONE
    }
}
```

**Additional Security Measure - Redact Sensitive Headers:**
```kotlin
val loggingInterceptor = HttpLoggingInterceptor().apply {
    level = if (BuildConfig.DEBUG) {
        HttpLoggingInterceptor.Level.BODY
    } else {
        HttpLoggingInterceptor.Level.NONE
    }
    redactHeader("Authorization")
    redactHeader("Cookie")
    redactHeader("Set-Cookie")
}
```

---

### 1.3 Data Bug: Hardcoded User ID Placeholder

**Severity:** CRITICAL  
**Impact:** Transaction lists always empty, incorrect data filtering  
**File:** `app/src/main/java/com/bookstore/bookapp/presentation/viewmodel/MyLibraryViewModel.kt`

#### Problem

The code uses a hardcoded `"CURRENT_USER_ID"` string instead of the actual user ID.

**Current Code (lines 62-63):**
```kotlin
val borrowed = txs.filter { it.isBorrower("CURRENT_USER_ID") }
val lent = txs.filter { it.isOwner("CURRENT_USER_ID") }
```

#### Solution

Inject `AuthRepository` and use the actual user ID.

**Fixed MyLibraryViewModel.kt:**
```kotlin
package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MyLibraryState(
    val isLoading: Boolean = false,
    val refreshing: Boolean = false,
    val error: String? = null,
    val myBooks: List<Book> = emptyList(),
    val borrowedBooks: List<Transaction> = emptyList(),
    val lentBooks: List<Transaction> = emptyList()
)

@HiltViewModel
class MyLibraryViewModel @Inject constructor(
    private val bookRepository: BookRepository,
    private val transactionRepository: TransactionRepository,
    private val authRepository: AuthRepository  // ADD THIS
) : ViewModel() {

    private val _uiState = MutableStateFlow(MyLibraryState(isLoading = true))
    val uiState: StateFlow<MyLibraryState> = _uiState.asStateFlow()

    init {
        observeMyBooks()
        observeTransactions()
        refresh()
    }

    private fun observeMyBooks() {
        viewModelScope.launch {
            bookRepository.getMyBooks()
                .catch { e ->
                    // Log error
                }
                .collect { books ->
                    _uiState.value = _uiState.value.copy(
                        myBooks = books,
                        isLoading = false
                    )
                }
        }
    }

    private fun observeTransactions() {
        viewModelScope.launch {
            // Combine transactions with current user to filter correctly
            combine(
                transactionRepository.activeTransactions,
                authRepository.currentUser
            ) { txs, user ->
                val userId = user?.id ?: return@combine Pair(emptyList(), emptyList())
                val borrowed = txs.filter { it.isBorrower(userId) }
                val lent = txs.filter { it.isOwner(userId) }
                Pair(borrowed, lent)
            }.collect { (borrowed, lent) ->
                _uiState.value = _uiState.value.copy(
                    borrowedBooks = borrowed,
                    lentBooks = lent
                )
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(refreshing = true, error = null)
            try {
                bookRepository.fetchMyBooks()
                transactionRepository.fetchTransactions("BORROWER")
                transactionRepository.fetchTransactions("OWNER")
                _uiState.value = _uiState.value.copy(refreshing = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    refreshing = false,
                    error = e.localizedMessage
                )
            }
        }
    }
}
```

---

## 2. High Priority Issues (P1)

### 2.1 Missing OkHttp Timeouts

**Severity:** HIGH  
**Impact:** Network issues cause indefinite hangs  
**File:** `app/src/main/java/com/bookstore/bookapp/di/NetworkModule.kt`

#### Problem

No explicit timeouts configured. Default OkHttp timeouts (10 seconds) may not be appropriate for all endpoints.

#### Solution

Add explicit timeouts to OkHttpClient.

**Fixed Code:**
```kotlin
import java.util.concurrent.TimeUnit

return OkHttpClient.Builder()
    .connectTimeout(30, TimeUnit.SECONDS)
    .readTimeout(30, TimeUnit.SECONDS)
    .writeTimeout(30, TimeUnit.SECONDS)
    .callTimeout(60, TimeUnit.SECONDS)  // Overall timeout for the entire call
    .authenticator(tokenAuthenticator)
    .addInterceptor(loggingInterceptor)
    .addInterceptor(authInterceptor)
    .build()
```

**For specific slow endpoints, consider per-request timeouts:**
```kotlin
// In repository
suspend fun uploadLargeFile(): Response {
    val request = Request.Builder()
        .url("...")
        .tag(Timeout::class.java, Timeout().timeout(5, TimeUnit.MINUTES))
        .build()
    // ...
}
```

---

### 2.2 Search Without Debounce

**Severity:** HIGH  
**Impact:** Excessive network calls, poor UX, potential rate limiting  
**File:** `app/src/main/java/com/bookstore/bookapp/presentation/ui/DiscoverGroupsScreen.kt`

#### Problem

Every keystroke triggers a network call, causing:
- Wasted network requests
- UI flickering from rapid state changes
- Server load / potential rate limiting
- Battery drain

**Current Code (lines 107-110):**
```kotlin
onQueryChange = { 
    viewModel.onSearchQueryChanged(it)
    viewModel.searchGroups()  // Called on every keystroke!
}
```

#### Solution

Implement debouncing in the ViewModel.

**Fixed DiscoverGroupsViewModel.kt:**
```kotlin
package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DiscoverGroupsState(
    val isLoading: Boolean = false,
    val refreshing: Boolean = false,
    val error: String? = null,
    val searchQuery: String = "",
    val discoveredGroups: List<BookClub> = emptyList(),
    val myGroups: List<BookClub> = emptyList()
)

@OptIn(FlowPreview::class)
@HiltViewModel
class DiscoverGroupsViewModel @Inject constructor(
    private val groupRepository: GroupRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DiscoverGroupsState())
    val uiState: StateFlow<DiscoverGroupsState> = _uiState.asStateFlow()

    // Separate flow for search query to enable debouncing
    private val searchQueryFlow = MutableStateFlow("")

    init {
        observeMyGroups()
        setupSearchDebounce()
        searchGroups() // Initial load
    }

    private fun setupSearchDebounce() {
        searchQueryFlow
            .debounce(300) // Wait 300ms after last keystroke
            .distinctUntilChanged() // Only search if query actually changed
            .onEach { query ->
                performSearch(query)
            }
            .launchIn(viewModelScope)
    }

    fun onSearchQueryChanged(query: String) {
        _uiState.value = _uiState.value.copy(searchQuery = query)
        searchQueryFlow.value = query
    }

    private suspend fun performSearch(query: String) {
        _uiState.value = _uiState.value.copy(isLoading = true)
        try {
            val groups = groupRepository.searchGroups(query)
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                discoveredGroups = groups
            )
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                error = e.localizedMessage
            )
        }
    }

    fun searchGroups(isRefresh: Boolean = false) {
        viewModelScope.launch {
            if (isRefresh) {
                _uiState.value = _uiState.value.copy(refreshing = true)
            }
            performSearch(_uiState.value.searchQuery)
            _uiState.value = _uiState.value.copy(refreshing = false)
        }
    }

    private fun observeMyGroups() {
        viewModelScope.launch {
            groupRepository.getMyGroups().collect { groups ->
                _uiState.value = _uiState.value.copy(myGroups = groups)
            }
        }
    }
}
```

**Updated DiscoverGroupsScreen.kt (lines 105-113):**
```kotlin
if (selectedTabIndex == 0) {
    SearchBar(
        query = uiState.searchQuery,
        onQueryChange = { viewModel.onSearchQueryChanged(it) },  // Remove searchGroups() call
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}
```

---

### 2.3 BarcodeScanner Resource Leak

**Severity:** HIGH  
**Impact:** Memory leak, potential OOM on repeated scanner use  
**File:** `app/src/main/java/com/bookstore/bookapp/presentation/ui/CameraPreview.kt`

#### Problem

The ML Kit `BarcodeScanner` client is created but never closed. Each time the scanner composable is displayed, a new client is created without releasing the previous one.

**Current Code (line 100):**
```kotlin
private class BarcodeAnalyzer(...) : ImageAnalysis.Analyzer {
    private val scanner = BarcodeScanning.getClient(options)
    // scanner.close() is never called
}
```

#### Solution

Close the scanner when the composable is disposed.

**Fixed CameraPreview.kt:**
```kotlin
package com.bookstore.bookapp.presentation.ui

import android.util.Log
import android.view.ViewGroup
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@Composable
fun CameraPreview(
    onBarcodeScanned: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    val cameraProviderFuture = remember { ProcessCameraProvider.getInstance(context) }
    val cameraExecutor: ExecutorService = remember { Executors.newSingleThreadExecutor() }
    
    // Create scanner options and client
    val scannerOptions = remember {
        BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_ALL_FORMATS)
            .build()
    }
    val barcodeScanner = remember { BarcodeScanning.getClient(scannerOptions) }

    DisposableEffect(Unit) {
        onDispose {
            // Properly shut down executor with timeout
            cameraExecutor.shutdown()
            try {
                if (!cameraExecutor.awaitTermination(500, TimeUnit.MILLISECONDS)) {
                    cameraExecutor.shutdownNow()
                }
            } catch (e: InterruptedException) {
                cameraExecutor.shutdownNow()
            }
            
            // Close the barcode scanner to release resources
            barcodeScanner.close()
        }
    }

    AndroidView(
        factory = { ctx ->
            val previewView = PreviewView(ctx).apply {
                this.scaleType = PreviewView.ScaleType.FILL_CENTER
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            }

            cameraProviderFuture.addListener({
                val cameraProvider = cameraProviderFuture.get()

                val preview = Preview.Builder()
                    .build()
                    .also {
                        it.setSurfaceProvider(previewView.surfaceProvider)
                    }

                val imageAnalyzer = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()
                    .also {
                        it.setAnalyzer(cameraExecutor, BarcodeAnalyzer(barcodeScanner) { barcode ->
                            onBarcodeScanned(barcode)
                        })
                    }

                val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                try {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(
                        lifecycleOwner,
                        cameraSelector,
                        preview,
                        imageAnalyzer
                    )
                } catch (exc: Exception) {
                    Log.e("CameraPreview", "Use case binding failed", exc)
                }
            }, ContextCompat.getMainExecutor(ctx))

            previewView
        },
        modifier = modifier.fillMaxSize()
    )
}

private class BarcodeAnalyzer(
    private val scanner: BarcodeScanner,  // Inject scanner instead of creating
    private val onBarcodeDetected: (String) -> Unit
) : ImageAnalysis.Analyzer {

    @androidx.annotation.OptIn(androidx.camera.core.ExperimentalGetImage::class)
    override fun analyze(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)

            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    for (barcode in barcodes) {
                        barcode.rawValue?.let { value ->
                            onBarcodeDetected(value)
                            return@addOnSuccessListener
                        }
                    }
                }
                .addOnFailureListener {
                    Log.e("BarcodeAnalyzer", "Barcode scanning failed", it)
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }
}
```

---

## 3. Medium Priority Issues (P2)

### 3.1 Database: Missing Indices

**Severity:** MEDIUM  
**Impact:** Slow queries as data grows  
**Files:** Entity classes in `data/local/entity/`

#### Problem

Queries filter by columns like `isMyBook`, `isMyGroup`, but these columns lack indices.

#### Solution

Add indices to entity classes.

**Example - BookEntity.kt:**
```kotlin
@Entity(
    tableName = "books",
    indices = [
        Index(value = ["isMyBook"]),
        Index(value = ["ownerId"]),
        Index(value = ["isAvailable"])
    ]
)
data class BookEntity(
    @PrimaryKey val id: String,
    val title: String,
    val author: String,
    // ... other fields
    val isMyBook: Boolean = false,
    val ownerId: String,
    val isAvailable: Boolean
)
```

**BookClubEntity.kt:**
```kotlin
@Entity(
    tableName = "book_clubs",
    indices = [
        Index(value = ["isMyGroup"])
    ]
)
data class BookClubEntity(
    @PrimaryKey val id: String,
    val name: String,
    // ... other fields
    val isMyGroup: Boolean = false
)
```

**TransactionEntity.kt:**
```kotlin
@Entity(
    tableName = "transactions",
    indices = [
        Index(value = ["borrowerId"]),
        Index(value = ["ownerId"]),
        Index(value = ["status"])
    ]
)
data class TransactionEntity(
    @PrimaryKey val id: String,
    val borrowerId: String,
    val ownerId: String,
    val status: String,
    // ... other fields
)
```

---

### 3.2 Database: Non-Atomic Operations

**Severity:** MEDIUM  
**Impact:** Data inconsistency on partial failures  
**File:** `app/src/main/java/com/bookstore/bookapp/data/repository/BookRepositoryImpl.kt`

#### Problem

Clear and insert operations are separate, not in a transaction.

**Current Code (lines 27-28):**
```kotlin
override suspend fun fetchMyBooks() {
    val remoteBooks = bookApi.fetchMyBooks()
    bookDao.clearMyBooks()      // If this succeeds...
    bookDao.insertBooks(...)    // ...but this fails, data is lost
}
```

#### Solution

Use `@Transaction` annotation or `withTransaction`.

**Option 1 - DAO Transaction:**
```kotlin
// BookDao.kt
@Dao
interface BookDao {
    @Transaction
    suspend fun replaceMyBooks(books: List<BookEntity>) {
        clearMyBooks()
        insertBooks(books)
    }
    
    @Query("DELETE FROM books WHERE isMyBook = 1")
    suspend fun clearMyBooks()
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBooks(books: List<BookEntity>)
}
```

**Option 2 - Repository Transaction:**
```kotlin
// BookRepositoryImpl.kt
override suspend fun fetchMyBooks() {
    val remoteBooks = bookApi.fetchMyBooks()
    database.withTransaction {
        bookDao.clearMyBooks()
        bookDao.insertBooks(remoteBooks.map { it.toEntity(isMyBook = true) })
    }
}
```

---

### 3.3 Race Condition in ProfileViewModel

**Severity:** MEDIUM  
**Impact:** Stale data displayed after profile fetch  
**File:** `app/src/main/java/com/bookstore/bookapp/presentation/viewmodel/ProfileViewModel.kt`

#### Problem

After calling `fetchCurrentUser()`, the code immediately reads `currentUser.value`, which may still contain the old value because the Flow hasn't emitted yet.

**Current Code (lines 53-54):**
```kotlin
authRepository.fetchCurrentUser()
val user = currentUser.value  // May still be old value!
```

#### Solution

Either await the Flow update or use the returned value directly.

**Fixed Code:**
```kotlin
fun fetchProfile() {
    viewModelScope.launch {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        try {
            // Option 1: fetchCurrentUser returns the user
            val user = authRepository.fetchCurrentUser()
            
            // Option 2: If fetchCurrentUser updates DataStore, wait for Flow
            // val user = authRepository.currentUser.filterNotNull().first()
            
            var booksAdded = 0
            var booksBorrowed = 0
            var booksLent = 0
            var reputation = 0.0
            
            if (user != null) {
                try {
                    val books = bookRepository.fetchBooks()
                    booksAdded = books.count { it.ownerId == user.id }
                    
                    val borrowedTransactions = transactionRepository.fetchTransactions(role = "BORROWER")
                    booksBorrowed = borrowedTransactions.count { 
                        it.status == TransactionStatus.RETURNED || it.status == TransactionStatus.ACTIVE 
                    }
                    
                    val lentTransactions = transactionRepository.fetchTransactions(role = "OWNER")
                    booksLent = lentTransactions.count { 
                        it.status == TransactionStatus.RETURNED || it.status == TransactionStatus.ACTIVE 
                    }
                    
                    reputation = user.stats.averageRating
                } catch (e: Exception) {
                    // Use proper logging instead of printStackTrace
                    Log.e("ProfileViewModel", "Failed to fetch stats", e)
                }
            }
            
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                booksAddedCount = booksAdded,
                booksBorrowedCount = booksBorrowed,
                booksLentCount = booksLent,
                reputationScore = reputation
            )
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                error = e.localizedMessage
            )
        }
    }
}
```

---

### 3.4 Compose Recomposition Issues

**Severity:** MEDIUM  
**Impact:** UI jank, unnecessary work  
**Files:**
- `app/src/main/java/com/bookstore/bookapp/presentation/ui/AddBookScreen.kt`
- `app/src/main/java/com/bookstore/bookapp/presentation/ui/HomeScreen.kt`

#### Problem 1: `remember` inside conditional blocks

**Current Code (AddBookScreen.kt line 184):**
```kotlin
if (!uiState.isLoading) {
    // This remember resets when isLoading changes!
    var genreExpanded by remember { mutableStateOf(false) }
}
```

**Fix:** Move `remember` to stable call site:
```kotlin
@Composable
fun AddBookScreen(...) {
    val uiState by viewModel.uiState.collectAsState()
    
    // Move remember outside conditional
    var genreExpanded by remember { mutableStateOf(false) }
    var conditionExpanded by remember { mutableStateOf(false) }
    
    // Now safe to use inside conditional
    if (!uiState.isLoading) {
        // Use genreExpanded, conditionExpanded here
    }
}
```

#### Problem 2: Derived lists recomputed every composition

**Current Code (HomeScreen.kt lines 104-106):**
```kotlin
val continueReading = uiState.featuredBooks.take(2)
val availableNearYou = uiState.featuredBooks.filter { it.isAvailable }
val recentlyAdded = uiState.featuredBooks
```

**Fix:** Use `remember` with keys or move to ViewModel:
```kotlin
// Option 1: remember with key
val continueReading = remember(uiState.featuredBooks) {
    uiState.featuredBooks.take(2)
}
val availableNearYou = remember(uiState.featuredBooks) {
    uiState.featuredBooks.filter { it.isAvailable }
}

// Option 2: derivedStateOf (for expensive computations)
val availableNearYou by remember {
    derivedStateOf { uiState.featuredBooks.filter { it.isAvailable } }
}

// Option 3 (Best): Move to ViewModel state
data class HomeState(
    val featuredBooks: List<Book> = emptyList(),
    val continueReading: List<Book> = emptyList(),  // Pre-computed
    val availableNearYou: List<Book> = emptyList()  // Pre-computed
)
```

#### Problem 3: Non-lazy list for groups

**Current Code (AddBookScreen.kt lines 304-318):**
```kotlin
uiState.userGroups.forEach { group ->
    Row(...) {
        Text(group.name)
        Checkbox(...)
    }
}
```

**Fix:** Use LazyColumn for many items:
```kotlin
LazyColumn(
    modifier = Modifier.heightIn(max = 200.dp)  // Limit height
) {
    items(uiState.userGroups, key = { it.id }) { group ->
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { viewModel.toggleGroupSelection(group.id) }
                .padding(vertical = 4.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(group.name, modifier = Modifier.weight(1f))
            Checkbox(
                checked = uiState.selectedGroupIds.contains(group.id),
                onCheckedChange = { viewModel.toggleGroupSelection(group.id) }
            )
        }
    }
}
```

---

### 3.5 Destructive Database Migrations

**Severity:** MEDIUM  
**Impact:** User data loss on app updates  
**File:** `app/src/main/java/com/bookstore/bookapp/di/DatabaseModule.kt`

#### Problem

`fallbackToDestructiveMigration()` wipes all local data when the schema changes.

**Current Code (line 27):**
```kotlin
Room.databaseBuilder(...)
    .fallbackToDestructiveMigration()
    .build()
```

#### Solution

Implement proper migrations.

**Fixed Code:**
```kotlin
@Provides
@Singleton
fun provideBookShareDatabase(@ApplicationContext context: Context): BookShareDatabase {
    return Room.databaseBuilder(
        context,
        BookShareDatabase::class.java,
        "bookshare_db"
    )
    .addMigrations(MIGRATION_1_2, MIGRATION_2_3)  // Add migrations
    // Only use destructive migration as last resort in development
    // .fallbackToDestructiveMigration()
    .build()
}

// Define migrations
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Add new column
        database.execSQL("ALTER TABLE books ADD COLUMN new_field TEXT DEFAULT ''")
    }
}

val MIGRATION_2_3 = object : Migration(2, 3) {
    override fun migrate(database: SupportSQLiteDatabase) {
        // Create index
        database.execSQL("CREATE INDEX IF NOT EXISTS index_books_isMyBook ON books(isMyBook)")
    }
}
```

---

## 4. Low Priority Issues (P3)

### 4.1 Unused Async Result

**Severity:** LOW  
**Impact:** Wasted computation  
**File:** `app/src/main/java/com/bookstore/bookapp/presentation/viewmodel/HomeViewModel.kt`

#### Problem

`groupsDummy` is fetched but never used.

**Current Code (lines 48-58):**
```kotlin
val (groupsDummy, feedBooks) = coroutineScope {
    val groupsDeferred = async { 
        groupRepository.fetchMyGroups()
        groupRepository.getMyGroups()  // Returns Flow, never collected
    }
    // ...
}
```

#### Solution

Either use the result or remove the unnecessary fetch.

**Fixed Code:**
```kotlin
fun fetchHomeData(isRefresh: Boolean = false) {
    viewModelScope.launch {
        if (isRefresh) {
            _uiState.value = _uiState.value.copy(refreshing = true, error = null)
        } else {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        }

        try {
            // Fetch in parallel only what we need
            val feedBooks = bookRepository.fetchBooks(limit = 10, sortBy = "RECENT")
            
            // If we need groups, fetch them separately and observe via Flow
            groupRepository.fetchMyGroups()  // Just update local DB

            _uiState.value = _uiState.value.copy(
                isLoading = false,
                refreshing = false,
                featuredBooks = feedBooks
            )
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                refreshing = false,
                error = e.localizedMessage
            )
        }
    }
}
```

---

### 4.2 Build Minification Disabled

**Severity:** LOW  
**Impact:** Larger APK, no obfuscation  
**File:** `app/build.gradle.kts`

#### Problem

Release builds are not minified.

**Current Code (line 28):**
```kotlin
release {
    isMinifyEnabled = false
    proguardFiles(...)
}
```

#### Solution

Enable minification and create ProGuard rules.

**Fixed build.gradle.kts:**
```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

**Create proguard-rules.pro:**
```proguard
# Keep data classes for Gson/Retrofit serialization
-keepclassmembers class com.bookstore.bookapp.data.remote.** { *; }
-keepclassmembers class com.bookstore.bookapp.domain.model.** { *; }

# Keep Room entities
-keep class com.bookstore.bookapp.data.local.entity.** { *; }

# Retrofit
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keepclasseswithmembers class * {
    @retrofit2.http.* <methods>;
}

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Gson
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*

# Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }
-keep class * extends dagger.hilt.android.lifecycle.HiltViewModel

# ML Kit
-keep class com.google.mlkit.** { *; }

# CameraX
-keep class androidx.camera.** { *; }
```

---

## 5. Testing Recommendations

### 5.1 ANR Testing

```bash
# Enable strict mode in debug builds
# Add to Application.onCreate():
if (BuildConfig.DEBUG) {
    StrictMode.setThreadPolicy(
        StrictMode.ThreadPolicy.Builder()
            .detectDiskReads()
            .detectDiskWrites()
            .detectNetwork()
            .penaltyLog()
            .penaltyDeath()  // Crash on violations
            .build()
    )
}
```

### 5.2 Memory Leak Testing

1. Use Android Studio Profiler
2. Use LeakCanary library:
```kotlin
// build.gradle.kts
debugImplementation("com.squareup.leakcanary:leakcanary-android:2.12")
```

### 5.3 Performance Testing

```kotlin
// Add to debug builds for recomposition tracking
@Composable
fun MyScreen() {
    SideEffect {
        Log.d("Recomposition", "MyScreen recomposed")
    }
}
```

### 5.4 Network Testing

- Test with airplane mode
- Test with slow network (use Android Emulator's network throttling)
- Test with intermittent connectivity

---

## 6. Performance Metrics to Track

### 6.1 App Startup Time
- Cold start: < 2 seconds
- Warm start: < 1 second

### 6.2 Frame Rate
- Target: 60 fps
- Jank frames: < 1%

### 6.3 Memory Usage
- Peak memory: < 200MB
- No memory leaks after navigation cycles

### 6.4 Network
- API response time: < 2 seconds
- Retry on transient failures

### 6.5 Battery
- Background CPU: < 1%
- No wakelocks held unnecessarily

---

## 7. Implementation Checklist

### P0 - Critical (Do First)

- [ ] Create `TokenHolder` class for non-blocking token access
- [ ] Update `NetworkModule` to use `TokenHolder`
- [ ] Update `TokenAuthenticator` to use `TokenHolder`
- [ ] Add `BuildConfig.DEBUG` check for HTTP logging
- [ ] Fix hardcoded `"CURRENT_USER_ID"` in `MyLibraryViewModel`

### P1 - High Priority

- [ ] Add OkHttp timeouts (connect, read, write, call)
- [ ] Implement search debouncing in `DiscoverGroupsViewModel`
- [ ] Update `DiscoverGroupsScreen` to not call search on every keystroke
- [ ] Fix `CameraPreview` to close `BarcodeScanner` on dispose

### P2 - Medium Priority

- [ ] Add database indices to entity classes
- [ ] Wrap clear+insert operations in transactions
- [ ] Fix race condition in `ProfileViewModel`
- [ ] Move `remember` calls outside conditionals in `AddBookScreen`
- [ ] Use `remember` with keys for derived lists in `HomeScreen`
- [ ] Convert group list to `LazyColumn` in `AddBookScreen`
- [ ] Replace `fallbackToDestructiveMigration` with proper migrations

### P3 - Low Priority

- [ ] Remove unused `groupsDummy` fetch in `HomeViewModel`
- [ ] Enable minification in release builds
- [ ] Create `proguard-rules.pro` file
- [ ] Replace `e.printStackTrace()` with proper logging

---

## Appendix: Quick Reference

### Files Changed Summary

| File | Changes |
|------|---------|
| `di/NetworkModule.kt` | Add timeouts, conditional logging, use TokenHolder |
| `di/TokenAuthenticator.kt` | Use TokenHolder, reduce runBlocking |
| `di/TokenHolder.kt` | NEW FILE - In-memory token cache |
| `di/DatabaseModule.kt` | Add migrations, remove destructive fallback |
| `viewmodel/MyLibraryViewModel.kt` | Inject AuthRepository, use real user ID |
| `viewmodel/DiscoverGroupsViewModel.kt` | Add search debouncing |
| `viewmodel/ProfileViewModel.kt` | Fix race condition |
| `viewmodel/HomeViewModel.kt` | Remove unused fetch |
| `ui/DiscoverGroupsScreen.kt` | Remove search call from onQueryChange |
| `ui/CameraPreview.kt` | Close BarcodeScanner on dispose |
| `ui/AddBookScreen.kt` | Fix remember placement, use LazyColumn |
| `ui/HomeScreen.kt` | Use remember with keys |
| `data/local/entity/*.kt` | Add indices |
| `data/local/dao/*.kt` | Add @Transaction methods |
| `build.gradle.kts` | Enable minification |
| `proguard-rules.pro` | NEW FILE - ProGuard rules |

---

*Document created: March 14, 2026*  
*Last updated: March 14, 2026*
