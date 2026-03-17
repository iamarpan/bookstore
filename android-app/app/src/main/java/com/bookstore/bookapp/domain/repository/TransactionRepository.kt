package com.bookstore.bookapp.domain.repository

import com.bookstore.bookapp.data.remote.api.Message
import com.bookstore.bookapp.domain.model.BorrowDuration
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import kotlinx.coroutines.flow.Flow

interface TransactionRepository {
    val activeTransactions: Flow<List<Transaction>>

    suspend fun fetchTransactions(
        role: String? = null,
        status: TransactionStatus? = null,
        page: Int = 1,
        limit: Int = 20
    ): List<Transaction>

    suspend fun createBorrowRequest(
        bookId: String,
        duration: BorrowDuration,
        durationDays: Int? = null,
        message: String? = null
    ): Transaction

    suspend fun fetchTransactionById(id: String): Transaction

    suspend fun generateHandoverOTP(id: String): String
    suspend fun generateReturnOTP(id: String): String

    suspend fun approveRequest(id: String): Transaction
    suspend fun rejectRequest(id: String, reason: String? = null): Transaction

    fun generateLocalHandoverOTP(): String
    suspend fun confirmHandover(id: String, otp: String): Transaction

    fun generateLocalReturnOTP(): String
    suspend fun confirmReturn(id: String, otp: String): Transaction

    suspend fun markPaymentComplete(id: String, role: String)
    suspend fun rateTransaction(
        id: String,
        rating: Int,
        comment: String? = null,
        bookConditionRating: Int? = null
    )

    suspend fun cancelTransaction(id: String): Transaction
    
    fun getTransactionsByRoleAndStatus(role: String, status: TransactionStatus): Flow<List<Transaction>>

    suspend fun getMessages(transactionId: String): List<Message>
    suspend fun sendMessage(transactionId: String, content: String): Message
    suspend fun getUnreadCount(transactionId: String): Int
    suspend fun markMessagesAsRead(transactionId: String)
}
