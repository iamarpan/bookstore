package com.bookstore.bookapp.data.repository

import com.bookstore.bookapp.data.local.dao.TransactionDao
import com.bookstore.bookapp.data.local.entity.toDomain
import com.bookstore.bookapp.data.local.entity.toEntity
import com.bookstore.bookapp.data.remote.api.BorrowRequest
import com.bookstore.bookapp.data.remote.api.HandoverRequest
import com.bookstore.bookapp.data.remote.api.MarkPaymentRequest
import com.bookstore.bookapp.data.remote.api.Message
import com.bookstore.bookapp.data.remote.api.RatingRequest
import com.bookstore.bookapp.data.remote.api.RejectRequest
import com.bookstore.bookapp.data.remote.api.ReturnRequest
import com.bookstore.bookapp.data.remote.api.SendMessageRequest
import com.bookstore.bookapp.data.remote.api.TransactionApi
import com.bookstore.bookapp.domain.model.BorrowDuration
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.domain.repository.TransactionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map

class TransactionRepositoryImpl(
    private val transactionApi: TransactionApi,
    private val transactionDao: TransactionDao
) : TransactionRepository {

    // A simplified active transactions stream combining borrower and owner lists and keeping those that are pending, approved, active, etc.
    override val activeTransactions: Flow<List<Transaction>> =
        combine(
            transactionDao.getBorrowerTransactions(),
            transactionDao.getOwnerTransactions()
        ) { borrowerTxns, ownerTxns ->
            // Distinct combined list
            (borrowerTxns + ownerTxns)
                .map { it.toDomain() }
                .distinctBy { it.id }
                .filter { it.status == TransactionStatus.PENDING || it.status == TransactionStatus.APPROVED || it.status == TransactionStatus.ACTIVE }
                .sortedByDescending { it.requestedAt }
        }

    override suspend fun fetchTransactions(
        role: String?,
        status: TransactionStatus?,
        page: Int,
        limit: Int
    ): List<Transaction> {
        val response = transactionApi.fetchTransactions(role, status?.name, page, limit)
        val transactions = response.transactions

        // Update local cache
        when (role) {
            "BORROWER" -> {
                if (page == 1) {
                    transactionDao.replaceBorrowerTransactions(transactions.map { it.toEntity(isBorrowerTxn = true) })
                } else {
                    transactionDao.insertTransactions(transactions.map { it.toEntity(isBorrowerTxn = true) })
                }
            }
            "OWNER" -> {
                if (page == 1) {
                    transactionDao.replaceOwnerTransactions(transactions.map { it.toEntity(isOwnerTxn = true) })
                } else {
                    transactionDao.insertTransactions(transactions.map { it.toEntity(isOwnerTxn = true) })
                }
            }
            else -> {
                // Not caching unstructured lists for now
            }
        }
        return transactions
    }

    override suspend fun createBorrowRequest(
        bookId: String,
        duration: BorrowDuration,
        durationDays: Int?,
        message: String?
    ): Transaction {
        val tx = transactionApi.createBorrowRequest(BorrowRequest(bookId, duration.name, durationDays ?: duration.days, message))
        transactionDao.insertTransactions(listOf(tx.toEntity(isBorrowerTxn = true)))
        return tx
    }

    override suspend fun fetchTransactionById(id: String): Transaction {
        // Here we could cache it, but usually standard detail fetch.
        return transactionApi.fetchTransactionById(id)
    }

    override suspend fun generateHandoverOTP(id: String): String {
        return transactionApi.generateHandoverOTP(id).otp
    }

    override suspend fun generateReturnOTP(id: String): String {
        return transactionApi.generateReturnOTP(id).otp
    }

    override suspend fun approveRequest(id: String): Transaction {
        val tx = transactionApi.approveRequest(id)
        refreshTransactionInCache(tx)
        return tx
    }

    override suspend fun rejectRequest(id: String, reason: String?): Transaction {
        val tx = transactionApi.rejectRequest(id, RejectRequest(reason))
        refreshTransactionInCache(tx)
        return tx
    }

    override fun generateLocalHandoverOTP(): String {
        return String.format("%04d", (0..9999).random())
    }

    override suspend fun confirmHandover(id: String, otp: String): Transaction {
        val tx = transactionApi.confirmHandover(id, HandoverRequest(otp))
        refreshTransactionInCache(tx)
        return tx
    }

    override fun generateLocalReturnOTP(): String {
        return String.format("%04d", (0..9999).random())
    }

    override suspend fun confirmReturn(id: String, otp: String): Transaction {
        val tx = transactionApi.confirmReturn(id, ReturnRequest(otp))
        refreshTransactionInCache(tx)
        return tx
    }

    override suspend fun markPaymentComplete(id: String, role: String) {
        val tx = transactionApi.markPaymentComplete(id, MarkPaymentRequest(role))
        refreshTransactionInCache(tx)
    }

    override suspend fun rateTransaction(id: String, rating: Int, comment: String?, bookConditionRating: Int?) {
        transactionApi.rateTransaction(id, RatingRequest(rating, comment, bookConditionRating))
    }

    override suspend fun cancelTransaction(id: String): Transaction {
        val tx = transactionApi.cancelTransaction(id)
        refreshTransactionInCache(tx)
        return tx
    }

    override fun getTransactionsByRoleAndStatus(
        role: String,
        status: TransactionStatus
    ): Flow<List<Transaction>> {
        val baseFlow = if (role == "BORROWER") {
            transactionDao.getBorrowerTransactions()
        } else {
            transactionDao.getOwnerTransactions()
        }
        
        return baseFlow.map { list ->
            list.map { it.toDomain() }.filter { it.status == status }
        }
    }

    private suspend fun refreshTransactionInCache(tx: Transaction) {
        // For simplicity, we can insert it in all caches where it might belong
        // In a real app we'd fetch the lists again or selectively update based on current user role
        transactionDao.insertTransactions(listOf(
            tx.toEntity(isBorrowerTxn = true),
            tx.toEntity(isOwnerTxn = true),
            tx.toEntity(isHistoryTxn = true)
        ))
    }

    override suspend fun getMessages(transactionId: String): List<Message> {
        return transactionApi.getMessages(transactionId).messages
    }

    override suspend fun sendMessage(transactionId: String, content: String): Message {
        return transactionApi.sendMessage(transactionId, SendMessageRequest(content))
    }

    override suspend fun getUnreadCount(transactionId: String): Int {
        return transactionApi.getUnreadCount(transactionId).unreadCount
    }

    override suspend fun markMessagesAsRead(transactionId: String) {
        transactionApi.markAsRead(transactionId)
    }
}
