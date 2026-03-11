package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch
import javax.inject.Inject

data class MyLibraryState(
    val isLoading: Boolean = false,
    val refreshing: Boolean = false,
    val error: String? = null,
    val myBooks: List<Book> = emptyList(),
    val borrowedBooks: List<Transaction> = emptyList(), // Borrowed by me
    val lentBooks: List<Transaction> = emptyList()      // Lent to others
)

@HiltViewModel
class MyLibraryViewModel @Inject constructor(
    private val bookRepository: BookRepository,
    private val transactionRepository: TransactionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MyLibraryState(isLoading = true))
    val uiState: StateFlow<MyLibraryState> = _uiState.asStateFlow()

    init {
        observeMyBooks()
        observeTransactions()
        
        // Initial fetch
        refresh()
    }

    private fun observeMyBooks() {
        viewModelScope.launch {
            bookRepository.getMyBooks()
                .catch { e ->
                    // Handle error if needed
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
            transactionRepository.activeTransactions
                .collect { txs ->
                    val borrowed = txs.filter { it.isBorrower("CURRENT_USER_ID") } // Ideally check actual user id
                    val lent = txs.filter { it.isOwner("CURRENT_USER_ID") }
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
                _uiState.value = _uiState.value.copy(refreshing = false, error = e.localizedMessage)
            }
        }
    }
}
