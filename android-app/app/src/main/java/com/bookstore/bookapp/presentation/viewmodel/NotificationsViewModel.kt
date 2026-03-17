package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.BookNotification
import com.bookstore.bookapp.domain.repository.NotificationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NotificationsState(
    val isLoading: Boolean = true,
    val notifications: List<BookNotification> = emptyList(),
    val unreadCount: Int = 0,
    val error: String? = null
)

@HiltViewModel
class NotificationsViewModel @Inject constructor(
    private val notificationRepository: NotificationRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(NotificationsState())
    val uiState: StateFlow<NotificationsState> = _uiState.asStateFlow()

    init {
        observeNotifications()
        loadNotifications()
    }

    private fun observeNotifications() {
        viewModelScope.launch {
            notificationRepository.notifications.collect { notifications ->
                _uiState.value = _uiState.value.copy(notifications = notifications)
            }
        }
        viewModelScope.launch {
            notificationRepository.unreadCount.collect { count ->
                _uiState.value = _uiState.value.copy(unreadCount = count)
            }
        }
    }

    fun loadNotifications() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                notificationRepository.fetchNotifications()
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load notifications"
                )
            }
        }
    }

    fun markAsRead(notification: BookNotification) {
        viewModelScope.launch {
            try {
                notificationRepository.markAsRead(notification)
            } catch (e: Exception) {
                // Silent fail
            }
        }
    }

    fun markAllAsRead() {
        viewModelScope.launch {
            try {
                notificationRepository.markAllAsRead()
            } catch (e: Exception) {
                // Silent fail
            }
        }
    }

    fun deleteNotification(notification: BookNotification) {
        viewModelScope.launch {
            try {
                notificationRepository.deleteNotification(notification)
            } catch (e: Exception) {
                // Silent fail
            }
        }
    }

    fun refresh() {
        loadNotifications()
    }
}
