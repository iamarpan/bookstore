import Foundation

@MainActor
class PublicProfileViewModel: ObservableObject {
    @Published var profile: PublicUserProfile?
    @Published var books: [Book] = []
    @Published var isLoading = true  // Start true so view shows spinner immediately
    @Published var errorMessage: String?

    private let userId: String
    private let userService = UserService()

    init(userId: String) {
        self.userId = userId
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load profile and books in parallel
            async let profileFetch = userService.fetchPublicProfile(userId: userId)
            async let booksFetch = userService.fetchUserBooks(userId: userId)

            let (fetchedProfile, fetchedBooks) = try await (profileFetch, booksFetch)
            profile = fetchedProfile
            books = fetchedBooks
        } catch {
            errorMessage = "Could not load profile. Please try again."
            print("❌ PublicProfileViewModel error: \(error)")
        }

        isLoading = false
    }
}
