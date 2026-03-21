package com.bookstore.bookapp.domain.model

import java.util.Date

enum class BookCondition(val value: String) {
    NEW("NEW"),
    LIKE_NEW("LIKE_NEW"),
    GOOD("GOOD"),
    FAIR("FAIR"),
    POOR("POOR")
}

data class Book(
    val id: String,
    val title: String,
    val author: String,
    val genre: String,
    val description: String,
    val personalNotes: String?,
    val imageUrl: String,
    
    // ISBN and metadata
    val isbn: String?,
    val publisher: String?,
    val year: Int?,
    val pages: Int?,
    val language: String?,
    
    // Condition and pricing
    val condition: BookCondition,
    val lendingPricePerWeek: Double,
    
    // Availability and ownership
    val isAvailable: Boolean,
    val ownerId: String,
    val ownerName: String,
    val ownerRating: Double?,
    val ownerBooksCount: Int?,
    val ownerProfileImageUrl: String?,
    
    // Multi-group visibility
    val visibleInGroups: List<String>?,
    
    // Transaction tracking
    val currentTransactionId: String?,
    
    // Timestamps
    val createdAt: Date,
    val updatedAt: Date?
) {
    val primaryGroupId: String?
        get() = visibleInGroups?.firstOrNull()

    fun isVisibleIn(groupId: String): Boolean {
        return visibleInGroups?.contains(groupId) == true
    }

    val formattedPrice: String
        get() {
            if (lendingPricePerWeek == 0.0) return "Free"
            return "₹${lendingPricePerWeek.toInt()}/week"
        }

    val statusText: String
        get() {
            if (!isAvailable && currentTransactionId != null) return "Currently Lent"
            if (!isAvailable) return "Not Available"
            return "Available"
        }
}
