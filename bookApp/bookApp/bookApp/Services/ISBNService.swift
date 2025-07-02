import Foundation

struct ISBNService {
    static let shared = ISBNService()
    
    private init() {}
    
    func fetchBookInfo(isbn: String) async throws -> BookInfo {
        // Clean ISBN (remove hyphens, spaces)
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        
        // Try Open Library API first
        if let bookInfo = try? await fetchFromOpenLibrary(isbn: cleanISBN) {
            return bookInfo
        }
        
        // Fallback to Google Books API
        return try await fetchFromGoogleBooks(isbn: cleanISBN)
    }
    
    private func fetchFromOpenLibrary(isbn: String) async throws -> BookInfo {
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data"
        guard let url = URL(string: urlString) else {
            throw ISBNError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ISBNError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bookData = json?["ISBN:\(isbn)"] as? [String: Any] else {
            throw ISBNError.bookNotFound
        }
        
        return parseOpenLibraryResponse(bookData)
    }
    
    private func fetchFromGoogleBooks(isbn: String) async throws -> BookInfo {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        guard let url = URL(string: urlString) else {
            throw ISBNError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ISBNError.networkError
        }
        
        let googleResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        guard let item = googleResponse.items?.first else {
            throw ISBNError.bookNotFound
        }
        
        return parseGoogleBooksResponse(item)
    }
    
    private func parseOpenLibraryResponse(_ data: [String: Any]) -> BookInfo {
        let title = data["title"] as? String ?? "Unknown Title"
        
        let authors = (data["authors"] as? [[String: Any]])?.compactMap { author in
            author["name"] as? String
        }.joined(separator: ", ") ?? "Unknown Author"
        
        let subjects = (data["subjects"] as? [[String: Any]])?.compactMap { subject in
            subject["name"] as? String
        }.first ?? "General"
        
        let description = (data["excerpts"] as? [[String: Any]])?.first?["text"] as? String ?? 
                         "No description available"
        
        let coverURL = (data["cover"] as? [String: Any])?["large"] as? String ?? ""
        
        return BookInfo(
            title: title,
            authors: authors,
            genre: mapSubjectToGenre(subjects),
            description: description,
            imageURL: coverURL,
            isbn: ""
        )
    }
    
    private func parseGoogleBooksResponse(_ item: GoogleBooksItem) -> BookInfo {
        let volumeInfo = item.volumeInfo
        let title = volumeInfo.title ?? "Unknown Title"
        let authors = volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author"
        let categories = volumeInfo.categories?.first ?? "General"
        let description = volumeInfo.description ?? "No description available"
        let imageURL = volumeInfo.imageLinks?.thumbnail ?? ""
        
        return BookInfo(
            title: title,
            authors: authors,
            genre: mapSubjectToGenre(categories),
            description: description,
            imageURL: imageURL,
            isbn: ""
        )
    }
    
    private func mapSubjectToGenre(_ subject: String) -> String {
        let lowercaseSubject = subject.lowercased()
        
        if lowercaseSubject.contains("fiction") || lowercaseSubject.contains("novel") {
            return "Fiction"
        } else if lowercaseSubject.contains("biography") || lowercaseSubject.contains("memoir") {
            return "Biography"
        } else if lowercaseSubject.contains("science") {
            return "Science"
        } else if lowercaseSubject.contains("history") {
            return "History"
        } else if lowercaseSubject.contains("technology") || lowercaseSubject.contains("computer") {
            return "Technology"
        } else if lowercaseSubject.contains("romance") {
            return "Romance"
        } else if lowercaseSubject.contains("mystery") || lowercaseSubject.contains("crime") {
            return "Mystery"
        } else {
            return "Other"
        }
    }
}

// MARK: - Models

struct BookInfo {
    let title: String
    let authors: String
    let genre: String
    let description: String
    let imageURL: String
    let isbn: String
}

enum ISBNError: LocalizedError {
    case invalidURL
    case networkError
    case bookNotFound
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .bookNotFound:
            return "Book not found for this ISBN"
        case .parsingError:
            return "Error parsing book data"
        }
    }
}

// MARK: - Google Books API Models

struct GoogleBooksResponse: Codable {
    let items: [GoogleBooksItem]?
}

struct GoogleBooksItem: Codable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let description: String?
    let categories: [String]?
    let imageLinks: ImageLinks?
}

struct ImageLinks: Codable {
    let thumbnail: String?
} 