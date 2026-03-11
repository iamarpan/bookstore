package com.bookstore.bookapp.data.remote.api

import com.bookstore.bookapp.domain.model.Transaction
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

data class TransactionsResponse(val transactions: List<Transaction>)

data class BorrowRequest(
    val bookId: String,
    val duration: String,
    val durationDays: Int?,
    val message: String?
)

data class RejectRequest(val reason: String?)

data class HandoverRequest(val otp: String)
data class ReturnRequest(val otp: String)
data class MarkPaymentRequest(val role: String)

data class RatingRequest(
    val rating: Int,
    val comment: String?,
    val bookConditionRating: Int?
)

data class OTPResponse(val otp: String)

interface TransactionApi {
    @GET("transactions/my")
    suspend fun fetchTransactions(
        @Query("role") role: String?,
        @Query("status") status: String?,
        @Query("page") page: Int,
        @Query("limit") limit: Int
    ): TransactionsResponse

    @POST("transactions/request")
    suspend fun createBorrowRequest(@Body request: BorrowRequest): Transaction

    @GET("transactions/{id}")
    suspend fun fetchTransactionById(@Path("id") id: String): Transaction

    @POST("transactions/{id}/generate-handover-otp")
    suspend fun generateHandoverOTP(@Path("id") id: String): OTPResponse

    @POST("transactions/{id}/generate-return-otp")
    suspend fun generateReturnOTP(@Path("id") id: String): OTPResponse

    @POST("transactions/{id}/approve")
    suspend fun approveRequest(@Path("id") id: String): Transaction

    @POST("transactions/{id}/reject")
    suspend fun rejectRequest(@Path("id") id: String, @Body request: RejectRequest): Transaction

    @POST("transactions/{id}/confirm-handover")
    suspend fun confirmHandover(@Path("id") id: String, @Body request: HandoverRequest): Transaction

    @POST("transactions/{id}/confirm-return")
    suspend fun confirmReturn(@Path("id") id: String, @Body request: ReturnRequest): Transaction

    @POST("transactions/{id}/mark-payment")
    suspend fun markPaymentComplete(@Path("id") id: String, @Body request: MarkPaymentRequest): Transaction

    @POST("transactions/{id}/rate")
    suspend fun rateTransaction(@Path("id") id: String, @Body request: RatingRequest)

    @POST("transactions/{id}/cancel")
    suspend fun cancelTransaction(@Path("id") id: String): Transaction
}
