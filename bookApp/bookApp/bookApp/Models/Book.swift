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
            ownerId: "2",
            ownerName: "Sarah Johnson",
            ownerFlatNumber: "B-205"
        )
    ]
} 