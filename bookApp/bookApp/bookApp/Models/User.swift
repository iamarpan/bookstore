import Foundation

// MARK: - Phone Visibility Enum
enum PhoneVisibility: String, Codable {
    case afterApproval = "AFTER_APPROVAL"
    case groupMembers = "GROUP_MEMBERS"
    case public_ = "PUBLIC"
    
    enum CodingKeys: String, CodingKey {
        case afterApproval = "AFTER_APPROVAL"
        case groupMembers = "GROUP_MEMBERS"
        case public_ = "PUBLIC"
    }
}

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    var phoneVisibility: PhoneVisibility
    
    init(phoneVisibility: PhoneVisibility = .afterApproval) {
        self.phoneVisibility = phoneVisibility
    }
}

// MARK: - User Stats
struct UserStats: Codable {
    var booksShared: Int
    var successfulLends: Int
    var booksBorrowed: Int
    var totalEarned: Double
    var averageRating: Double
    
    init(
        booksShared: Int = 0,
        successfulLends: Int = 0,
        booksBorrowed: Int = 0,
        totalEarned: Double = 0,
        averageRating: Double = 0
    ) {
        self.booksShared = booksShared
        self.successfulLends = successfulLends
        self.booksBorrowed = booksBorrowed
        self.totalEarned = totalEarned
        self.averageRating = averageRating
    }
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable {
    var pushEnabled: Bool
    var emailEnabled: Bool
    var borrowRequests: Bool
    var dueDateReminders: Bool
    var groupActivity: Bool
    
    init(
        pushEnabled: Bool = true,
        emailEnabled: Bool = true,
        borrowRequests: Bool = true,
        dueDateReminders: Bool = true,
        groupActivity: Bool = true
    ) {
        self.pushEnabled = pushEnabled
        self.emailEnabled = emailEnabled
        self.borrowRequests = borrowRequests
        self.dueDateReminders = dueDateReminders
        self.groupActivity = groupActivity
    }
}

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    var phoneNumber: String  // Primary identifier, required by API
    var phoneVerified: Bool?  // Optional - not returned by API initially
    var name: String
    var email: String?  // Optional
    var bio: String?
    var profileImageUrl: String?
    
    // Group memberships - local only, not returned by API
    var joinedGroupIds: [String]?
    var createdGroupIds: [String]?
    
    // Statistics
    var stats: UserStats
    
    // Settings - local only, not returned by API
    var privacySettings: PrivacySettings?
    var notificationPreferences: NotificationPreferences?
    
    // Device and session - local only
    var deviceToken: String?  // APNs token for push notifications
    var lastTokenUpdate: Date?
    
