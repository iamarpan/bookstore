import Foundation

// MARK: - Book Condition Enum
enum BookCondition: String, Codable {
    case new = "NEW"
    case likeNew = "LIKE_NEW"
    case good = "GOOD"
    case fair = "FAIR"
    case poor = "POOR"
}

// MARK: - Book Model
struct Book: Identifiable, Codable {
    let id: String
    let title: String
    let author: String
    let genre: String
    let description: String
    var personalNotes: String?
    let imageUrl: String  // Changed from imageURL to match API contract
    
    // ISBN and metadata
    var isbn: String?
    var publisher: String?
    var year: Int?
    var pages: Int?
    var language: String?
    
    // Condition and pricing
    var condition: BookCondition
    var lendingPricePerWeek: Double
    
    // Availability and ownership
    var isAvailable: Bool
    let ownerId: String
    let ownerName: String
    var ownerRating: Double?
    var ownerBooksCount: Int?
    var ownerProfileImageUrl: String?
    
    // Multi-group visibility
    var visibleInGroups: [String]  // Array of group IDs
    
    // Transaction tracking
    var currentTransactionId: String?
    
    // Timestamps
    let createdAt: Date
    var updatedAt: Date?
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, title, author, genre, description, personalNotes
        case imageUrl
        case isbn, publisher, year, pages, language
        case condition
        case lendingPricePerWeek
        case isAvailable
        case ownerId, ownerName, ownerRating, ownerBooksCount, ownerProfileImageUrl
        case visibleInGroups
        case currentTransactionId
        case createdAt, updatedAt
    }
    
    // MARK: - Initializers
    
    /// Main initializer for creating a new book
    init(
        id: String = UUID().uuidString,
        title: String,
        author: String,
        genre: String,
        description: String,
        personalNotes: String? = nil,
        imageUrl: String = "",
        isbn: String? = nil,
        publisher: String? = nil,
        year: Int? = nil,
        pages: Int? = nil,
        language: String? = "English",
        condition: BookCondition = .good,
        lendingPricePerWeek: Double = 0,
        isAvailable: Bool = true,
        ownerId: String,
        ownerName: String,
        ownerRating: Double? = nil,
        ownerBooksCount: Int? = nil,
        ownerProfileImageUrl: String? = nil,
        visibleInGroups: [String],
        currentTransactionId: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.description = description
        self.personalNotes = personalNotes
        self.imageUrl = imageUrl
        self.isbn = isbn
        self.publisher = publisher
        self.year = year
        self.pages = pages
        self.language = language
        self.condition = condition
        self.lendingPricePerWeek = lendingPricePerWeek
        self.isAvailable = isAvailable
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.ownerRating = ownerRating
        self.ownerBooksCount = ownerBooksCount
        self.ownerProfileImageUrl = ownerProfileImageUrl
        self.visibleInGroups = visibleInGroups
        self.currentTransactionId = currentTransactionId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Convenience initializer for backward compatibility during migration
    @available(*, deprecated, message: "Use init with visibleInGroups instead")
    init(
        title: String,
        author: String,
        genre: String,
        description: String,
        imageURL: String = "",
        isAvailable: Bool = true,
        ownerId: String,
        ownerName: String,
        bookClubId: String  // Single group ID for backward compat
    ) {
        self.init(
            title: title,
            author: author,
            genre: genre,
            description: description,
            imageUrl: imageURL,
            ownerId: ownerId,
            ownerName: ownerName,
            visibleInGroups: [bookClubId]
        )
    }
}

// MARK: - Helper Properties
extension Book {
    /// Primary group ID for backward compatibility
    var primaryGroupId: String? {
        visibleInGroups.first
    }
    
    /// Check if book is visible in a specific group
    func isVisibleIn(groupId: String) -> Bool {
        visibleInGroups.contains(groupId)
    }
    
    /// Formatted price string
    var formattedPrice: String {
        if lendingPricePerWeek == 0 {
            return "Free"
        }
        return "₹\(Int(lendingPricePerWeek))/week"
    }
    
    /// Status text for UI
    var statusText: String {
        if !isAvailable && currentTransactionId != nil {
            return "Currently Lent"
        } else if !isAvailable {
            return "Not Available"
        } else {
            return "Available"
        }
    }
}

// MARK: - Mock Data
extension Book {
    static let mockBooks: [Book] = [
        Book(
            title: "The Great Gatsby",
            author: "F. Scott Fitzgerald",
            genre: "Fiction",
            description: "A classic American novel about the American Dream and the decadence of the 1920s.",
            imageUrl: "https://covers.openlibrary.org/b/id/8225261-L.jpg",
            isbn: "9780743273565",
            publisher: "Scribner",
            year: 1925,
            pages: 180,
            condition: .good,
            lendingPricePerWeek: 30,
            ownerId: "1",
            ownerName: "John Smith",
            visibleInGroups: ["club1"]
        ),
        Book(
            title: "Becoming",
            author: "Michelle Obama",
            genre: "Biography",
            description: "The memoir of former United States First Lady Michelle Obama.",
            imageUrl: "https://covers.openlibrary.org/b/id/8393955-L.jpg",
            isbn: "9781524763138",
            year: 2018,
            condition: .likeNew,
            lendingPricePerWeek: 50,
            isAvailable: false,
            ownerId: "2",
            ownerName: "Sarah Johnson",
            visibleInGroups: ["club1", "club2"],
            currentTransactionId: "txn_001"
        ),
        Book(
            title: "Clean Code",
            author: "Robert C. Martin",
            genre: "Technology",
            description: "A handbook of agile software craftsmanship for writing clean, maintainable code.",
            imageUrl: "https://covers.openlibrary.org/b/id/6999792-L.jpg",
            isbn: "9780132350884",
            publisher: "Prentice Hall",
            year: 2008,
            pages: 464,
            condition: .good,
            lendingPricePerWeek: 40,
            ownerId: "3",
            ownerName: "Alex Rodriguez",
            visibleInGroups: ["club1"]
        ),
        Book(
            title: "The Midnight Library",
            author: "Matt Haig",
            genre: "Fiction",
            description: "Between life and death there is a library, and within that library, the shelves go on forever.",
            imageUrl: "https://covers.openlibrary.org/b/id/10909258-L.jpg",
            year: 2020,
            condition: .new,
            lendingPricePerWeek: 0,  // Free
            ownerId: "4",
            ownerName: "Emma Davis",
            visibleInGroups: ["club1"]
        ),
        Book(
            title: "Sapiens",
            author: "Yuval Noah Harari",
            genre: "History",
            description: "A brief history of humankind, exploring how biology and history have defined us and enhanced our understanding of what it means to be human.",
            imageUrl: "https://covers.openlibrary.org/b/id/8192456-L.jpg",
            isbn: "9780062316097",
            year: 2015,
            pages: 443,
            condition: .good,
            lendingPricePerWeek: 45,
            isAvailable: false,
            ownerId: "5",
            ownerName: "David Chen",
            visibleInGroups: ["club1", "club3"],
            currentTransactionId: "txn_002"
        )
    ]
}