package com.bookstore.bookapp.domain.model

import java.util.Date

data class MemberUser(
    val id: String,
    val name: String,
    val profileImageUrl: String?,
    val booksShared: Int,
    val averageRating: Double?
) {
    val formattedRating: String
        get() {
            if (averageRating == null) return "No ratings yet"
            return String.format("%.1f", averageRating)
        }
}

data class GroupMember(
    val id: String,
    val userId: String,
    val role: MemberRole,
    val joinedAt: Date,
    val user: MemberUser
)
