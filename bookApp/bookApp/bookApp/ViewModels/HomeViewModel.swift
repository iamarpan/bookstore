// ViewModels/HomeViewModel.swift
import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published (source of truth)
    @Published var books: [Book] = []
    @Published var searchText: String = ""
    @Published var selectedGenre: String? = nil
    @Published var selectedAvailability: String? = nil
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Derived (computed once via Combine, not on every render)
    @Published private(set) var filteredBooks: [Book] = []
    @Published private(set) var genres: [String] = []

    let availabilityOptions = ["Available", "Not Available"]

    private let refresher: AppDataRefresher
    private var selectedGroupIds: [String] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed

    var hasActiveFilters: Bool {
        selectedGenre != nil || selectedAvailability != nil
    }

    // MARK: - Initialization

    init(refresher: AppDataRefresher = .shared) {
        self.refresher = refresher
        setupFiltering()
    }

    // MARK: - Combine pipeline — derived filteredBooks & genres

    private func setupFiltering() {
        // React only when books, searchText, selectedGenre, or selectedAvailability change.
        // Debounce search input so we don't re-filter on every keystroke.
        Publishers.CombineLatest4($books, $searchText, $selectedGenre, $selectedAvailability)
            .debounce(for: .milliseconds(120), scheduler: DispatchQueue.global(qos: .userInitiated))
            .map { books, search, genre, avail -> ([Book], [String]) in
                // Compute both filteredBooks and genres in one pass (background thread)
                let uniqueGenres = Array(Set(books.map { $0.genre })).sorted()

                var filtered = books
                if !search.isEmpty {
                    filtered = filtered.filter {
                        $0.title.localizedCaseInsensitiveContains(search) ||
                        $0.author.localizedCaseInsensitiveContains(search) ||
                        $0.genre.localizedCaseInsensitiveContains(search)
                    }
                }
                if let genre, !genre.isEmpty { filtered = filtered.filter { $0.genre == genre } }
                if avail == "Available"     { filtered = filtered.filter { $0.isAvailable } }
                else if avail == "Not Available" { filtered = filtered.filter { !$0.isAvailable } }
                return (filtered, uniqueGenres)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (filtered, genres) in
                self?.filteredBooks = filtered
                self?.genres = genres
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    /// Fetch books — shows cached data instantly, then refreshes only if stale.
    func fetchBooks(for groupIds: [String]) async {
        selectedGroupIds = groupIds
        errorMessage = nil

        let availability = selectedAvailability == "Available" ? "AVAILABLE" : nil
        let genres       = selectedGenre != nil ? [selectedGenre!] : nil
        let search       = searchText.isEmpty ? nil : searchText
        let key          = AppDataStore.booksFeedKey(
            groupIds: groupIds.isEmpty ? nil : groupIds,
            availability: availability, genres: genres, sortBy: "RECENT", search: search
        )

        // 1. Serve from memory immediately (zero I/O)
        if let cached = AppDataStore.shared.cachedBooksInMemory(forKey: key, ttl: .infinity) {
            books = cached
        }

        // 2. Only show a spinner if we have nothing to show yet
        if books.isEmpty { isLoading = true }

        // 3. Async disk read if memory was cold
        if books.isEmpty, let cached = await AppDataStore.shared.cachedBooks(forKey: key, ttl: .infinity) {
            books = cached
            isLoading = false
        }

        // 4. Fetch from the API only if cache is stale (respects TTL)
        do {
            let result = try await refresher.refreshBooksIfNeeded(
                groupIds: groupIds.isEmpty ? nil : groupIds,
                availability: availability,
                genres: genres,
                sortBy: "RECENT",
                search: search,
                forceRefresh: false   // Let TTL decide — no redundant network calls
            )
            books = result
        } catch {
            // Network failed — if we already showed cached data, stay silent
            if books.isEmpty {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isLoading = false
    }

    /// Pull-to-refresh — always goes to the network.
    func refreshBooks() async {
        isLoading = false  // pull-to-refresh has its own spinner
        errorMessage = nil

        let availability = selectedAvailability == "Available" ? "AVAILABLE" : nil
        let genres       = selectedGenre != nil ? [selectedGenre!] : nil
        let search       = searchText.isEmpty ? nil : searchText

        do {
            let result = try await refresher.refreshBooksIfNeeded(
                groupIds: selectedGroupIds.isEmpty ? nil : selectedGroupIds,
                availability: availability,
                genres: genres,
                sortBy: "RECENT",
                search: search,
                forceRefresh: true
            )
            books = result
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Clear all filters and reload
    func clearFilters() {
        selectedGenre = nil
        selectedAvailability = nil
        searchText = ""

        Task {
            await refreshBooks()
        }
    }

    /// Load mock data for development
    func loadMockBooks() {
        books = Book.mockBooks
    }
}