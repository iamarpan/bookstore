// Utilities/AppDataStore.swift
// Centralised cache for all API-fetched data with DISK persistence.
// In-memory lookups are O(1) and never block. Disk writes are background-dispatched.
// Disk reads on first-launch are performed asynchronously to avoid main-thread I/O stalls.

import Foundation
import Combine

// MARK: - Persisted Cache Entry

private struct PersistedEntry<T: Codable>: Codable {
    let value: T
    let cachedAt: Date
}

// MARK: - AppDataStore

/// NOT @MainActor — disk I/O helpers run on the calling task's context (background).
/// Published properties are updated explicitly on the main actor where needed.
final class AppDataStore: ObservableObject, @unchecked Sendable {

    // MARK: Singleton
    static let shared = AppDataStore()
    
    private init() {
        // Hydrate from disk on init (fire and forget, updates @Published on main actor)
        Task {
            await loadAllFromDisk()
        }
    }

    // MARK: - Published (Single Source of Truth)
    // ViewModels observe these for reactive UI updates.
    @MainActor @Published var overallBooks: [Book] = []
    @MainActor @Published var myGroups: [BookClub] = []
    @MainActor @Published var myBooks: [Book] = []
    @MainActor @Published var borrowedTransactions: [Transaction] = []
    @MainActor @Published var ownerTransactions: [Transaction] = []
    @MainActor @Published var historyTransactions: [Transaction] = []
    @MainActor @Published var notifications: [BookNotification] = []
    @MainActor @Published var messagesByTransaction: [String: [Message]] = [:]
    @MainActor @Published var groupMembersByGroup: [String: [GroupMember]] = [:]
    @MainActor @Published var groupBooksByGroup: [String: [Book]] = [:]

    // MARK: - TTL
    static let defaultTTL: TimeInterval = 5 * 60   // 5 minutes

    // MARK: - In-memory cache (avoids repeated disk reads)
    private var memoryCache: [String: Any] = [:]
    private let memoryCacheLock = NSLock()

