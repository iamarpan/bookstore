package com.bookstore.bookapp.domain.repository

import com.bookstore.bookapp.data.remote.api.PublicUserProfile
import com.bookstore.bookapp.domain.model.Book

interface UserRepository {
    suspend fun fetchPublicProfile(userId: String): PublicUserProfile
    suspend fun fetchUserBooks(userId: String): List<Book>
}
