package com.bookstore.bookapp.data.repository

import com.bookstore.bookapp.data.local.dao.BookClubDao
import com.bookstore.bookapp.data.local.entity.toDomain
import com.bookstore.bookapp.data.local.entity.toEntity
import com.bookstore.bookapp.data.remote.api.CreateGroupRequest
import com.bookstore.bookapp.data.remote.api.GroupApi
import com.bookstore.bookapp.data.remote.api.JoinGroupViaInviteRequest
import com.bookstore.bookapp.data.remote.api.RegenerateInviteRequest
import com.bookstore.bookapp.data.remote.api.UpdateGroupRequest
import com.bookstore.bookapp.data.remote.api.UpdateRoleRequest
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupCategory
import com.bookstore.bookapp.domain.model.GroupMember
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.domain.model.PrivacySetting
import com.bookstore.bookapp.domain.repository.GroupRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.Date

class GroupRepositoryImpl(
    private val groupApi: GroupApi,
    private val bookClubDao: BookClubDao
) : GroupRepository {

    override fun getMyGroups(): Flow<List<BookClub>> =
        bookClubDao.getMyGroups().map { entities -> entities.map { it.toDomain() } }

    override suspend fun fetchMyGroups() {
        val remoteGroups = groupApi.fetchMyGroups()
        bookClubDao.replaceMyGroups(remoteGroups.map { it.toEntity(isMyGroup = true) })
    }

    override suspend fun discoverGroups(category: GroupCategory?, search: String?): List<BookClub> {
        val response = groupApi.discoverGroups(category?.name, search)
        return response.groups
    }

    override suspend fun fetchGroupDetails(id: String): BookClub {
        return groupApi.fetchGroupDetails(id)
    }

    override suspend fun getAllGroups(): List<BookClub> {
        return groupApi.getAllGroups()
    }

    override suspend fun createGroup(
        name: String,
        description: String,
        category: GroupCategory,
        privacy: PrivacySetting,
        rules: String?,
        coverImageUrl: String?
    ): BookClub {
        val createdGroup = groupApi.createGroup(
            CreateGroupRequest(name, description, category.name, privacy.name, rules, coverImageUrl)
        )
        bookClubDao.insertGroup(createdGroup.toEntity(isMyGroup = true))
        return createdGroup
    }

    override suspend fun joinGroup(id: String) {
        groupApi.joinGroup(id)
        fetchMyGroups()
    }

    override suspend fun joinViaInvite(code: String): BookClub {
        val response = groupApi.joinViaInvite(JoinGroupViaInviteRequest(code))
        bookClubDao.insertGroup(response.group.toEntity(isMyGroup = true))
        return response.group
    }

    override suspend fun leaveGroup(id: String) {
        groupApi.leaveGroup(id)
        fetchMyGroups()
    }

    override suspend fun updateGroup(
        id: String,
        name: String?,
        description: String?,
        category: GroupCategory?,
        privacy: PrivacySetting?,
        coverImageUrl: String?,
        rules: String?
    ): BookClub {
        val updatedGroup = groupApi.updateGroup(
            id,
            UpdateGroupRequest(name, description, category?.name, privacy?.name, coverImageUrl, rules)
        )
        bookClubDao.insertGroup(updatedGroup.toEntity(isMyGroup = true))
        return updatedGroup
    }

    override suspend fun deleteGroup(id: String) {
        groupApi.deleteGroup(id)
        fetchMyGroups()
    }

    override suspend fun fetchGroupMembers(groupId: String, role: MemberRole?): List<GroupMember> {
        return groupApi.fetchGroupMembers(groupId, role?.name).members
    }

    override suspend fun updateMemberRole(groupId: String, userId: String, role: MemberRole): GroupMember {
        return groupApi.updateMemberRole(groupId, userId, UpdateRoleRequest(role.name)).member
    }

    override suspend fun removeMember(groupId: String, userId: String) {
        groupApi.removeMember(groupId, userId)
    }

    override suspend fun fetchGroupBooks(
        groupId: String,
        page: Int,
        limit: Int,
        availability: Boolean?,
        genre: String?,
        sortBy: String
    ): Pair<List<Book>, Int> {
        val availStr = availability?.let { if (it) "AVAILABLE" else "NOT_AVAILABLE" }
        val response = groupApi.fetchGroupBooks(groupId, page, limit, sortBy, availStr, genre)
        return Pair(response.books, response.pagination.total)
    }

    override suspend fun regenerateInviteCode(groupId: String, expiresInDays: Int?): Pair<String, Date?> {
        val response = groupApi.regenerateInviteCode(groupId, RegenerateInviteRequest(expiresInDays))
        return Pair(response.inviteCode, response.inviteCodeExpiry)
    }
}
