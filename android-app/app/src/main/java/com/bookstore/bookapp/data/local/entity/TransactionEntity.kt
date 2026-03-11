package com.bookstore.bookapp.data.local.entity

import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.bookstore.bookapp.domain.model.BorrowDuration
import com.bookstore.bookapp.domain.model.PaymentStatus
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import java.util.Date

@Entity(tableName = "transactions")
data class TransactionEntity(
    @PrimaryKey val id: String,
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
    @Embedded val paymentStatus: PaymentStatusEntity,
    val requestedAt: Date,
    val approvedAt: Date?,
    val handoverAt: Date?,
    val dueDate: Date?,
    val returnedAt: Date?,
    val ownerRating: Int?,
    val ownerComment: String?,
    val borrowerRating: Int?,
    val borrowerComment: String?,
    val bookConditionRating: Int?,
    // Differentiator for Room caching lists independently
    val isBorrowerTxn: Boolean = false,
    val isOwnerTxn: Boolean = false,
    val isHistoryTxn: Boolean = false
)

data class PaymentStatusEntity(
    val borrowerConfirmed: Boolean,
    val ownerConfirmed: Boolean
)

fun TransactionEntity.toDomain() = Transaction(
    id = id,
    bookId = bookId,
    bookTitle = bookTitle,
    bookImageUrl = bookImageUrl,
    borrowerId = borrowerId,
    borrowerName = borrowerName,
    borrowerProfileImageUrl = borrowerProfileImageUrl,
    ownerId = ownerId,
    ownerName = ownerName,
    ownerProfileImageUrl = ownerProfileImageUrl,
    groupId = groupId,
    status = status,
    duration = duration,
    durationDays = durationDays,
    lendingFee = lendingFee,
    requestMessage = requestMessage,
    rejectionReason = rejectionReason,
    handoverOTP = handoverOTP,
    handoverOTPExpiry = handoverOTPExpiry,
    returnOTP = returnOTP,
    returnOTPExpiry = returnOTPExpiry,
    paymentStatus = PaymentStatus(paymentStatus.borrowerConfirmed, paymentStatus.ownerConfirmed),
    requestedAt = requestedAt,
    approvedAt = approvedAt,
    handoverAt = handoverAt,
    dueDate = dueDate,
    returnedAt = returnedAt,
    ownerRating = ownerRating,
    ownerComment = ownerComment,
    borrowerRating = borrowerRating,
    borrowerComment = borrowerComment,
    bookConditionRating = bookConditionRating
)

fun Transaction.toEntity(
    isBorrowerTxn: Boolean = false,
    isOwnerTxn: Boolean = false,
    isHistoryTxn: Boolean = false
) = TransactionEntity(
    id = id,
    bookId = bookId,
    bookTitle = bookTitle,
    bookImageUrl = bookImageUrl,
    borrowerId = borrowerId,
    borrowerName = borrowerName,
    borrowerProfileImageUrl = borrowerProfileImageUrl,
    ownerId = ownerId,
    ownerName = ownerName,
    ownerProfileImageUrl = ownerProfileImageUrl,
    groupId = groupId,
    status = status,
    duration = duration,
    durationDays = durationDays,
    lendingFee = lendingFee,
    requestMessage = requestMessage,
    rejectionReason = rejectionReason,
    handoverOTP = handoverOTP,
    handoverOTPExpiry = handoverOTPExpiry,
    returnOTP = returnOTP,
    returnOTPExpiry = returnOTPExpiry,
    paymentStatus = PaymentStatusEntity(paymentStatus.borrowerConfirmed, paymentStatus.ownerConfirmed),
    requestedAt = requestedAt,
    approvedAt = approvedAt,
    handoverAt = handoverAt,
    dueDate = dueDate,
    returnedAt = returnedAt,
    ownerRating = ownerRating,
    ownerComment = ownerComment,
    borrowerRating = borrowerRating,
    borrowerComment = borrowerComment,
    bookConditionRating = bookConditionRating,
    isBorrowerTxn = isBorrowerTxn,
    isOwnerTxn = isOwnerTxn,
    isHistoryTxn = isHistoryTxn
)
