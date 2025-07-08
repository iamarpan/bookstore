import Foundation

@MainActor
class MyLibraryViewModel: ObservableObject {
    @Published var borrowedBooks: [BookRequest] = []
    @Published var lentBooks: [BookRequest] = []
    @Published var myListedBooks: [Book] = []
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
                        borrowerFlatNumber: User.mockUser.flat,
                        ownerId: "owner1",
                        societyId: User.mockUser.societyId
                    ),
                    BookRequest(
                        bookId: "2", 
                        borrowerId: currentUserId,
                        borrowerName: User.mockUser.name,
                        borrowerFlatNumber: User.mockUser.flat,
                        ownerId: "owner2",
                        societyId: User.mockUser.societyId
                    )
                ]
                
                // Requests for my books (lent books)
                var lentRequest = BookRequest(
                    bookId: "3",
                    borrowerId: "borrower1",
                    borrowerName: "Jane Smith",
                    borrowerFlatNumber: "B-102",
                    ownerId: currentUserId,
                    societyId: User.mockUser.societyId
                )
                lentRequest.status = .pending
                
                self.lentBooks = [lentRequest]
                
                // Books I've listed/added to the system
                self.myListedBooks = [
                    Book(
                        title: "To Kill a Mockingbird",
                        author: "Harper Lee",
                        genre: "Fiction",
                        description: "A classic American novel about racial injustice and childhood innocence.",
                        imageURL: "https://covers.openlibrary.org/b/id/8225261-L.jpg",
                        isAvailable: true,
                        ownerId: currentUserId,
                        ownerName: User.mockUser.name,
                        ownerFlatNumber: User.mockUser.flat,
                        societyId: User.mockUser.societyId
                    ),
                    Book(
                        title: "The Catcher in the Rye",
                        author: "J.D. Salinger",
                        genre: "Fiction",
                        description: "A coming-of-age story about teenage rebellion and angst.",
                        imageURL: "https://covers.openlibrary.org/b/id/8225261-L.jpg",
                        isAvailable: false, // Currently lent out
                        ownerId: currentUserId,
                        ownerName: User.mockUser.name,
                        ownerFlatNumber: User.mockUser.flat,
                        societyId: User.mockUser.societyId
                    ),
                    Book(
                        title: "Educated",
                        author: "Tara Westover",
                        genre: "Biography",
                        description: "A memoir about education, family, and the struggle for self-invention.",
                        imageURL: "https://covers.openlibrary.org/b/id/8225261-L.jpg",
                        isAvailable: true,
                        ownerId: currentUserId,
                        ownerName: User.mockUser.name,
                        ownerFlatNumber: User.mockUser.flat,
                        societyId: User.mockUser.societyId
                    )
                ]
                
                self.isLoading = false
            }
        }
    }
    
    func refreshLibraryData() {
        loadLibraryData()
    }
    
    func updateRequestStatus(_ request: BookRequest, newStatus: RequestStatus) {
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
    
    func deleteBook(_ book: Book) {
        // Simulate API call
        Task {
            try await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                myListedBooks.removeAll { $0.id == book.id }
            }
        }
    }
    
    func toggleBookAvailability(_ book: Book) {
        // Simulate API call
        Task {
            try await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                if let index = myListedBooks.firstIndex(where: { $0.id == book.id }) {
                    myListedBooks[index].isAvailable.toggle()
                }
            }
        }
    }
} 