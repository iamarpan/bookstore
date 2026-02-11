import Foundation

// MARK: - Group Member Model

/// Represents a member of a group with their role and user information
struct GroupMember: Identifiable, Codable {
    let id: String
    let userId: String
    let role: MemberRole
    let joinedAt: Date
    let user: MemberUser
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, userId, role, joinedAt, user
    }
}

// MARK: - Member User Info

/// User information included in group member response
struct MemberUser: Codable {
    let id: String
    let name: String
    let profileImageUrl: String?
    let booksShared: Int
    let averageRating: Double?
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, name, profileImageUrl, booksShared, averageRating
    }
    
    /// Formatted rating string
    var formattedRating: String {
        guard let rating = averageRating else {
            return "No ratings yet"
        }
        return String(format: "%.1f", rating)
    }
}

// MARK: - Mock Data
extension GroupMember {
    static let mockMembers: [GroupMember] = [
        GroupMember(
            id: "mem1",
            userId: "usr_demo",
            role: .creator,
            joinedAt: Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date(),
            user: MemberUser(
                id: "usr_demo",
                name: "John Doe",
                profileImageUrl: nil,
                booksShared: 12,
                averageRating: 4.5
            )
        ),
        GroupMember(
            id: "mem2",
            userId: "usr_2",
            role: .admin,
            joinedAt: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
            user: MemberUser(
                id: "usr_2",
                name: "Jane Smith",
                profileImageUrl: nil,
                booksShared: 8,
                averageRating: 4.8
            )
        ),
        GroupMember(
            id: "mem3",
            userId: "usr_3",
            role: .moderator,
            joinedAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            user: MemberUser(
                id: "usr_3",
                name: "Alex Johnson",
                profileImageUrl: nil,
                booksShared: 5,
                averageRating: 4.2
            )
        ),
        GroupMember(
            id: "mem4",
            userId: "usr_4",
            role: .member,
            joinedAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
            user: MemberUser(
                id: "usr_4",
                name: "Sarah Williams",
                profileImageUrl: nil,
                booksShared: 3,
                averageRating: nil
            )
        )
    ]
}
