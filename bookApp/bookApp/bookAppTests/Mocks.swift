// bookAppTests/Mocks.swift
import Foundation
@testable import bookApp

/// Mock BookService for unit testing
class MockBookService: BookServiceProtocol {
    var booksToReturn: [Book] = []
    var shouldFail = false
    var lastUpdatedBook: Book?
    var lastDeletedBookId: String?

    func fetchBooks(groupIds: [String]?, availability: String?, genres: [String]?, minPrice: Double?, maxPrice: Double?, sortBy: String?, search: String?, page: Int, limit: Int) async throws -> [Book] {
        return booksToReturn
    }
    
    func fetchBook(id: String) async throws -> Book {
        return Book(id: id, title: "Mock", author: "Mock", genre: "Mock", description: "", ownerId: "m", ownerName: "m", visibleInGroups: [])
    }

    func fetchMyBooks() async throws -> [Book] {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        return booksToReturn
    }

    func createBook(_ book: Book) async throws -> Book { return book }

    func updateBook(_ book: Book) async throws -> Book {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        lastUpdatedBook = book
        return book
    }

    func deleteBook(id: String) async throws {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        lastDeletedBookId = id
    }
}

/// Mock TransactionService for unit testing
@MainActor
class MockTransactionService: TransactionServiceProtocol {
    @Published var transactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    var transactionsToReturn: [Transaction] = []
    var shouldFail = false
    var lastApprovedId: String?
    var lastRejectedId: String?

    func fetchTransactions(role: String? = nil, status: TransactionStatus? = nil, page: Int = 1, limit: Int = 20) async throws -> [Transaction] {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        return transactionsToReturn
    }
    
    func createBorrowRequest(bookId: String, duration: BorrowDuration, durationDays: Int?, message: String?) async throws -> Transaction {
        return Transaction.makeStub(status: .pending)
    }

    func approveRequest(id: String) async throws -> Transaction {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        lastApprovedId = id
        return Transaction.makeStub(status: .approved, id: id)
    }

    func rejectRequest(id: String, reason: String? = nil) async throws -> Transaction {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        lastRejectedId = id
        return Transaction.makeStub(status: .rejected, id: id)
    }
    
    func confirmHandover(id: String, otp: String) async throws -> Transaction { return Transaction.makeStub(status: .active) }
    func confirmReturn(id: String, otp: String) async throws -> Transaction { return Transaction.makeStub(status: .returned) }
}

/// Mock AppDataRefresher for unit testing
@MainActor
class MockAppDataRefresher: AppDataRefresherProtocol {
    var myBooksToReturn: [Book] = []
    var borrowerTransactionsToReturn: [Transaction] = []
    var ownerTransactionsToReturn: [Transaction] = []
    var historyTransactionsToReturn: [Transaction] = []
    var shouldFail = false

    func refreshBooksIfNeeded(groupIds: [String]?, availability: String?, genres: [String]?, sortBy: String?, search: String?, forceRefresh: Bool) async throws -> [Book] {
        return []
    }

    func refreshMyBooksIfNeeded(userId: String, forceRefresh: Bool) async throws -> [Book] {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        return myBooksToReturn
    }

    func refreshBorrowerTransactionsIfNeeded(forceRefresh: Bool) async throws -> [Transaction] {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        return borrowerTransactionsToReturn
    }

    func refreshOwnerTransactionsIfNeeded(forceRefresh: Bool) async throws -> [Transaction] {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        return ownerTransactionsToReturn
    }

    func refreshHistoryTransactionsIfNeeded(forceRefresh: Bool) async throws -> [Transaction] {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock Error"]) }
        return historyTransactionsToReturn
    }
}

/// Mock AuthService for unit testing
@MainActor
class MockAuthService: AuthServiceProtocol {
    @Published var currentUser: User? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var isGoogleLoading: Bool = false
    @Published var error: String? = nil
    
    var shouldFail = false
    var otpSentSuccessfully = false
    var verifyOTPSuccessful = false
    var needsRegistration = false

    func sendOTP(to phoneNumber: String) async throws {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Send OTP Failed"]) }
        otpSentSuccessfully = true
    }

    func verifyOTP(phoneNumber: String, otp: String, name: String? = nil, bio: String? = nil) async throws {
        if shouldFail { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Verify OTP Failed"]) }
        if needsRegistration && name == nil {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name is required"])
        }
        verifyOTPSuccessful = true
    }

    func fetchCurrentUser() async throws {}
    func updateProfile(name: String?, bio: String?, profileImageUrl: String?) async throws {}
    func signInWithGoogle() async throws {}

    func logout() {
        self.isAuthenticated = false
        self.currentUser = nil
    }
}
