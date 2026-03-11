package com.bookstore.bookapp.domain.model

import java.util.Date

enum class GroupCategory(val value: String, val displayName: String) {
    FRIENDS("FRIENDS", "Friends"),
    OFFICE("OFFICE", "Office"),
    NEIGHBORHOOD("NEIGHBORHOOD", "Neighborhood"),
    BOOK_CLUB("BOOK_CLUB", "Book Club"),
    SCHOOL("SCHOOL", "School")
}

enum class PrivacySetting(val value: String) {
    PUBLIC("PUBLIC"),
    PRIVATE("PRIVATE")
}

enum class MemberRole(val value: String) {
    MEMBER("MEMBER"),
    MODERATOR("MODERATOR"),
    ADMIN("ADMIN"),
    CREATOR("CREATOR")
}

data class BookClub(
    val id: String,
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
    val updatedAt: Date?
) {
    val isCreator: Boolean
        get() = role == MemberRole.CREATOR

    val canModerate: Boolean
        get() = role == MemberRole.CREATOR || role == MemberRole.ADMIN || role == MemberRole.MODERATOR

    val isAdmin: Boolean
        get() = role == MemberRole.CREATOR || role == MemberRole.ADMIN

    val canManageMembers: Boolean
        get() = isAdmin

    val canUpdateSettings: Boolean
        get() = isAdmin
}
