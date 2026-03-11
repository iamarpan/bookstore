package com.bookstore.bookapp.domain.model

import java.util.Date

enum class PhoneVisibility(val value: String) {
    AFTER_APPROVAL("AFTER_APPROVAL"),
    GROUP_MEMBERS("GROUP_MEMBERS"),
    PUBLIC("PUBLIC")
}

data class PrivacySettings(
    val phoneVisibility: PhoneVisibility = PhoneVisibility.AFTER_APPROVAL
)

data class UserStats(
    val booksShared: Int = 0,
    val successfulLends: Int = 0,
    val booksBorrowed: Int = 0,
    val totalEarned: Double = 0.0,
    val averageRating: Double = 0.0
)

data class NotificationPreferences(
    val pushEnabled: Boolean = true,
    val emailEnabled: Boolean = true,
    val borrowRequests: Boolean = true,
    val dueDateReminders: Boolean = true,
    val groupActivity: Boolean = true
)

data class User(
    val id: String,
    val phoneNumber: String,
    val phoneVerified: Boolean?,
    val name: String,
    val email: String?,
    val bio: String?,
    val profileImageUrl: String?,
    val joinedGroupIds: List<String>?,
    val createdGroupIds: List<String>?,
    val stats: UserStats,
    val privacySettings: PrivacySettings?,
    val notificationPreferences: NotificationPreferences?,
    val deviceToken: String?,
    val lastTokenUpdate: Date?,
    val isActive: Boolean?,
    val createdAt: Date,
    val lastLoginAt: Date?
) {
    val displayRating: String
        get() {
            if (stats.averageRating > 0) {
                return String.format("%.1f", stats.averageRating)
            }
            return "No ratings yet"
        }

    val totalGroups: Int
        get() {
            val joined = joinedGroupIds ?: emptyList()
            val created = createdGroupIds ?: emptyList()
            return (joined + created).toSet().size
        }

    fun isMemberOf(groupId: String): Boolean {
        val joined = joinedGroupIds ?: emptyList()
        val created = createdGroupIds ?: emptyList()
        return joined.contains(groupId) || created.contains(groupId)
    }

    fun isCreatorOf(groupId: String): Boolean {
        val created = createdGroupIds ?: emptyList()
        return created.contains(groupId)
    }
}
