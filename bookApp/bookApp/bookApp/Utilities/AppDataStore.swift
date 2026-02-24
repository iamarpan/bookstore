// Utilities/AppDataStore.swift
// Centralised cache for all API-fetched data with DISK persistence.
// Each bucket is stored as a JSON file in the app's Caches directory so
// the data survives app restarts.  In-memory lookups are fast; disk I/O
// happens in the background on every write and synchronously on first read.

import Foundation

// MARK: - Persisted Cache Entry

private struct PersistedEntry<T: Codable>: Codable {
    let value: T
    let cachedAt: Date
}

// MARK: - AppDataStore

@MainActor
final class AppDataStore: ObservableObject {

    // MARK: Singleton
    static let shared = AppDataStore()
    private init() {}

    // MARK: - TTL
    static let defaultTTL: TimeInterval = 5 * 60   // 5 minutes

    // MARK: - Caches directory
    private static let cachesURL: URL = {
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = url.appendingPathComponent("AppDataStore", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Generic Disk Helpers
    // ──────────────────────────────────────────────────────────────────────────

    /// Write an encodable value + timestamp to disk under `filename`.
    private func persist<T: Codable>(_ value: T, filename: String) {
        let entry = PersistedEntry(value: value, cachedAt: Date())
        Task.detached(priority: .background) {
            let url = Self.cachesURL.appendingPathComponent(filename)
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    /// Load a previously persisted entry from disk; returns nil if missing, corrupt, or stale.
    private func load<T: Codable>(_ type: T.Type, filename: String, ttl: TimeInterval) -> T? {
        let url = Self.cachesURL.appendingPathComponent(filename)
        guard
            let data  = try? Data(contentsOf: url),
            let entry = try? JSONDecoder().decode(PersistedEntry<T>.self, from: data),
            !isStale(entry.cachedAt, ttl: ttl)
        else { return nil }
        return entry.value
    }

    /// Delete a single cache file.
    private func deleteDisk(filename: String) {
        Task.detached(priority: .background) {
            let url = Self.cachesURL.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Delete all files in the AppDataStore cache directory.
    private func deleteAllDisk() {
        Task.detached(priority: .background) {
            let items = (try? FileManager.default.contentsOfDirectory(
                at: Self.cachesURL,
                includingPropertiesForKeys: nil
            )) ?? []
            for url in items { try? FileManager.default.removeItem(at: url) }
        }
    }

    private func isStale(_ cachedAt: Date, ttl: TimeInterval) -> Bool {
        Date().timeIntervalSince(cachedAt) > ttl
    }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Books Feed
    // Key: deterministic string from query params
    // ──────────────────────────────────────────────────────────────────────────

    func cachedBooks(forKey key: String, ttl: TimeInterval = defaultTTL) -> [Book]? {
        load([Book].self, filename: "books_\(key.safeFilename).json", ttl: ttl)
    }

    func storeBooks(_ books: [Book], forKey key: String) {
        persist(books, filename: "books_\(key.safeFilename).json")
    }

    func invalidateBooks() { deleteAllDisk(prefix: "books_") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Book Detail
    // ──────────────────────────────────────────────────────────────────────────

    func cachedBookDetail(id: String, ttl: TimeInterval = defaultTTL) -> Book? {
        load(Book.self, filename: "book_\(id).json", ttl: ttl)
    }

    func storeBookDetail(_ book: Book) {
        persist(book, filename: "book_\(book.id).json")
    }

    func invalidateBookDetail(id: String) { deleteDisk(filename: "book_\(id).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Groups
    // ──────────────────────────────────────────────────────────────────────────

    func cachedMyGroups(ttl: TimeInterval = defaultTTL) -> [BookClub]? {
        load([BookClub].self, filename: "my_groups.json", ttl: ttl)
    }

    func storeMyGroups(_ groups: [BookClub]) {
        persist(groups, filename: "my_groups.json")
    }

    func invalidateMyGroups() { deleteDisk(filename: "my_groups.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Discovered Groups
    // ──────────────────────────────────────────────────────────────────────────

    func cachedDiscoveredGroups(forKey key: String, ttl: TimeInterval = defaultTTL) -> [BookClub]? {
        load([BookClub].self, filename: "discover_\(key.safeFilename).json", ttl: ttl)
    }

    func storeDiscoveredGroups(_ groups: [BookClub], forKey key: String) {
        persist(groups, filename: "discover_\(key.safeFilename).json")
    }

    func invalidateDiscoveredGroups() { deleteAllDisk(prefix: "discover_") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Detail
    // ──────────────────────────────────────────────────────────────────────────

    func cachedGroupDetail(id: String, ttl: TimeInterval = defaultTTL) -> BookClub? {
        load(BookClub.self, filename: "group_\(id).json", ttl: ttl)
    }

    func storeGroupDetail(_ group: BookClub) {
        persist(group, filename: "group_\(group.id).json")
    }

    func invalidateGroupDetail(id: String) { deleteDisk(filename: "group_\(id).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Members
    // ──────────────────────────────────────────────────────────────────────────

    func cachedGroupMembers(groupId: String, ttl: TimeInterval = defaultTTL) -> [GroupMember]? {
        load([GroupMember].self, filename: "members_\(groupId).json", ttl: ttl)
    }

    func storeGroupMembers(_ members: [GroupMember], groupId: String) {
        persist(members, filename: "members_\(groupId).json")
    }

    func invalidateGroupMembers(groupId: String) { deleteDisk(filename: "members_\(groupId).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Group Books
    // ──────────────────────────────────────────────────────────────────────────

    func cachedGroupBooks(groupId: String, ttl: TimeInterval = defaultTTL) -> [Book]? {
        load([Book].self, filename: "group_books_\(groupId).json", ttl: ttl)
    }

    func storeGroupBooks(_ books: [Book], groupId: String) {
        persist(books, filename: "group_books_\(groupId).json")
    }

    func invalidateGroupBooks(groupId: String) { deleteDisk(filename: "group_books_\(groupId).json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - My Owned Books
    // ──────────────────────────────────────────────────────────────────────────

    func cachedMyBooks(ttl: TimeInterval = defaultTTL) -> [Book]? {
        load([Book].self, filename: "my_books.json", ttl: ttl)
    }

    func storeMyBooks(_ books: [Book]) { persist(books, filename: "my_books.json") }

    func invalidateMyBooks() { deleteDisk(filename: "my_books.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions — Borrower
    // ──────────────────────────────────────────────────────────────────────────

    func cachedBorrowerTransactions(ttl: TimeInterval = defaultTTL) -> [Transaction]? {
        load([Transaction].self, filename: "txn_borrower.json", ttl: ttl)
    }

    func storeBorrowerTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_borrower.json")
    }

    func invalidateBorrowerTransactions() { deleteDisk(filename: "txn_borrower.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions — Owner
    // ──────────────────────────────────────────────────────────────────────────

    func cachedOwnerTransactions(ttl: TimeInterval = defaultTTL) -> [Transaction]? {
        load([Transaction].self, filename: "txn_owner.json", ttl: ttl)
    }

    func storeOwnerTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_owner.json")
    }

    func invalidateOwnerTransactions() { deleteDisk(filename: "txn_owner.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Transactions — History
    // ──────────────────────────────────────────────────────────────────────────

    func cachedHistoryTransactions(ttl: TimeInterval = defaultTTL) -> [Transaction]? {
        load([Transaction].self, filename: "txn_history.json", ttl: ttl)
    }

    func storeHistoryTransactions(_ txns: [Transaction]) {
        persist(txns, filename: "txn_history.json")
    }

    func invalidateHistoryTransactions() { deleteDisk(filename: "txn_history.json") }

    // ──────────────────────────────────────────────────────────────────────────
    // MARK: - Global Invalidation
    // ──────────────────────────────────────────────────────────────────────────

    func invalidateAll() { deleteAllDisk() }

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
