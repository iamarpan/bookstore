package com.bookstore.bookapp.data.remote.api

import com.bookstore.bookapp.domain.model.User
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT

data class OTPRequest(val phoneNumber: String)
data class AuthOTPResponse(val message: String, val expiresIn: Int)

data class VerifyOTPRequest(val phoneNumber: String, val otp: String, val name: String?, val bio: String?)
data class AuthResponse(val accessToken: String, val refreshToken: String, val user: User)

data class UpdateProfileRequest(val name: String?, val bio: String?, val profileImageUrl: String?)

data class RefreshRequest(val refreshToken: String)
data class RefreshResponse(val accessToken: String, val refreshToken: String)

interface AuthApi {
    @POST("auth/send-otp")
    suspend fun sendOTP(@Body request: OTPRequest): AuthOTPResponse

    @POST("auth/verify-otp")
    suspend fun verifyOTP(@Body request: VerifyOTPRequest): AuthResponse

    @POST("auth/refresh")
    suspend fun refreshToken(@Body request: RefreshRequest): RefreshResponse

    @GET("users/me")
    suspend fun fetchCurrentUser(): User

    @PUT("users/me")
    suspend fun updateProfile(@Body request: UpdateProfileRequest): User
}
