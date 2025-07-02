import Foundation

@MainActor
class MyLibraryViewModel: ObservableObject {
    @Published var borrowedBooks: [BookRequest] = []
    @Published var lentBooks: [BookRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    init() {
        loadLibraryData()
    }
    
    func loadLibraryData() {
        isLoading = true
        
        Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            
            await MainActor.run {
                // Create more realistic mock data
                let currentUserId = User.mockUser.id ?? ""
                
                // Books I've requested (borrowed books)
                self.borrowedBooks = [
                    BookRequest(
                        bookId: "1",
                        borrowerId: currentUserId,
                        borrowerName: User.mockUser.name,
                        borrowerFlatNumber: User.mockUser.flatNumber,
                        ownerId: "owner1"
                    ),
                    BookRequest(
                        bookId: "2", 
                        borrowerId: currentUserId,
                        borrowerName: User.mockUser.name,
                        borrowerFlatNumber: User.mockUser.flatNumber,
                        ownerId: "owner2"
                    )
                ]
                
                // Requests for my books (lent books)
                var lentRequest = BookRequest(
                    bookId: "3",
                    borrowerId: "borrower1",
                    borrowerName: "Jane Smith",
                    borrowerFlatNumber: "B-102",
                    ownerId: currentUserId
                )
                lentRequest.status = .pending
                
                self.lentBooks = [lentRequest]
                self.isLoading = false
            }
        }
    }
    
    func refreshLibraryData() {
        loadLibraryData()
    }
    
    func updateRequestStatus(_ request: BookRequest, newStatus: BookRequest.RequestStatus) {
        // Simulate API call
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                if let index = lentBooks.firstIndex(where: { $0.id == request.id }) {
                    lentBooks[index].status = newStatus
                    lentBooks[index].responseDate = Date()
                    
                    if newStatus == .approved {
                        lentBooks[index].dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
                    }
                }
            }
        }
    }
} 