    // Account status - some fields not returned by API
    var isActive: Bool?
    var createdAt: Date
    var lastLoginAt: Date?
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, phoneNumber, phoneVerified, name, email, bio
        case profileImageUrl
        case joinedGroupIds, createdGroupIds
        case stats
        case privacySettings, notificationPreferences
        case deviceToken, lastTokenUpdate
        case isActive, createdAt, lastLoginAt
    }
    
    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields from API
        id = try container.decode(String.self, forKey: .id)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        name = try container.decode(String.self, forKey: .name)
        stats = try container.decode(UserStats.self, forKey: .stats)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Optional fields from API
        phoneVerified = try container.decodeIfPresent(Bool.self, forKey: .phoneVerified)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        
        // Local-only fields (may be in UserDefaults but not from API)
        joinedGroupIds = try container.decodeIfPresent([String].self, forKey: .joinedGroupIds)
        createdGroupIds = try container.decodeIfPresent([String].self, forKey: .createdGroupIds)
        privacySettings = try container.decodeIfPresent(PrivacySettings.self, forKey: .privacySettings)
        notificationPreferences = try container.decodeIfPresent(NotificationPreferences.self, forKey: .notificationPreferences)
        deviceToken = try container.decodeIfPresent(String.self, forKey: .deviceToken)
        lastTokenUpdate = try container.decodeIfPresent(Date.self, forKey: .lastTokenUpdate)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        lastLoginAt = try container.decodeIfPresent(Date.self, forKey: .lastLoginAt)
    }
    
    // MARK: - Initializers
    
    /// Main initializer for creating a new user
    init(
        id: String = UUID().uuidString,
        phoneNumber: String,
        phoneVerified: Bool? = nil,
        name: String,
        email: String? = nil,
        bio: String? = nil,
        profileImageUrl: String? = nil,
        joinedGroupIds: [String]? = nil,
        createdGroupIds: [String]? = nil,
        stats: UserStats = UserStats(),
        privacySettings: PrivacySettings? = nil,
        notificationPreferences: NotificationPreferences? = nil,
        deviceToken: String? = nil,
        lastTokenUpdate: Date? = nil,
        isActive: Bool? = nil,
        createdAt: Date = Date(),
        lastLoginAt: Date? = nil
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.phoneVerified = phoneVerified
        self.name = name
        self.email = email
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.joinedGroupIds = joinedGroupIds
        self.createdGroupIds = createdGroupIds
        self.stats = stats
        self.privacySettings = privacySettings
        self.notificationPreferences = notificationPreferences
        self.deviceToken = deviceToken
        self.lastTokenUpdate = lastTokenUpdate
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}

// MARK: - Helper Properties
extension User {
    /// Formatted display rating
    var displayRating: String {
        if stats.averageRating > 0 {
            return String(format: "%.1f", stats.averageRating)
        }
        return "No ratings yet"
    }
    
    /// Total groups (joined + created)
    var totalGroups: Int {
        let joined = joinedGroupIds ?? []
        let created = createdGroupIds ?? []
        return Set(joined + created).count
    }
    
    /// Check if user is a member of a specific group
    func isMemberOf(groupId: String) -> Bool {
        let joined = joinedGroupIds ?? []
        let created = createdGroupIds ?? []
        return joined.contains(groupId) || created.contains(groupId)
    }
    
    /// Check if user created a specific group
    func isCreatorOf(groupId: String) -> Bool {
        let created = createdGroupIds ?? []
        return created.contains(groupId)
    }
}

// MARK: - Local Storage
extension User {
    /// Save user to UserDefaults for offline access
    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    /// Load user from UserDefaults
    static func loadFromUserDefaults() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser") else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(User.self, from: data)
    }
    
    /// Clear user from UserDefaults (logout)
    static func clearFromUserDefaults() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

// MARK: - Mock Data
extension User {
    static let mockUser = User(
        id: "usr_demo",
        phoneNumber: "+919876543210",
        phoneVerified: true,
        name: "Demo User",
        email: "demo@example.com",
        bio: "Book enthusiast and avid reader",
        joinedGroupIds: ["club1", "club2"],
        createdGroupIds: ["club1"],
        stats: UserStats(
            booksShared: 8,
            successfulLends: 15,
            booksBorrowed: 12,
            totalEarned: 650,
            averageRating: 4.7
        ),
        privacySettings: PrivacySettings(),
        notificationPreferences: NotificationPreferences(),
        isActive: true
    )
    
    static let mockUsers: [User] = [
        User(
            id: "1",
            phoneNumber: "+919876543211",
            phoneVerified: true,
            name: "John Smith",
            stats: UserStats(booksShared: 12, averageRating: 4.8),
            isActive: true
        ),
        User(
            id: "2",
            phoneNumber: "+919876543212",
            phoneVerified: true,
            name: "Sarah Johnson",
            stats: UserStats(booksShared: 8, averageRating: 4.9),
            isActive: true
        ),
        User(
            id: "3",
            phoneNumber: "+919876543213",
            phoneVerified: true,
            name: "Alex Rodriguez",
            stats: UserStats(booksShared: 15, averageRating: 4.6),
            isActive: true
        )
    ]
}
