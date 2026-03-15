package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BorrowDuration
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class BookDetailState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val book: Book? = null,
    val isRequesting: Boolean = false,
    val requestSuccess: Boolean = false
)

@HiltViewModel
class BookDetailViewModel @Inject constructor(
    private val bookRepository: BookRepository,
    private val transactionRepository: TransactionRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val bookId: String? = savedStateHandle["bookId"]

    private val _uiState = MutableStateFlow(BookDetailState(isLoading = bookId != null, error = if (bookId == null) "Invalid book" else null))
    val uiState: StateFlow<BookDetailState> = _uiState.asStateFlow()

    init {
        if (bookId != null) {
            loadBook()
        }
    }

    fun loadBook() {
        val id = bookId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val book = bookRepository.fetchBook(id)
                _uiState.value = _uiState.value.copy(isLoading = false, book = book)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.localizedMessage)
            }
        }
    }

    fun requestToBorrow(duration: BorrowDuration, customDays: Int? = null, message: String? = null) {
        val id = bookId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRequesting = true, error = null)
            try {
                transactionRepository.createBorrowRequest(id, duration, customDays, message)
                _uiState.value = _uiState.value.copy(isRequesting = false, requestSuccess = true)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isRequesting = false, error = e.localizedMessage)
            }
        }
    }
}
