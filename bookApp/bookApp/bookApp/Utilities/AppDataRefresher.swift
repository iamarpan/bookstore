// Utilities/AppDataRefresher.swift
// Orchestrates background refreshes by coordinating the services and writing
// results into AppDataStore. ViewModels inject this to trigger cache-miss fetches.

import Foundation

/// Orchestrates background refreshes by coordinating the services and writing
/// results into AppDataStore. ViewModels inject this to trigger cache-miss fetches.
@MainActor
class AppDataRefresher: AppDataRefresherProtocol, ObservableObject {

    // MARK: - Singleton
    static let shared = AppDataRefresher()

    // MARK: - Services
    private let bookService    = BookService()
    private let groupService   = GroupService()
    private let transactionService = TransactionService()

    // MARK: - Store
    let store = AppDataStore.shared

    // MARK: - In-flight deduplication
    private var inFlightBooksFeed: Task<[Book], Error>?
    private var inFlightMyGroups:  Task<[BookClub], Error>?
    private var inFlightMyBooks:   Task<[Book], Error>?

    private init() {}

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Books Feed
    // ──────────────────────────────────────────────────────────────────────────

    /// Returns cached books (async disk read) or fetches from the API.
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

        // Fast path — memory cache (no I/O)
        if !forceRefresh, let cached = store.cachedBooksInMemory(forKey: key) {
            return cached
        }

        // Medium path — async disk read (if not forcing)
        if !forceRefresh, let cached = await store.cachedBooks(forKey: key) {
            return cached
        }

        // Deduplication: reuse an in-flight request for identical parameters
        if let existing = inFlightBooksFeed {
            return try await existing.value
        }

        // Fetch from API
        let task = Task<[Book], Error> {
            let books = try await self.bookService.fetchBooks(
                groupIds: groupIds,
                availability: availability,
                genres: genres,
                sortBy: sortBy,
                search: search
            )
            self.store.storeBooks(books, forKey: key)
            // Warm individual book-detail cache entries
            for book in books { self.store.storeBookDetail(book) }
            return books
        }
        inFlightBooksFeed = task
        defer { inFlightBooksFeed = nil }
        return try await task.value
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Book Detail
    // ──────────────────────────────────────────────────────────────────────────

