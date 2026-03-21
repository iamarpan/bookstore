package com.bookstore.bookapp.presentation.viewmodel

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
import javax.inject.Inject

data class CreateGroupState(
    val name: String = "",
    val description: String = "",
    val category: GroupCategory = GroupCategory.FRIENDS,
    val privacy: PrivacySetting = PrivacySetting.PUBLIC,
    val rules: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val createdGroup: BookClub? = null,
    val isSuccess: Boolean = false
) {
    val isValid: Boolean
        get() = name.isNotBlank() && description.isNotBlank()
    
    val nameError: String?
        get() = if (name.isBlank()) "Name is required" else null
    
    val descriptionError: String?
        get() = if (description.isBlank()) "Description is required" else null
}

@HiltViewModel
class CreateGroupViewModel @Inject constructor(
    private val groupRepository: GroupRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CreateGroupState())
    val uiState: StateFlow<CreateGroupState> = _uiState.asStateFlow()

    fun onNameChange(name: String) {
        _uiState.value = _uiState.value.copy(name = name, error = null)
    }

    fun onDescriptionChange(description: String) {
        _uiState.value = _uiState.value.copy(description = description, error = null)
    }

    fun onCategoryChange(category: GroupCategory) {
        _uiState.value = _uiState.value.copy(category = category)
    }

    fun onPrivacyChange(privacy: PrivacySetting) {
        _uiState.value = _uiState.value.copy(privacy = privacy)
    }

    fun onRulesChange(rules: String) {
        _uiState.value = _uiState.value.copy(rules = rules)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun createGroup() {
        val state = _uiState.value
        if (!state.isValid) {
            _uiState.value = state.copy(error = "Please fill in all required fields")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val group = groupRepository.createGroup(
                    name = state.name.trim(),
                    description = state.description.trim(),
                    category = state.category,
                    privacy = state.privacy,
                    rules = state.rules.trim().ifBlank { null }
                )
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    createdGroup = group,
                    isSuccess = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to create group"
                )
            }
        }
    }

    fun resetState() {
        _uiState.value = CreateGroupState()
    }
}
