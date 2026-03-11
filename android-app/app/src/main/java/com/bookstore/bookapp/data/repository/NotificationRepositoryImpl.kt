package com.bookstore.bookapp.data.repository

import com.bookstore.bookapp.data.remote.api.DeviceTokenRequest
import com.bookstore.bookapp.data.remote.api.NotificationApi
import com.bookstore.bookapp.domain.model.BookNotification
import com.bookstore.bookapp.domain.repository.NotificationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

class NotificationRepositoryImpl(
    private val notificationApi: NotificationApi
) : NotificationRepository {

    private val _notifications = MutableStateFlow<List<BookNotification>>(emptyList())
    override val notifications: Flow<List<BookNotification>> = _notifications.asStateFlow()

    private val _unreadCount = MutableStateFlow(0)
    override val unreadCount: Flow<Int> = _unreadCount.asStateFlow()

    override suspend fun registerDeviceToken(token: String) {
        notificationApi.registerDeviceToken(DeviceTokenRequest(token))
    }

    override suspend fun fetchNotifications(unreadOnly: Boolean) {
        val response = notificationApi.fetchNotifications(if (unreadOnly) true else null)
        _notifications.value = response.notifications
        _unreadCount.value = response.unreadCount
    }

    override suspend fun markAsRead(notification: BookNotification) {
        // Optimistic update
        val updatedList = _notifications.value.map {
            if (it.id == notification.id) it.copy(isRead = true) else it
        }
        _notifications.value = updatedList
        _unreadCount.value = updatedList.count { !it.isRead }

        try {
            notificationApi.markAsRead(notification.id)
        } catch (e: Exception) {
             // Revert optimistic update
        }
    }

    override suspend fun markAllAsRead() {
        val updatedList = _notifications.value.map { it.copy(isRead = true) }
        _notifications.value = updatedList
        _unreadCount.value = 0

        try {
            notificationApi.markAllAsRead()
        } catch (e: Exception) {
            // Revert
        }
    }

    override suspend fun deleteNotification(notification: BookNotification) {
        val updatedList = _notifications.value.filter { it.id != notification.id }
        _notifications.value = updatedList
        _unreadCount.value = updatedList.count { !it.isRead }

        try {
            notificationApi.deleteNotification(notification.id)
        } catch (e: Exception) {
            // Revert
        }
    }
}
