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
    @Published var isSocketConnected = false
    @Published var otherUserTyping = false

    let transactionId: String
    private let store = AppDataStore.shared
    private let messageService = MessageService.shared
    private let transactionService = TransactionService()
    private let socketManager = ChatSocketManager.shared
    private var usePollingFallback = false
    private var pollTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    init(transactionId: String) {
        self.transactionId = transactionId
        setupMessageObservation()
        setupSocketObservation()
    }
    
    private func setupMessageObservation() {
        store.$messagesByTransaction
            .map { $0[self.transactionId] ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: \.messages, on: self)
            .store(in: &cancellables)
    }
    
    private func setupSocketObservation() {
        socketManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.isSocketConnected = (state == .connected)
                
                switch state {
                case .connected:
                    self.stopPollingFallback()
                    self.socketManager.joinChat(transactionId: self.transactionId)
                case .disconnected, .error:
                    if self.chatAvailable {
                        self.startPollingFallback()
                    }
                case .connecting:
                    break
                }
            }
            .store(in: &cancellables)
        
        socketManager.incomingMessages
            .filter { [weak self] message in
                message.transactionId == self?.transactionId
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                if !self.messages.contains(where: { $0.id == message.id }) {
                    var updatedMessages = self.messages
                    updatedMessages.append(message)
                    self.store.storeMessages(updatedMessages, transactionId: self.transactionId)
                }
            }
            .store(in: &cancellables)
        
        socketManager.typingEvents
            .filter { [weak self] event in
                event.transactionId == self?.transactionId &&
                event.userId != self?.currentUserId
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.otherUserTyping = event.isTyping
            }
            .store(in: &cancellables)
    }

    func fetchInitialData(currentUserId: String) async {
        self.currentUserId = currentUserId
        isLoading = true
        error = nil
        
        do {
            if let cached = store.borrowedTransactions.first(where: { $0.id == transactionId }) {
                self.transaction = cached
            } else if let cached = store.ownerTransactions.first(where: { $0.id == transactionId }) {
                self.transaction = cached
            }
            
            if let t = self.transaction {
                updateOtherPartyInfo(t, currentUserId: currentUserId)
            }

            let fetchedTransaction = try await transactionService.fetchTransactionById(id: transactionId)
            self.transaction = fetchedTransaction
            
            updateOtherPartyInfo(fetchedTransaction, currentUserId: currentUserId)
            
            let status = fetchedTransaction.status
            self.chatAvailable = (status == .pending || status == .approved || status == .active)

            if chatAvailable {
                _ = await messageService.fetchCachedMessages(transactionId: transactionId)
                _ = try await messageService.fetchMessages(transactionId: transactionId)
                await markAsRead()
                
                connectToSocket()
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func connectToSocket() {
        if let token = KeychainManager.shared.getAccessToken() {
            socketManager.connect(token: token)
            socketManager.joinChat(transactionId: transactionId)
        } else {
            startPollingFallback()
        }
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
        socketManager.sendTypingStatus(transactionId: transactionId, isTyping: false)
        
        do {
            let sentMessage = try await messageService.sendMessage(transactionId: transactionId, content: text)
            
            if !messages.contains(where: { $0.id == sentMessage.id }) {
                var updatedMessages = self.messages
                updatedMessages.append(sentMessage)
                store.storeMessages(updatedMessages, transactionId: transactionId)
            }
            
            self.newMessageText = ""
        } catch {
            self.error = error.localizedDescription
        }
        isSending = false
    }
    
    func markAsRead() async {
        do {
            try await messageService.markAsRead(transactionId: transactionId)
            socketManager.sendMessageRead(transactionId: transactionId)
        } catch {
            print("Failed to mark messages as read: \(error.localizedDescription)")
        }
    }
    
    func onTypingStateChanged(_ isTyping: Bool) {
        socketManager.sendTypingStatus(transactionId: transactionId, isTyping: isTyping)
    }
    
    private func startPollingFallback() {
        guard pollTimer == nil, chatAvailable else { return }
        usePollingFallback = true
        
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.usePollingFallback else { return }
                await self.fetchMessages()
            }
        }
    }
    
    private func stopPollingFallback() {
        usePollingFallback = false
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    func startPolling() {
        startPollingFallback()
    }
    
    func stopPolling() {
        socketManager.leaveChat(transactionId: transactionId)
        stopPollingFallback()
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
