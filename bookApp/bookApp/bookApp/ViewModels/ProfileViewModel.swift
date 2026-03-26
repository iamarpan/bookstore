import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var booksAddedCount = 0
    @Published var booksBorrowedCount = 0
    @Published var booksLentCount = 0
    @Published var reputationScore = 5.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var recentActions: [String] = []
    
    private let bookService = BookService()
    private let transactionService = TransactionService()
    
    init() {
        self.user = User.loadFromUserDefaults()
    }
    
    func fetchStats() async {
        guard user?.id != nil else { return }
        
        isLoading = true
        
        do {
            // Fetch books added
            let myBooks = try await bookService.fetchMyBooks()
            booksAddedCount = myBooks.count
            
            // Fetch transactions by role
            let borrowedTransactions = try await transactionService.fetchTransactions(role: "BORROWER")
            booksBorrowedCount = borrowedTransactions.filter { $0.status == .returned || $0.status == .active }.count
            
            let lentTransactions = try await transactionService.fetchTransactions(role: "OWNER")
            booksLentCount = lentTransactions.filter { $0.status == .returned || $0.status == .active }.count
            
            // Use real rating from user model
            reputationScore = user?.stats.averageRating ?? 0.0
            
            // Generate recent actions summary (local logic for now)
            var actions: [String] = []
            if booksLentCount > 0 {
                actions.append("Lent out \(booksLentCount) book\(booksLentCount == 1 ? "" : "s") in total")
            }
            if let lastBorrowed = borrowedTransactions.sorted(by: { $0.requestedAt > $1.requestedAt }).first {
                actions.append("Recently borrowed \"\(lastBorrowed.book.title)\"")
            }
            if booksAddedCount > 0 {
                actions.append("Added \(booksAddedCount) book\(booksAddedCount == 1 ? "" : "s") to your library")
            }
            recentActions = actions
            
        } catch {
            print("Error fetching stats: \(error)")
            errorMessage = "Failed to load stats: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func signOut() {
        AuthService().logout()
    }
}
