import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var filteredBooks: [Book] = []
    @Published var searchText = ""
    @Published var selectedGenre = "All"
    @Published var selectedAvailability = "All"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    let genres = ["All", "Fiction", "Biography", "Science", "History", "Technology", "Romance", "Mystery"]
    let availabilityOptions = ["All", "Available", "Borrowed"]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchAndFilter()
        loadBooks()
    }
    
    private func setupSearchAndFilter() {
        Publishers.CombineLatest4($books, $searchText, $selectedGenre, $selectedAvailability)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { books, searchText, selectedGenre, selectedAvailability in
                self.filterBooks(books: books, searchText: searchText, genre: selectedGenre, availability: selectedAvailability)
            }
            .assign(to: \.filteredBooks, on: self)
            .store(in: &cancellables)
    }
    
    private func filterBooks(books: [Book], searchText: String, genre: String, availability: String) -> [Book] {
        var filtered = books
        
        // Filter by genre
        if genre != "All" {
            filtered = filtered.filter { $0.genre == genre }
        }
        
        // Filter by availability
        if availability != "All" {
            filtered = filtered.filter { book in
                if availability == "Available" {
                    return book.isAvailable
                } else if availability == "Borrowed" {
                    return !book.isAvailable
                }
                return true
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText) ||
                book.genre.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    func loadBooks() {
        isLoading = true
        
        // Simulate API call
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            await MainActor.run {
                self.books = Book.mockBooks
                self.isLoading = false
            }
        }
    }
    
    func refreshBooks() {
        loadBooks()
    }
    
    func clearFilters() {
        selectedGenre = "All"
        selectedAvailability = "All"
    }
    
    var hasActiveFilters: Bool {
        selectedGenre != "All" || selectedAvailability != "All"
    }
} 