package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.local.UserPreferences
import com.bookstore.bookapp.data.local.dao.BookClubDao
import com.bookstore.bookapp.data.local.dao.BookDao
import com.bookstore.bookapp.data.local.dao.TransactionDao
import com.bookstore.bookapp.data.remote.api.AuthApi
import com.bookstore.bookapp.data.remote.api.BookApi
import com.bookstore.bookapp.data.remote.api.GoogleBooksApi
import com.bookstore.bookapp.data.remote.api.GroupApi
import com.bookstore.bookapp.data.remote.api.NotificationApi
import com.bookstore.bookapp.data.remote.api.TransactionApi
import com.bookstore.bookapp.data.remote.api.UserApi
import com.bookstore.bookapp.data.repository.AuthRepositoryImpl
import com.bookstore.bookapp.data.repository.BookRepositoryImpl
import com.bookstore.bookapp.data.repository.GroupRepositoryImpl
import com.bookstore.bookapp.data.repository.NotificationRepositoryImpl
import com.bookstore.bookapp.data.repository.TransactionRepositoryImpl
import com.bookstore.bookapp.data.repository.UserRepositoryImpl
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object RepositoryProviderModule {
    
    // We provide implementations here instead of @Binds if we want to instantiate manually
    
    @Provides
    @Singleton
    fun provideAuthRepositoryImpl(
        api: AuthApi, 
        prefs: UserPreferences
    ): AuthRepositoryImpl = AuthRepositoryImpl(api, prefs)

    @Provides
    @Singleton
    fun provideBookRepositoryImpl(
        api: BookApi,
        dao: BookDao,
        googleApi: GoogleBooksApi
    ): BookRepositoryImpl = BookRepositoryImpl(api, dao, googleApi)

    @Provides
    @Singleton
    fun provideGroupRepositoryImpl(
        api: GroupApi,
        dao: BookClubDao
    ): GroupRepositoryImpl = GroupRepositoryImpl(api, dao)

    @Provides
    @Singleton
    fun provideTransactionRepositoryImpl(
        api: TransactionApi,
        dao: TransactionDao
    ): TransactionRepositoryImpl = TransactionRepositoryImpl(api, dao)

    @Provides
    @Singleton
    fun provideUserRepositoryImpl(
        api: UserApi
    ): UserRepositoryImpl = UserRepositoryImpl(api)

    @Provides
    @Singleton
    fun provideNotificationRepositoryImpl(
        api: NotificationApi
    ): NotificationRepositoryImpl = NotificationRepositoryImpl(api)
}
