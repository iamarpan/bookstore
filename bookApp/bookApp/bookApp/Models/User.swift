import Foundation

struct User: Identifiable, Codable {
    var id: String?
    let name: String
    let email: String?
    let phoneNumber: String
    let societyId: String
    let societyName: String
    let blockName: String
    let flatNumber: String
    let profileImageURL: String?
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?
    
    init(name: String, email: String? = nil, phoneNumber: String, societyId: String, societyName: String, blockName: String, flatNumber: String, profileImageURL: String? = nil, isActive: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.societyId = societyId
        self.societyName = societyName
        self.blockName = blockName
        self.flatNumber = flatNumber
        self.profileImageURL = profileImageURL
        self.isActive = isActive
        self.createdAt = Date()
        self.lastLoginAt = nil
    }
    
    // Convenience computed property for display
    var fullAddress: String {
        return "\(blockName)-\(flatNumber), \(societyName)"
    }
}

// MARK: - Mock Data
extension User {
    static let mockUser = User(
        name: "Demo User",
        email: "demo@example.com",
        phoneNumber: "+919876543210",
        societyId: Society.mockSocieties[0].id,
        societyName: Society.mockSocieties[0].name,
        blockName: "A",
        flatNumber: "101"
    )
} 