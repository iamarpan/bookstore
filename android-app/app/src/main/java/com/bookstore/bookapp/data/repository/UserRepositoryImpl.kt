package com.bookstore.bookapp.data.repository

import com.bookstore.bookapp.data.remote.api.PublicUserProfile
import com.bookstore.bookapp.data.remote.api.UserApi
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.repository.UserRepository

class UserRepositoryImpl(
    private val userApi: UserApi
) : UserRepository {
    override suspend fun fetchPublicProfile(userId: String): PublicUserProfile {
        return userApi.fetchPublicProfile(userId)
    }

    override suspend fun fetchUserBooks(userId: String): List<Book> {
        return userApi.fetchUserBooks(userId)
    }
}
