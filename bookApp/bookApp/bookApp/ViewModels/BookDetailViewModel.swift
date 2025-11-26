import Foundation

@MainActor
class BookDetailViewModel: ObservableObject {
    @Published var book: Book
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasRequestedBook = false
    @Published var existingTransaction: Transaction?
    
    private let transactionService = TransactionService()
    
    init(book: Book) {
        self.book = book
        checkExistingRequest()
    }
    
    func requestBook() async {
        guard !hasRequestedBook else { return }
        
        isLoading = true
        
        // Get current user (use mock for now)
        _ = User.loadFromUserDefaults() ?? User.mockUser
        
        // Create a borrow request
        do {
            let transaction = try await transactionService.createBorrowRequest(
                bookId: book.id,
                duration: .twoWeeks,
                message: "I'd like to borrow this book!"
            )
            
            // Update state
            existingTransaction = transaction
            hasRequestedBook = true
            showSuccessAlert = true
            
        } catch {
            errorMessage = "Failed to send request: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func cancelRequest() async {
        guard hasRequestedBook, let _ = existingTransaction else { return }
        
        isLoading = true
        
        // TODO: Add cancel request API endpoint
        // For now, just update local state
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Update state
            existingTransaction = nil
            hasRequestedBook = false
            
        } catch {
            errorMessage = "Failed to cancel request: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    private func checkExistingRequest() {
        // Check if user has already requested this book
        // In a real app, this would be an API call
        // For now, simulate with mock data
        hasRequestedBook = false
    }
    
    var canRequestBook: Bool {
        let currentUser = User.loadFromUserDefaults() ?? User.mockUser
        return book.isAvailable &&
               !hasRequestedBook &&
               book.ownerId != currentUser.id
    }
    
    var requestButtonTitle: String {
        let currentUser = User.loadFromUserDefaults() ?? User.mockUser
        
        if !book.isAvailable {
            return "Not Available"
        } else if book.ownerId == currentUser.id {
            return "Your Book"
        } else if hasRequestedBook {
            return "Request Sent"
        } else {
            return "Request This Book"
        }
    }
    
    var requestStatus: String? {
        guard let transaction = existingTransaction else { return nil }
        
        switch transaction.status {
        case .pending:
            return "Your request is pending approval"
        case .approved:
            return "Request approved! Arrange book handover"
        case .rejected:
            return "Request was rejected"
        case .active:
            return "Book is currently borrowed"
        case .returned:
            return "Book has been returned"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}