package com.bookstore.bookapp.data.repository

import com.bookstore.bookapp.data.local.dao.BookDao
import com.bookstore.bookapp.data.local.entity.toDomain
import com.bookstore.bookapp.data.local.entity.toEntity
import com.bookstore.bookapp.data.remote.api.BookApi
import com.bookstore.bookapp.data.remote.api.GoogleBooksApi
import com.bookstore.bookapp.data.remote.api.ISBNScanRequest
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookCondition
import com.bookstore.bookapp.domain.repository.BookRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Date

class BookRepositoryImpl(
    private val bookApi: BookApi,
    private val bookDao: BookDao,
    private val googleBooksApi: GoogleBooksApi
) : BookRepository {

    override fun getMyBooks(): Flow<List<Book>> =
        bookDao.getMyBooks().map { entities -> entities.map { it.toDomain() } }

    override suspend fun fetchMyBooks() {
        val remoteBooks = bookApi.fetchMyBooks()
        bookDao.clearMyBooks()
        bookDao.insertBooks(remoteBooks.map { it.toEntity(isMyBook = true) })
    }

    override suspend fun fetchBooks(
        groupIds: List<String>?,
        availability: String?,
        genres: List<String>?,
        minPrice: Double?,
        maxPrice: Double?,
        sortBy: String?,
        search: String?,
        page: Int,
        limit: Int
    ): List<Book> {
        val response = bookApi.fetchBooks(
            groupIds = groupIds?.joinToString(","),
            availability = availability,
            genres = genres?.joinToString(","),
            minPrice = minPrice,
            maxPrice = maxPrice,
            sortBy = sortBy,
            search = search,
            page = page,
            limit = limit
        )
        return response.books
    }

    override suspend fun fetchBook(id: String): Book {
        return bookApi.fetchBook(id)
    }

    override suspend fun createBook(book: Book): Book {
        val createdBook = bookApi.createBook(book)
        bookDao.insertBook(createdBook.toEntity(isMyBook = true))
        return createdBook
    }

    override suspend fun updateBook(book: Book): Book {
        val updatedBook = bookApi.updateBook(book.id, book)
        bookDao.insertBook(updatedBook.toEntity(isMyBook = true))
        return updatedBook
    }

    override suspend fun deleteBook(id: String) {
        bookApi.deleteBook(id)
        // Would prefer to just delete by id, but we can clear and refresh, or implement a specific delete in dao
        // I will add a method if needed, but for now we can just fetch my books again to resync:
        val book = bookDao.getBookById(id)
        if (book != null && book.isMyBook) {
            // we should ideally add deleteBook to DAO, wait I'll do fetchMyBooks() to refresh
            fetchMyBooks()
        }
    }

    override suspend fun lookupISBN(isbn: String): Book? {
        return try {
            bookApi.lookupISBN(ISBNScanRequest(isbn))
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun searchISBNExternal(isbn: String): Book? {
        return try {
            val response = googleBooksApi.searchByIsbn("isbn:$isbn")
            val item = response.items?.firstOrNull()?.volumeInfo ?: return null
            Book(
                id = "", // temporary ID
                title = item.title ?: "Unknown Title",
                author = item.authors?.joinToString(", ") ?: "Unknown Author",
                genre = item.categories?.firstOrNull() ?: "General",
                description = item.description ?: "No description",
                personalNotes = null,
                imageUrl = item.imageLinks?.thumbnail?.replace("http:", "https:") ?: "", // enforce https for coil
                isbn = isbn,
                publisher = null,
                year = null,
                pages = null,
                language = null,
                condition = BookCondition.GOOD,
                lendingPricePerWeek = 0.0,
                isAvailable = true,
                ownerId = "",
                ownerName = "",
                ownerRating = null,
                ownerBooksCount = 0,
                ownerProfileImageUrl = null,
                visibleInGroups = emptyList(),
                currentTransactionId = null,
                createdAt = Date(),
                updatedAt = null
            )
        } catch (e: Exception) {
            null
        }
    }
}
