package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.local.UserPreferences
import com.bookstore.bookapp.data.remote.api.AuthApi
import com.bookstore.bookapp.data.remote.api.RefreshRequest
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import javax.inject.Inject
import javax.inject.Provider

class TokenAuthenticator @Inject constructor(
    private val userPreferences: UserPreferences,
    private val authApiProvider: Provider<AuthApi>,
    private val tokenHolder: TokenHolder
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        // Prevent infinite loops if the refresh call itself gets a 401
        if (response.request.url.encodedPath.endsWith("auth/refresh")) {
            tokenHolder.clearTokens()
            runBlocking { userPreferences.clearTokens() }
            return null
        }

        synchronized(this) {
            // Read from in-memory cache first (non-blocking)
            val currentRefreshToken = tokenHolder.refreshToken
            
            if (currentRefreshToken == null) {
                return null
            }

            return try {
                val authApi = authApiProvider.get()
                // This network call is expected to block, that's OK
                val refreshResponse = runBlocking {
                    authApi.refreshToken(RefreshRequest(currentRefreshToken))
                }

                // Update both in-memory cache and persistent storage
                tokenHolder.updateTokens(refreshResponse.accessToken, refreshResponse.refreshToken)
                runBlocking {
                    userPreferences.saveTokens(refreshResponse.accessToken, refreshResponse.refreshToken)
                }

                response.request.newBuilder()
                    .header("Authorization", "Bearer ${refreshResponse.accessToken}")
                    .build()
            } catch (e: Exception) {
                tokenHolder.clearTokens()
                runBlocking { userPreferences.clearTokens() }
                null
            }
        }
    }
}
