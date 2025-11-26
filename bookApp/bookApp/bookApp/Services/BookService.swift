import Foundation

/// Service for book operations
@MainActor
class BookService: ObservableObject {
    // MARK: - Published Properties
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let apiClient: APIClient
    
    // MARK: - Initialization
    
    nonisolated init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Fetch Books
    
    /// Fetch books feed with filters
    func fetchBooks(
        groupIds: [String]? = nil,
        availability: String? = nil,
        genres: [String]? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        sortBy: String? = nil,
        search: String? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> [Book] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        var queryParams: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if let groupIds = groupIds {
            queryParams["groupIds[]"] = groupIds
        }
        if let availability = availability {
            queryParams["availability"] = availability
        }
        if let genres = genres {
            queryParams["genres[]"] = genres
        }
        if let minPrice = minPrice {
            queryParams["minPrice"] = minPrice
        }
        if let maxPrice = maxPrice {
            queryParams["maxPrice"] = maxPrice
        }
        if let sortBy = sortBy {
            queryParams["sortBy"] = sortBy
        }
        if let search = search {
            queryParams["search"] = search
        }
        
        struct BooksResponse: Codable {
            let books: [Book]
        }
        
        do {
            let response: BooksResponse = try await apiClient.get(
                "/books/feed",
                queryParams: queryParams
            )
            
            books = response.books
            return response.books
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Fetch book details
    func fetchBook(id: String) async throws -> Book {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let book: Book = try await apiClient.get("/books/\(id)")
            return book
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Fetch current user's books
    func fetchMyBooks() async throws -> [Book] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let books: [Book] = try await apiClient.get("/users/me/books")
            return books
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Create/Update Books
    
    /// Create a new book
    func createBook(_ book: Book) async throws -> Book {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let createdBook: Book = try await apiClient.post("/books", body: book)
            
            // Add to local list
            books.insert(createdBook, at: 0)
            
            print("✅ Book created: \(createdBook.title)")
            return createdBook
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Update a book
    func updateBook(_ book: Book) async throws -> Book {
        guard !book.id.isEmpty else {
            throw APIError.invalidURL
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let updatedBook: Book = try await apiClient.put("/books/\(book.id)", body: book)
            
            // Update in local list
            if let index = books.firstIndex(where: { $0.id == book.id }) {
                books[index] = updatedBook
            }
            
            print("✅ Book updated: \(updatedBook.title)")
            return updatedBook
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Delete a book
    func deleteBook(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await apiClient.delete("/books/\(id)")
            
            // Remove from local list
            books.removeAll { $0.id == id }
            
            print("✅ Book deleted")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - ISBN Lookup
    
    /// Lookup book by ISBN (from backend or external API)
    func lookupISBN(_ isbn: String) async throws -> Book? {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct ISBNRequest: Codable {
            let isbn: String
        }
        
        do {
            let request = ISBNRequest(isbn: isbn)
            let book: Book = try await apiClient.post("/books/scan-isbn", body: request)
            
            print("✅ Book found via ISBN: \(book.title)")
            return book
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Image Upload
    
    /// Upload book cover image
    func uploadBookImage(_ imageData: Data) async throws -> String {
        // TODO: Implement multipart/form-data upload
        // For now, return a placeholder
        
        print("📸 Would upload image (\(imageData.count) bytes)")
        
        // This would be implemented with multipart upload
        // let imageUrl: String = try await apiClient.uploadImage(imageData, to: "/books/upload-image")
        
        return "https://placeholder.com/book-cover.jpg"
    }
    
    // MARK: - Mock Data (for development)
    
    /// Load mock books for UI development
    func loadMockBooks() {
        books = Book.mockBooks
        print("✅ Loaded \(books.count) mock books")
    }
}