    func refreshBookDetailIfNeeded(id: String, forceRefresh: Bool = false) async throws -> Book {
        if !forceRefresh, let cached = await store.cachedBookDetail(id: id) { return cached }

        let book = try await bookService.fetchBook(id: id)
        store.storeBookDetail(book)
        return book
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Groups
    // ──────────────────────────────────────────────────────────────────────────

    func refreshMyGroupsIfNeeded(forceRefresh: Bool = false) async throws -> [BookClub] {
        // Fast path — memory
        if !forceRefresh, let cached = store.cachedMyGroupsInMemory() { return cached }

        if !forceRefresh, let cached = await store.cachedMyGroups() { return cached }

        if let existing = inFlightMyGroups {
            return try await existing.value
        }

        let task = Task<[BookClub], Error> {
            let groups = try await self.groupService.fetchMyGroups()
            self.store.storeMyGroups(groups)
            return groups
        }
        inFlightMyGroups = task
        defer { inFlightMyGroups = nil }
        return try await task.value
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

        if !forceRefresh, let cached = await store.cachedDiscoveredGroups(forKey: key) { return cached }

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
        if !forceRefresh, let cached = await store.cachedGroupDetail(id: id) { return cached }

        let group = try await groupService.fetchGroupDetails(id: id)
        store.storeGroupDetail(group)
        return group
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Members
    // ──────────────────────────────────────────────────────────────────────────

    func refreshGroupMembersIfNeeded(groupId: String, forceRefresh: Bool = false) async throws -> [GroupMember] {
        if !forceRefresh, let cached = await store.cachedGroupMembers(groupId: groupId) { return cached }

        let members = try await groupService.fetchGroupMembers(groupId: groupId)
        store.storeGroupMembers(members, groupId: groupId)
        return members
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Books
    // ──────────────────────────────────────────────────────────────────────────

    func refreshGroupBooksIfNeeded(groupId: String, forceRefresh: Bool = false) async throws -> [Book] {
        if !forceRefresh, let cached = await store.cachedGroupBooks(groupId: groupId) { return cached }

        let (books, _) = try await groupService.fetchGroupBooks(groupId: groupId)
        store.storeGroupBooks(books, groupId: groupId)
        return books
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Library
    // ──────────────────────────────────────────────────────────────────────────

    /// Refresh owned books — uses dedicated /users/me/books endpoint (not fetch-all-then-filter).
    func refreshMyBooksIfNeeded(userId: String, forceRefresh: Bool = false) async throws -> [Book] {
        // Fast path — memory
        if !forceRefresh, let cached = store.cachedMyBooksInMemory() { return cached }

        if !forceRefresh, let cached = await store.cachedMyBooks() { return cached }

        if let existing = inFlightMyBooks {
            return try await existing.value
        }

        let task = Task<[Book], Error> {
            // Use /users/me/books directly — avoids fetching the full catalog
            let myBooks = try await self.bookService.fetchMyBooks()
            self.store.storeMyBooks(myBooks)
            return myBooks
        }
        inFlightMyBooks = task
        defer { inFlightMyBooks = nil }
        return try await task.value
    }

    /// Refresh borrower-role transactions.
    func refreshBorrowerTransactionsIfNeeded(forceRefresh: Bool = false) async throws -> [Transaction] {
        if !forceRefresh, let cached = await store.cachedBorrowerTransactions() { return cached }

        let txns = try await transactionService.fetchTransactions(role: "BORROWER")
        store.storeBorrowerTransactions(txns)
        return txns
    }

    /// Refresh owner-role transactions.
    func refreshOwnerTransactionsIfNeeded(forceRefresh: Bool = false) async throws -> [Transaction] {
        if !forceRefresh, let cached = await store.cachedOwnerTransactions() { return cached }

        let txns = try await transactionService.fetchTransactions(role: "OWNER")
        store.storeOwnerTransactions(txns)
        return txns
    }

    /// Refresh history (returned transactions).
    func refreshHistoryTransactionsIfNeeded(forceRefresh: Bool = false) async throws -> [Transaction] {
        if !forceRefresh, let cached = await store.cachedHistoryTransactions() { return cached }

        let txns = try await transactionService.fetchTransactions(status: .returned)
        store.storeHistoryTransactions(txns)
        return txns
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Notifications
    // ──────────────────────────────────────────────────────────────────────────

    func refreshNotificationsIfNeeded(forceRefresh: Bool = false) async throws -> [BookNotification] {
        if !forceRefresh, let cached = await store.cachedNotifications() { return cached }

        let notifications = try await NotificationService.shared.fetchNotifications()
        store.storeNotifications(notifications)
        return notifications
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Messages
    // ──────────────────────────────────────────────────────────────────────────

    func refreshMessagesIfNeeded(transactionId: String, forceRefresh: Bool = false) async throws -> [Message] {
        if !forceRefresh, let cached = await store.cachedMessages(transactionId: transactionId) { return cached }

        let messages = try await MessageService.shared.fetchMessages(transactionId: transactionId)
        store.storeMessages(messages, transactionId: transactionId)
        return messages
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Full Library Refresh
    // ──────────────────────────────────────────────────────────────────────────

    /// Convenience: refresh all library-related data concurrently.
    func refreshLibraryIfNeeded(userId: String, forceRefresh: Bool = false) async {
        async let myBooks  = refreshMyBooksIfNeeded(userId: userId, forceRefresh: forceRefresh)
        async let borrower = refreshBorrowerTransactionsIfNeeded(forceRefresh: forceRefresh)
        async let owner    = refreshOwnerTransactionsIfNeeded(forceRefresh: forceRefresh)
        async let history  = refreshHistoryTransactionsIfNeeded(forceRefresh: forceRefresh)
        async let notifs   = refreshNotificationsIfNeeded(forceRefresh: forceRefresh)

        _ = try? await (myBooks, borrower, owner, history, notifs)
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Global Invalidation
    // ──────────────────────────────────────────────────────────────────────────

    /// Call on logout to wipe all cached data.
    func invalidateAll() {
        store.invalidateAll()
    }
}
