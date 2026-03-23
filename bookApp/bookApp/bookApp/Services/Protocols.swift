// Services/Protocols.swift
import Foundation
import Combine

/// Protocol defining authentication operations
@MainActor
protocol AuthServiceProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var currentUser: User? { get set }
    var isAuthenticated: Bool { get set }
    var isLoading: Bool { get set }
    var isGoogleLoading: Bool { get set }
    var error: String? { get set }
    
    func sendOTP(to phoneNumber: String) async throws
    func verifyOTP(phoneNumber: String, otp: String, name: String?, bio: String?) async throws
    func fetchCurrentUser() async throws
    func updateProfile(name: String?, bio: String?, profileImageUrl: String?) async throws
    func signInWithGoogle() async throws
    func logout()
}

/// Protocol defining book operations
protocol BookServiceProtocol {
    func fetchBooks(groupIds: [String]?, availability: String?, genres: [String]?, minPrice: Double?, maxPrice: Double?, sortBy: String?, search: String?, page: Int, limit: Int) async throws -> [Book]
    func fetchBook(id: String) async throws -> Book
    func fetchMyBooks() async throws -> [Book]
    func createBook(_ book: Book) async throws -> Book
    func updateBook(_ book: Book) async throws -> Book
    func deleteBook(id: String) async throws
}

/// Protocol defining transaction operations
@MainActor
protocol TransactionServiceProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var transactions: [Transaction] { get set }
    var isLoading: Bool { get set }
    var error: String? { get set }
    
    func fetchTransactions(role: String?, status: TransactionStatus?, page: Int, limit: Int) async throws -> [Transaction]
    func createBorrowRequest(bookId: String, duration: BorrowDuration, durationDays: Int?, message: String?) async throws -> Transaction
    func approveRequest(id: String) async throws -> Transaction
    func rejectRequest(id: String, reason: String?) async throws -> Transaction
    func confirmHandover(id: String, otp: String) async throws -> Transaction
    func confirmReturn(id: String, otp: String) async throws -> Transaction
    func markPaymentComplete(id: String, role: String) async throws -> Transaction
    func cancelTransaction(id: String) async throws -> Transaction
    func rateTransaction(id: String, rating: Int, comment: String?, bookConditionRating: Int?) async throws
}

/// Extension to provide default values for TransactionServiceProtocol methods
extension TransactionServiceProtocol {
    func fetchTransactions(
        role: String? = nil,
        status: TransactionStatus? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> [Transaction] {
        try await fetchTransactions(role: role, status: status, page: page, limit: limit)
    }
    
    func createBorrowRequest(
        bookId: String,
        duration: BorrowDuration,
        durationDays: Int? = nil,
        message: String? = nil
    ) async throws -> Transaction {
        try await createBorrowRequest(bookId: bookId, duration: duration, durationDays: durationDays, message: message)
    }
    
    func rejectRequest(id: String, reason: String? = nil) async throws -> Transaction {
        try await rejectRequest(id: id, reason: reason)
    }
}

/// Protocol defining application data refresh operations
@MainActor
protocol AppDataRefresherProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    func refreshBooksIfNeeded(groupIds: [String]?, availability: String?, genres: [String]?, sortBy: String?, search: String?, forceRefresh: Bool) async throws -> [Book]
    func refreshBookDetailIfNeeded(id: String, forceRefresh: Bool) async throws -> Book
    func refreshMyGroupsIfNeeded(forceRefresh: Bool) async throws -> [BookClub]
    func refreshDiscoveredGroupsIfNeeded(category: String?, search: String?, forceRefresh: Bool) async throws -> [BookClub]
    func refreshGroupDetailIfNeeded(id: String, forceRefresh: Bool) async throws -> BookClub
    func refreshMyBooksIfNeeded(userId: String, forceRefresh: Bool) async throws -> [Book]
    func refreshBorrowerTransactionsIfNeeded(forceRefresh: Bool) async throws -> [Transaction]
    func refreshOwnerTransactionsIfNeeded(forceRefresh: Bool) async throws -> [Transaction]
    func refreshHistoryTransactionsIfNeeded(forceRefresh: Bool) async throws -> [Transaction]
    func refreshNotificationsIfNeeded(forceRefresh: Bool) async throws -> [BookNotification]
    func refreshMessagesIfNeeded(transactionId: String, forceRefresh: Bool) async throws -> [Message]
    func refreshGroupMembersIfNeeded(groupId: String, forceRefresh: Bool) async throws -> [GroupMember]
    func refreshGroupBooksIfNeeded(groupId: String, forceRefresh: Bool) async throws -> [Book]
}
