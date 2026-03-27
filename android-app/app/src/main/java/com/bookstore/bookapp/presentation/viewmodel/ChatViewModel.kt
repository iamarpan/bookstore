package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.data.remote.api.Message
import com.bookstore.bookapp.data.remote.socket.ChatSocketManager
import com.bookstore.bookapp.data.remote.socket.SocketConnectionState
import com.bookstore.bookapp.data.remote.socket.TypingEvent
import com.bookstore.bookapp.di.TokenHolder
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
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
    val chatAvailable: Boolean = false,
    val isSocketConnected: Boolean = false,
    val otherUserTyping: Boolean = false
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
    private val authRepository: AuthRepository,
    private val chatSocketManager: ChatSocketManager,
    private val tokenHolder: TokenHolder
) : ViewModel() {

    private val transactionId: String? = savedStateHandle["transactionId"]

    private val _uiState = MutableStateFlow(ChatState())
    val uiState: StateFlow<ChatState> = _uiState.asStateFlow()

    private var pollingJob: Job? = null
    private var usePollingFallback = false

    init {
        loadChat()
        observeSocketConnection()
        observeIncomingMessages()
        observeTypingEvents()
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
                    connectToSocket()
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load chat"
                )
            }
        }
    }

    private fun connectToSocket() {
        val token = tokenHolder.accessToken
        if (token != null) {
            chatSocketManager.connect(token)
            transactionId?.let { chatSocketManager.joinChat(it) }
        } else {
            startPollingFallback()
        }
    }

    private fun observeSocketConnection() {
        viewModelScope.launch {
            chatSocketManager.connectionState.collect { state ->
                val isConnected = state is SocketConnectionState.Connected
                _uiState.value = _uiState.value.copy(isSocketConnected = isConnected)
                
                when (state) {
                    is SocketConnectionState.Connected -> {
                        stopPollingFallback()
                        transactionId?.let { chatSocketManager.joinChat(it) }
                    }
                    is SocketConnectionState.Disconnected,
                    is SocketConnectionState.Error -> {
                        if (_uiState.value.chatAvailable) {
                            startPollingFallback()
                        }
                    }
                    is SocketConnectionState.Connecting -> {
                    }
                }
            }
        }
    }

    private fun observeIncomingMessages() {
        viewModelScope.launch {
            chatSocketManager.incomingMessages.collect { message ->
                if (message.transactionId == transactionId) {
                    val currentMessages = _uiState.value.messages
                    if (currentMessages.none { it.id == message.id }) {
                        _uiState.value = _uiState.value.copy(
                            messages = currentMessages + message
                        )
                    }
                }
            }
        }
    }

    private fun observeTypingEvents() {
        viewModelScope.launch {
            chatSocketManager.typingEvents.collect { event ->
                if (event.transactionId == transactionId && 
                    event.userId != _uiState.value.currentUserId) {
                    _uiState.value = _uiState.value.copy(otherUserTyping = event.isTyping)
                }
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
            }
        }
    }

    private fun startPollingFallback() {
        if (pollingJob?.isActive == true) return
        usePollingFallback = true
        
        pollingJob = viewModelScope.launch {
            while (isActive && usePollingFallback) {
                delay(5000)
                if (_uiState.value.chatAvailable && !_uiState.value.isLoading) {
                    loadMessages()
                }
            }
        }
    }

    private fun stopPollingFallback() {
        usePollingFallback = false
        pollingJob?.cancel()
        pollingJob = null
    }

    fun sendMessage(content: String) {
        val id = transactionId ?: return
        if (content.isBlank()) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isSending = true)
            try {
                val newMessage = transactionRepository.sendMessage(id, content)
                val currentMessages = _uiState.value.messages
                if (currentMessages.none { it.id == newMessage.id }) {
                    _uiState.value = _uiState.value.copy(
                        isSending = false,
                        messages = currentMessages + newMessage
                    )
                } else {
                    _uiState.value = _uiState.value.copy(isSending = false)
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isSending = false,
                    error = e.localizedMessage ?: "Failed to send message"
                )
            }
        }
    }

    fun onTypingStateChanged(isTyping: Boolean) {
        transactionId?.let { id ->
            chatSocketManager.sendTypingStatus(id, isTyping)
        }
    }

    fun refresh() {
        loadMessages()
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    override fun onCleared() {
        super.onCleared()
        transactionId?.let { chatSocketManager.leaveChat(it) }
        stopPollingFallback()
    }
}
