package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.data.remote.api.Message
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ChatState(
    val isLoading: Boolean = true,
    val transaction: Transaction? = null,
    val messages: List<Message> = emptyList(),
    val currentUserId: String? = null,
    val error: String? = null,
    val isSending: Boolean = false,
    val chatAvailable: Boolean = false
) {
    val otherPartyName: String
        get() {
            if (transaction == null || currentUserId == null) return ""
            return if (transaction.borrowerId == currentUserId) 
                transaction.ownerName 
            else 
                transaction.borrowerName
        }

    val otherPartyImageUrl: String?
        get() {
            if (transaction == null || currentUserId == null) return null
            return if (transaction.borrowerId == currentUserId)
                transaction.ownerProfileImageUrl
            else
                transaction.borrowerProfileImageUrl
        }
}

@HiltViewModel
class ChatViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val transactionRepository: TransactionRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    private val transactionId: String? = savedStateHandle["transactionId"]

    private val _uiState = MutableStateFlow(ChatState())
    val uiState: StateFlow<ChatState> = _uiState.asStateFlow()

    init {
        loadChat()
        startPolling()
    }

    private fun loadChat() {
        val id = transactionId ?: run {
            _uiState.value = _uiState.value.copy(isLoading = false, error = "Invalid transaction")
            return
        }

        viewModelScope.launch {
            try {
                val user = authRepository.currentUser.first()
                val transaction = transactionRepository.fetchTransactionById(id)
                val chatAvailable = transaction.status == TransactionStatus.APPROVED || 
                                   transaction.status == TransactionStatus.ACTIVE

                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    transaction = transaction,
                    currentUserId = user?.id,
                    chatAvailable = chatAvailable,
                    error = null
                )

                if (chatAvailable) {
                    loadMessages()
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load chat"
                )
            }
        }
    }

    private fun loadMessages() {
        val id = transactionId ?: return
        viewModelScope.launch {
            try {
                val messages = transactionRepository.getMessages(id)
                _uiState.value = _uiState.value.copy(messages = messages)
            } catch (e: Exception) {
                // Silent fail for message loading - don't show error for refresh
            }
        }
    }

    private fun startPolling() {
        viewModelScope.launch {
            while (isActive) {
                delay(5000)
                if (_uiState.value.chatAvailable && !_uiState.value.isLoading) {
                    loadMessages()
                }
            }
        }
    }

    fun sendMessage(content: String) {
        val id = transactionId ?: return
        if (content.isBlank()) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSending = true)
            try {
                val newMessage = transactionRepository.sendMessage(id, content)
                _uiState.value = _uiState.value.copy(
                    isSending = false,
                    messages = _uiState.value.messages + newMessage
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSending = false,
                    error = e.localizedMessage ?: "Failed to send message"
                )
            }
        }
    }

    fun refresh() {
        loadMessages()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
