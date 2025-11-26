import Foundation
import FirebaseFirestore

struct Book: Identifiable, Codable {
    var id: String?
    let title: String
    let author: String
    let genre: String
    let description: String
    let imageURL: String
    var isAvailable: Bool
    let ownerId: String
    let ownerName: String
    let bookClubId: String
    let createdAt: Date
    let updatedAt: Date?
    
    init(title: String, author: String, genre: String, description: String, imageURL: String = "", isAvailable: Bool = true, ownerId: String, ownerName: String, bookClubId: String) {
        self.id = UUID().uuidString
        self.title = title
        self.author = author
        self.genre = genre
        self.description = description
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.bookClubId = bookClubId
        self.createdAt = Date()
        self.updatedAt = nil
    }
    
    // Firebase initializer
    init(id: String, title: String, author: String, genre: String, description: String, imageURL: String = "", isAvailable: Bool = true, ownerId: String, ownerName: String, bookClubId: String, createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.description = description
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.bookClubId = bookClubId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Firebase Serialization
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "author": author,
            "genre": genre,
            "description": description,
            "imageURL": imageURL,
            "isAvailable": isAvailable,
            "ownerId": ownerId,
            "ownerName": ownerName,
            "bookClubId": bookClubId,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": updatedAt != nil ? Timestamp(date: updatedAt!) : FieldValue.serverTimestamp()
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> Book? {
        guard let title = data["title"] as? String,
              let author = data["author"] as? String,
              let genre = data["genre"] as? String,
              let description = data["description"] as? String,
              let isAvailable = data["isAvailable"] as? Bool,
              let ownerId = data["ownerId"] as? String,
              let ownerName = data["ownerName"] as? String,
              let bookClubId = data["bookClubId"] as? String else {
            return nil
        }
        
        let imageURL = data["imageURL"] as? String ?? ""
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let updatedAt: Date?
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = nil
        }
        
        return Book(
            id: id,
            title: title,
            author: author,
            genre: genre,
            description: description,
            imageURL: imageURL,
            isAvailable: isAvailable,
            ownerId: ownerId,
            ownerName: ownerName,
            bookClubId: bookClubId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
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
            imageURL: "https://covers.openlibrary.org/b/id/8225261-L.jpg",
            ownerId: "1",
            ownerName: "John Smith",
            bookClubId: "club1"
        ),
        Book(
            title: "Becoming",
            author: "Michelle Obama",
            genre: "Biography",
            description: "The memoir of former United States First Lady Michelle Obama.",
            imageURL: "https://covers.openlibrary.org/b/id/8393955-L.jpg",
            isAvailable: false,
            ownerId: "2",
            ownerName: "Sarah Johnson",
            bookClubId: "club1"
        ),
        Book(
            title: "Dune",
            author: "Frank Herbert",
            genre: "Science",
            description: "A science fiction masterpiece set on the desert planet Arrakis, exploring politics, religion, and ecology.",
            imageURL: "https://covers.openlibrary.org/b/id/8632264-L.jpg",
            ownerId: "3",
            ownerName: "Mike Wilson",
            bookClubId: "club1"
        ),
        Book(
            title: "The Midnight Library",
            author: "Matt Haig",
            genre: "Fiction",
            description: "Between life and death there is a library, and within that library, the shelves go on forever.",
            imageURL: "https://covers.openlibrary.org/b/id/10909258-L.jpg",
            ownerId: "4",
            ownerName: "Emma Davis",
            bookClubId: "club1"
        ),
        Book(
            title: "Sapiens",
            author: "Yuval Noah Harari",
            genre: "History",
            description: "A brief history of humankind, exploring how biology and history have defined us and enhanced our understanding of what it means to be human.",
            imageURL: "https://covers.openlibrary.org/b/id/8192456-L.jpg",
            isAvailable: false,
            ownerId: "5",
            ownerName: "David Chen",
            bookClubId: "club1"
        ),
        Book(
            title: "Clean Code",
            author: "Robert C. Martin",
            genre: "Technology",
            description: "A handbook of agile software craftsmanship for writing clean, maintainable code.",
            imageURL: "https://covers.openlibrary.org/b/id/6999792-L.jpg",
            ownerId: "6",
            ownerName: "Alex Rodriguez",
            bookClubId: "club1"
        ),
        Book(
            title: "Pride and Prejudice",
            author: "Jane Austen",
            genre: "Romance",
            description: "A romantic novel about Elizabeth Bennet and Mr. Darcy, exploring themes of love, reputation, and class.",
            imageURL: "https://covers.openlibrary.org/b/id/8091016-L.jpg",
            ownerId: "7",
            ownerName: "Lisa Thompson",
            bookClubId: "club1"
        ),
        Book(
            title: "The Girl with the Dragon Tattoo",
            author: "Stieg Larsson",
            genre: "Mystery",
            description: "A gripping thriller about a journalist and a hacker investigating a wealthy family's dark secrets.",
            imageURL: "https://covers.openlibrary.org/b/id/6279134-L.jpg",
            isAvailable: false,
            ownerId: "8",
            ownerName: "Kevin Park",
            bookClubId: "club1"
        ),
        Book(
            title: "The Alchemist",
            author: "Paulo Coelho",
            genre: "Fiction",
            description: "A philosophical novel about a young shepherd's journey to find treasure and discover his destiny.",
            imageURL: "https://covers.openlibrary.org/b/id/8308854-L.jpg",
            ownerId: "9",
            ownerName: "Maria Garcia",
            bookClubId: "club1"
        ),
        Book(
            title: "Steve Jobs",
            author: "Walter Isaacson",
            genre: "Biography",
            description: "The exclusive biography of Steve Jobs, based on more than forty interviews with Jobs conducted over two years.",
            imageURL: "https://covers.openlibrary.org/b/id/7326678-L.jpg",
            ownerId: "10",
            ownerName: "Rachel Kim",
            bookClubId: "club1"
        ),
        Book(
            title: "The Martian",
            author: "Andy Weir",
            genre: "Science",
            description: "A thrilling tale of survival as an astronaut is stranded on Mars and must find a way home.",
            imageURL: "https://covers.openlibrary.org/b/id/8091348-L.jpg",
            ownerId: "11",
            ownerName: "Tom Anderson",
            bookClubId: "club1"
        ),
        Book(
            title: "Atomic Habits",
            author: "James Clear",
            genre: "Technology",
            description: "An easy and proven way to build good habits and break bad ones through small changes.",
            imageURL: "https://covers.openlibrary.org/b/id/8091540-L.jpg",
            isAvailable: false,
            ownerId: "12",
            ownerName: "Jennifer Lee",
            bookClubId: "club1"
        )
    ]
}