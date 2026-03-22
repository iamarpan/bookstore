import Foundation
import GoogleSignIn

/// Service for authentication operations
@MainActor
class AuthService: AuthServiceProtocol, ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isGoogleLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let apiClient: APIClient
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        
        // Load user from local storage
        self.currentUser = User.loadFromUserDefaults()
        self.isAuthenticated = currentUser != nil && apiClient.isAuthenticated()
        
        // Force logout if the refresh token is rejected mid-session
        // (secret mismatch, token revoked, or backend env change)
        NotificationCenter.default.addObserver(
            forName: APIClient.sessionExpiredNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("⚠️ AuthService: session expired, forcing logout")
            self?.logout()
        }
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
    
    // MARK: - Google Sign-In
    
    /// Sign in with Google
    func signInWithGoogle() async throws {
        isGoogleLoading = true
        error = nil
        
        defer { isGoogleLoading = false }
        
        // Get the presenting view controller
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }
        
        do {
            // Initiate Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingIdToken
            }
            
            // Send ID token to backend
            try await verifyGoogleToken(idToken: idToken)
            
        } catch let error as GIDSignInError {
            if error.code == .canceled {
                print("User cancelled Google Sign-In")
                return
            }
            self.error = "Google Sign-In failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Verify Google ID token with backend
    private func verifyGoogleToken(idToken: String) async throws {
        struct GoogleSignInRequest: Codable {
            let idToken: String
        }
        
        struct AuthResponse: Codable {
            let accessToken: String
            let refreshToken: String
            let user: User
        }
        
        let request = GoogleSignInRequest(idToken: idToken)
        
        let response: AuthResponse = try await apiClient.post(
            "/auth/google",
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
        
        print("✅ User authenticated via Google: \(response.user.name)")
    }
    
    // MARK: - Logout
    
    /// Logout user
    func logout() {
        apiClient.clearTokens()
        User.clearFromUserDefaults()
        currentUser = nil
        isAuthenticated = false
        
        // Sign out of Google as well
        GIDSignIn.sharedInstance.signOut()
        
        print("✅ User logged out")
    }
    
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noRootViewController
    case missingIdToken
    
    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Unable to present Google Sign-In"
        case .missingIdToken:
            return "Failed to get Google ID token"
        }
    }
}

