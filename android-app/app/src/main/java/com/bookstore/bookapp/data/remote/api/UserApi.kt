package com.bookstore.bookapp.data.remote.api

import com.bookstore.bookapp.domain.model.Book
import retrofit2.http.GET
import retrofit2.http.Path

// We didn't define PublicUserProfile yet, so we define it here or map it mapping user.
// From iOS Models/PublicUserProfile.swift it is likely similar to MemberUser or User.
// Let's create a lean PublicUserProfile locally.
data class PublicUserProfile(
    val id: String,
    val name: String,
    val bio: String?,
    val profileImageUrl: String?,
    val stats: com.bookstore.bookapp.domain.model.UserStats
)

interface UserApi {
    @GET("users/{userId}")
    suspend fun fetchPublicProfile(@Path("userId") userId: String): PublicUserProfile

    @GET("users/{userId}/books")
    suspend fun fetchUserBooks(@Path("userId") userId: String): List<Book>
}
