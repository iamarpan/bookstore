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
    var phoneNumber: String  // Primary identifier, now required
    var phoneVerified: Bool
    var name: String
    var email: String?  // Optional
    var bio: String?
    var profileImageUrl: String?
    
    // Group memberships
    var joinedGroupIds: [String]
    var createdGroupIds: [String]
    
    // Statistics
    var stats: UserStats
    
    // Settings
    var privacySettings: PrivacySettings
    var notificationPreferences: NotificationPreferences
    
    // Device and session
    var deviceToken: String?  // APNs token for push notifications
    var lastTokenUpdate: Date?
    
    // Account status
    var isActive: Bool
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
    
    // MARK: - Initializers
    
    /// Main initializer for creating a new user
    init(
        id: String = UUID().uuidString,
        phoneNumber: String,
        phoneVerified: Bool = false,
        name: String,
        email: String? = nil,
        bio: String? = nil,
        profileImageUrl: String? = nil,
        joinedGroupIds: [String] = [],
        createdGroupIds: [String] = [],
        stats: UserStats = UserStats(),
        privacySettings: PrivacySettings = PrivacySettings(),
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        deviceToken: String? = nil,
        lastTokenUpdate: Date? = nil,
        isActive: Bool = true,
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
        Set(joinedGroupIds + createdGroupIds).count
    }
    
    /// Check if user is a member of a specific group
    func isMemberOf(groupId: String) -> Bool {
        joinedGroupIds.contains(groupId) || createdGroupIds.contains(groupId)
    }
    
    /// Check if user created a specific group
    func isCreatorOf(groupId: String) -> Bool {
        createdGroupIds.contains(groupId)
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
        )
    )
    
    static let mockUsers: [User] = [
        User(
            id: "1",
            phoneNumber: "+919876543211",
            phoneVerified: true,
            name: "John Smith",
            stats: UserStats(booksShared: 12, averageRating: 4.8)
        ),
        User(
            id: "2",
            phoneNumber: "+919876543212",
            phoneVerified: true,
            name: "Sarah Johnson",
            stats: UserStats(booksShared: 8, averageRating: 4.9)
        ),
        User(
            id: "3",
            phoneNumber: "+919876543213",
            phoneVerified: true,
            name: "Alex Rodriguez",
            stats: UserStats(booksShared: 15, averageRating: 4.6)
        )
    ]
}
