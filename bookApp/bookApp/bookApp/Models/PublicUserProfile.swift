import Foundation

/// Public-safe user profile returned by GET /users/:id.
/// Contains only fields safe to display publicly (no phone, email, device token, etc.)
struct PublicUserProfile: Codable, Identifiable {
    let id: String
    let name: String
    let bio: String?
    let profileImageUrl: String?
    let createdAt: Date
    let stats: PublicUserStats

    struct PublicUserStats: Codable {
        let booksShared: Int
        let successfulLends: Int
        let booksBorrowed: Int
        let averageRating: Double
    }

    /// Initials derived from the user's name (for the avatar fallback)
    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    /// Formatted member-since string, e.g. "Member since March 2025"
    var memberSince: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Member since \(formatter.string(from: createdAt))"
    }
}
