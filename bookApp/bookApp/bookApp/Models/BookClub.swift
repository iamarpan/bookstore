import Foundation

// MARK: - Group Category Enum
enum GroupCategory: String, Codable {
    case friends = "FRIENDS"
    case office = "OFFICE"
    case neighborhood = "NEIGHBORHOOD"
    case bookClub = "BOOK_CLUB"
    case school = "SCHOOL"
    
    var displayName: String {
        switch self {
        case .friends: return "Friends"
        case .office: return "Office"
        case .neighborhood: return "Neighborhood"
        case .bookClub: return "Book Club"
        case .school: return "School"
        }
    }
}

// MARK: - Privacy Setting Enum
enum PrivacySetting: String, Codable {
    case public_ = "PUBLIC"
    case private_ = "PRIVATE"
}

// MARK: - Member Role Enum
enum MemberRole: String, Codable {
    case member = "MEMBER"
    case moderator = "MODERATOR"
    case admin = "ADMIN"
    case creator = "CREATOR"
}

// MARK: - BookClub Model
struct BookClub: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var coverImageUrl: String?
    var category: GroupCategory
    var privacy: PrivacySetting
    
    // Admin and members
    let creatorId: String
    var adminIds: [String]
    var moderatorIds: [String]
    var memberIds: [String]
    
    // Invite system
    var inviteCode: String
    var inviteCodeExpiry: Date?
    
    // Group rules
    var rules: String?
    
    // Stats
    var booksCount: Int
    var memberCount: Int
    
    // Calculated fields (not persisted)
    var distance: Double?
    
    // Timestamps
    let createdAt: Date
    var updatedAt: Date?
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case coverImageUrl
        case category, privacy
        case distance
        case creatorId, adminIds, moderatorIds, memberIds
        case inviteCode, inviteCodeExpiry
        case rules
        case booksCount, memberCount
        case createdAt, updatedAt
    }
    
    // MARK: - Initializers
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        coverImageUrl: String? = nil,
        category: GroupCategory = .friends,
        privacy: PrivacySetting = .private_,
        creatorId: String,
        adminIds: [String]? = nil,
        moderatorIds: [String] = [],
        memberIds: [String]? = nil,
        inviteCode: String? = nil,
        inviteCodeExpiry: Date? = nil,
        rules: String? = nil,
        booksCount: Int = 0,
        memberCount: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.coverImageUrl = coverImageUrl
        self.category = category
        self.privacy = privacy
        self.creatorId = creatorId
        self.adminIds = adminIds ?? [creatorId]
        self.moderatorIds = moderatorIds
        self.memberIds = memberIds ?? [creatorId]
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.inviteCodeExpiry = inviteCodeExpiry
        self.rules = rules
        self.booksCount = booksCount
        self.memberCount = memberCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Helper Methods
    
    /// Generate a random invite code
    static func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<9).map{ _ in letters.randomElement()! })
    }
    
    /// Get role for a specific user
    func role(for userId: String) -> MemberRole? {
        if creatorId == userId {
            return .creator
        } else if adminIds.contains(userId) {
            return .admin
        } else if moderatorIds.contains(userId) {
            return .moderator
        } else if memberIds.contains(userId) {
            return .member
        }
        return nil
    }
    
    /// Check if user can moderate
    func canModerate(userId: String) -> Bool {
        let userRole = role(for: userId)
        return userRole == .creator || userRole == .admin || userRole == .moderator
    }
    
    /// Check if user is admin or creator
    func isAdmin(userId: String) -> Bool {
        let userRole = role(for: userId)
        return userRole == .creator || userRole == .admin
    }
}

// MARK: - Mock Data
extension BookClub {
    static let mockClubs: [BookClub] = [
        BookClub(
            id: "club1",
            name: "Office Book Club",
            description: "Share books among colleagues",
            category: .office,
            privacy: .private_,
            creatorId: "usr_demo",
            memberIds: ["usr_demo", "1", "2", "3", "4", "5"],
            inviteCode: "ABC123XYZ",
            rules: "1. Return books on time\n2. Keep books in good condition\n3. Be respectful",
            booksCount: 47,
            memberCount: 6
        ),
        BookClub(
            id: "club2",
            name: "Hyderabad Book Lovers",
            description: "Public book sharing community",
            category: .bookClub,
            privacy: .public_,
            creatorId: "2",
            booksCount: 120,
            memberCount: 45
        ),
        BookClub(
            id: "club3",
            name: "Friends & Family",
            description: "Private group for close friends",
            category: .friends,
            privacy: .private_,
            creatorId: "usr_demo",
            booksCount: 23,
            memberCount: 8
        )
    ]
}
