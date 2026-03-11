package com.bookstore.bookapp.data.local

import androidx.room.TypeConverter
import com.bookstore.bookapp.domain.model.BookCondition
import com.bookstore.bookapp.domain.model.BorrowDuration
import com.bookstore.bookapp.domain.model.GroupCategory
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.domain.model.PrivacySetting
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.util.Date

class Converters {
    private val gson = Gson()

    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    @TypeConverter
    fun fromStringList(value: String?): List<String> {
        if (value.isNullOrEmpty()) return emptyList()
        val listType = object : TypeToken<List<String>>() {}.type
        return gson.fromJson(value, listType)
    }

    @TypeConverter
    fun toStringList(list: List<String>?): String {
        return gson.toJson(list ?: emptyList<String>())
    }

    // Enums
    @TypeConverter
    fun fromBookCondition(value: String): BookCondition = enumValueOf(value)
    @TypeConverter
    fun toBookCondition(value: BookCondition): String = value.name

    @TypeConverter
    fun fromGroupCategory(value: String): GroupCategory = enumValueOf(value)
    @TypeConverter
    fun toGroupCategory(value: GroupCategory): String = value.name

    @TypeConverter
    fun fromPrivacySetting(value: String): PrivacySetting = enumValueOf(value)
    @TypeConverter
    fun toPrivacySetting(value: PrivacySetting): String = value.name

    @TypeConverter
    fun fromMemberRole(value: String?): MemberRole? = value?.let { enumValueOf<MemberRole>(it) }
    @TypeConverter
    fun toMemberRole(value: MemberRole?): String? = value?.name

    @TypeConverter
    fun fromTransactionStatus(value: String): TransactionStatus = enumValueOf(value)
    @TypeConverter
    fun toTransactionStatus(value: TransactionStatus): String = value.name

    @TypeConverter
    fun fromBorrowDuration(value: String): BorrowDuration = enumValueOf(value)
    @TypeConverter
    fun toBorrowDuration(value: BorrowDuration): String = value.name
}
