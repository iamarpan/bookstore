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
    
    // Creator
    let creatorId: String
    
    // Invite system
    var inviteCode: String
    var inviteCodeExpiry: Date?
    
    // Group rules
    var rules: String?
    
    // Stats
    var booksCount: Int
    var memberCount: Int
    
    // User's role and membership info (from API)
    var role: MemberRole?
    var isMember: Bool = false
    var joinedAt: Date?
    
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
        case creatorId
        case inviteCode, inviteCodeExpiry
        case rules
        case booksCount, memberCount
        case role, userRole // Handle both for robustness
        case isMember
        case joinedAt
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
        inviteCode: String? = nil,
        inviteCodeExpiry: Date? = nil,
        rules: String? = nil,
        booksCount: Int = 0,
        memberCount: Int = 1,
        role: MemberRole? = nil,
        isMember: Bool = false,
        joinedAt: Date? = nil,
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
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.inviteCodeExpiry = inviteCodeExpiry
        self.rules = rules
        self.booksCount = booksCount
        self.memberCount = memberCount
        self.role = role
        self.isMember = isMember
        self.joinedAt = joinedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Decodable implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        coverImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
        category = try container.decode(GroupCategory.self, forKey: .category)
        privacy = try container.decode(PrivacySetting.self, forKey: .privacy)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        inviteCode = try container.decode(String.self, forKey: .inviteCode)
        inviteCodeExpiry = try container.decodeIfPresent(Date.self, forKey: .inviteCodeExpiry)
        rules = try container.decodeIfPresent(String.self, forKey: .rules)
        booksCount = try container.decode(Int.self, forKey: .booksCount)
        memberCount = try container.decode(Int.self, forKey: .memberCount)
        
        // Robust role decoding: try 'role' then 'userRole'
        role = try container.decodeIfPresent(MemberRole.self, forKey: .role) ?? 
               container.decodeIfPresent(MemberRole.self, forKey: .userRole)
        
        isMember = try container.decodeIfPresent(Bool.self, forKey: .isMember) ?? (role != nil)
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // MARK: - Encodable implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(coverImageUrl, forKey: .coverImageUrl)
        try container.encode(category, forKey: .category)
        try container.encode(privacy, forKey: .privacy)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(inviteCode, forKey: .inviteCode)
        try container.encodeIfPresent(inviteCodeExpiry, forKey: .inviteCodeExpiry)
        try container.encodeIfPresent(rules, forKey: .rules)
        try container.encode(booksCount, forKey: .booksCount)
        try container.encode(memberCount, forKey: .memberCount)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encode(isMember, forKey: .isMember)
        try container.encodeIfPresent(joinedAt, forKey: .joinedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    /// Generate a random invite code
    static func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<9).map{ _ in letters.randomElement()! })
    }
    
    /// Check if current user is the creator
    var isCreator: Bool {
        return role == .creator
    }
    
    /// Check if current user can moderate (moderator, admin, or creator)
    var canModerate: Bool {
        guard let role = role else { return false }
        return role == .creator || role == .admin || role == .moderator
    }
    
    /// Check if current user is admin or creator
    var isAdmin: Bool {
        guard let role = role else { return false }
        return role == .creator || role == .admin
    }
    
    /// Check if current user can manage members (admin or creator)
    var canManageMembers: Bool {
        return isAdmin
    }
    
    /// Check if current user can update group settings (admin or creator)
    var canUpdateSettings: Bool {
        return isAdmin
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
            inviteCode: "ABC123XYZ",
            rules: "1. Return books on time\n2. Keep books in good condition\n3. Be respectful",
            booksCount: 47,
            memberCount: 6,
            role: .creator,
            joinedAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())
        ),
        BookClub(
            id: "club2",
            name: "Hyderabad Book Lovers",
            description: "Public book sharing community",
            category: .bookClub,
            privacy: .public_,
            creatorId: "2",
            booksCount: 120,
            memberCount: 45,
            role: .member,
            joinedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())
        ),
        BookClub(
            id: "club3",
            name: "Friends & Family",
            description: "Private group for close friends",
            category: .friends,
            privacy: .private_,
            creatorId: "usr_demo",
            booksCount: 23,
            memberCount: 8,
            role: .creator,
            joinedAt: Calendar.current.date(byAdding: .day, value: -60, to: Date())
        )
    ]
}
