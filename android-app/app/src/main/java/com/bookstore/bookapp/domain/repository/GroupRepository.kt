package com.bookstore.bookapp.domain.repository

import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupCategory
import com.bookstore.bookapp.domain.model.GroupMember
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.domain.model.PrivacySetting
import kotlinx.coroutines.flow.Flow
import java.util.Date

interface GroupRepository {
    fun getMyGroups(): Flow<List<BookClub>>
    suspend fun fetchMyGroups()
    
    suspend fun discoverGroups(category: GroupCategory? = null, search: String? = null): List<BookClub>
    suspend fun fetchGroupDetails(id: String): BookClub
    suspend fun getAllGroups(): List<BookClub>

    suspend fun createGroup(
        name: String,
        description: String,
        category: GroupCategory,
        privacy: PrivacySetting,
        rules: String? = null,
        coverImageUrl: String? = null
    ): BookClub

    suspend fun joinGroup(id: String)
    suspend fun joinViaInvite(code: String): BookClub
    suspend fun leaveGroup(id: String)

    suspend fun updateGroup(
        id: String,
        name: String? = null,
        description: String? = null,
        category: GroupCategory? = null,
        privacy: PrivacySetting? = null,
        coverImageUrl: String? = null,
        rules: String? = null
    ): BookClub

    suspend fun deleteGroup(id: String)

    suspend fun fetchGroupMembers(groupId: String, role: MemberRole? = null): List<GroupMember>
    suspend fun updateMemberRole(groupId: String, userId: String, role: MemberRole): GroupMember
    suspend fun removeMember(groupId: String, userId: String)

    suspend fun fetchGroupBooks(
        groupId: String,
        page: Int = 1,
        limit: Int = 20,
        availability: Boolean? = null,
        genre: String? = null,
        sortBy: String = "RECENT"
    ): Pair<List<Book>, Int>

    suspend fun regenerateInviteCode(groupId: String, expiresInDays: Int? = null): Pair<String, Date?>
}
