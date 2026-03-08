import Foundation

/// Service for fetching public user profiles and their books.
class UserService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    /// Fetch the public profile of any user by their ID.
    func fetchPublicProfile(userId: String) async throws -> PublicUserProfile {
        try await apiClient.get("/users/\(userId)")
    }

    /// Fetch all books listed by a user.
    func fetchUserBooks(userId: String) async throws -> [Book] {
        try await apiClient.get("/users/\(userId)/books")
    }
}
