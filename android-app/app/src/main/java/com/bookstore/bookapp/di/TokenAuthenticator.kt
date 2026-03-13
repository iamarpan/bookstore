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
    private val authApiProvider: Provider<AuthApi>
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        // Prevent infinite loops if the refresh call itself gets a 401
        if (response.request.url.encodedPath.endsWith("auth/refresh")) {
            runBlocking { userPreferences.clearTokens() }
            return null
        }

        synchronized(this) {
            return runBlocking {
                val refreshToken = userPreferences.refreshTokenFlow.firstOrNull()
                
                if (refreshToken == null) {
                    return@runBlocking null
                }
                
                try {
                    val authApi = authApiProvider.get()
                    val refreshResponse = authApi.refreshToken(RefreshRequest(refreshToken))
                    
                    userPreferences.saveTokens(refreshResponse.accessToken, refreshResponse.refreshToken)
                    
                    response.request.newBuilder()
                        .header("Authorization", "Bearer ${refreshResponse.accessToken}")
                        .build()
                } catch (e: Exception) {
                    userPreferences.clearTokens()
                    null
                }
            }
        }
    }
}
