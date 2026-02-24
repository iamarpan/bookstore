// Utilities/AppDataRefresher.swift
// Orchestrates background refreshes by coordinating the services and writing
// results into AppDataStore. ViewModels inject this to trigger cache-miss fetches.

import Foundation

@MainActor
final class AppDataRefresher: ObservableObject {

    // MARK: - Singleton (optional – can also be injected via environment)
    static let shared = AppDataRefresher()

    // MARK: - Services
    private let bookService    = BookService()
    private let groupService   = GroupService()
    private let transactionService = TransactionService()

    // MARK: - Store
    private let store = AppDataStore.shared

    // MARK: - In-flight deduplication
    // Prevent simultaneous identical requests from landing twice
    private var inFlightBooksFeed: Task<[Book], Error>?  = nil
    private var inFlightMyGroups:  Task<[BookClub], Error>? = nil

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Books Feed
    // ──────────────────────────────────────────────────────────────────────────

    /// Returns cached books immediately (if fresh) or fetches from the API.
    /// Pass `forceRefresh: true` (e.g. pull-to-refresh) to bypass the TTL.
    func refreshBooksIfNeeded(
        groupIds: [String]? = nil,
        availability: String? = nil,
        genres: [String]? = nil,
        sortBy: String? = "RECENT",
        search: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [Book] {
        let key = AppDataStore.booksFeedKey(
            groupIds: groupIds,
            availability: availability,
            genres: genres,
            sortBy: sortBy,
            search: search
        )

        // Fast path — fresh cache
        if !forceRefresh, let cached = store.cachedBooks(forKey: key) {
            return cached
        }

        // Fetch from API
        let books = try await bookService.fetchBooks(
            groupIds: groupIds,
            availability: availability,
            genres: genres,
            sortBy: sortBy,
            search: search
        )

        store.storeBooks(books, forKey: key)

        // Also warm individual book-detail cache entries
        for book in books {
            store.storeBookDetail(book)
        }

        return books
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Book Detail
    // ──────────────────────────────────────────────────────────────────────────

    /// Returns the book detail from cache if fresh, otherwise fetches from API.
    func refreshBookDetailIfNeeded(id: String, forceRefresh: Bool = false) async throws -> Book {
        if !forceRefresh, let cached = store.cachedBookDetail(id: id) {
            return cached
        }

        let book = try await bookService.fetchBook(id: id)
        store.storeBookDetail(book)
        return book
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Groups
    // ──────────────────────────────────────────────────────────────────────────

    func refreshMyGroupsIfNeeded(forceRefresh: Bool = false) async throws -> [BookClub] {
        if !forceRefresh, let cached = store.cachedMyGroups() {
            return cached
        }

        let groups = try await groupService.fetchMyGroups()
        store.storeMyGroups(groups)
        return groups
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Discover Groups
    // ──────────────────────────────────────────────────────────────────────────

    func refreshDiscoveredGroupsIfNeeded(
        category: String? = nil,
        search: String? = nil,
        forceRefresh: Bool = false
    ) async throws -> [BookClub] {
        let key = AppDataStore.discoverGroupsKey(category: category, search: search)

        if !forceRefresh, let cached = store.cachedDiscoveredGroups(forKey: key) {
            return cached
        }

        let groups = try await groupService.discoverGroups(
            category: category.flatMap { GroupCategory(rawValue: $0) },
            search: search
        )
        store.storeDiscoveredGroups(groups, forKey: key)
        return groups
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Detail
    // ──────────────────────────────────────────────────────────────────────────

    func refreshGroupDetailIfNeeded(id: String, forceRefresh: Bool = false) async throws -> BookClub {
        if !forceRefresh, let cached = store.cachedGroupDetail(id: id) {
            return cached
        }

        let group = try await groupService.fetchGroupDetails(id: id)
        store.storeGroupDetail(group)
        return group
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Members
    // ──────────────────────────────────────────────────────────────────────────

    func refreshGroupMembersIfNeeded(groupId: String, forceRefresh: Bool = false) async throws -> [GroupMember] {
        if !forceRefresh, let cached = store.cachedGroupMembers(groupId: groupId) {
            return cached
        }

        let members = try await groupService.fetchGroupMembers(groupId: groupId)
        store.storeGroupMembers(members, groupId: groupId)
        return members
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Books
    // ──────────────────────────────────────────────────────────────────────────

    func refreshGroupBooksIfNeeded(groupId: String, forceRefresh: Bool = false) async throws -> [Book] {
        if !forceRefresh, let cached = store.cachedGroupBooks(groupId: groupId) {
            return cached
        }

        let (books, _) = try await groupService.fetchGroupBooks(groupId: groupId)
        store.storeGroupBooks(books, groupId: groupId)
        return books
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Library
    // ──────────────────────────────────────────────────────────────────────────

    /// Refresh owned books.
    func refreshMyBooksIfNeeded(userId: String, forceRefresh: Bool = false) async throws -> [Book] {
        if !forceRefresh, let cached = store.cachedMyBooks() {
            return cached
        }

        let allBooks = try await bookService.fetchBooks()
        let myBooks = allBooks.filter { $0.ownerId == userId }
        store.storeMyBooks(myBooks)
        return myBooks
    }

    /// Refresh borrower-role transactions (active borrows).
    func refreshBorrowerTransactionsIfNeeded(forceRefresh: Bool = false) async throws -> [Transaction] {
        if !forceRefresh, let cached = store.cachedBorrowerTransactions() {
            return cached
        }

        let txns = try await transactionService.fetchTransactions(role: "BORROWER", status: .active)
        store.storeBorrowerTransactions(txns)
        return txns
    }

    /// Refresh owner-role transactions (lent books).
    func refreshOwnerTransactionsIfNeeded(forceRefresh: Bool = false) async throws -> [Transaction] {
        if !forceRefresh, let cached = store.cachedOwnerTransactions() {
            return cached
        }

        let txns = try await transactionService.fetchTransactions(role: "OWNER")
        store.storeOwnerTransactions(txns)
        return txns
    }

    /// Refresh history (returned transactions).
    func refreshHistoryTransactionsIfNeeded(forceRefresh: Bool = false) async throws -> [Transaction] {
        if !forceRefresh, let cached = store.cachedHistoryTransactions() {
            return cached
        }

        let txns = try await transactionService.fetchTransactions(status: .returned)
        store.storeHistoryTransactions(txns)
        return txns
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Full Library Refresh
    // ──────────────────────────────────────────────────────────────────────────

    /// Convenience: refresh all library-related data concurrently.
    func refreshLibraryIfNeeded(userId: String, forceRefresh: Bool = false) async {
        async let myBooks = refreshMyBooksIfNeeded(userId: userId, forceRefresh: forceRefresh)
        async let borrower = refreshBorrowerTransactionsIfNeeded(forceRefresh: forceRefresh)
        async let owner = refreshOwnerTransactionsIfNeeded(forceRefresh: forceRefresh)
        async let history = refreshHistoryTransactionsIfNeeded(forceRefresh: forceRefresh)

        _ = try? await (myBooks, borrower, owner, history)
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Global Invalidation
    // ──────────────────────────────────────────────────────────────────────────

    /// Call on logout to wipe all cached data.
    func invalidateAll() {
        store.invalidateAll()
    }
}
