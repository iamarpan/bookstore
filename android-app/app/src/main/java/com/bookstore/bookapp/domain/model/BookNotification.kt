package com.bookstore.bookapp.domain.model

import java.util.Date

enum class NotificationType(val value: String) {
    BORROW_REQUEST("BORROW_REQUEST"),
    REQUEST_APPROVED("REQUEST_APPROVED"),
    REQUEST_REJECTED("REQUEST_REJECTED"),
    BOOK_HANDOVER_PENDING("BOOK_HANDOVER_PENDING"),
    BOOK_HANDED_OVER("BOOK_HANDED_OVER"),
    RETURN_PENDING("RETURN_PENDING"),
    BOOK_RETURNED("BOOK_RETURNED"),
    PAYMENT_COMPLETED("PAYMENT_COMPLETED"),
    TRANSACTION_CANCELLED("TRANSACTION_CANCELLED"),
    NEW_MESSAGE("NEW_MESSAGE"),
    SYSTEM("SYSTEM")
}

data class NotificationData(
    var transactionId: String? = null,
    var bookId: String? = null,
    var groupId: String? = null,
    var userId: String? = null
)

data class BookNotification(
    val id: String,
    val type: NotificationType,
    val title: String,
    val message: String,
    val data: NotificationData? = null,
    var isRead: Boolean = false,
    val createdAt: Date = Date()
)
