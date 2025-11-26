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
    
    private let bookService: BookService
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
    
    init(bookService: BookService = BookService()) {
        self.bookService = bookService
    }
    
    // MARK: - Methods
    
    /// Fetch books for selected groups
    func fetchBooks(for groupIds: [String]) async {
        isLoading = true
        errorMessage = nil
        selectedGroupIds = groupIds
        
        do {
            books = try await bookService.fetchBooks(
                groupIds: groupIds.isEmpty ? nil : groupIds,
                availability: selectedAvailability == "Available" ? "AVAILABLE" : nil,
                genres: selectedGenre != nil ? [selectedGenre!] : nil,
                sortBy: "RECENT",
                search: searchText.isEmpty ? nil : searchText
            )
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
    
    /// Refresh books with current filters
    func refreshBooks() async {
        await fetchBooks(for: selectedGroupIds)
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
        bookService.loadMockBooks()
        books = bookService.books
    }
}