import Foundation

struct Book: Identifiable, Codable {
    var id: String?
    let title: String
    let author: String
    let genre: String
    let description: String
    let imageURL: String
    let isAvailable: Bool
    let ownerId: String
    let ownerName: String
    let ownerFlatNumber: String
    let createdAt: Date
    
    init(title: String, author: String, genre: String, description: String, imageURL: String = "", isAvailable: Bool = true, ownerId: String, ownerName: String, ownerFlatNumber: String) {
        self.id = UUID().uuidString
        self.title = title
        self.author = author
        self.genre = genre
        self.description = description
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.ownerFlatNumber = ownerFlatNumber
        self.createdAt = Date()
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
            ownerFlatNumber: "A-101"
        ),
        Book(
            title: "Becoming",
            author: "Michelle Obama",
            genre: "Biography",
            description: "A memoir by former First Lady Michelle Obama, chronicling her journey from childhood to the White House.",
            imageURL: "https://covers.openlibrary.org/b/id/8508311-L.jpg",
            isAvailable: false,
            ownerId: "2",
            ownerName: "Sarah Johnson",
            ownerFlatNumber: "B-205"
        ),
        Book(
            title: "Dune",
            author: "Frank Herbert",
            genre: "Science",
            description: "A science fiction masterpiece set on the desert planet Arrakis, exploring politics, religion, and ecology.",
            imageURL: "https://covers.openlibrary.org/b/id/8632264-L.jpg",
            ownerId: "3",
            ownerName: "Mike Wilson",
            ownerFlatNumber: "C-302"
        ),
        Book(
            title: "The Midnight Library",
            author: "Matt Haig",
            genre: "Fiction",
            description: "Between life and death there is a library, and within that library, the shelves go on forever.",
            imageURL: "https://covers.openlibrary.org/b/id/10909258-L.jpg",
            ownerId: "4",
            ownerName: "Emma Davis",
            ownerFlatNumber: "A-205"
        ),
        Book(
            title: "Sapiens",
            author: "Yuval Noah Harari",
            genre: "History",
            description: "A brief history of humankind, exploring how Homo sapiens came to rule the world.",
            imageURL: "https://covers.openlibrary.org/b/id/8379786-L.jpg",
            isAvailable: false,
            ownerId: "5",
            ownerName: "David Chen",
            ownerFlatNumber: "D-101"
        ),
        Book(
            title: "Clean Code",
            author: "Robert C. Martin",
            genre: "Technology",
            description: "A handbook of agile software craftsmanship for writing clean, maintainable code.",
            imageURL: "https://covers.openlibrary.org/b/id/6999792-L.jpg",
            ownerId: "6",
            ownerName: "Alex Rodriguez",
            ownerFlatNumber: "B-108"
        ),
        Book(
            title: "Pride and Prejudice",
            author: "Jane Austen",
            genre: "Romance",
            description: "A romantic novel about Elizabeth Bennet and Mr. Darcy, exploring themes of love, reputation, and class.",
            imageURL: "https://covers.openlibrary.org/b/id/8091016-L.jpg",
            ownerId: "7",
            ownerName: "Lisa Thompson",
            ownerFlatNumber: "C-407"
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
            ownerFlatNumber: "A-309"
        ),
        Book(
            title: "The Alchemist",
            author: "Paulo Coelho",
            genre: "Fiction",
            description: "A philosophical novel about a young shepherd's journey to find treasure and discover his destiny.",
            imageURL: "https://covers.openlibrary.org/b/id/8308854-L.jpg",
            ownerId: "9",
            ownerName: "Maria Garcia",
            ownerFlatNumber: "D-203"
        ),
        Book(
            title: "Steve Jobs",
            author: "Walter Isaacson",
            genre: "Biography",
            description: "The exclusive biography of Apple's co-founder, based on interviews with Jobs himself.",
            imageURL: "https://covers.openlibrary.org/b/id/7225629-L.jpg",
            ownerId: "10",
            ownerName: "Rachel Kim",
            ownerFlatNumber: "B-401"
        ),
        Book(
            title: "The Martian",
            author: "Andy Weir",
            genre: "Science",
            description: "A thrilling tale of survival as an astronaut is stranded on Mars and must find a way home.",
            imageURL: "https://covers.openlibrary.org/b/id/8091348-L.jpg",
            ownerId: "11",
            ownerName: "Tom Anderson",
            ownerFlatNumber: "C-506"
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
            ownerFlatNumber: "A-502"
        )
    ]
} 