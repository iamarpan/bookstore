// Utilities/AppDataStore.swift
// Centralised cache for all API-fetched data with DISK persistence.
// In-memory lookups are O(1) and never block. Disk writes are background-dispatched.
// Disk reads on first-launch are performed asynchronously to avoid main-thread I/O stalls.

import Foundation

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
    private init() {}

    // MARK: - TTL
    static let defaultTTL: TimeInterval = 5 * 60   // 5 minutes

    // MARK: - In-memory cache (avoids repeated disk reads)
    // The memory cache holds the decoded Swift values keyed by filename.
    // It's accessed only from background Tasks that hold the actor hop,
    // so we protect it with a simple lock.
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
    // MARK: - Generic Async Disk Helpers
    // ──────────────────────────────────────────────────────────────────────────

    /// Async disk read — runs on the calling context (should be a background Task).
    /// Returns nil if missing, corrupt, or stale. Populates in-memory cache on success.
    func load<T: Codable>(_ type: T.Type, filename: String, ttl: TimeInterval) async -> T? {
        // 1. Check memory cache first (no I/O)
        memoryCacheLock.lock()
        if let entry = memoryCache[filename] as? PersistedEntry<T> {
            memoryCacheLock.unlock()
            guard !isStale(entry.cachedAt, ttl: ttl) else { return nil }
            return entry.value
        }
        memoryCacheLock.unlock()

        // 2. Background disk read
        return await Task.detached(priority: .userInitiated) { [weak self] () -> T? in
            guard let self else { return nil }
            let url = Self.cachesURL.appendingPathComponent(filename)
            guard
                let data  = try? Data(contentsOf: url),
                let entry = try? JSONDecoder().decode(PersistedEntry<T>.self, from: data),
                !self.isStale(entry.cachedAt, ttl: ttl)
            else { return nil }

            // Warm in-memory cache
            self.memoryCacheLock.lock()
            self.memoryCache[filename] = entry
            self.memoryCacheLock.unlock()

            return entry.value
        }.value
    }

    /// Synchronous memory-only read (no disk I/O). Use only when you know the cache
    /// has already been warmed (e.g., after a previous `load` or `persist`).
    func loadFromMemory<T: Codable>(_ type: T.Type, filename: String, ttl: TimeInterval) -> T? {
        memoryCacheLock.lock()
        defer { memoryCacheLock.unlock() }
        guard let entry = memoryCache[filename] as? PersistedEntry<T>,
              !isStale(entry.cachedAt, ttl: ttl) else { return nil }
        return entry.value
    }

    /// Write an encodable value + timestamp to disk (background) and memory (immediate).
    func persist<T: Codable>(_ value: T, filename: String) {
        let entry = PersistedEntry(value: value, cachedAt: Date())

        // Update memory cache immediately so subsequent reads hit memory
        memoryCacheLock.lock()
        memoryCache[filename] = entry
        memoryCacheLock.unlock()

        // Write to disk in the background
        Task.detached(priority: .background) {
            let url = Self.cachesURL.appendingPathComponent(filename)
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    /// Delete a single cache file from memory + disk.
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
    // MARK: - Books Feed
    // ──────────────────────────────────────────────────────────────────────────

    func cachedBooks(forKey key: String, ttl: TimeInterval = defaultTTL) async -> [Book]? {
        await load([Book].self, filename: "books_\(key.safeFilename).json", ttl: ttl)
    }

    /// Memory-only read for instant display (no async needed).
    func cachedBooksInMemory(forKey key: String, ttl: TimeInterval = defaultTTL) -> [Book]? {
        loadFromMemory([Book].self, filename: "books_\(key.safeFilename).json", ttl: ttl)
    }

    func storeBooks(_ books: [Book], forKey key: String) {
        persist(books, filename: "books_\(key.safeFilename).json")
    }

    func invalidateBooks() { deleteAllDisk(prefix: "books_") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Book Detail
    // ──────────────────────────────────────────────────────────────────────────

    func cachedBookDetail(id: String, ttl: TimeInterval = defaultTTL) async -> Book? {
        await load(Book.self, filename: "book_\(id).json", ttl: ttl)
    }

    func storeBookDetail(_ book: Book) {
        persist(book, filename: "book_\(book.id).json")
    }

    func invalidateBookDetail(id: String) { deleteDisk(filename: "book_\(id).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Groups
    // ──────────────────────────────────────────────────────────────────────────

    func cachedMyGroups(ttl: TimeInterval = defaultTTL) async -> [BookClub]? {
        await load([BookClub].self, filename: "my_groups.json", ttl: ttl)
    }

    func cachedMyGroupsInMemory(ttl: TimeInterval = defaultTTL) -> [BookClub]? {
        loadFromMemory([BookClub].self, filename: "my_groups.json", ttl: ttl)
    }

    func storeMyGroups(_ groups: [BookClub]) {
        persist(groups, filename: "my_groups.json")
    }

    func invalidateMyGroups() { deleteDisk(filename: "my_groups.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Discovered Groups
    // ──────────────────────────────────────────────────────────────────────────

    func cachedDiscoveredGroups(forKey key: String, ttl: TimeInterval = defaultTTL) async -> [BookClub]? {
        await load([BookClub].self, filename: "discover_\(key.safeFilename).json", ttl: ttl)
    }

    func storeDiscoveredGroups(_ groups: [BookClub], forKey key: String) {
        persist(groups, filename: "discover_\(key.safeFilename).json")
    }

    func invalidateDiscoveredGroups() { deleteAllDisk(prefix: "discover_") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Detail
    // ──────────────────────────────────────────────────────────────────────────

    func cachedGroupDetail(id: String, ttl: TimeInterval = defaultTTL) async -> BookClub? {
        await load(BookClub.self, filename: "group_\(id).json", ttl: ttl)
    }

    func storeGroupDetail(_ group: BookClub) {
        persist(group, filename: "group_\(group.id).json")
    }

    func invalidateGroupDetail(id: String) { deleteDisk(filename: "group_\(id).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Members
    // ──────────────────────────────────────────────────────────────────────────

    func cachedGroupMembers(groupId: String, ttl: TimeInterval = defaultTTL) async -> [GroupMember]? {
        await load([GroupMember].self, filename: "members_\(groupId).json", ttl: ttl)
    }

    func storeGroupMembers(_ members: [GroupMember], groupId: String) {
        persist(members, filename: "members_\(groupId).json")
    }

    func invalidateGroupMembers(groupId: String) { deleteDisk(filename: "members_\(groupId).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Books
    // ──────────────────────────────────────────────────────────────────────────

    func cachedGroupBooks(groupId: String, ttl: TimeInterval = defaultTTL) async -> [Book]? {
        await load([Book].self, filename: "group_books_\(groupId).json", ttl: ttl)
    }

    func storeGroupBooks(_ books: [Book], groupId: String) {
        persist(books, filename: "group_books_\(groupId).json")
    }

    func invalidateGroupBooks(groupId: String) { deleteDisk(filename: "group_books_\(groupId).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Owned Books
    // ──────────────────────────────────────────────────────────────────────────

    func cachedMyBooks(ttl: TimeInterval = defaultTTL) async -> [Book]? {
        await load([Book].self, filename: "my_books.json", ttl: ttl)
    }

    func cachedMyBooksInMemory(ttl: TimeInterval = defaultTTL) -> [Book]? {
        loadFromMemory([Book].self, filename: "my_books.json", ttl: ttl)
    }

    func storeMyBooks(_ books: [Book]) { persist(books, filename: "my_books.json") }

    func invalidateMyBooks() { deleteDisk(filename: "my_books.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions — Borrower
    // ──────────────────────────────────────────────────────────────────────────

    func cachedBorrowerTransactions(ttl: TimeInterval = defaultTTL) async -> [Transaction]? {
        await load([Transaction].self, filename: "txn_borrower.json", ttl: ttl)
    }

    func storeBorrowerTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_borrower.json")
    }

    func invalidateBorrowerTransactions() { deleteDisk(filename: "txn_borrower.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions — Owner
    // ──────────────────────────────────────────────────────────────────────────

    func cachedOwnerTransactions(ttl: TimeInterval = defaultTTL) async -> [Transaction]? {
        await load([Transaction].self, filename: "txn_owner.json", ttl: ttl)
    }

    func storeOwnerTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_owner.json")
    }

    func invalidateOwnerTransactions() { deleteDisk(filename: "txn_owner.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions — History
    // ──────────────────────────────────────────────────────────────────────────

    func cachedHistoryTransactions(ttl: TimeInterval = defaultTTL) async -> [Transaction]? {
        await load([Transaction].self, filename: "txn_history.json", ttl: ttl)
    }

    func storeHistoryTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_history.json")
    }

    func invalidateHistoryTransactions() { deleteDisk(filename: "txn_history.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Global Invalidation
    // ──────────────────────────────────────────────────────────────────────────

    func invalidateAll() {
        memoryCacheLock.lock()
        memoryCache.removeAll()
        memoryCacheLock.unlock()
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

    /// Delete all files in cachesURL whose name begins with `prefix`.
    private func deleteAllDisk(prefix: String = "") {
        // Clear matching memory cache entries first
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
