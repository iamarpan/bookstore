import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var newMessageText: String = ""
    
    let transactionId: String
    private let apiClient = APIClient.shared
    private var isPolling = false
    private var pollTimer: Timer?
    
    init(transactionId: String) {
        self.transactionId = transactionId
    }
    
    func fetchMessages() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedMessages: [Message] = try await apiClient.get("/transactions/\(transactionId)/messages")
            self.messages = fetchedMessages
            await markAsRead()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func sendMessage() async {
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        struct SendMessageRequest: Codable {
            let content: String
        }
        
        do {
            let request = SendMessageRequest(content: text)
            let sentMessage: Message = try await apiClient.post("/transactions/\(transactionId)/messages", body: request)
            
            // Optimistically add to list
            self.messages.append(sentMessage)
            self.newMessageText = ""
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func markAsRead() async {
        do {
            struct EmptyBody: Codable {}
            let _: EmptyBody = try await apiClient.post("/transactions/\(transactionId)/messages/read", body: EmptyBody())
            // Update local state if needed (all read)
        } catch {
            // Ignore mark as read errors silently
            print("Failed to mark messages as read: \(error.localizedDescription)")
        }
    }
    
    // Polling mechanics
    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Silent fetch
                do {
                    let fetchedMessages: [Message] = try await self.apiClient.get("/transactions/\(self.transactionId)/messages")
                    if fetchedMessages.count > self.messages.count {
                        self.messages = fetchedMessages
                        await self.markAsRead()
                    }
                } catch {
                    print("Polling error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func stopPolling() {
        isPolling = false
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
