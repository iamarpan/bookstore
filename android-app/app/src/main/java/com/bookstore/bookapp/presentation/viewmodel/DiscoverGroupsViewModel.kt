package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupCategory
import com.bookstore.bookapp.domain.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DiscoverGroupsState(
    val isLoading: Boolean = false,
    val refreshing: Boolean = false,
    val error: String? = null,
    val discoveredGroups: List<BookClub> = emptyList(),
    val myGroups: List<BookClub> = emptyList(),
    val searchQuery: String = "",
    val selectedCategory: GroupCategory? = null
)

@OptIn(FlowPreview::class)
@HiltViewModel
class DiscoverGroupsViewModel @Inject constructor(
    private val groupRepository: GroupRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DiscoverGroupsState(isLoading = true))
    val uiState: StateFlow<DiscoverGroupsState> = _uiState.asStateFlow()

    private val searchQueryFlow = MutableStateFlow("")

    init {
        observeMyGroups()
        setupSearchDebounce()
        searchGroups()
    }

    private fun setupSearchDebounce() {
        searchQueryFlow
            .debounce(300)
            .distinctUntilChanged()
            .onEach { query ->
                _uiState.value = _uiState.value.copy(searchQuery = query)
                searchGroups()
            }
            .launchIn(viewModelScope)
    }

    private fun observeMyGroups() {
        viewModelScope.launch {
            groupRepository.getMyGroups().collect { groups ->
                _uiState.value = _uiState.value.copy(myGroups = groups)
            }
        }
    }

    fun onSearchQueryChanged(query: String) {
        _uiState.value = _uiState.value.copy(searchQuery = query)
        searchQueryFlow.value = query
    }

    fun onCategorySelected(category: GroupCategory?) {
        _uiState.value = _uiState.value.copy(selectedCategory = category)
        searchGroups()
    }

    fun searchGroups(isRefresh: Boolean = false) {
        viewModelScope.launch {
            if (isRefresh) {
                _uiState.value = _uiState.value.copy(refreshing = true, error = null)
                // In a real app we might also refetch myGroups
                groupRepository.fetchMyGroups()
            } else {
                _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            }
            try {
                val state = _uiState.value
                val groups = groupRepository.discoverGroups(
                    category = state.selectedCategory,
                    search = state.searchQuery.ifBlank { null }
                )
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    refreshing = false,
                    discoveredGroups = groups
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    refreshing = false,
                    error = e.localizedMessage
                )
            }
        }
    }

    fun joinPublicGroup(groupId: String) {
        viewModelScope.launch {
            try {
                groupRepository.joinGroup(groupId)
                // Re-fetch groups to update lists
                searchGroups()
                groupRepository.fetchMyGroups()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(error = e.localizedMessage)
            }
        }
    }

    fun joinViaInvite(code: String) {
        viewModelScope.launch {
            try {
                groupRepository.joinViaInvite(code)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(error = e.localizedMessage)
            }
        }
    }
}
