package com.bookstore.bookapp.data.remote.api

import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupMember
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Path
import retrofit2.http.Query
import java.util.Date

data class GroupsResponse(val groups: List<BookClub>)

data class CreateGroupRequest(
    val name: String,
    val description: String,
    val category: String,
    val privacy: String,
    val rules: String?,
    val coverImageUrl: String?
)

data class JoinGroupViaInviteRequest(val inviteCode: String)
data class JoinGroupResponse(val message: String, val group: BookClub)

// Backend sometimes returns custom empty structs or simple Status/Message mappings.
// We use simple data classes or Unit. Let's use custom responses when parsed.
data class SimpleStatusResponse(val status: String)
data class SimpleMessageResponse(val message: String)

data class UpdateGroupRequest(
    val name: String?,
    val description: String?,
    val category: String?,
    val privacy: String?,
    val coverImageUrl: String?,
    val rules: String?
)

data class MembersResponse(val members: List<GroupMember>, val total: Int)

data class UpdateRoleRequest(val role: String)
data class UpdateRoleResponse(val message: String, val member: GroupMember)

data class GroupBooksResponse(val books: List<Book>, val pagination: Pagination)
data class Pagination(val page: Int, val limit: Int, val total: Int, val totalPages: Int)

data class RegenerateInviteRequest(val expiresInDays: Int?)
data class RegenerateInviteResponse(val inviteCode: String, val inviteCodeExpiry: Date?)

interface GroupApi {
    @GET("groups/my-groups")
    suspend fun fetchMyGroups(): List<BookClub>

    @GET("groups/discover")
    suspend fun discoverGroups(
        @Query("category") category: String?,
        @Query("search") search: String?
    ): GroupsResponse

    @GET("groups/{id}")
    suspend fun fetchGroupDetails(@Path("id") id: String): BookClub

    @GET("groups")
    suspend fun getAllGroups(): List<BookClub>

    @POST("groups")
    suspend fun createGroup(@Body request: CreateGroupRequest): BookClub

    @POST("groups/{id}/join")
    suspend fun joinGroup(@Path("id") id: String): SimpleStatusResponse

    @POST("groups/join")
    suspend fun joinViaInvite(@Body request: JoinGroupViaInviteRequest): JoinGroupResponse

    @POST("groups/{id}/leave")
    suspend fun leaveGroup(@Path("id") id: String)

    @PUT("groups/{id}")
    suspend fun updateGroup(@Path("id") id: String, @Body request: UpdateGroupRequest): BookClub

    @DELETE("groups/{id}")
    suspend fun deleteGroup(@Path("id") id: String): SimpleMessageResponse

    @GET("groups/{id}/members")
    suspend fun fetchGroupMembers(
        @Path("id") groupId: String,
        @Query("role") role: String?
    ): MembersResponse

    @PUT("groups/{groupId}/members/{userId}")
    suspend fun updateMemberRole(
        @Path("groupId") groupId: String,
        @Path("userId") userId: String,
        @Body request: UpdateRoleRequest
    ): UpdateRoleResponse

    @DELETE("groups/{groupId}/members/{userId}")
    suspend fun removeMember(
        @Path("groupId") groupId: String,
        @Path("userId") userId: String
    ): SimpleMessageResponse

    @GET("groups/{groupId}/books")
    suspend fun fetchGroupBooks(
        @Path("groupId") groupId: String,
        @Query("page") page: Int,
        @Query("limit") limit: Int,
        @Query("sortBy") sortBy: String,
        @Query("availability") availability: String?,
        @Query("genre") genre: String?
    ): GroupBooksResponse

    @POST("groups/{groupId}/regenerate-invite")
    suspend fun regenerateInviteCode(
        @Path("groupId") groupId: String,
        @Body request: RegenerateInviteRequest
    ): RegenerateInviteResponse
}
