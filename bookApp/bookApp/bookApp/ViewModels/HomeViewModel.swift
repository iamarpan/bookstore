import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var filteredBooks: [Book] = []
    @Published var searchText = ""
    @Published var selectedGenre = "All"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    let genres = ["All", "Fiction", "Biography", "Science", "History", "Technology", "Romance", "Mystery"]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchAndFilter()
        loadBooks()
    }
    
    private func setupSearchAndFilter() {
        Publishers.CombineLatest3($books, $searchText, $selectedGenre)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { books, searchText, selectedGenre in
                self.filterBooks(books: books, searchText: searchText, genre: selectedGenre)
            }
            .assign(to: \.filteredBooks, on: self)
            .store(in: &cancellables)
    }
    
    private func filterBooks(books: [Book], searchText: String, genre: String) -> [Book] {
        var filtered = books
        
        // Filter by genre
        if genre != "All" {
            filtered = filtered.filter { $0.genre == genre }
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
} 