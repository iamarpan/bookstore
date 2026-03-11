package com.bookstore.bookapp.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bookstore.bookapp.data.local.entity.TransactionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TransactionDao {

    @Query("SELECT * FROM transactions WHERE isBorrowerTxn = 1")
    fun getBorrowerTransactions(): Flow<List<TransactionEntity>>

    @Query("SELECT * FROM transactions WHERE isOwnerTxn = 1")
    fun getOwnerTransactions(): Flow<List<TransactionEntity>>

    @Query("SELECT * FROM transactions WHERE isHistoryTxn = 1")
    fun getHistoryTransactions(): Flow<List<TransactionEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTransactions(transactions: List<TransactionEntity>)

    @Query("DELETE FROM transactions WHERE isBorrowerTxn = 1")
    suspend fun clearBorrowerTransactions()

    @Query("DELETE FROM transactions WHERE isOwnerTxn = 1")
    suspend fun clearOwnerTransactions()

    @Query("DELETE FROM transactions WHERE isHistoryTxn = 1")
    suspend fun clearHistoryTransactions()

    @Query("DELETE FROM transactions")
    suspend fun clearAll()
}
