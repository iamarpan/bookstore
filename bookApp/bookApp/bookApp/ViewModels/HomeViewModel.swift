// ViewModels/HomeViewModel.swift
import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published (derived or UI state)
    @Published var searchText: String = ""
    @Published var selectedGenre: String? = nil
    @Published var selectedAvailability: String? = nil
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Derived (computed once via Combine, not on every render)
    @Published private(set) var filteredBooks: [Book] = []
    @Published private(set) var genres: [String] = []
    @Published private(set) var books: [Book] = []
    @Published private(set) var activeTransactions: [Transaction] = []

    let availabilityOptions = ["Available", "Not Available"]

    private let store = AppDataStore.shared
    private let refresher: any AppDataRefresherProtocol
    @Published var selectedGroupIds: [String] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed

    var hasActiveFilters: Bool {
        selectedGenre != nil || selectedAvailability != nil
    }

    // MARK: - Initialization

    init(refresher: (any AppDataRefresherProtocol)? = nil) {
        self.refresher = refresher ?? AppDataRefresher.shared
        setupFiltering()
    }

    // MARK: - Combine pipeline — derived filteredBooks & genres

    private func setupFiltering() {
        // Observe our own 'books' property as the source for filtering
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
            
        // Observe active borrows for "Continue Reading"
        store.$borrowedTransactions
            .map { $0.filter { $0.status == .active } }
            .receive(on: DispatchQueue.main)
            .assign(to: &$activeTransactions)
    }

    // MARK: - Methods

    /// Fetch books — triggering the refresher updates the store, which updates our UI.
    func fetchBooks(for groupIds: [String]) async {
        selectedGroupIds = groupIds
        errorMessage = nil

        let availability = selectedAvailability == "Available" ? "AVAILABLE" : nil
        let genres       = selectedGenre != nil ? [selectedGenre!] : nil
        let search       = searchText.isEmpty ? nil : searchText
        
        // Always show spinner if the store is currently empty
        if store.overallBooks.isEmpty { isLoading = true }

        do {
            let fetchedBooks = try await refresher.refreshBooksIfNeeded(
                groupIds: groupIds.isEmpty ? nil : groupIds,
                availability: availability,
                genres: genres,
                sortBy: "RECENT",
                search: search,
                forceRefresh: false
            )
            self.books = fetchedBooks
        } catch {
            if store.overallBooks.isEmpty {
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
            let fetchedBooks = try await refresher.refreshBooksIfNeeded(
                groupIds: selectedGroupIds.isEmpty ? nil : selectedGroupIds,
                availability: availability,
                genres: genres,
                sortBy: "RECENT",
                search: search,
                forceRefresh: true
            )
            self.books = fetchedBooks
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

}