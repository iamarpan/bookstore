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
        case owner  // Nested owner object from API
        case bookGroups  // Nested bookGroups array from API
        case visibleInGroups
        case currentTransactionId
        case createdAt, updatedAt
    }
    
    // Nested owner structure from API
    private struct OwnerResponse: Codable {
        let id: String
        let name: String
        let averageRating: String?
        let booksShared: Int?
        let profileImageUrl: String?
    }
    
    // Nested bookGroup structure from API
    private struct BookGroupResponse: Codable {
        let groupId: String
        let group: GroupInfo?
        
        struct GroupInfo: Codable {
            let id: String
            let name: String
        }
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Basic fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        genre = try container.decode(String.self, forKey: .genre)
        description = try container.decode(String.self, forKey: .description)
        personalNotes = try container.decodeIfPresent(String.self, forKey: .personalNotes)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        
        // ISBN and metadata
        isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        pages = try container.decodeIfPresent(Int.self, forKey: .pages)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        
        // Condition
        condition = try container.decode(BookCondition.self, forKey: .condition)
        
        // Convert string lendingPricePerWeek to Double
        if let priceString = try? container.decode(String.self, forKey: .lendingPricePerWeek) {
            lendingPricePerWeek = Double(priceString) ?? 0
        } else if let priceDouble = try? container.decode(Double.self, forKey: .lendingPricePerWeek) {
            lendingPricePerWeek = priceDouble
        } else {
            lendingPricePerWeek = 0
        }
        
        // Availability
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        
        // Owner - handle both flat and nested structure
        if let ownerResponse = try? container.decode(OwnerResponse.self, forKey: .owner) {
            // Nested owner object from API
            ownerId = ownerResponse.id
            ownerName = ownerResponse.name
            if let ratingString = ownerResponse.averageRating {
                ownerRating = Double(ratingString)
            } else {
                ownerRating = nil
            }
            ownerBooksCount = ownerResponse.booksShared
            ownerProfileImageUrl = ownerResponse.profileImageUrl
        } else if let id = try? container.decode(String.self, forKey: .ownerId) {
            // Flat structure (fallback)
            ownerId = id
            ownerName = (try? container.decode(String.self, forKey: .ownerName)) ?? ""
            ownerRating = try? container.decode(Double.self, forKey: .ownerRating)
            ownerBooksCount = try? container.decode(Int.self, forKey: .ownerBooksCount)
            ownerProfileImageUrl = try? container.decode(String.self, forKey: .ownerProfileImageUrl)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .ownerId, in: container, debugDescription: "Owner information missing")
        }
        
        // Visible groups - extract from bookGroups array
        if let bookGroupsResponse = try? container.decode([BookGroupResponse].self, forKey: .bookGroups) {
            visibleInGroups = bookGroupsResponse.map { $0.groupId }
        } else {
            visibleInGroups = (try? container.decode([String].self, forKey: .visibleInGroups)) ?? []
        }
        
        // Transaction
        currentTransactionId = try container.decodeIfPresent(String.self, forKey: .currentTransactionId)
        
        // Timestamps
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
        try container.encode(genre, forKey: .genre)
        try container.encode(description, forKey: .description)
        try container.encode(personalNotes, forKey: .personalNotes)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(isbn, forKey: .isbn)
        try container.encode(publisher, forKey: .publisher)
        try container.encode(year, forKey: .year)
        try container.encode(pages, forKey: .pages)
        try container.encode(language, forKey: .language)
        try container.encode(condition, forKey: .condition)
        try container.encode("\(Int(lendingPricePerWeek))", forKey: .lendingPricePerWeek)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(ownerName, forKey: .ownerName)
        try container.encode(visibleInGroups, forKey: .visibleInGroups)
        try container.encode(currentTransactionId, forKey: .currentTransactionId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        
        // Note: For simplicity, we are not encoding 'owner' and 'bookGroups' back to their complex nested objects
        // as the backend usually expects simpler structures during POST/PUT. 
        // If we really need them, we'd rebuild OwnerResponse and BookGroupResponse here.
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