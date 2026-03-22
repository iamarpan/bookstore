// ViewModels/MyLibraryViewModel.swift
import Foundation
import Combine

@MainActor
class MyLibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var myBooks: [Book] = []
    @Published var borrowedBooks: [Transaction] = []
    @Published var lentBooks: [Transaction] = []
    @Published var bookHistory: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Services
    private let bookService: any BookServiceProtocol
    private let transactionService: any TransactionServiceProtocol
    private let refresher: any AppDataRefresherProtocol
    private var currentUserId: String = ""

    // MARK: - Computed Properties

    var activeLoans: [Transaction] {
        borrowedBooks.filter { $0.status == .active }
    }

    var overdueLoans: [Transaction] {
        activeLoans.filter { $0.isOverdue }
    }

    var totalBooksShared: Int { myBooks.count }

    /// Reuse activeLoans instead of double-filtering borrowedBooks
    var totalActiveLends: Int { activeLoans.count }

    var myListedBooks: [Book] { myBooks }

    // MARK: - Initialization

    init(
        bookService: (any BookServiceProtocol)? = nil,
        transactionService: (any TransactionServiceProtocol)? = nil,
        refresher: (any AppDataRefresherProtocol)? = nil
    ) {
        self.bookService = bookService ?? BookService()
        self.transactionService = transactionService ?? TransactionService()
        self.refresher = refresher ?? AppDataRefresher.shared
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
            } catch {
                errorMessage = "Failed to update book availability: \(error.localizedDescription)"
                showError = true
            }
            isLoading = false
        }
    }

    // MARK: - Fetch Methods

    /// Fetch user's owned books — shows memory/disk-cached data instantly, refreshes in background.
    func fetchMyBooks() async {
        errorMessage = nil

        // 1. Memory cache (instant, no I/O)
        if let cached = AppDataStore.shared.cachedMyBooksInMemory(ttl: .infinity) {
            myBooks = cached
        }

        if myBooks.isEmpty { isLoading = true }

        // 2. Async disk read if memory cold
        if myBooks.isEmpty, let cached = await AppDataStore.shared.cachedMyBooks(ttl: .infinity) {
            myBooks = cached
            isLoading = false
        }

        // 3. Network refresh
        do {
            let books = try await refresher.refreshMyBooksIfNeeded(userId: currentUserId, forceRefresh: false)
            myBooks = books
        } catch {
            if myBooks.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isLoading = false
    }

    /// Fetch borrower transactions — shows cached data instantly, refreshes in background.
    func fetchBorrowedBooks() async {
        errorMessage = nil

        if let cached = await AppDataStore.shared.cachedBorrowerTransactions(ttl: .infinity) {
            borrowedBooks = cached
        }

        do {
            let txns = try await refresher.refreshBorrowerTransactionsIfNeeded(forceRefresh: false)
            borrowedBooks = txns
        } catch {
            if borrowedBooks.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Fetch owner transactions — shows cached data instantly, refreshes in background.
    func fetchLentBooks() async {
        errorMessage = nil

        if let cached = await AppDataStore.shared.cachedOwnerTransactions(ttl: .infinity) {
            lentBooks = cached
        }

        do {
            let txns = try await refresher.refreshOwnerTransactionsIfNeeded(forceRefresh: false)
            lentBooks = txns
        } catch {
            // If we have no cached data, surface the error so the user knows
            if lentBooks.isEmpty {
                errorMessage = "Failed to load lent books: \(error.localizedDescription)"
                showError = true
            }
            print("⚠️ fetchLentBooks error: \(error.localizedDescription)")
        }
    }

    /// Fetch history — shows cached data instantly, refreshes in background.
    func fetchHistory() async {
        errorMessage = nil

        if let cached = await AppDataStore.shared.cachedHistoryTransactions(ttl: .infinity) {
            bookHistory = cached
        }

        do {
            let txns = try await refresher.refreshHistoryTransactionsIfNeeded(forceRefresh: false)
            bookHistory = txns
        } catch {
            // If we have no cached data, surface the error so the user knows
            if bookHistory.isEmpty {
                errorMessage = "Failed to load history: \(error.localizedDescription)"
                showError = true
            }
            print("⚠️ fetchHistory error: \(error.localizedDescription)")
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
            myBooks.removeAll { $0.id == book.id }
            AppDataStore.shared.invalidateMyBooks()
            AppDataStore.shared.invalidateBooks()
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

