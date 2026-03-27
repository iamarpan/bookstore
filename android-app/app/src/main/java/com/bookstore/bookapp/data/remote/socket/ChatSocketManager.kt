package com.bookstore.bookapp.data.remote.socket

import android.util.Log
import com.bookstore.bookapp.data.remote.api.Message
import com.bookstore.bookapp.data.remote.api.MessageSender
import com.google.gson.Gson
import com.google.gson.JsonObject
import io.socket.client.IO
import io.socket.client.Socket
import io.socket.emitter.Emitter
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.callbackFlow
import org.json.JSONObject
import java.net.URI
import com.bookstore.bookapp.di.NetworkModule
import javax.inject.Inject
import javax.inject.Singleton

sealed class SocketConnectionState {
    data object Disconnected : SocketConnectionState()
    data object Connecting : SocketConnectionState()
    data object Connected : SocketConnectionState()
    data class Error(val message: String) : SocketConnectionState()
}

data class TypingEvent(
    val userId: String,
    val transactionId: String,
    val isTyping: Boolean
)

data class MessagesReadEvent(
    val userId: String,
    val transactionId: String
)

@Singleton
class ChatSocketManager @Inject constructor() {
    
    companion object {
        private const val TAG = "ChatSocketManager"
        private val SOCKET_URL = NetworkModule.SOCKET_URL
    }
    
    private var socket: Socket? = null
    private val gson = Gson()
    private var currentToken: String? = null
    private val joinedChats = mutableSetOf<String>()
    
    private val _connectionState = MutableStateFlow<SocketConnectionState>(SocketConnectionState.Disconnected)
    val connectionState: StateFlow<SocketConnectionState> = _connectionState.asStateFlow()
    
    private val _incomingMessages = MutableSharedFlow<Message>(replay = 0, extraBufferCapacity = 64)
    val incomingMessages: SharedFlow<Message> = _incomingMessages.asSharedFlow()
    
    private val _typingEvents = MutableSharedFlow<TypingEvent>(replay = 0, extraBufferCapacity = 16)
    val typingEvents: SharedFlow<TypingEvent> = _typingEvents.asSharedFlow()
    
    private val _messagesReadEvents = MutableSharedFlow<MessagesReadEvent>(replay = 0, extraBufferCapacity = 16)
    val messagesReadEvents: SharedFlow<MessagesReadEvent> = _messagesReadEvents.asSharedFlow()
    
    fun connect(token: String) {
        if (socket?.connected() == true && currentToken == token) {
            Log.d(TAG, "Already connected with same token")
            return
        }
        
        disconnect()
        currentToken = token
        _connectionState.value = SocketConnectionState.Connecting
        
        try {
            val options = IO.Options().apply {
                auth = mapOf("token" to token)
                transports = arrayOf("websocket", "polling")
                reconnection = true
                reconnectionAttempts = 10
                reconnectionDelay = 1000
                reconnectionDelayMax = 5000
                timeout = 20000
            }
            
            socket = IO.socket(URI.create(SOCKET_URL), options).apply {
                on(Socket.EVENT_CONNECT, onConnect)
                on(Socket.EVENT_DISCONNECT, onDisconnect)
                on(Socket.EVENT_CONNECT_ERROR, onConnectError)
                on("new_message", onNewMessage)
                on("message_notification", onMessageNotification)
                on("user_typing", onUserTyping)
                on("messages_read", onMessagesRead)
                connect()
            }
            
            Log.d(TAG, "Attempting to connect to socket server")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create socket connection", e)
            _connectionState.value = SocketConnectionState.Error(e.message ?: "Connection failed")
        }
    }
    
    fun disconnect() {
        socket?.let { s ->
            s.off()
            s.disconnect()
            Log.d(TAG, "Disconnected from socket server")
        }
        socket = null
        joinedChats.clear()
        _connectionState.value = SocketConnectionState.Disconnected
    }
    
    fun joinChat(transactionId: String) {
        if (joinedChats.contains(transactionId)) {
            Log.d(TAG, "Already joined chat: $transactionId")
            return
        }
        
        socket?.let { s ->
            if (s.connected()) {
                s.emit("join_chat", transactionId)
                joinedChats.add(transactionId)
                Log.d(TAG, "Joined chat: $transactionId")
            } else {
                Log.w(TAG, "Cannot join chat - socket not connected")
            }
        }
    }
    
