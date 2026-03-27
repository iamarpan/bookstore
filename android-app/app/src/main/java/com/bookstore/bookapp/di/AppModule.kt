package com.bookstore.bookapp.di

import android.content.Context
import com.bookstore.bookapp.data.local.UserPreferences
import com.bookstore.bookapp.data.remote.socket.ChatSocketManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideUserPreferences(@ApplicationContext context: Context): UserPreferences {
        return UserPreferences(context)
    }

    @Provides
    @Singleton
    fun provideChatSocketManager(): ChatSocketManager {
        return ChatSocketManager()
    }
}
