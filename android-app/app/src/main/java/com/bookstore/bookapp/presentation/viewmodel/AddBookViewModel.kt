package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.BookCondition
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.GroupRepository
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
    val genre: String = "Fiction",
    val condition: BookCondition = BookCondition.GOOD,
    val isAvailable: Boolean = true,
    val personalNotes: String = "",
    val lendingPrice: String = "",
    val imageUrl: String = "",

    // Groups
    val userGroups: List<BookClub> = emptyList(),
    val selectedGroupIds: Set<String> = emptySet()
) {
    val isFormValid: Boolean
        get() = title.isNotBlank() && author.isNotBlank() && description.isNotBlank() && selectedGroupIds.isNotEmpty()
}

@HiltViewModel
class AddBookViewModel @Inject constructor(
    private val bookRepository: BookRepository,
    private val groupRepository: GroupRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AddBookState())
    val uiState: StateFlow<AddBookState> = _uiState.asStateFlow()

    init {
        fetchUserGroups()
    }

    private fun fetchUserGroups() {
        viewModelScope.launch {
            try {
                // Trigger refresh from network if needed
                groupRepository.fetchMyGroups()
            } catch (e: Exception) {
                // Ignore network errors, flow will emit cached data
            }
            
            groupRepository.getMyGroups().collect { groups ->
                val currentSelectedIds = _uiState.value.selectedGroupIds
                val newSelectedIds = if (currentSelectedIds.isEmpty() && groups.isNotEmpty()) {
                    setOf(groups.first().id)
                } else {
                    currentSelectedIds
                }
                
                _uiState.value = _uiState.value.copy(
                    userGroups = groups,
                    selectedGroupIds = newSelectedIds
                )
            }
        }
    }

    fun updateField(
        title: String? = null,
        author: String? = null,
        description: String? = null,
        genre: String? = null,
        condition: BookCondition? = null,
        isAvailable: Boolean? = null,
        personalNotes: String? = null,
        lendingPrice: String? = null,
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

    fun toggleGroupSelection(groupId: String) {
        val current = _uiState.value
        val currentSelections = current.selectedGroupIds.toMutableSet()
        if (currentSelections.contains(groupId)) {
            currentSelections.remove(groupId)
        } else {
            currentSelections.add(groupId)
        }
        _uiState.value = current.copy(selectedGroupIds = currentSelections)
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
        if (!state.isFormValid) {
            _uiState.value = state.copy(errorMessage = "Please fill in all required fields and select at least one group")
            return
        }

        viewModelScope.launch {
            _uiState.value = state.copy(isLoading = true, errorMessage = null)
            try {
                val priceValue = state.lendingPrice.toDoubleOrNull() ?: 0.0

                val newBook = Book(
                    id = "", // Will be assigned by backend
                    title = state.title.trim(),
                    author = state.author.trim(),
                    genre = state.genre,
                    description = state.description.trim(),
                    personalNotes = state.personalNotes.ifBlank { null },
                    imageUrl = state.imageUrl.ifBlank { "https://via.placeholder.com/150" }, // Placeholder matching iOS
                    isbn = state.isbnQuery.ifBlank { null },
                    publisher = null,
                    year = null,
                    pages = null,
                    language = null,
                    condition = state.condition,
                    lendingPricePerWeek = priceValue,
                    isAvailable = state.isAvailable,
                    ownerId = "", // Assigned by backend
                    ownerName = "",
                    ownerRating = null,
                    ownerBooksCount = null,
                    ownerProfileImageUrl = null,
                    visibleInGroups = state.selectedGroupIds.toList(),
                    currentTransactionId = null,
                    createdAt = Date(),
                    updatedAt = null
                )

                bookRepository.createBook(newBook)
                _uiState.value = _uiState.value.copy(isLoading = false, success = true)
                resetForm()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, errorMessage = "Failed to add book: ${e.localizedMessage}")
            }
        }
    }

    private fun resetForm() {
        _uiState.value = _uiState.value.copy(
            title = "",
            author = "",
            description = "",
            genre = "Fiction",
            lendingPrice = "",
            condition = BookCondition.GOOD,
            isAvailable = true,
            isbnQuery = "",
            imageUrl = ""
            // Keep userGroups and selectedGroupIds
        )
    }
}
