package com.bookstore.bookapp.data.remote.api

import retrofit2.http.GET
import retrofit2.http.Query

// Models for Google Books
data class GoogleBooksResponse(val items: List<GoogleBooksItem>?)
data class GoogleBooksItem(val volumeInfo: VolumeInfo)
data class VolumeInfo(
    val title: String?,
    val authors: List<String>?,
    val description: String?,
    val categories: List<String>?,
    val imageLinks: ImageLinks?
)
data class ImageLinks(val thumbnail: String?)

interface GoogleBooksApi {
    @GET("/books/v1/volumes")
    suspend fun searchByIsbn(@Query("q") query: String): GoogleBooksResponse
}
