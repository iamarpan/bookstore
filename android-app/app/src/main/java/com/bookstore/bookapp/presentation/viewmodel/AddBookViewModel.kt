package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookCondition
import com.bookstore.bookapp.domain.repository.BookRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Date
import javax.inject.Inject

data class AddBookState(
    val isLoading: Boolean = false,
    val isScanning: Boolean = false,
    val isbnQuery: String = "",
    val errorMessage: String? = null,
    val success: Boolean = false,
    
    // Form fields
    val title: String = "",
    val author: String = "",
    val description: String = "",
    val genre: String = "",
    val condition: BookCondition = BookCondition.GOOD,
    val isAvailable: Boolean = true,
    val personalNotes: String = "",
    val lendingPrice: Double = 0.0,
    val imageUrl: String = ""
)

@HiltViewModel
class AddBookViewModel @Inject constructor(
    private val bookRepository: BookRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AddBookState())
    val uiState: StateFlow<AddBookState> = _uiState.asStateFlow()

    fun updateField(
        title: String? = null,
        author: String? = null,
        description: String? = null,
        genre: String? = null,
        condition: BookCondition? = null,
        isAvailable: Boolean? = null,
        personalNotes: String? = null,
        lendingPrice: Double? = null,
        imageUrl: String? = null
    ) {
        val current = _uiState.value
        _uiState.value = current.copy(
            title = title ?: current.title,
            author = author ?: current.author,
            description = description ?: current.description,
            genre = genre ?: current.genre,
            condition = condition ?: current.condition,
            isAvailable = isAvailable ?: current.isAvailable,
            personalNotes = personalNotes ?: current.personalNotes,
            lendingPrice = lendingPrice ?: current.lendingPrice,
            imageUrl = imageUrl ?: current.imageUrl
        )
    }

    fun onIsbnQueryChange(isbn: String) {
        _uiState.value = _uiState.value.copy(isbnQuery = isbn)
    }

    fun toggleScanner() {
        val current = _uiState.value
        _uiState.value = current.copy(isScanning = !current.isScanning, errorMessage = null)
    }

    fun lookupIsbn(isbn: String) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, isScanning = false, errorMessage = null)
            try {
                // Try backend scan logic
                var book = bookRepository.lookupISBN(isbn)
                
                // Fallback to Google Books external if backend fails/not implemented fully or returned null
                if (book == null) {
                    book = bookRepository.searchISBNExternal(isbn)
                }

                if (book != null) {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        title = book.title,
                        author = book.author,
                        description = book.description,
                        genre = book.genre,
                        imageUrl = book.imageUrl,
                        isbnQuery = isbn
                    )
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        errorMessage = "Book not found for this ISBN. Please enter details manually."
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    errorMessage = "Error looking up ISBN: ${e.localizedMessage}"
                )
            }
        }
    }

    fun saveBook() {
        val state = _uiState.value
        if (state.title.isBlank() || state.author.isBlank()) {
            _uiState.value = state.copy(errorMessage = "Title and Author are required")
            return
        }

        viewModelScope.launch {
            _uiState.value = state.copy(isLoading = true, errorMessage = null)
            try {
                val newBook = Book(
                    id = "", // Will be assigned by backend
                    title = state.title,
                    author = state.author,
                    genre = state.genre.ifBlank { "General" },
                    description = state.description,
                    personalNotes = state.personalNotes.ifBlank { null },
                    imageUrl = state.imageUrl,
                    isbn = state.isbnQuery.ifBlank { null },
                    publisher = null,
                    year = null,
                    pages = null,
                    language = null,
                    condition = state.condition,
                    lendingPricePerWeek = state.lendingPrice,
                    isAvailable = state.isAvailable,
                    ownerId = "", // Assigned by backend
                    ownerName = "",
                    ownerRating = null,
                    ownerBooksCount = null,
                    ownerProfileImageUrl = null,
                    visibleInGroups = emptyList(), // Assigned by user during creation ideally, simple for now
                    currentTransactionId = null,
                    createdAt = Date(),
                    updatedAt = null
                )

                bookRepository.createBook(newBook)
                _uiState.value = _uiState.value.copy(isLoading = false, success = true)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, errorMessage = e.localizedMessage)
            }
        }
    }
}
