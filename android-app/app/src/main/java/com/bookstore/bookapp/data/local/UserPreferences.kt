package com.bookstore.bookapp.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.bookstore.bookapp.domain.model.User
import com.google.gson.Gson
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_prefs")

class UserPreferences(private val context: Context) {

    private val gson = Gson()

    companion object {
        val CURRENT_USER_KEY = stringPreferencesKey("currentUser")
        val ACCESS_TOKEN_KEY = stringPreferencesKey("accessToken")
        val REFRESH_TOKEN_KEY = stringPreferencesKey("refreshToken")
    }

    val currentUserFlow: Flow<User?> = context.dataStore.data.map { preferences ->
        preferences[CURRENT_USER_KEY]?.let { json ->
            try {
                gson.fromJson(json, User::class.java)
            } catch (e: Exception) {
                null
            }
        }
    }

    val accessTokenFlow: Flow<String?> = context.dataStore.data.map { preferences ->
        preferences[ACCESS_TOKEN_KEY]
    }

    val refreshTokenFlow: Flow<String?> = context.dataStore.data.map { preferences ->
        preferences[REFRESH_TOKEN_KEY]
    }

    suspend fun saveUser(user: User) {
        context.dataStore.edit { preferences ->
            preferences[CURRENT_USER_KEY] = gson.toJson(user)
        }
    }

    suspend fun clearUser() {
        context.dataStore.edit { preferences ->
            preferences.remove(CURRENT_USER_KEY)
        }
    }

    suspend fun saveTokens(accessToken: String, refreshToken: String) {
        context.dataStore.edit { preferences ->
            preferences[ACCESS_TOKEN_KEY] = accessToken
            preferences[REFRESH_TOKEN_KEY] = refreshToken
        }
    }

    suspend fun clearTokens() {
        context.dataStore.edit { preferences ->
            preferences.remove(ACCESS_TOKEN_KEY)
            preferences.remove(REFRESH_TOKEN_KEY)
        }
    }

    suspend fun clearAll() {
        context.dataStore.edit { preferences ->
            preferences.clear()
        }
    }
}
