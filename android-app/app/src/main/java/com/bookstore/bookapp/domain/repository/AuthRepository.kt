package com.bookstore.bookapp.domain.repository

import com.bookstore.bookapp.domain.model.User
import kotlinx.coroutines.flow.Flow

interface AuthRepository {
    val currentUser: Flow<User?>
    val isAuthenticated: Flow<Boolean>

    suspend fun sendOTP(phoneNumber: String): Int
    suspend fun verifyOTP(phoneNumber: String, otp: String, name: String?, bio: String?)
    suspend fun fetchCurrentUser()
    suspend fun updateProfile(name: String?, bio: String?, profileImageUrl: String?)
    suspend fun logout()
}
