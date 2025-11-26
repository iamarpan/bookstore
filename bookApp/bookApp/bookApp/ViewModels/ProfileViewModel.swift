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
            
            // Fetch transactions to calculate borrowed/lent
            // Note: In a real app, we might have dedicated endpoints for stats
            // For now, we'll use what we have or mock it if endpoints are missing
            
            // Mocking transaction stats for now as we don't have a direct "fetch all my transactions" 
            // that separates borrowed vs lent easily without fetching everything.
            // But we can try to fetch if we add methods to TransactionService.
            
            // Let's assume we have these methods or add them later.
            // For now, I'll set some mock values or 0
            booksBorrowedCount = 0 
            booksLentCount = 0
            
            // Reputation is mocked in User model or calculated
            reputationScore = 4.8
            
        } catch {
            print("Error fetching stats: \(error)")
            errorMessage = "Failed to load stats"
        }
        
        isLoading = false
    }
    
    func signOut() {
        AuthService().logout()
    }
}
