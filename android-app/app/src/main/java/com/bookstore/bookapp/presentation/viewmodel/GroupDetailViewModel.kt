package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupMember
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
    val members: List<GroupMember> = emptyList(),
    val error: String? = null,
    val isActionLoading: Boolean = false,
    val actionSuccess: String? = null,
    val isDeleted: Boolean = false,
    val hasLeft: Boolean = false
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
                val members = try {
                    groupRepository.fetchGroupMembers(id).take(5)
                } catch (e: Exception) {
                    emptyList()
                }
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    group = groupInfo,
                    books = groupBooks.first,
                    members = members
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "An unexpected error occurred."
                )
            }
        }
    }

    fun leaveGroup() {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true, error = null)
            try {
                groupRepository.leaveGroup(id)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    hasLeft = true,
                    actionSuccess = "You have left the group"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to leave group"
                )
            }
        }
    }

    fun deleteGroup() {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true, error = null)
            try {
                groupRepository.deleteGroup(id)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    isDeleted = true,
                    actionSuccess = "Group has been deleted"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to delete group"
                )
            }
        }
    }

    fun clearActionSuccess() {
        _uiState.value = _uiState.value.copy(actionSuccess = null)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
