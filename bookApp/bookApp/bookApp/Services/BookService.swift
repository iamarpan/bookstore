import Foundation

/// Service for book operations.
/// NOT @MainActor — JSON decoding runs on the calling task's context (background).
class BookService {
    // MARK: - Private Properties
    private let apiClient: APIClient

    // MARK: - Initialization

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Fetch Books

    /// Fetch books feed with optional filters
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
        var queryParams: [String: Any] = [
            "page": page,
            "limit": limit
        ]

        if let groupIds = groupIds, !groupIds.isEmpty {
            queryParams["groupIds"] = groupIds.joined(separator: ",")
        }
        if let availability = availability { queryParams["availability"] = availability }
        if let genres = genres, !genres.isEmpty { queryParams["genres"] = genres.joined(separator: ",") }
        if let minPrice = minPrice { queryParams["minPrice"] = minPrice }
        if let maxPrice = maxPrice { queryParams["maxPrice"] = maxPrice }
        if let sortBy = sortBy { queryParams["sortBy"] = sortBy }
        if let search = search { queryParams["search"] = search }

        struct BooksResponse: Codable {
            let books: [Book]
        }

        let response: BooksResponse = try await apiClient.get("/books/feed", queryParams: queryParams)
        return response.books
    }

    /// Fetch book details by ID
    func fetchBook(id: String) async throws -> Book {
        try await apiClient.get("/books/\(id)")
    }

    /// Fetch the current user's books via /users/me/books
    func fetchMyBooks() async throws -> [Book] {
        try await apiClient.get("/users/me/books")
    }

    // MARK: - Create/Update/Delete

    func createBook(_ book: Book) async throws -> Book {
        let createdBook: Book = try await apiClient.post("/books", body: book)
        print("✅ Book created: \(createdBook.title)")
        return createdBook
    }

    func updateBook(_ book: Book) async throws -> Book {
        guard !book.id.isEmpty else { throw APIError.invalidURL }
        let updatedBook: Book = try await apiClient.put("/books/\(book.id)", body: book)
        print("✅ Book updated: \(updatedBook.title)")
        return updatedBook
    }

    func deleteBook(id: String) async throws {
        try await apiClient.delete("/books/\(id)")
        print("✅ Book deleted")
    }

    // MARK: - ISBN Lookup

    func lookupISBN(_ isbn: String) async throws -> Book? {
        struct ISBNRequest: Codable { let isbn: String }
        do {
            let book: Book = try await apiClient.post("/books/scan-isbn", body: ISBNRequest(isbn: isbn))
            print("✅ Book found via ISBN: \(book.title)")
            return book
        } catch {
            return nil
        }
    }

    // MARK: - Image Upload

    func uploadBookImage(_ imageData: Data) async throws -> String {
        guard let url = URL(string: APIConfiguration.shared.baseURL + "/upload") else {
            throw APIError.invalidURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Attach auth token
        if let token = KeychainManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Build multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"book.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        struct UploadResponse: Decodable { let url: String }
        let decoded = try JSONDecoder().decode(UploadResponse.self, from: data)
        print("✅ Image uploaded: \(decoded.url)")
        return decoded.url
    }

}
