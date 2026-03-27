package com.bookstore.bookapp.data.remote.api

import com.bookstore.bookapp.domain.model.Book
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query

data class BooksResponse(val books: List<Book>)
data class ISBNScanRequest(val isbn: String)
data class IsbnLookupResponse(
    val title: String?,
    val author: String?,
    val publisher: String?,
    val year: Int?,
    val pages: Int?,
    val description: String?,
    val imageUrl: String?,
    val isbn: String?
)

interface BookApi {
    @GET("books/feed")
    suspend fun fetchBooks(
        @Query("groupIds") groupIds: String?,
        @Query("availability") availability: String?,
        @Query("genres") genres: String?,
        @Query("minPrice") minPrice: Double?,
        @Query("maxPrice") maxPrice: Double?,
        @Query("sortBy") sortBy: String?,
        @Query("search") search: String?,
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): BooksResponse

    @GET("books/{id}")
    suspend fun fetchBook(@Path("id") id: String): Book

    @GET("users/me/books")
    suspend fun fetchMyBooks(): List<Book>

    @POST("books")
    suspend fun createBook(@Body book: Book): Book

    @PUT("books/{id}")
    suspend fun updateBook(@Path("id") id: String, @Body book: Book): Book

    @DELETE("books/{id}")
    suspend fun deleteBook(@Path("id") id: String)

    @POST("books/scan-isbn")
    suspend fun lookupISBN(@Body request: ISBNScanRequest): IsbnLookupResponse
}
