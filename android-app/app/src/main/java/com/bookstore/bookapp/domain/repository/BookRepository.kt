package com.bookstore.bookapp.domain.repository

import com.bookstore.bookapp.domain.model.Book
import kotlinx.coroutines.flow.Flow

interface BookRepository {
    fun getMyBooks(): Flow<List<Book>>
    suspend fun fetchMyBooks()
    
    suspend fun fetchBooks(
        groupIds: List<String>? = null,
        availability: String? = null,
        genres: List<String>? = null,
        minPrice: Double? = null,
        maxPrice: Double? = null,
        sortBy: String? = null,
        search: String? = null,
        page: Int = 1,
        limit: Int = 20
    ): List<Book>

    suspend fun fetchBook(id: String): Book
    suspend fun createBook(book: Book): Book
    suspend fun updateBook(book: Book): Book
    suspend fun deleteBook(id: String)
    suspend fun lookupISBN(isbn: String): Book?
    suspend fun searchISBNExternal(isbn: String): Book?
}
