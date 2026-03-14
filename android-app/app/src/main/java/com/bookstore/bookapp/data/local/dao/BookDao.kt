package com.bookstore.bookapp.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bookstore.bookapp.data.local.entity.BookEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BookDao {

    @Query("SELECT * FROM books")
    fun getAllBooks(): Flow<List<BookEntity>>

    @Query("SELECT * FROM books WHERE isMyBook = 1")
    fun getMyBooks(): Flow<List<BookEntity>>

    @Query("SELECT * FROM books WHERE id = :id")
    suspend fun getBookById(id: String): BookEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBooks(books: List<BookEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBook(book: BookEntity)

    @androidx.room.Transaction
    suspend fun replaceMyBooks(books: List<BookEntity>) {
        clearMyBooks()
        insertBooks(books)
    }

    @Query("DELETE FROM books WHERE isMyBook = 1")
    suspend fun clearMyBooks()

    @Query("DELETE FROM books")
    suspend fun clearAll()
}
