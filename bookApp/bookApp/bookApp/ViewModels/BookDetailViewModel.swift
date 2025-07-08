import Foundation

@MainActor
class BookDetailViewModel: ObservableObject {
    @Published var book: Book
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasRequestedBook = false
    @Published var existingRequest: BookRequest?
    
    init(book: Book) {
        self.book = book
        checkExistingRequest()
    }
    
    func requestBook() async {
        guard !hasRequestedBook else { return }
        
        isLoading = true
        
        // Create a new book request
        let newRequest = BookRequest(
            bookId: book.id ?? "",
            borrowerId: User.mockUser.id ?? "",
            borrowerName: User.mockUser.name,
            borrowerFlatNumber: User.mockUser.flat,
            ownerId: book.ownerId,
            societyId: book.societyId
        )
        
        // Simulate API call
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Update state
            existingRequest = newRequest
            hasRequestedBook = true
            showSuccessAlert = true
            
        } catch {
            errorMessage = "Failed to send request: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func cancelRequest() async {
        guard hasRequestedBook else { return }
        
        isLoading = true
        
        // Simulate API call to cancel request
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Update state
            existingRequest = nil
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
        if book.title == "The Great Gatsby" {
            // Simulate existing request for demo
            existingRequest = BookRequest(
                bookId: book.id ?? "",
                borrowerId: User.mockUser.id ?? "",
                borrowerName: User.mockUser.name,
                borrowerFlatNumber: User.mockUser.flat,
                ownerId: book.ownerId,
                societyId: book.societyId
            )
            hasRequestedBook = true
        }
    }
    
    var canRequestBook: Bool {
        return book.isAvailable && 
               !hasRequestedBook && 
               book.ownerId != User.mockUser.id
    }
    
    var requestButtonTitle: String {
        if !book.isAvailable {
            return "Not Available"
        } else if book.ownerId == User.mockUser.id {
            return "Your Book"
        } else if hasRequestedBook {
            return "Request Sent"
        } else {
            return "Request This Book"
        }
    }
    
    var requestStatus: String? {
        guard let request = existingRequest else { return nil }
        
        switch request.status {
        case .pending:
            return "Your request is pending approval"
        case .approved:
            return "Request approved! Contact the owner"
        case .rejected:
            return "Request was rejected"
        case .returned:
            return "Book has been returned"
        case .overdue:
            return "Book is overdue for return"
        }
    }
} 