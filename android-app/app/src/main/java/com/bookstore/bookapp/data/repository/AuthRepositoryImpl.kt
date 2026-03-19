package com.bookstore.bookapp.data.repository

import com.bookstore.bookapp.data.local.UserPreferences
import com.bookstore.bookapp.data.remote.api.AuthApi
import com.bookstore.bookapp.data.remote.api.GoogleSignInRequest
import com.bookstore.bookapp.data.remote.api.OTPRequest
import com.bookstore.bookapp.data.remote.api.UpdateProfileRequest
import com.bookstore.bookapp.data.remote.api.VerifyOTPRequest
import com.bookstore.bookapp.domain.model.User
import com.bookstore.bookapp.domain.repository.AuthRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class AuthRepositoryImpl(
    private val authApi: AuthApi,
    private val userPreferences: UserPreferences
) : AuthRepository {

    override val currentUser: Flow<User?> = userPreferences.currentUserFlow

    override val isAuthenticated: Flow<Boolean> = userPreferences.accessTokenFlow.map { it != null }

    override suspend fun sendOTP(phoneNumber: String): Int {
        val response = authApi.sendOTP(OTPRequest(phoneNumber))
        return response.expiresIn
    }

    override suspend fun verifyOTP(phoneNumber: String, otp: String, name: String?, bio: String?) {
        val response = authApi.verifyOTP(VerifyOTPRequest(phoneNumber, otp, name, bio))
        userPreferences.saveTokens(response.accessToken, response.refreshToken)
        userPreferences.saveUser(response.user)
    }

    override suspend fun signInWithGoogle(idToken: String) {
        val response = authApi.signInWithGoogle(GoogleSignInRequest(idToken))
        userPreferences.saveTokens(response.accessToken, response.refreshToken)
        userPreferences.saveUser(response.user)
    }

    override suspend fun fetchCurrentUser() {
        val user = authApi.fetchCurrentUser()
        userPreferences.saveUser(user)
    }

    override suspend fun updateProfile(name: String?, bio: String?, profileImageUrl: String?) {
        val user = authApi.updateProfile(UpdateProfileRequest(name, bio, profileImageUrl))
        userPreferences.saveUser(user)
    }

    override suspend fun logout() {
        userPreferences.clearTokens()
        userPreferences.clearUser()
        userPreferences.clearAll()
    }
}
