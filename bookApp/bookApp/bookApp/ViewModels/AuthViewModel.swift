import Foundation

// Simplified AuthViewModel for compatibility (no actual auth needed)
@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User? = User.mockUser
    
    init() {
        // Always use mock user
        currentUser = User.mockUser
    }
} 