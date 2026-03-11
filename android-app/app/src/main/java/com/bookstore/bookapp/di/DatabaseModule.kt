package com.bookstore.bookapp.di

import android.content.Context
import androidx.room.Room
import com.bookstore.bookapp.data.local.BookShareDatabase
import com.bookstore.bookapp.data.local.dao.BookClubDao
import com.bookstore.bookapp.data.local.dao.BookDao
import com.bookstore.bookapp.data.local.dao.TransactionDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideBookShareDatabase(@ApplicationContext context: Context): BookShareDatabase {
        return Room.databaseBuilder(
            context,
            BookShareDatabase::class.java,
            "bookshare_db"
        ).fallbackToDestructiveMigration().build()
    }

    @Provides
    @Singleton
    fun provideBookDao(database: BookShareDatabase): BookDao = database.bookDao

    @Provides
    @Singleton
    fun provideBookClubDao(database: BookShareDatabase): BookClubDao = database.bookClubDao

    @Provides
    @Singleton
    fun provideTransactionDao(database: BookShareDatabase): TransactionDao = database.transactionDao
}
