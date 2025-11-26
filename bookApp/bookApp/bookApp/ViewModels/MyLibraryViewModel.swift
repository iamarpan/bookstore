// ViewModels/MyLibraryViewModel.swift
import Foundation
import Combine

@MainActor
class MyLibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var myBooks: [Book] = []
    @Published var borrowedBooks: [Transaction] = []
    @Published var bookHistory: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Services
    private let bookService: BookService
    private let transactionService: TransactionService
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
    
    // Computed properties for views
    var lentBooks: [Transaction] {
        // TODO: Fetch transactions where current user is the owner
        []
    }
    
    var myListedBooks: [Book] {
        myBooks
    }
    
    // MARK: - Initialization
    
    init(
        bookService: BookService = BookService(),
        transactionService: TransactionService = TransactionService()
    ) {
        self.bookService = bookService
        self.transactionService = transactionService
    }
    
    // MARK: - View Actions
    
    func refreshLibraryData() {
        Task {
            await refreshAll()
        }
    }
    
    func updateRequestStatus(_ transaction: Transaction, newStatus: TransactionStatus) {
        // TODO: Implement API call to update transaction status
        print("Would update transaction \(transaction.id) to status: \(newStatus)")
    }
    
    func toggleBookAvailability(_ book: Book) {
        // TODO: Implement API call to toggle book availability
        print("Would toggle availability for book: \(book.title)")
    }
    
    // MARK: - Fetch Methods
    
    // MARK: - Fetch Methods
    
    /// Fetch user's own books
    func fetchMyBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Add ownerId filter to API
            // For now, fetch all and filter locally
            let allBooks = try await bookService.fetchBooks()
            myBooks = allBooks.filter { $0.ownerId == currentUserId }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
    
    /// Fetch books currently borrowed
    func fetchBorrowedBooks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            borrowedBooks = try await transactionService.fetchTransactions(
                role: "BORROWER",
                status: .active
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
    
    /// Fetch transaction history
    func fetchHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            bookHistory = try await transactionService.fetchTransactions(
                status: .returned
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
    
    /// Fetch all library data
    func fetchAllData(userId: String) async {
        currentUserId = userId
        
        await fetchMyBooks()
        await fetchBorrowedBooks()
        await fetchHistory()
    }
    
    /// Refresh all data
    func refreshAll() async {
        await fetchAllData(userId: currentUserId)
    }
    
    // MARK: - Book Actions
    
    /// Delete a book
    func deleteBook(_ book: Book) async {
        guard !book.id.isEmpty else { return }
        
        isLoading = true
        
        do {
            try await bookService.deleteBook(id: book.id)
            myBooks.removeAll { $0.id == book.id }
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
    
    /// Load mock data for development
    func loadMockData() {
        bookService.loadMockBooks()
        myBooks = bookService.books.filter { $0.ownerId == "usr_demo" }
        
        transactionService.loadMockTransactions()
        borrowedBooks = transactionService.transactions.filter { 
            $0.borrowerId == "usr_demo" && $0.status == .active 
        }
        bookHistory = transactionService.transactions.filter { $0.status == .returned }
        
        print("✅ Loaded mock library data")
    }
}
