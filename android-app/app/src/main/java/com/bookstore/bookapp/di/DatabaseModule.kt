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
        )
        .addMigrations(MIGRATION_1_2)
        .build()
    }

    private val MIGRATION_1_2 = object : androidx.room.migration.Migration(1, 2) {
        override fun migrate(database: androidx.sqlite.db.SupportSQLiteDatabase) {
            // books table indices
            database.execSQL("CREATE INDEX IF NOT EXISTS `index_books_isAvailable` ON `books` (`isAvailable`)")
            database.execSQL("CREATE INDEX IF NOT EXISTS `index_books_isMyBook` ON `books` (`isMyBook`)")
            
            // book_clubs table indices
            database.execSQL("CREATE INDEX IF NOT EXISTS `index_book_clubs_isMyGroup` ON `book_clubs` (`isMyGroup`)")
            
            // transactions table indices
            database.execSQL("CREATE INDEX IF NOT EXISTS `index_transactions_borrowerId` ON `transactions` (`borrowerId`)")
            database.execSQL("CREATE INDEX IF NOT EXISTS `index_transactions_ownerId` ON `transactions` (`ownerId`)")
            database.execSQL("CREATE INDEX IF NOT EXISTS `index_transactions_status` ON `transactions` (`status`)")
        }
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