    fun leaveChat(transactionId: String) {
        socket?.let { s ->
            if (s.connected()) {
                s.emit("leave_chat", transactionId)
                joinedChats.remove(transactionId)
                Log.d(TAG, "Left chat: $transactionId")
            }
        }
    }
    
    fun sendTypingStatus(transactionId: String, isTyping: Boolean) {
        socket?.let { s ->
            if (s.connected()) {
                val data = JSONObject().apply {
                    put("transactionId", transactionId)
                    put("isTyping", isTyping)
                }
                s.emit("typing", data)
            }
        }
    }
    
    fun sendMessageRead(transactionId: String) {
        socket?.let { s ->
            if (s.connected()) {
                val data = JSONObject().apply {
                    put("transactionId", transactionId)
                }
                s.emit("message_read", data)
            }
        }
    }
    
    fun isConnected(): Boolean = socket?.connected() == true
    
    private val onConnect = Emitter.Listener {
        Log.d(TAG, "Socket connected")
        _connectionState.value = SocketConnectionState.Connected
        
        joinedChats.forEach { chatId ->
            socket?.emit("join_chat", chatId)
        }
    }
    
    private val onDisconnect = Emitter.Listener { args ->
        val reason = args.firstOrNull()?.toString() ?: "Unknown"
        Log.d(TAG, "Socket disconnected: $reason")
        _connectionState.value = SocketConnectionState.Disconnected
    }
    
    private val onConnectError = Emitter.Listener { args ->
        val error = args.firstOrNull()?.toString() ?: "Unknown error"
        Log.e(TAG, "Socket connection error: $error")
        _connectionState.value = SocketConnectionState.Error(error)
    }
    
    private val onNewMessage = Emitter.Listener { args ->
        try {
            val data = args.firstOrNull()
            if (data != null) {
                val message = parseMessage(data)
                message?.let {
                    Log.d(TAG, "Received new message: ${it.id}")
                    _incomingMessages.tryEmit(it)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing new message", e)
        }
    }
    
    private val onMessageNotification = Emitter.Listener { args ->
        try {
            val data = args.firstOrNull()
            if (data != null && data is JSONObject) {
                val messageJson = data.optJSONObject("message")
                messageJson?.let {
                    val message = parseMessage(it)
                    message?.let { msg ->
                        Log.d(TAG, "Received message notification: ${msg.id}")
                        _incomingMessages.tryEmit(msg)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing message notification", e)
        }
    }
    
    private val onUserTyping = Emitter.Listener { args ->
        try {
            val data = args.firstOrNull() as? JSONObject
            data?.let {
                val event = TypingEvent(
                    userId = it.optString("userId"),
                    transactionId = it.optString("transactionId"),
                    isTyping = it.optBoolean("isTyping", false)
                )
                _typingEvents.tryEmit(event)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing typing event", e)
        }
    }
    
    private val onMessagesRead = Emitter.Listener { args ->
        try {
            val data = args.firstOrNull() as? JSONObject
            data?.let {
                val event = MessagesReadEvent(
                    userId = it.optString("userId"),
                    transactionId = it.optString("transactionId")
                )
                _messagesReadEvents.tryEmit(event)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing messages read event", e)
        }
    }
    
    private fun parseMessage(data: Any): Message? {
        return try {
            val jsonStr = when (data) {
                is JSONObject -> data.toString()
                is String -> data
                else -> return null
            }
            
            val json = JSONObject(jsonStr)
            val senderJson = json.optJSONObject("sender")
            
            Message(
                id = json.optString("id"),
                transactionId = json.optString("transactionId"),
                senderId = json.optString("senderId"),
                content = json.optString("content"),
                isRead = json.optBoolean("isRead", false),
                createdAt = json.optString("createdAt"),
                sender = if (senderJson != null) {
                    MessageSender(
                        id = senderJson.optString("id"),
                        name = senderJson.optString("name"),
                        profileImageUrl = senderJson.optString("profileImageUrl").takeIf { it.isNotEmpty() }
                    )
                } else {
                    MessageSender(id = "", name = "Unknown", profileImageUrl = null)
                }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing message JSON", e)
            null
        }
    }
}
