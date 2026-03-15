package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class GroupDetailUiState(
    val isLoading: Boolean = true,
    val group: BookClub? = null,
    val books: List<Book> = emptyList(),
    val error: String? = null
)

@HiltViewModel
class GroupDetailViewModel @Inject constructor(
    private val groupRepository: GroupRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(GroupDetailUiState())
    val uiState: StateFlow<GroupDetailUiState> = _uiState.asStateFlow()

    private val groupId: String? = savedStateHandle["groupId"]

    init {
        if (groupId != null) {
            loadGroupDetails()
        } else {
            _uiState.value = _uiState.value.copy(isLoading = false, error = "Invalid group")
        }
    }

    private fun loadGroupDetails() {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val groupInfo = groupRepository.fetchGroupDetails(id)
                val groupBooks = groupRepository.fetchGroupBooks(id)
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    group = groupInfo,
                    books = groupBooks.first
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "An unexpected error occurred."
                )
            }
        }
    }
}
