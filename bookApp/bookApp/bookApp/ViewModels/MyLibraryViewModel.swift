// ViewModels/MyLibraryViewModel.swift
import Foundation
import Combine

@MainActor
class MyLibraryViewModel: ObservableObject {
    // MARK: - Published Properties (UI state)
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil
    @Published var unreadCounts: [String: Int] = [:]
    @Published var borrowedBooks: [Transaction] = []
    @Published var lentBooks: [Transaction] = []
    @Published var myListedBooks: [Book] = []

    // MARK: - Store & Services
    private let store = AppDataStore.shared
    private let bookService: any BookServiceProtocol
    private let transactionService: any TransactionServiceProtocol
    private let messageService = MessageService.shared
    private let refresher: any AppDataRefresherProtocol
    private var currentUserId: String = ""
    private var syncTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var activeLoans: [Transaction] {
        store.borrowedTransactions.filter { $0.status == .active }
    }

    var overdueLoans: [Transaction] {
        activeLoans.filter { $0.isOverdue }
    }

    var totalBooksShared: Int { store.myBooks.count }

    /// Reuse activeLoans instead of double-filtering borrowedBooks
    var totalActiveLends: Int { activeLoans.count }

    // MARK: - Initialization

    init(
        bookService: (any BookServiceProtocol)? = nil,
        transactionService: (any TransactionServiceProtocol)? = nil,
        refresher: (any AppDataRefresherProtocol)? = nil
    ) {
        self.bookService = bookService ?? BookService()
        self.transactionService = transactionService ?? TransactionService()
        self.refresher = refresher ?? AppDataRefresher.shared
        setupObservations()
    }

    private func setupObservations() {
        store.$borrowedTransactions
            .receive(on: DispatchQueue.main)
            .assign(to: &$borrowedBooks)
        
        store.$ownerTransactions
            .receive(on: DispatchQueue.main)
            .assign(to: &$lentBooks)
            
        store.$myBooks
            .receive(on: DispatchQueue.main)
            .assign(to: &$myListedBooks)
    }

    deinit {
        // syncTask?.cancel() // Cannot call @MainActor task cancellation in deinit easily
    }

    // MARK: - Background Sync

    /// Starts a background polling task that refreshes library data every 30 seconds.
    /// It respects the AppDataStore TTL (5m) to avoid redundant network hits.
    func startSync() {
        stopSync()
        syncTask = Task {
            while !Task.isCancelled {
                // Fetch all data (respects TTL)
                await refreshAll(force: false)
                
                // Wait 30 seconds before next poll
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            }
        }
    }

    /// Cancels the ongoing background polling task.
    func stopSync() {
        syncTask?.cancel()
        syncTask = nil
    }

    // MARK: - View Actions

    func refreshLibraryData() {
        Task {
            await refreshAll(force: true)
        }
    }

    func updateRequestStatus(_ transaction: Transaction, newStatus: TransactionStatus) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                if newStatus == .approved {
                    _ = try await transactionService.approveRequest(id: transaction.id)
                } else if newStatus == .rejected {
                    // Reason parameter can be passed if needed, here we just reject without reason.
                    _ = try await transactionService.rejectRequest(id: transaction.id, reason: nil)
                } else {
                    print("Unsupported status update from MyLibrary: \(newStatus)")
                    isLoading = false
                    return
                }
                
                // Refresh data to reflect the new state securely
                await fetchLentBooks()
                await fetchBorrowedBooks()
                await fetchHistory()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    func toggleBookAvailability(_ book: Book) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                var updatedBook = book
                updatedBook.isAvailable.toggle()
                _ = try await bookService.updateBook(updatedBook)
                
                // Refresh specific cache or all data
                await fetchMyBooks()
                store.invalidateBooks()
            } catch {
                errorMessage = "Failed to update book availability: \(error.localizedDescription)"
                showError = true
            }
            isLoading = false
        }
    }

    // MARK: - Fetch Methods

    /// Fetch user's owned books — triggering refresher updates the store.
    func fetchMyBooks() async {
        errorMessage = nil

        if store.myBooks.isEmpty { isLoading = true }

        do {
            _ = try await refresher.refreshMyBooksIfNeeded(userId: currentUserId, forceRefresh: false)
        } catch {
            if store.myBooks.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isLoading = false
    }

    /// Fetch borrower transactions — triggering refresher updates the store.
    func fetchBorrowedBooks() async {
        errorMessage = nil

        do {
            _ = try await refresher.refreshBorrowerTransactionsIfNeeded(forceRefresh: false)
        } catch {
            if store.borrowedTransactions.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Fetch owner transactions — triggering refresher updates the store.
    func fetchLentBooks() async {
        errorMessage = nil

        do {
            _ = try await refresher.refreshOwnerTransactionsIfNeeded(forceRefresh: false)
        } catch {
            if store.ownerTransactions.isEmpty {
                errorMessage = "Failed to load lent books: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// Fetch history — triggering refresher updates the store.
    func fetchHistory() async {
        errorMessage = nil

        do {
            _ = try await refresher.refreshHistoryTransactionsIfNeeded(forceRefresh: false)
        } catch {
            if store.historyTransactions.isEmpty {
                errorMessage = "Failed to load history: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    /// Fetch all library data concurrently.
    func fetchAllData(userId: String) async {
        currentUserId = userId

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchMyBooks() }
            group.addTask { await self.fetchBorrowedBooks() }
            group.addTask { await self.fetchLentBooks() }
            group.addTask { await self.fetchHistory() }
        }
        await fetchUnreadCounts()
        
        // Ensure background sync is running
        if syncTask == nil {
            startSync()
        }
    }

    /// Fetch unread counts for all active/pending/approved transactions
    func fetchUnreadCounts() async {
        let allTransactions = store.borrowedTransactions + store.ownerTransactions
        await withTaskGroup(of: (String, Int)?.self) { group in
            for txn in allTransactions {
                // Only for statuses that support chat
                if txn.status == .pending || txn.status == .approved || txn.status == .active {
                    group.addTask {
                        do {
                            let count = try await self.messageService.getUnreadCount(transactionId: txn.id)
                            return (txn.id, count)
                        } catch {
                            return nil
                        }
                    }
                }
            }
            
            var counts: [String: Int] = [:]
            for await result in group {
                if let (id, count) = result {
                    counts[id] = count
                }
            }
            self.unreadCounts = counts
        }
    }

    /// Force-refresh all data.
    func refreshAll(force: Bool = false) async {
        if force {
            AppDataStore.shared.invalidateMyBooks()
            AppDataStore.shared.invalidateBorrowerTransactions()
            AppDataStore.shared.invalidateOwnerTransactions()
            AppDataStore.shared.invalidateHistoryTransactions()
        }
        await fetchAllData(userId: currentUserId)
    }

    // MARK: - Book Actions

    /// Delete a book.
    func deleteBook(_ book: Book) async {
        guard !book.id.isEmpty else { return }

        isLoading = true

        do {
            try await bookService.deleteBook(id: book.id)
            // UI will update automatically when store is refreshed or if we manually update store here
            // For immediate UI feedback, we can manually prune it from the store if it's there
            store.invalidateMyBooks()
            store.invalidateBooks()
            _ = try? await refresher.refreshMyBooksIfNeeded(userId: currentUserId, forceRefresh: true)
            isLoading = false
            print("✅ Book deleted successfully")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
            print("❌ Error deleting book: \(error)")
        }
    }

}

