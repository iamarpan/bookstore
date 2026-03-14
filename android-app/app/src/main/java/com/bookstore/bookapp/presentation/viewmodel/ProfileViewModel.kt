package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.User
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val isEditing: Boolean = false,
    val editName: String = "",
    val editBio: String = "",
    val booksAddedCount: Int = 0,
    val booksBorrowedCount: Int = 0,
    val booksLentCount: Int = 0,
    val reputationScore: Double = 0.0,
    val isNotificationsEnabled: Boolean = true
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val bookRepository: BookRepository,
    private val transactionRepository: TransactionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileState())
    val uiState: StateFlow<ProfileState> = _uiState.asStateFlow()

    val currentUser: StateFlow<User?> = authRepository.currentUser
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    init {
        fetchProfile()
    }

    fun fetchProfile() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.fetchCurrentUser()
                val user = currentUser.value
                
                var booksAdded = 0
                var booksBorrowed = 0
                var booksLent = 0
                var reputation = 0.0
                
                if (user != null) {
                    try {
                        val books = bookRepository.fetchBooks()
                        booksAdded = books.filter { it.ownerId == user.id }.size
                        
                        val borrowedTransactions = transactionRepository.fetchTransactions(role = "BORROWER")
                        booksBorrowed = borrowedTransactions.count { it.status == TransactionStatus.RETURNED || it.status == TransactionStatus.ACTIVE }
                        
                        val lentTransactions = transactionRepository.fetchTransactions(role = "OWNER")
                        booksLent = lentTransactions.count { it.status == TransactionStatus.RETURNED || it.status == TransactionStatus.ACTIVE }
                        
                        reputation = user.stats.averageRating
                    } catch (e: Exception) {
                        // Keep values at 0 if stats fail to fetch, but don't fail the whole profile fetch
                        e.printStackTrace()
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
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.localizedMessage)
            }
        }
    }

    fun startEditing() {
        val user = currentUser.value
        if (user != null) {
            _uiState.value = _uiState.value.copy(
                isEditing = true,
                editName = user.name,
                editBio = user.bio ?: ""
            )
        }
    }

    fun cancelEditing() {
        _uiState.value = _uiState.value.copy(isEditing = false)
    }

    fun onNameChange(name: String) {
        _uiState.value = _uiState.value.copy(editName = name)
    }

    fun onBioChange(bio: String) {
        _uiState.value = _uiState.value.copy(editBio = bio)
    }

    fun saveProfile() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.updateProfile(
                    name = _uiState.value.editName.ifBlank { null },
                    bio = _uiState.value.editBio.ifBlank { null },
                    profileImageUrl = currentUser.value?.profileImageUrl
                )
                _uiState.value = _uiState.value.copy(isLoading = false, isEditing = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.localizedMessage)
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
        }
    }
    
    fun toggleNotifications(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(isNotificationsEnabled = enabled)
        // In a real app, update settings repository/preferences
    }
}
