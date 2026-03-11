package com.bookstore.bookapp.domain.model

import java.util.Date
import java.util.Calendar

enum class TransactionStatus(val value: String, val displayName: String, val color: String) {
    PENDING("PENDING", "Pending", "orange"),
    APPROVED("APPROVED", "Approved", "green"),
    ACTIVE("ACTIVE", "Active", "blue"),
    RETURNED("RETURNED", "Returned", "purple"),
    REJECTED("REJECTED", "Rejected", "red"),
    CANCELLED("CANCELLED", "Cancelled", "red")
}

enum class BorrowDuration(val value: String, val displayName: String, val days: Int) {
    ONE_WEEK("ONE_WEEK", "1 Week", 7),
    TWO_WEEKS("TWO_WEEKS", "2 Weeks", 14),
    ONE_MONTH("ONE_MONTH", "1 Month", 30),
    CUSTOM("CUSTOM", "Custom", 0)
}

data class PaymentStatus(
    val borrowerConfirmed: Boolean = false,
    val ownerConfirmed: Boolean = false
) {
    val isComplete: Boolean
        get() = borrowerConfirmed && ownerConfirmed
}

data class Transaction(
    val id: String,
    val bookId: String,
    val bookTitle: String,
    val bookImageUrl: String?,
    val borrowerId: String,
    val borrowerName: String,
    val borrowerProfileImageUrl: String?,
    val ownerId: String,
    val ownerName: String,
    val ownerProfileImageUrl: String?,
    val groupId: String,
    val status: TransactionStatus,
    val duration: BorrowDuration,
    val durationDays: Int,
    val lendingFee: Double,
    val requestMessage: String?,
    val rejectionReason: String?,
    val handoverOTP: String?,
    val handoverOTPExpiry: Date?,
    val returnOTP: String?,
    val returnOTPExpiry: Date?,
    val paymentStatus: PaymentStatus,
    val requestedAt: Date,
    val approvedAt: Date?,
    val handoverAt: Date?,
    val dueDate: Date?,
    val returnedAt: Date?,
    val ownerRating: Int?,
    val ownerComment: String?,
    val borrowerRating: Int?,
    val borrowerComment: String?,
    val bookConditionRating: Int?
) {
    val isOverdue: Boolean
        get() {
            if (dueDate == null || status != TransactionStatus.ACTIVE) return false
            return Date().after(dueDate)
        }

    val daysUntilDue: Int?
        get() {
            if (dueDate == null || status != TransactionStatus.ACTIVE) return null
            val timeDiff = dueDate.time - Date().time
            return (timeDiff / (1000 * 60 * 60 * 24)).toInt()
        }

    val dueDateDisplay: String?
        get() {
            if (dueDate == null) return null
            val days = daysUntilDue
            if (days != null) {
                if (days < 0) return "Overdue by ${Math.abs(days)} day${if (Math.abs(days) == 1) "" else "s"}"
                if (days == 0) return "Due today"
                if (days == 1) return "Due tomorrow"
                return "Due in $days days"
            }
            // Fallback
            return "Due: $dueDate" // A formatter can be supplied later
        }

    fun isOwner(userId: String) = ownerId == userId
    fun isBorrower(userId: String) = borrowerId == userId

    val totalCostDisplay: String
        get() {
            if (lendingFee == 0.0) return "Free"
            val totalWeeks = durationDays.toDouble() / 7.0
            val total = lendingFee * totalWeeks
            return "₹${total.toInt()}"
        }
}
