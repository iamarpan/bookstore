import Foundation

/// Service for handling chat message operations
@MainActor
class MessageService: ObservableObject {
    static let shared = MessageService()
    private let apiClient = APIClient.shared
    
    struct MessagesResponse: Codable {
        let messages: [Message]
    }
    
    /// Fetch all messages for a specific transaction and cache them
    func fetchMessages(transactionId: String) async throws -> [Message] {
        let response: MessagesResponse = try await apiClient.get("/transactions/\(transactionId)/messages")
        AppDataStore.shared.storeMessages(response.messages, transactionId: transactionId)
        return response.messages
    }
    
    /// Load messages from local cache (immediate response)
    func fetchCachedMessages(transactionId: String) async -> [Message]? {
        return await AppDataStore.shared.cachedMessages(transactionId: transactionId)
    }
    
    /// Send a new message in a transaction chat
    func sendMessage(transactionId: String, content: String) async throws -> Message {
        struct SendMessageRequest: Codable {
            let content: String
        }
        let request = SendMessageRequest(content: content)
        return try await apiClient.post("/transactions/\(transactionId)/messages", body: request)
    }
    
    /// Get unread message count for a transaction
    func getUnreadCount(transactionId: String) async throws -> Int {
        struct UnreadCountResponse: Codable {
            let unreadCount: Int
        }
        let response: UnreadCountResponse = try await apiClient.get("/transactions/\(transactionId)/messages/unread")
        return response.unreadCount
    }
    
    /// Mark all messages in a transaction as read
    func markAsRead(transactionId: String) async throws {
        struct EmptyBody: Codable {}
        try await apiClient.post("/transactions/\(transactionId)/messages/read", body: EmptyBody())
    }
}
