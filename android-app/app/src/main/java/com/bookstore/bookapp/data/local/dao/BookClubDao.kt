package com.bookstore.bookapp.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bookstore.bookapp.data.local.entity.BookClubEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BookClubDao {

    @Query("SELECT * FROM book_clubs WHERE isMyGroup = 1")
    fun getMyGroups(): Flow<List<BookClubEntity>>

    @Query("SELECT * FROM book_clubs WHERE isMyGroup = 0")
    fun getDiscoveredGroups(): Flow<List<BookClubEntity>>

    @Query("SELECT * FROM book_clubs WHERE id = :id")
    suspend fun getGroupById(id: String): BookClubEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGroups(groups: List<BookClubEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertGroup(group: BookClubEntity)

    @androidx.room.Transaction
    suspend fun replaceMyGroups(groups: List<BookClubEntity>) {
        clearMyGroups()
        insertGroups(groups)
    }

    @androidx.room.Transaction
    suspend fun replaceDiscoveredGroups(groups: List<BookClubEntity>) {
        clearDiscoveredGroups()
        insertGroups(groups)
    }

    @Query("DELETE FROM book_clubs WHERE isMyGroup = 1")
    suspend fun clearMyGroups()

    @Query("DELETE FROM book_clubs WHERE isMyGroup = 0")
    suspend fun clearDiscoveredGroups()

    @Query("DELETE FROM book_clubs")
    suspend fun clearAll()
}
