package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.repository.AuthRepositoryImpl
import com.bookstore.bookapp.data.repository.BookRepositoryImpl
import com.bookstore.bookapp.data.repository.GroupRepositoryImpl
import com.bookstore.bookapp.data.repository.NotificationRepositoryImpl
import com.bookstore.bookapp.data.repository.TransactionRepositoryImpl
import com.bookstore.bookapp.data.repository.UserRepositoryImpl
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.bookstore.bookapp.domain.repository.BookRepository
import com.bookstore.bookapp.domain.repository.GroupRepository
import com.bookstore.bookapp.domain.repository.NotificationRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import com.bookstore.bookapp.domain.repository.UserRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    @Binds
    @Singleton
    abstract fun bindBookRepository(impl: BookRepositoryImpl): BookRepository

    @Binds
    @Singleton
    abstract fun bindGroupRepository(impl: GroupRepositoryImpl): GroupRepository

    @Binds
    @Singleton
    abstract fun bindTransactionRepository(impl: TransactionRepositoryImpl): TransactionRepository

    @Binds
    @Singleton
    abstract fun bindUserRepository(impl: UserRepositoryImpl): UserRepository

    @Binds
    @Singleton
    abstract fun bindNotificationRepository(impl: NotificationRepositoryImpl): NotificationRepository
}
