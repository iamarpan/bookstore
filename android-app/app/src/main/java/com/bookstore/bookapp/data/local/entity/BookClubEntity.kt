package com.bookstore.bookapp.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupCategory
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.domain.model.PrivacySetting
import java.util.Date

@Entity(tableName = "book_clubs")
data class BookClubEntity(
    @PrimaryKey val id: String,
    val name: String,
    val description: String,
    val coverImageUrl: String?,
    val category: GroupCategory,
    val privacy: PrivacySetting,
    val creatorId: String,
    val inviteCode: String,
    val inviteCodeExpiry: Date?,
    val rules: String?,
    val booksCount: Int,
    val memberCount: Int,
    val role: MemberRole?,
    val isMember: Boolean,
    val joinedAt: Date?,
    val distance: Double?,
    val createdAt: Date,
    val updatedAt: Date?,
    val isMyGroup: Boolean = false
)

fun BookClubEntity.toDomain() = BookClub(
    id = id,
    name = name,
    description = description,
    coverImageUrl = coverImageUrl,
    category = category,
    privacy = privacy,
    creatorId = creatorId,
    inviteCode = inviteCode,
    inviteCodeExpiry = inviteCodeExpiry,
    rules = rules,
    booksCount = booksCount,
    memberCount = memberCount,
    role = role,
    isMember = isMember,
    joinedAt = joinedAt,
    distance = distance,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun BookClub.toEntity(isMyGroup: Boolean = false) = BookClubEntity(
    id = id,
    name = name,
    description = description,
    coverImageUrl = coverImageUrl,
    category = category,
    privacy = privacy,
    creatorId = creatorId,
    inviteCode = inviteCode,
    inviteCodeExpiry = inviteCodeExpiry,
    rules = rules,
    booksCount = booksCount,
    memberCount = memberCount,
    role = role,
    isMember = isMember,
    joinedAt = joinedAt,
    distance = distance,
    createdAt = createdAt,
    updatedAt = updatedAt,
    isMyGroup = isMyGroup
)
