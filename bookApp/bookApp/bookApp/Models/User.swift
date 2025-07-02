import Foundation

struct User: Identifiable, Codable {
    var id: String?
    let name: String
    let flatNumber: String
    let phoneNumber: String
    let createdAt: Date
    
    init(name: String, flatNumber: String, phoneNumber: String) {
        self.id = UUID().uuidString
        self.name = name
        self.flatNumber = flatNumber
        self.phoneNumber = phoneNumber
        self.createdAt = Date()
    }
}

// MARK: - Mock Data
extension User {
    static let mockUser = User(
        name: "Demo User",
        flatNumber: "A-101",
        phoneNumber: "+1234567890"
    )
} 