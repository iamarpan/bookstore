package com.bookstore.bookapp.data.remote.api

import com.bookstore.bookapp.domain.model.BookNotification
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query

data class DeviceTokenRequest(val deviceToken: String)

data class NotificationResponse(
    val notifications: List<BookNotification>,
    val unreadCount: Int
)

interface NotificationApi {
    @POST("users/me/device-token")
    suspend fun registerDeviceToken(@Body request: DeviceTokenRequest)

    @GET("notifications")
    suspend fun fetchNotifications(@Query("unreadOnly") unreadOnly: Boolean?): NotificationResponse

    @PUT("notifications/{id}/read")
    suspend fun markAsRead(@Path("id") id: String)

    @PUT("notifications/mark-all-read")
    suspend fun markAllAsRead()

    @DELETE("notifications/{id}")
    suspend fun deleteNotification(@Path("id") id: String)
}
