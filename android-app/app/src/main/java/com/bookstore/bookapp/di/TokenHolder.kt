package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.local.UserPreferences
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TokenHolder @Inject constructor(
    userPreferences: UserPreferences
) {
    @Volatile
    var accessToken: String? = null
        private set

    @Volatile
    var refreshToken: String? = null
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    init {
        // Observe token changes and cache them in memory
        userPreferences.accessTokenFlow
            .onEach { accessToken = it }
            .launchIn(scope)

        userPreferences.refreshTokenFlow
            .onEach { refreshToken = it }
            .launchIn(scope)
    }

    fun updateTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
    }

    fun clearTokens() {
        accessToken = null
        refreshToken = null
    }
}
