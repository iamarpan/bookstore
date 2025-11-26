import FirebaseFirestore
import Foundation

@MainActor
class MyLibraryViewModel: ObservableObject {
    @Published var borrowedBooks: [BookRequest] = []
    @Published var lentBooks: [BookRequest] = []
    @Published var myListedBooks: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let firestoreService = FirestoreService()
    private let authService = FirebaseAuthService()
    private var requestsListener: ListenerRegistration?
    
    init() {
        loadLibraryData()
    }
    
    deinit {
        requestsListener?.remove()
    }
    
    func loadLibraryData() {
        guard let user = authService.currentUser else {
            // If no user is logged in, we can't fetch data
            // In a real app, you might want to clear the lists or show a login prompt
            return
        }
        guard let userId = user.id else {
            print("Error: User ID is missing")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Fetch books I've listed
                let myBooks = try await firestoreService.getUserBooks(userId: userId)
                
                // 2. Setup listener for requests (both borrowing and lending)
                // Note: The current FirestoreService.listenToRequests only listens for requests *made by* the user (borrowing).
                // We might need to enhance this or add a separate listener for requests *received* by the user (lending).
                // For now, let's assume we fetch them once or implement a better listener structure.
                
                // Fetch requests where I am the borrower
                setupBorrowingListener(userId: userId)
                
                // Fetch requests where I am the owner (lending)
                // Since we don't have a direct listener for this in FirestoreService yet, 
                // we might need to query it. For now, let's add a method to FirestoreService or use a query here.
                // Ideally, FirestoreService should handle this.
                // Let's assume we will add `getRequestsForOwner` to FirestoreService.
                
                await MainActor.run {
                    self.myListedBooks = myBooks
                    self.isLoading = false
                }
                
                // Fetch incoming requests (Lent Books / Requests to approve)
                // We need to implement this in FirestoreService
                let incomingRequests = try await firestoreService.getIncomingRequests(for: userId)
                
                await MainActor.run {
                    self.lentBooks = incomingRequests
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load library: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func setupBorrowingListener(userId: String) {
        requestsListener = firestoreService.listenToRequests(for: userId) { [weak self] requests in
            Task { @MainActor in
                self?.borrowedBooks = requests
            }
        }
    }
    
    func refreshLibraryData() {
        loadLibraryData()
    }
    
    func updateRequestStatus(_ request: BookRequest, newStatus: RequestStatus) {
        isLoading = true
        
        Task {
            do {
                var updatedRequest = request
                updatedRequest.status = newStatus
                updatedRequest.responseDate = Date()
                
                if newStatus == .approved {
                    updatedRequest.dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
                    
                    // Also update book availability
                    try await firestoreService.updateBookAvailability(bookId: request.bookId, isAvailable: false)
                }
                
                try await firestoreService.updateBookRequest(updatedRequest)
                
                // Refresh data to reflect changes
                loadLibraryData()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update request: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteBook(_ book: Book) {
        guard let bookId = book.id else { return }
        isLoading = true
        
        Task {
            do {
                try await firestoreService.deleteBook(with: bookId)
                
                await MainActor.run {
                    self.myListedBooks.removeAll { $0.id == bookId }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete book: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    func toggleBookAvailability(_ book: Book) {
        guard let bookId = book.id else { return }
        // Optimistic update
        if let index = myListedBooks.firstIndex(where: { $0.id == bookId }) {
            myListedBooks[index].isAvailable.toggle()
        }
        
        Task {
            do {
                try await firestoreService.updateBookAvailability(bookId: bookId, isAvailable: !book.isAvailable)
            } catch {
                // Revert on failure
                await MainActor.run {
                    if let index = self.myListedBooks.firstIndex(where: { $0.id == bookId }) {
                        self.myListedBooks[index].isAvailable.toggle()
                        self.errorMessage = "Failed to update availability: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
            }
        }
    }
}
 
