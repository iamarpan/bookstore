package com.bookstore.bookapp.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookCondition
import java.util.Date

@Entity(tableName = "books")
data class BookEntity(
    @PrimaryKey val id: String,
    val title: String,
    val author: String,
    val genre: String,
    val description: String,
    val personalNotes: String?,
    val imageUrl: String,
    val isbn: String?,
    val publisher: String?,
    val year: Int?,
    val pages: Int?,
    val language: String?,
    val condition: BookCondition,
    val lendingPricePerWeek: Double,
    val isAvailable: Boolean,
    val ownerId: String?,
    val ownerName: String?,
    val ownerRating: Double?,
    val ownerBooksCount: Int?,
    val ownerProfileImageUrl: String?,
    val visibleInGroups: List<String>?,
    val currentTransactionId: String?,
    val createdAt: Date,
    val updatedAt: Date?,
    val isMyBook: Boolean = false // used to query 'my books' exclusively
)

fun BookEntity.toDomain() = Book(
    id = id,
    title = title,
    author = author,
    genre = genre,
    description = description,
    personalNotes = personalNotes,
    imageUrl = imageUrl,
    isbn = isbn,
    publisher = publisher,
    year = year,
    pages = pages,
    language = language,
    condition = condition,
    lendingPricePerWeek = lendingPricePerWeek,
    isAvailable = isAvailable,
    ownerId = ownerId ?: "",
    ownerName = ownerName ?: "Unknown",
    ownerRating = ownerRating,
    ownerBooksCount = ownerBooksCount,
    ownerProfileImageUrl = ownerProfileImageUrl,
    visibleInGroups = visibleInGroups ?: emptyList(),
    currentTransactionId = currentTransactionId,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun Book.toEntity(isMyBook: Boolean = false) = BookEntity(
    id = id,
    title = title,
    author = author,
    genre = genre,
    description = description,
    personalNotes = personalNotes,
    imageUrl = imageUrl,
    isbn = isbn,
    publisher = publisher,
    year = year,
    pages = pages,
    language = language,
    condition = condition,
    lendingPricePerWeek = lendingPricePerWeek,
    isAvailable = isAvailable,
    ownerId = ownerId,
    ownerName = ownerName,
    ownerRating = ownerRating,
    ownerBooksCount = ownerBooksCount,
    ownerProfileImageUrl = ownerProfileImageUrl,
    visibleInGroups = visibleInGroups,
    currentTransactionId = currentTransactionId,
    createdAt = createdAt,
    updatedAt = updatedAt,
    isMyBook = isMyBook
)
