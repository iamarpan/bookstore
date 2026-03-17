package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.domain.model.User
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TransactionDetailState(
    val isLoading: Boolean = true,
    val transaction: Transaction? = null,
    val currentUserId: String? = null,
    val error: String? = null,
    val isActionLoading: Boolean = false,
    val actionSuccess: String? = null,
    val generatedOTP: String? = null,
    val otpExpirySeconds: Int? = null,
    val showRejectDialog: Boolean = false,
    val showRatingDialog: Boolean = false
) {
    val isOwner: Boolean
        get() = currentUserId != null && transaction?.ownerId == currentUserId

    val isBorrower: Boolean
        get() = currentUserId != null && transaction?.borrowerId == currentUserId

    val canApprove: Boolean
        get() = isOwner && transaction?.status == TransactionStatus.PENDING

    val canReject: Boolean
        get() = isOwner && transaction?.status == TransactionStatus.PENDING

    val canCancel: Boolean
        get() = isBorrower && (transaction?.status == TransactionStatus.PENDING || transaction?.status == TransactionStatus.APPROVED)

    val canGenerateHandoverOTP: Boolean
        get() = isOwner && transaction?.status == TransactionStatus.APPROVED

    val canConfirmHandover: Boolean
        get() = isBorrower && transaction?.status == TransactionStatus.APPROVED

    val canGenerateReturnOTP: Boolean
        get() = isOwner && transaction?.status == TransactionStatus.ACTIVE

    val canConfirmReturn: Boolean
        get() = isBorrower && transaction?.status == TransactionStatus.ACTIVE

    val canRate: Boolean
        get() {
            if (transaction?.status != TransactionStatus.RETURNED) return false
            return if (isOwner) transaction.borrowerRating == null else transaction.ownerRating == null
        }

    val otherPartyName: String
        get() = if (isOwner) transaction?.borrowerName ?: "" else transaction?.ownerName ?: ""

    val otherPartyImageUrl: String?
        get() = if (isOwner) transaction?.borrowerProfileImageUrl else transaction?.ownerProfileImageUrl

    val roleLabel: String
        get() = if (isOwner) "You are lending" else "You are borrowing"
}

@HiltViewModel
class TransactionDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val transactionRepository: TransactionRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val transactionId: String? = savedStateHandle["transactionId"]

    private val _uiState = MutableStateFlow(TransactionDetailState())
    val uiState: StateFlow<TransactionDetailState> = _uiState.asStateFlow()

    init {
        loadTransaction()
    }

    private fun loadTransaction() {
        val id = transactionId ?: run {
            _uiState.value = _uiState.value.copy(isLoading = false, error = "Invalid transaction")
            return
        }

        viewModelScope.launch {
            try {
                val user = authRepository.currentUser.first()
                val transaction = transactionRepository.fetchTransactionById(id)
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    transaction = transaction,
                    currentUserId = user?.id,
                    error = null
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load transaction"
                )
            }
        }
    }

    fun refresh() {
        _uiState.value = _uiState.value.copy(isLoading = true, error = null)
        loadTransaction()
    }

    fun approveRequest() {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true)
            try {
                val updated = transactionRepository.approveRequest(id)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    transaction = updated,
                    actionSuccess = "Request approved"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to approve"
                )
            }
        }
    }

    fun showRejectDialog() {
        _uiState.value = _uiState.value.copy(showRejectDialog = true)
    }

    fun dismissRejectDialog() {
        _uiState.value = _uiState.value.copy(showRejectDialog = false)
    }

    fun rejectRequest(reason: String?) {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true, showRejectDialog = false)
            try {
                val updated = transactionRepository.rejectRequest(id, reason)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    transaction = updated,
                    actionSuccess = "Request rejected"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to reject"
                )
            }
        }
    }

    fun cancelRequest() {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true)
            try {
                val updated = transactionRepository.cancelTransaction(id)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    transaction = updated,
                    actionSuccess = "Request cancelled"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to cancel"
                )
            }
        }
    }

    fun generateHandoverOTP() {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true)
            try {
                val otp = transactionRepository.generateHandoverOTP(id)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    generatedOTP = otp,
                    otpExpirySeconds = 600,
                    actionSuccess = "OTP generated. Share with borrower."
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to generate OTP"
                )
            }
        }
    }

    fun confirmHandover(otp: String) {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true)
            try {
                val updated = transactionRepository.confirmHandover(id, otp)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    transaction = updated,
                    generatedOTP = null,
                    actionSuccess = "Handover confirmed. Book is now with you!"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Invalid OTP"
                )
            }
        }
    }

    fun generateReturnOTP() {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true)
            try {
                val otp = transactionRepository.generateReturnOTP(id)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    generatedOTP = otp,
                    otpExpirySeconds = 600,
                    actionSuccess = "OTP generated. Share with borrower."
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to generate OTP"
                )
            }
        }
    }

    fun confirmReturn(otp: String) {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true)
            try {
                val updated = transactionRepository.confirmReturn(id, otp)
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    transaction = updated,
                    generatedOTP = null,
                    actionSuccess = "Book returned successfully!"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Invalid OTP"
                )
            }
        }
    }

    fun showRatingDialog() {
        _uiState.value = _uiState.value.copy(showRatingDialog = true)
    }

    fun dismissRatingDialog() {
        _uiState.value = _uiState.value.copy(showRatingDialog = false)
    }

    fun submitRating(rating: Int, comment: String?, bookConditionRating: Int?) {
        val id = transactionId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true, showRatingDialog = false)
            try {
                transactionRepository.rateTransaction(id, rating, comment, bookConditionRating)
                loadTransaction()
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    actionSuccess = "Rating submitted"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    error = e.localizedMessage ?: "Failed to submit rating"
                )
            }
        }
    }

    fun clearActionSuccess() {
        _uiState.value = _uiState.value.copy(actionSuccess = null)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun clearOTP() {
        _uiState.value = _uiState.value.copy(generatedOTP = null, otpExpirySeconds = null)
    }
}
