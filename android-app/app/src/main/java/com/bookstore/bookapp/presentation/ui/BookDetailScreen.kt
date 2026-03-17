package com.bookstore.bookapp.presentation.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.bookstore.bookapp.domain.model.BorrowDuration
import com.bookstore.bookapp.presentation.ui.components.AvailabilityBadge
import com.bookstore.bookapp.presentation.ui.components.BookCoverImage
import com.bookstore.bookapp.presentation.ui.components.ConditionDots
import com.bookstore.bookapp.presentation.ui.components.LendingTermsCard
import com.bookstore.bookapp.presentation.ui.components.OwnerInfoCard
import com.bookstore.bookapp.presentation.viewmodel.BookDetailViewModel

/** Ensures Text() never receives null or blank; Gson can leave fields null at runtime. */
private fun safeText(value: String?, default: String): String =
    value?.takeIf { it.isNotBlank() } ?: default

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun BookDetailScreen(
    onNavigateBack: () -> Unit,
    viewModel: BookDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        },
        bottomBar = {
            if (uiState.book != null) {
                val book = uiState.book!!
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shadowElevation = 8.dp,
                    color = MaterialTheme.colorScheme.surface
                ) {
                    Box(
                        modifier = Modifier
                            .windowInsetsPadding(WindowInsets.navigationBars)
                            .padding(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        when {
                            uiState.isOwnBook -> {
                                Button(
                                    onClick = { /* no-op, user owns this book */ },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(56.dp),
                                    enabled = false
                                ) {
                                    Text("You own this book")
                                }
                            }
                            uiState.requestSuccess -> {
                                Text(
                                    text = "Borrow request sent successfully!",
                                    color = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.align(Alignment.Center)
                                )
                            }
                            book.isAvailable -> {
                                Button(
                                    onClick = { viewModel.requestToBorrow(duration = BorrowDuration.TWO_WEEKS) },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(56.dp),
                                    enabled = !uiState.isRequesting
                                ) {
                                    if (uiState.isRequesting) {
                                        CircularProgressIndicator(color = MaterialTheme.colorScheme.onPrimary)
                                    } else {
                                        Text("Request to Borrow")
                                    }
                                }
                            }
                            else -> {
                                Button(
                                    onClick = { /* TODO: Notify when available */ },
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(56.dp),
                                    enabled = true
                                ) {
                                    Text("Notify Me When Available")
                                }
                            }
                        }
                    }
                }
            }
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            if (uiState.isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (uiState.error != null) {
                Text(
                    text = uiState.error!!,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.align(Alignment.Center)
                )
            } else if (uiState.book != null) {
                val book = uiState.book!!
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    // Hero image section with 3D effect / shadow wrapper
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 32.dp, vertical = 16.dp)
                            .shadow(elevation = 16.dp, shape = RoundedCornerShape(16.dp), spotColor = MaterialTheme.colorScheme.primary)
                    ) {
                        BookCoverImage(
                            imageUrl = book.imageUrl,
                            contentDescription = "Cover of ${safeText(book.title as String?, "book")}",
                            title = safeText(book.title as String?, ""),
                            author = safeText(book.author as String?, ""),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = safeText(book.title as String?, "Untitled"),
                        style = MaterialTheme.typography.headlineMedium
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "by ${safeText(book.author as String?, "Unknown")}",
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(modifier = Modifier.height(16.dp))
                    
                    // Quick glance chips
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        AvailabilityBadge(isAvailable = book.isAvailable, modifier = Modifier)
                        Spacer(modifier = Modifier.width(12.dp))
                        ConditionDots(condition = book.condition, modifier = Modifier)
                    }

                    Spacer(modifier = Modifier.height(24.dp))
                    
                    // Advanced Component Integration
                    OwnerInfoCard(book = book)
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    LendingTermsCard(book = book)

                    Spacer(modifier = Modifier.height(24.dp))
                    
                    Text(
                        text = "Description",
                        style = MaterialTheme.typography.titleMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = safeText(book.description as String?, "No description."),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    val visibleInGroups = book.visibleInGroups ?: emptyList()
                    if (visibleInGroups.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(24.dp))
                        Text(
                            text = "Also in these groups",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            visibleInGroups.forEach { groupId ->
                                Surface(
                                    shape = RoundedCornerShape(16.dp),
                                    color = MaterialTheme.colorScheme.secondaryContainer
                                ) {
                                    Text(
                                        text = "Group $groupId", // In a real app, map ID to name
                                        style = MaterialTheme.typography.bodySmall,
                                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                                        color = MaterialTheme.colorScheme.onSecondaryContainer
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(32.dp))
                }
            }
        }
    }
}
