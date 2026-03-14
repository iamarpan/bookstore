package com.bookstore.bookapp.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.bookstore.bookapp.data.local.dao.BookClubDao
import com.bookstore.bookapp.data.local.dao.BookDao
import com.bookstore.bookapp.data.local.dao.TransactionDao
import com.bookstore.bookapp.data.local.entity.BookClubEntity
import com.bookstore.bookapp.data.local.entity.BookEntity
import com.bookstore.bookapp.data.local.entity.TransactionEntity

@Database(
    entities = [
        BookEntity::class,
        BookClubEntity::class,
        TransactionEntity::class
    ],
    version = 2,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class BookShareDatabase : RoomDatabase() {
    abstract val bookDao: BookDao
    abstract val bookClubDao: BookClubDao
    abstract val transactionDao: TransactionDao
}
