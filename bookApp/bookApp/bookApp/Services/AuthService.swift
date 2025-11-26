import Foundation

/// Service for authentication operations
@MainActor
class AuthService: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let apiClient: APIClient
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        
        // Load user from local storage
        self.currentUser = User.loadFromUserDefaults()
        self.isAuthenticated = currentUser != nil && apiClient.isAuthenticated()
    }
    
    // MARK: - Phone OTP Authentication
    
    /// Send OTP to phone number
    func sendOTP(to phoneNumber: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct OTPRequest: Codable {
            let phoneNumber: String
        }
        
        struct OTPResponse: Codable {
            let message: String
            let expiresIn: Int
        }
        
        do {
            let request = OTPRequest(phoneNumber: phoneNumber)
            let response: OTPResponse = try await apiClient.post(
                "/auth/send-otp",
                body: request,
                requiresAuth: false
            )
            
            print("✅ OTP sent successfully. Expires in: \(response.expiresIn)s")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Verify OTP and login/register
    func verifyOTP(
        phoneNumber: String,
        otp: String,
        name: String? = nil,
        bio: String? = nil
    ) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct VerifyOTPRequest: Codable {
            let phoneNumber: String
            let otp: String
            let name: String?
            let bio: String?
        }
        
        struct AuthResponse: Codable {
            let accessToken: String
            let refreshToken: String
            let user: User
        }
        
        do {
            let request = VerifyOTPRequest(
                phoneNumber: phoneNumber,
                otp: otp,
                name: name,
                bio: bio
            )
            
            let response: AuthResponse = try await apiClient.post(
                "/auth/verify-otp",
                body: request,
                requiresAuth: false
            )
            
            // Save tokens
            apiClient.saveTokens(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            
            // Save user
            currentUser = response.user
            currentUser?.saveToUserDefaults()
            isAuthenticated = true
            
            print("✅ User authenticated: \(response.user.name)")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - User Profile
    
    /// Fetch current user profile from API
    func fetchCurrentUser() async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let user: User = try await apiClient.get("/users/me")
            
            currentUser = user
            user.saveToUserDefaults()
            
            print("✅ User profile fetched: \(user.name)")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Update user profile
    func updateProfile(
        name: String? = nil,
        bio: String? = nil,
        profileImageUrl: String? = nil
    ) async throws {
        guard currentUser != nil else {
            throw APIError.unauthorized
        }
        
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct UpdateProfileRequest: Codable {
            let name: String?
            let bio: String?
            let profileImageUrl: String?
        }
        
        do {
            let request = UpdateProfileRequest(
                name: name,
                bio: bio,
                profileImageUrl: profileImageUrl
            )
            
            let updatedUser: User = try await apiClient.put(
                "/users/me",
                body: request
            )
            
            currentUser = updatedUser
            updatedUser.saveToUserDefaults()
            
            print("✅ User profile updated")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Logout
    
    /// Logout user
    func logout() {
        apiClient.clearTokens()
        User.clearFromUserDefaults()
        currentUser = nil
        isAuthenticated = false
        
        print("✅ User logged out")
    }
    
    // MARK: - Mock Authentication (for development)
    
    /// Mock login for testing UI without backend
    func mockLogin() {
        let mockUser = User.mockUser
        currentUser = mockUser
        mockUser.saveToUserDefaults()
        isAuthenticated = true
        
        // Save mock tokens
        apiClient.saveTokens(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token"
        )
        
        print("✅ Mock user logged in: \(mockUser.name)")
    }
}