    // MARK: - Caches directory
    private static let cachesURL: URL = {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = url.appendingPathComponent("AppDataStore", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Hydration
    // ──────────────────────────────────────────────────────────────────────────

    /// Loads key data sets from disk asynchronously.
    private func loadAllFromDisk() async {
        async let books = load([Book].self, filename: "books_feed.json", ttl: .infinity)
        async let mGroups = load([BookClub].self, filename: "my_groups.json", ttl: .infinity)
        async let mBooks = load([Book].self, filename: "my_books.json", ttl: .infinity)
        async let bTxns = load([Transaction].self, filename: "txn_borrower.json", ttl: .infinity)
        async let oTxns = load([Transaction].self, filename: "txn_owner.json", ttl: .infinity)
        async let hTxns = load([Transaction].self, filename: "txn_history.json", ttl: .infinity)
        async let notifs = load([BookNotification].self, filename: "notifications.json", ttl: .infinity)

        let resolvedBooks = await books
        let resolvedMyGroups = await mGroups
        let resolvedMyBooks = await mBooks
        let resolvedBorrower = await bTxns
        let resolvedOwner = await oTxns
        let resolvedHistory = await hTxns
        let resolvedNotifs = await notifs

        await MainActor.run {
            self.overallBooks = resolvedBooks ?? []
            self.myGroups = resolvedMyGroups ?? []
            self.myBooks = resolvedMyBooks ?? []
            self.borrowedTransactions = resolvedBorrower ?? []
            self.ownerTransactions = resolvedOwner ?? []
            self.historyTransactions = resolvedHistory ?? []
            self.notifications = resolvedNotifs ?? []
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Generic Async Disk Helpers
    // ──────────────────────────────────────────────────────────────────────────

    func load<T: Codable>(_ type: T.Type, filename: String, ttl: TimeInterval) async -> T? {
        memoryCacheLock.lock()
        if let entry = memoryCache[filename] as? PersistedEntry<T> {
            memoryCacheLock.unlock()
            guard !isStale(entry.cachedAt, ttl: ttl) else { return nil }
            return entry.value
        }
        memoryCacheLock.unlock()

        return await Task.detached(priority: .userInitiated) { [weak self] () -> T? in
            guard let self else { return nil }
            let url = Self.cachesURL.appendingPathComponent(filename)
            guard
                let data  = try? Data(contentsOf: url),
                let entry = try? JSONDecoder().decode(PersistedEntry<T>.self, from: data),
                !self.isStale(entry.cachedAt, ttl: ttl)
            else { return nil }

            self.memoryCacheLock.lock()
            self.memoryCache[filename] = entry
            self.memoryCacheLock.unlock()

            return entry.value
        }.value
    }

    func loadFromMemory<T: Codable>(_ type: T.Type, filename: String, ttl: TimeInterval) -> T? {
        memoryCacheLock.lock()
        defer { memoryCacheLock.unlock() }
        guard let entry = memoryCache[filename] as? PersistedEntry<T>,
              !isStale(entry.cachedAt, ttl: ttl) else { return nil }
        return entry.value
    }

    func persist<T: Codable>(_ value: T, filename: String) {
        let entry = PersistedEntry(value: value, cachedAt: Date())

        memoryCacheLock.lock()
        memoryCache[filename] = entry
        memoryCacheLock.unlock()

        Task.detached(priority: .background) {
            let url = Self.cachesURL.appendingPathComponent(filename)
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    func deleteDisk(filename: String) {
        memoryCacheLock.lock()
        memoryCache.removeValue(forKey: filename)
        memoryCacheLock.unlock()

        Task.detached(priority: .background) {
            let url = Self.cachesURL.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func isStale(_ cachedAt: Date, ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Domain Specific Methods
    // ──────────────────────────────────────────────────────────────────────────

    // MARK: Books Feed
    func cachedBooks(forKey key: String, ttl: TimeInterval = defaultTTL) async -> [Book]? {
        await load([Book].self, filename: "books_\(key.safeFilename).json", ttl: ttl)
    }

    func cachedBooksInMemory(forKey key: String, ttl: TimeInterval = defaultTTL) -> [Book]? {
        loadFromMemory([Book].self, filename: "books_\(key.safeFilename).json", ttl: ttl)
    }

    func storeBooks(_ books: [Book], forKey key: String) {
        persist(books, filename: "books_\(key.safeFilename).json")
        // If it's the main feed (default params), update the published property
        if key.contains("feed|||||") || key.isEmpty {
            Task { @MainActor in self.overallBooks = books }
        }
    }

    func invalidateBooks() { deleteAllDisk(prefix: "books_") }

    // MARK: Book Detail
    func cachedBookDetail(id: String, ttl: TimeInterval = defaultTTL) async -> Book? {
        await load(Book.self, filename: "book_\(id).json", ttl: ttl)
    }

    func storeBookDetail(_ book: Book) {
        persist(book, filename: "book_\(book.id).json")
    }

    func invalidateBookDetail(id: String) { deleteDisk(filename: "book_\(id).json") }

    // MARK: My Groups
    func cachedMyGroups(ttl: TimeInterval = defaultTTL) async -> [BookClub]? {
        await load([BookClub].self, filename: "my_groups.json", ttl: ttl)
    }

    func cachedMyGroupsInMemory(ttl: TimeInterval = defaultTTL) -> [BookClub]? {
        loadFromMemory([BookClub].self, filename: "my_groups.json", ttl: ttl)
    }

    func storeMyGroups(_ groups: [BookClub]) {
        persist(groups, filename: "my_groups.json")
        Task { @MainActor in self.myGroups = groups }
    }

    func invalidateMyGroups() { deleteDisk(filename: "my_groups.json") }

    // MARK: Discovered Groups
    func cachedDiscoveredGroups(forKey key: String, ttl: TimeInterval = defaultTTL) async -> [BookClub]? {
        await load([BookClub].self, filename: "discover_\(key.safeFilename).json", ttl: ttl)
    }

    func storeDiscoveredGroups(_ groups: [BookClub], forKey key: String) {
        persist(groups, filename: "discover_\(key.safeFilename).json")
    }

    func invalidateDiscoveredGroups() { deleteAllDisk(prefix: "discover_") }

    // MARK: Group Detail
    func cachedGroupDetail(id: String, ttl: TimeInterval = defaultTTL) async -> BookClub? {
        await load(BookClub.self, filename: "group_\(id).json", ttl: ttl)
    }

    func storeGroupDetail(_ group: BookClub) {
        persist(group, filename: "group_\(group.id).json")
    }

    func invalidateGroupDetail(id: String) { deleteDisk(filename: "group_\(id).json") }

    // MARK: Group Members
    func cachedGroupMembers(groupId: String, ttl: TimeInterval = defaultTTL) async -> [GroupMember]? {
        let members = await load([GroupMember].self, filename: "members_\(groupId).json", ttl: ttl)
        if let members = members {
            Task { @MainActor in self.groupMembersByGroup[groupId] = members }
        }
        return members
    }

    func storeGroupMembers(_ members: [GroupMember], groupId: String) {
        persist(members, filename: "members_\(groupId).json")
        Task { @MainActor in self.groupMembersByGroup[groupId] = members }
    }

    func invalidateGroupMembers(groupId: String) { deleteDisk(filename: "members_\(groupId).json") }

    // MARK: Group Books
    func cachedGroupBooks(groupId: String, ttl: TimeInterval = defaultTTL) async -> [Book]? {
        let books = await load([Book].self, filename: "group_books_\(groupId).json", ttl: ttl)
        if let books = books {
            Task { @MainActor in self.groupBooksByGroup[groupId] = books }
        }
        return books
    }

    func storeGroupBooks(_ books: [Book], groupId: String) {
        persist(books, filename: "group_books_\(groupId).json")
        Task { @MainActor in self.groupBooksByGroup[groupId] = books }
    }

    func invalidateGroupBooks(groupId: String) { deleteDisk(filename: "group_books_\(groupId).json") }

    // MARK: My Owned Books
    func cachedMyBooks(ttl: TimeInterval = defaultTTL) async -> [Book]? {
        await load([Book].self, filename: "my_books.json", ttl: ttl)
    }

    func cachedMyBooksInMemory(ttl: TimeInterval = defaultTTL) -> [Book]? {
        loadFromMemory([Book].self, filename: "my_books.json", ttl: ttl)
    }

    func storeMyBooks(_ books: [Book]) {
        persist(books, filename: "my_books.json")
        Task { @MainActor in self.myBooks = books }
    }

    func invalidateMyBooks() { deleteDisk(filename: "my_books.json") }

    // MARK: Transactions — Borrower
    func cachedBorrowerTransactions(ttl: TimeInterval = defaultTTL) async -> [Transaction]? {
        await load([Transaction].self, filename: "txn_borrower.json", ttl: ttl)
    }

    func storeBorrowerTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_borrower.json")
        Task { @MainActor in self.borrowedTransactions = txns }
    }

    func invalidateBorrowerTransactions() { deleteDisk(filename: "txn_borrower.json") }

    // MARK: Transactions — Owner
    func cachedOwnerTransactions(ttl: TimeInterval = defaultTTL) async -> [Transaction]? {
        await load([Transaction].self, filename: "txn_owner.json", ttl: ttl)
    }

    func storeOwnerTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_owner.json")
        Task { @MainActor in self.ownerTransactions = txns }
    }

    func invalidateOwnerTransactions() { deleteDisk(filename: "txn_owner.json") }

    // MARK: Transactions — History
    func cachedHistoryTransactions(ttl: TimeInterval = defaultTTL) async -> [Transaction]? {
        await load([Transaction].self, filename: "txn_history.json", ttl: ttl)
    }

    func storeHistoryTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_history.json")
        Task { @MainActor in self.historyTransactions = txns }
    }

    func invalidateHistoryTransactions() { deleteDisk(filename: "txn_history.json") }

    // MARK: Chat Messages
    func cachedMessages(transactionId: String, ttl: TimeInterval = defaultTTL) async -> [Message]? {
        let messages = await load([Message].self, filename: "chat_\(transactionId).json", ttl: ttl)
        if let messages = messages {
            Task { @MainActor in self.messagesByTransaction[transactionId] = messages }
        }
        return messages
    }

    func storeMessages(_ messages: [Message], transactionId: String) {
        persist(messages, filename: "chat_\(transactionId).json")
        Task { @MainActor in self.messagesByTransaction[transactionId] = messages }
    }

    func invalidateMessages(transactionId: String) {
        deleteDisk(filename: "chat_\(transactionId).json")
    }

    // MARK: Notifications
    func cachedNotifications(ttl: TimeInterval = defaultTTL) async -> [BookNotification]? {
        await load([BookNotification].self, filename: "notifications.json", ttl: ttl)
    }

    func storeNotifications(_ notifications: [BookNotification]) {
        persist(notifications, filename: "notifications.json")
        Task { @MainActor in self.notifications = notifications }
    }

    func invalidateNotifications() { deleteDisk(filename: "notifications.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Global Invalidation
    // ──────────────────────────────────────────────────────────────────────────

    func invalidateAll() {
        memoryCacheLock.lock()
        memoryCache.removeAll()
        memoryCacheLock.unlock()
        
        Task { @MainActor in
            self.overallBooks = []
            self.myGroups = []
            self.myBooks = []
            self.borrowedTransactions = []
            self.ownerTransactions = []
            self.historyTransactions = []
            self.notifications = []
            self.messagesByTransaction = [:]
            self.groupMembersByGroup = [:]
            self.groupBooksByGroup = [:]
        }
        
        deleteAllDisk()
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Cache Key Helpers
    // ──────────────────────────────────────────────────────────────────────────

    static func booksFeedKey(
        groupIds: [String]?,
        availability: String?,
        genres: [String]?,
        sortBy: String?,
        search: String?
    ) -> String {
        let gids  = (groupIds  ?? []).sorted().joined(separator: ",")
        let avail = availability ?? ""
        let genre = (genres    ?? []).sorted().joined(separator: ",")
        let sort  = sortBy ?? ""
        let srch  = search ?? ""
        return "feed|\(gids)|\(avail)|\(genre)|\(sort)|\(srch)"
    }

    static func discoverGroupsKey(category: String?, search: String?) -> String {
        "discover|\(category ?? "")|\(search ?? "")"
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Private Helpers
    // ──────────────────────────────────────────────────────────────────────────

    private func deleteAllDisk(prefix: String = "") {
        memoryCacheLock.lock()
        if prefix.isEmpty {
            memoryCache.removeAll()
        } else {
            for key in memoryCache.keys where key.hasPrefix(prefix) {
                memoryCache.removeValue(forKey: key)
            }
        }
        memoryCacheLock.unlock()

        Task.detached(priority: .background) {
            let items = (try? FileManager.default.contentsOfDirectory(
                at: Self.cachesURL,
                includingPropertiesForKeys: nil
            )) ?? []
            for url in items where prefix.isEmpty || url.lastPathComponent.hasPrefix(prefix) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

// MARK: - String helper for safe filenames
private extension String {
    var safeFilename: String {
        self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "_")
    }
}
