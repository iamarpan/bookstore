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
    private let bookService: BookService
    private let transactionService: TransactionService
    private let refresher: AppDataRefresher
    private var currentUserId: String = ""
    
    // MARK: - Computed Properties
    
    var activeLoans: [Transaction] {
        borrowedBooks.filter { $0.status == .active }
    }
    
    var overdueLoans: [Transaction] {
        activeLoans.filter { $0.isOverdue }
    }
    
    var totalBooksShared: Int {
        myBooks.count
    }
    
    var totalActiveLends: Int {
        borrowedBooks.filter { $0.status == .active }.count
    }
    
    var myListedBooks: [Book] {
        myBooks
    }
    
    // MARK: - Initialization
    
    init(
        bookService: BookService? = nil,
        transactionService: TransactionService? = nil,
        refresher: AppDataRefresher = .shared
    ) {
        self.bookService = bookService ?? BookService()
        self.transactionService = transactionService ?? TransactionService()
        self.refresher = refresher
    }
    
    // MARK: - View Actions
    
    func refreshLibraryData() {
        Task {
            await refreshAll(force: true)
        }
    }
    
    func updateRequestStatus(_ transaction: Transaction, newStatus: TransactionStatus) {
        print("Would update transaction \(transaction.id) to status: \(newStatus)")
    }
    
    func toggleBookAvailability(_ book: Book) {
        print("Would toggle availability for book: \(book.title)")
    }
    
    // MARK: - Fetch Methods
    
    /// Fetch user's owned books — shows disk-cached data instantly, refreshes in background.
    func fetchMyBooks() async {
        errorMessage = nil

        // Serve stale-ok disk data immediately
        if let cached = AppDataStore.shared.cachedMyBooks(ttl: .infinity) {
            myBooks = cached
        }
        if myBooks.isEmpty { isLoading = true }

        do {
            let books = try await refresher.refreshMyBooksIfNeeded(userId: currentUserId, forceRefresh: true)
            myBooks = books
        } catch {
            if myBooks.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isLoading = false
    }
    
    /// Fetch borrower transactions — shows disk-cached data instantly, refreshes in background.
    func fetchBorrowedBooks() async {
        errorMessage = nil

        if let cached = AppDataStore.shared.cachedBorrowerTransactions(ttl: .infinity) {
            borrowedBooks = cached
        }

        do {
            let txns = try await refresher.refreshBorrowerTransactionsIfNeeded(forceRefresh: true)
            borrowedBooks = txns
        } catch {
            if borrowedBooks.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    /// Fetch owner transactions — shows disk-cached data instantly, refreshes in background.
    func fetchLentBooks() async {
        errorMessage = nil

        if let cached = AppDataStore.shared.cachedOwnerTransactions(ttl: .infinity) {
            lentBooks = cached
        }

        do {
            let txns = try await refresher.refreshOwnerTransactionsIfNeeded(forceRefresh: true)
            lentBooks = txns
        } catch { /* silent — stale data already shown */ }
    }
    
    /// Fetch history — shows disk-cached data instantly, refreshes in background.
    func fetchHistory() async {
        errorMessage = nil

        if let cached = AppDataStore.shared.cachedHistoryTransactions(ttl: .infinity) {
            bookHistory = cached
        }

        do {
            let txns = try await refresher.refreshHistoryTransactionsIfNeeded(forceRefresh: true)
            bookHistory = txns
        } catch { /* silent — stale data already shown */ }
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
            // Wipe library entries so next calls skip the cache
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
            // Invalidate so next fetch reflects the deletion
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
    
    // MARK: - Mock Data
    
    func loadMockData() {
        bookService.loadMockBooks()
        myBooks = bookService.books.filter { $0.ownerId == "usr_demo" }
        
        transactionService.loadMockTransactions()
        borrowedBooks = transactionService.transactions.filter {
            $0.borrowerId == "usr_demo" && $0.status == .active
        }
        lentBooks = transactionService.transactions.filter {
            $0.ownerId == "usr_demo"
        }
        bookHistory = transactionService.transactions.filter { $0.status == .returned }
        
        print("✅ Loaded mock library data")
    }
}
