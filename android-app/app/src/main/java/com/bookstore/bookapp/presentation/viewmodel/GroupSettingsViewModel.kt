package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupCategory
import com.bookstore.bookapp.domain.model.PrivacySetting
import com.bookstore.bookapp.domain.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Date
import javax.inject.Inject

data class GroupSettingsState(
    val isLoading: Boolean = true,
    val isSaving: Boolean = false,
    val group: BookClub? = null,
    val name: String = "",
    val description: String = "",
    val category: GroupCategory = GroupCategory.FRIENDS,
    val privacy: PrivacySetting = PrivacySetting.PUBLIC,
    val rules: String = "",
    val inviteCode: String = "",
    val inviteCodeExpiry: Date? = null,
    val isRegeneratingCode: Boolean = false,
    val error: String? = null,
    val saveSuccess: Boolean = false,
    val hasChanges: Boolean = false
)

@HiltViewModel
class GroupSettingsViewModel @Inject constructor(
    private val groupRepository: GroupRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(GroupSettingsState())
    val uiState: StateFlow<GroupSettingsState> = _uiState.asStateFlow()

    private val groupId: String? = savedStateHandle["groupId"]

    init {
        loadGroup()
    }

    private fun loadGroup() {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val group = groupRepository.fetchGroupDetails(id)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    group = group,
                    name = group.name,
                    description = group.description,
                    category = group.category,
                    privacy = group.privacy,
                    rules = group.rules ?: "",
                    inviteCode = group.inviteCode,
                    inviteCodeExpiry = group.inviteCodeExpiry
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load group"
                )
            }
        }
    }

    fun onNameChange(name: String) {
        _uiState.value = _uiState.value.copy(name = name, hasChanges = true)
    }

    fun onDescriptionChange(description: String) {
        _uiState.value = _uiState.value.copy(description = description, hasChanges = true)
    }

    fun onCategoryChange(category: GroupCategory) {
        _uiState.value = _uiState.value.copy(category = category, hasChanges = true)
    }

    fun onPrivacyChange(privacy: PrivacySetting) {
        _uiState.value = _uiState.value.copy(privacy = privacy, hasChanges = true)
    }

    fun onRulesChange(rules: String) {
        _uiState.value = _uiState.value.copy(rules = rules, hasChanges = true)
    }

    fun saveChanges() {
        val id = groupId ?: return
        val state = _uiState.value
        
        if (state.name.isBlank() || state.description.isBlank()) {
            _uiState.value = state.copy(error = "Name and description are required")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSaving = true, error = null)
            try {
                val updatedGroup = groupRepository.updateGroup(
                    id = id,
                    name = state.name.trim(),
                    description = state.description.trim(),
                    category = state.category,
                    privacy = state.privacy,
                    rules = state.rules.trim().ifBlank { null }
                )
                _uiState.value = _uiState.value.copy(
                    isSaving = false,
                    group = updatedGroup,
                    hasChanges = false,
                    saveSuccess = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSaving = false,
                    error = e.localizedMessage ?: "Failed to save changes"
                )
            }
        }
    }

    fun regenerateInviteCode() {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRegeneratingCode = true, error = null)
            try {
                val (newCode, expiry) = groupRepository.regenerateInviteCode(id)
                _uiState.value = _uiState.value.copy(
                    isRegeneratingCode = false,
                    inviteCode = newCode,
                    inviteCodeExpiry = expiry
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isRegeneratingCode = false,
                    error = e.localizedMessage ?: "Failed to regenerate invite code"
                )
            }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun clearSaveSuccess() {
        _uiState.value = _uiState.value.copy(saveSuccess = false)
    }
}
