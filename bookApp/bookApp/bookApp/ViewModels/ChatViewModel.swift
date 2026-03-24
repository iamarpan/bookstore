import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var newMessageText: String = ""
    @Published var transaction: Transaction?
    @Published var otherPartyName: String = "Chat"
    @Published var otherPartyImageUrl: String?
    @Published var isSending = false
    @Published var chatAvailable = true

    let transactionId: String
    private let store = AppDataStore.shared
    private let messageService = MessageService.shared
    private let transactionService = TransactionService()
    private var isPolling = false
    private var pollTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(transactionId: String) {
        self.transactionId = transactionId
        setupMessageObservation()
    }
    
    private func setupMessageObservation() {
        store.$messagesByTransaction
            .map { $0[self.transactionId] ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: \.messages, on: self)
            .store(in: &cancellables)
    }

    func fetchInitialData(currentUserId: String) async {
        isLoading = true
        error = nil
        
        do {
            // Check cache first for immediate UI (Manage button)
            if let cached = store.borrowedTransactions.first(where: { $0.id == transactionId }) {
                self.transaction = cached
            } else if let cached = store.ownerTransactions.first(where: { $0.id == transactionId }) {
                self.transaction = cached
            }
            
            // If we have a transaction from cache, set up other party info immediately
            if let t = self.transaction {
                updateOtherPartyInfo(t, currentUserId: currentUserId)
            }

            // Fetch transaction details from network to sync
            let fetchedTransaction = try await transactionService.fetchTransactionById(id: transactionId)
            self.transaction = fetchedTransaction
            
            // Re-confirm other party info and chat availability
            updateOtherPartyInfo(fetchedTransaction, currentUserId: currentUserId)
            
            let status = fetchedTransaction.status
            self.chatAvailable = (status == .pending || status == .approved || status == .active)

            // Initial messages fetch
            if chatAvailable {
                // Load from cache first for offline access / immediate UI
                _ = await messageService.fetchCachedMessages(transactionId: transactionId)
                
                // Then fetch from network to sync (store will update and notify UI)
                _ = try await messageService.fetchMessages(transactionId: transactionId)
                await markAsRead()
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }

    func fetchMessages() async {
        guard chatAvailable else { return }
        do {
            _ = try await messageService.fetchMessages(transactionId: transactionId)
            await markAsRead()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func sendMessage() async {
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, chatAvailable, !isSending else { return }
        
        isSending = true
        do {
            let sentMessage = try await messageService.sendMessage(transactionId: transactionId, content: text)
            
            // Optimistically update store
            var updatedMessages = self.messages
            updatedMessages.append(sentMessage)
            store.storeMessages(updatedMessages, transactionId: transactionId)
            
            self.newMessageText = ""
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }
    
    func markAsRead() async {
        do {
            try await messageService.markAsRead(transactionId: transactionId)
        } catch {
            print("Failed to mark messages as read: \(error.localizedDescription)")
        }
    }
    
    // Polling mechanics
    func startPolling() {
        guard !isPolling, chatAvailable else { return }
        isPolling = true
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Silent fetch
                await self.fetchMessages()
            }
        }
    }
    
    func stopPolling() {
        isPolling = false
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func updateOtherPartyInfo(_ t: Transaction, currentUserId: String) {
        if t.ownerId == currentUserId {
            self.otherPartyName = t.borrowerName
            self.otherPartyImageUrl = t.borrowerProfileImageUrl
        } else {
            self.otherPartyName = t.ownerName
            self.otherPartyImageUrl = t.ownerProfileImageUrl
        }
    }
}
