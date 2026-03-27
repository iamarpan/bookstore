import Foundation
import Combine

enum SocketConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    static func == (lhs: SocketConnectionState, rhs: SocketConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

struct TypingEvent: Codable {
    let userId: String
    let transactionId: String
    let isTyping: Bool
}

struct MessagesReadEvent: Codable {
    let userId: String
    let transactionId: String
}

struct SocketEvent: Codable {
    let event: String
    let data: String?
}

@MainActor
class ChatSocketManager: ObservableObject {
    static let shared = ChatSocketManager()
    
    private var socketURL: String {
        APIConfiguration.shared.socketURL
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var currentToken: String?
    private var joinedChats: Set<String> = []
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    
    @Published private(set) var connectionState: SocketConnectionState = .disconnected
    
    let incomingMessages = PassthroughSubject<Message, Never>()
    let typingEvents = PassthroughSubject<TypingEvent, Never>()
    let messagesReadEvents = PassthroughSubject<MessagesReadEvent, Never>()
    
    private init() {}
    
    func connect(token: String) {
        guard connectionState != .connected || currentToken != token else {
            print("[Socket] Already connected with same token")
            return
        }
        
        disconnect()
        currentToken = token
        connectionState = .connecting
        
        guard let url = URL(string: socketURL) else {
            connectionState = .error("Invalid socket URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        urlSession = URLSession(configuration: config)
        webSocketTask = urlSession?.webSocketTask(with: request)
        
        webSocketTask?.resume()
        
        receiveMessage()
        startPingTimer()
        
        connectionState = .connected
        reconnectAttempts = 0
        print("[Socket] Connected to server")
        
        for chatId in joinedChats {
            joinChat(transactionId: chatId)
        }
    }
    
    func disconnect() {
        pingTimer?.invalidate()
        pingTimer = nil
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        
        joinedChats.removeAll()
        connectionState = .disconnected
        print("[Socket] Disconnected from server")
    }
    
    func joinChat(transactionId: String) {
        joinedChats.insert(transactionId)
        
        guard connectionState == .connected else {
            print("[Socket] Cannot join chat - not connected")
            return
        }
        
        let event: [String: Any] = [
            "event": "join_chat",
            "transactionId": transactionId
        ]
        
        sendEvent(event)
        print("[Socket] Joined chat: \(transactionId)")
    }
    
    func leaveChat(transactionId: String) {
        joinedChats.remove(transactionId)
        
        guard connectionState == .connected else { return }
        
        let event: [String: Any] = [
            "event": "leave_chat",
            "transactionId": transactionId
        ]
        
        sendEvent(event)
        print("[Socket] Left chat: \(transactionId)")
    }
    
    func sendTypingStatus(transactionId: String, isTyping: Bool) {
        guard connectionState == .connected else { return }
        
        let event: [String: Any] = [
            "event": "typing",
            "transactionId": transactionId,
            "isTyping": isTyping
        ]
        
        sendEvent(event)
    }
    
    func sendMessageRead(transactionId: String) {
        guard connectionState == .connected else { return }
        
        let event: [String: Any] = [
            "event": "message_read",
            "transactionId": transactionId
        ]
        
        sendEvent(event)
    }
    
    var isConnected: Bool {
        connectionState == .connected
    }
    
    private func sendEvent(_ event: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: event),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("[Socket] Send error: \(error.localizedDescription)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.receiveMessage()
                    
                case .failure(let error):
                    print("[Socket] Receive error: \(error.localizedDescription)")
                    self?.handleDisconnection()
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseSocketMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseSocketMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func parseSocketMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let eventType = json["0"] as? String {
            handleSocketIOEvent(eventType: eventType, json: json)
        } else if let event = json["event"] as? String {
            handleCustomEvent(event: event, json: json)
        } else {
            handleDirectMessage(json: json)
        }
    }
    
    private func handleSocketIOEvent(eventType: String, json: [String: Any]) {
        switch eventType {
        case "new_message":
            if let messageData = json["1"] as? [String: Any] {
                parseNewMessage(messageData)
            }
        case "message_notification":
            if let notificationData = json["1"] as? [String: Any],
               let messageData = notificationData["message"] as? [String: Any] {
                parseNewMessage(messageData)
            }
        case "user_typing":
            if let typingData = json["1"] as? [String: Any] {
                parseTypingEvent(typingData)
            }
        case "messages_read":
            if let readData = json["1"] as? [String: Any] {
                parseMessagesReadEvent(readData)
            }
        default:
            break
        }
    }
    
    private func handleCustomEvent(event: String, json: [String: Any]) {
        switch event {
        case "new_message":
            if let messageData = json["data"] as? [String: Any] {
                parseNewMessage(messageData)
            }
        case "message_notification":
            if let messageData = json["message"] as? [String: Any] {
                parseNewMessage(messageData)
            }
        case "user_typing":
            parseTypingEvent(json)
        case "messages_read":
            parseMessagesReadEvent(json)
        default:
            break
        }
    }
    
    private func handleDirectMessage(_ json: [String: Any]) {
        if json["id"] != nil && json["content"] != nil && json["senderId"] != nil {
            parseNewMessage(json)
        }
    }
    
    private func parseNewMessage(_ data: [String: Any]) {
        guard let id = data["id"] as? String,
              let content = data["content"] as? String,
              let senderId = data["senderId"] as? String,
              let transactionId = data["transactionId"] as? String,
              let createdAt = data["createdAt"] as? String else {
            return
        }
        
        var sender: MessageSender? = nil
        if let senderData = data["sender"] as? [String: Any],
           let senderId = senderData["id"] as? String,
           let name = senderData["name"] as? String {
            sender = MessageSender(
                id: senderId,
                name: name,
                profileImageUrl: senderData["profileImageUrl"] as? String
            )
        }
        
        let message = Message(
            id: id,
            content: content,
            senderId: senderId,
            transactionId: transactionId,
            createdAt: createdAt,
            isRead: data["isRead"] as? Bool,
            sender: sender
        )
        
        print("[Socket] Received new message: \(id)")
        incomingMessages.send(message)
    }
    
    private func parseTypingEvent(_ data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let transactionId = data["transactionId"] as? String else {
            return
        }
        
        let event = TypingEvent(
            userId: userId,
            transactionId: transactionId,
            isTyping: data["isTyping"] as? Bool ?? false
        )
        
        typingEvents.send(event)
    }
    
    private func parseMessagesReadEvent(_ data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let transactionId = data["transactionId"] as? String else {
            return
        }
        
        let event = MessagesReadEvent(
            userId: userId,
            transactionId: transactionId
        )
        
        messagesReadEvents.send(event)
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("[Socket] Ping failed: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.handleDisconnection()
                }
            }
        }
    }
    
    private func handleDisconnection() {
        connectionState = .disconnected
        pingTimer?.invalidate()
        pingTimer = nil
        
        if reconnectAttempts < maxReconnectAttempts, let token = currentToken {
            reconnectAttempts += 1
            let delay = min(Double(reconnectAttempts) * 1.0, 5.0)
            print("[Socket] Attempting reconnect in \(delay)s (attempt \(reconnectAttempts))")
            
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                self.connect(token: token)
            }
        } else {
            connectionState = .error("Connection failed after \(maxReconnectAttempts) attempts")
        }
    }
}
