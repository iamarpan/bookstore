package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeState(
    val isLoading: Boolean = false,
    val refreshing: Boolean = false,
    val error: String? = null,
    val featuredBooks: List<Book> = emptyList(),
    val activeGroups: List<BookClub> = emptyList()
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val bookRepository: BookRepository,
    private val groupRepository: GroupRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeState(isLoading = true))
    val uiState: StateFlow<HomeState> = _uiState.asStateFlow()

    init {
        fetchHomeData()
    }

    fun fetchHomeData(isRefresh: Boolean = false) {
        viewModelScope.launch {
            if (isRefresh) {
                _uiState.value = _uiState.value.copy(refreshing = true, error = null)
            } else {
                _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            }

            try {
                // Fetch groups and recent feed books concurrently
                val (groupsDummy, feedBooks) = kotlinx.coroutines.coroutineScope {
                    val groupsDeferred = async { 
                        groupRepository.fetchMyGroups() // updates local DB
                        groupRepository.getMyGroups() // we get flow but can just collect one if needed
                    }
                    
                    val feedBooksDeferred = async {
                        bookRepository.fetchBooks(limit = 10, sortBy = "RECENT")
                    }

                    Pair(groupsDeferred.await(), feedBooksDeferred.await())
                }
                
                // For active groups, we might need a separate call or just read from dao flow.
                // We'll just set the books for now and rely on Flows in Compose for groups.

                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    refreshing = false,
                    featuredBooks = feedBooks
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
}
