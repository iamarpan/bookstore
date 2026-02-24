// ViewModels/HomeViewModel.swift
import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var searchText: String = ""
    @Published var selectedGenre: String? = nil
    @Published var selectedAvailability: String? = nil
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil
    
    private let refresher: AppDataRefresher
    private var selectedGroupIds: [String] = []
    
    // MARK: - Computed Properties
    
    var filteredBooks: [Book] {
        var filtered = books
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText) ||
                book.genre.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply genre filter
        if let selectedGenre = selectedGenre, !selectedGenre.isEmpty {
            filtered = filtered.filter { $0.genre == selectedGenre }
        }
        
        // Apply availability filter
        if let selectedAvailability = selectedAvailability, !selectedAvailability.isEmpty {
            if selectedAvailability == "Available" {
                filtered = filtered.filter { $0.isAvailable }
            } else if selectedAvailability == "Not Available" {
                filtered = filtered.filter { !$0.isAvailable }
            }
        }
        
        return filtered
    }
    
    var hasActiveFilters: Bool {
        return selectedGenre != nil || selectedAvailability != nil
    }
    
    var genres: [String] {
        let allGenres = Set(books.map { $0.genre })
        return Array(allGenres).sorted()
    }
    
    let availabilityOptions = ["Available", "Not Available"]
    
    // MARK: - Initialization
    
    init(refresher: AppDataRefresher = .shared) {
        self.refresher = refresher
    }
    
    // MARK: - Methods
    
    /// Fetch books — shows cached data instantly, then refreshes in background.
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

        // 1. Serve from disk immediately (even if stale) — no spinner
        if let cached = AppDataStore.shared.cachedBooks(forKey: key, ttl: .infinity) {
            books = cached
        }

        // 2. Only show a spinner if we have nothing to show yet
        if books.isEmpty { isLoading = true }

        // 3. Always fetch fresh data from the API
        do {
            let result = try await refresher.refreshBooksIfNeeded(
                groupIds: groupIds.isEmpty ? nil : groupIds,
                availability: availability,
                genres: genres,
                sortBy: "RECENT",
                search: search,
                forceRefresh: true   // always go to network; AppDataRefresher writes to disk
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

    /// Pull-to-refresh — force network, then update.
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