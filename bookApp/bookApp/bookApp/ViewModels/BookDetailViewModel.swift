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
        
        // No need to load user here — transactionService uses the authenticated token
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
        guard hasRequestedBook, let transaction = existingTransaction else { return }
        
        isLoading = true
        
        do {
            _ = try await transactionService.cancelTransaction(id: transaction.id)
            
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
        // Kick off a background task — init() cannot be async
        Task {
            await fetchExistingRequest()
        }
    }
    
    private func fetchExistingRequest() async {
        do {
            // Fetch all transactions where the current user is the borrower
            let allTransactions = try await transactionService.fetchTransactions(role: "BORROWER")
            
            // Find an active-ish transaction for this specific book
            if let match = allTransactions.first(where: {
                $0.bookId == book.id &&
                ($0.status == .pending || $0.status == .approved || $0.status == .active)
            }) {
                existingTransaction = match
                hasRequestedBook = true
            }
        } catch {
            // If the fetch fails (e.g. network issue), default to showing "Request This Book"
            print("⚠️ BookDetailViewModel: could not check existing request — \(error.localizedDescription)")
        }
    }
    
    var canRequestBook: Bool {
        let currentUserId = User.loadFromUserDefaults()?.id ?? ""
        return book.isAvailable &&
               !hasRequestedBook &&
               book.ownerId != currentUserId
    }
    
    var requestButtonTitle: String {
        let currentUserId = User.loadFromUserDefaults()?.id ?? ""
        
        if !book.isAvailable {
            return "Not Available"
        } else if book.ownerId == currentUserId {
            return "Your Book"
        } else if hasRequestedBook {
            return "Request Sent"
        } else {
            return "Request This Book"
        }
    }
    
    var requestStatus: RequestStatus? {
        let currentUserId = User.loadFromUserDefaults()?.id ?? ""
        
        if book.ownerId == currentUserId {
            return .ownBook
        }
        
        if let transaction = existingTransaction {
            switch transaction.status {
            case .pending, .approved:
                return .requested
            case .active:
                return .borrowed
            case .returned, .rejected, .cancelled:
                return book.isAvailable ? .canRequest : .unavailable
            }
        }
        
        if !book.isAvailable {
            return .unavailable
        }
        
        return .canRequest
    }
}

enum RequestStatus {
    case canRequest
    case requested
    case borrowed
    case unavailable
    case ownBook
}