package com.bookstore.bookapp.domain.repository

import com.bookstore.bookapp.domain.model.BookNotification
import kotlinx.coroutines.flow.Flow

interface NotificationRepository {
    val unreadCount: Flow<Int>
    val notifications: Flow<List<BookNotification>>

    suspend fun registerDeviceToken(token: String)
    suspend fun fetchNotifications(unreadOnly: Boolean = false)
    suspend fun markAsRead(notification: BookNotification)
    suspend fun markAllAsRead()
    suspend fun deleteNotification(notification: BookNotification)
}
