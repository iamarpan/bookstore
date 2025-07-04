import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

@MainActor
class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // Development mode flag
    private var isDevelopmentMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // Store the OTP code for consistent mock user IDs
    private var mockOTPCode: String = "123456"
    
    init() {
        // In development mode, restore any saved mock authentication state
        if isDevelopmentMode {
            // Clear any potentially corrupted authentication state first
            clearCorruptedAuthState()
            restoreMockAuthState()
        }
        
        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserData(uid: user.uid)
                    // Update FCM token when user signs in
                    await self?.updateFCMToken()
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Phone Authentication
    func sendOTP(phoneNumber: String) async throws -> String {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Development mode: use mock verification
        if isDevelopmentMode {
            print("🧪 Development mode: Using mock OTP verification")
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            return "mock-verification-id"
        }
        
        do {
            let verificationID = try await PhoneAuthProvider.provider()
                .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
            
            return verificationID
        } catch {
            errorMessage = "Failed to send OTP. Please try again."
            throw error
        }
    }
    
    func verifyOTP(verificationID: String, verificationCode: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Development mode: use mock verification
        if isDevelopmentMode {
            print("🧪 Development mode: Using mock OTP verification")
            print("🔓 Accepting any OTP code: \(verificationCode)")
            
            // Store the OTP code for consistent user ID
            mockOTPCode = verificationCode
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Mock user ID for development
            let mockUserId = "mock-user-" + verificationCode
            
            // In development mode, check if user exists but don't fail
            let userExists = try await checkUserExists(uid: mockUserId)
            
            if userExists {
                // User exists - sign them in directly
                print("🧪 Existing mock user found, signing in...")
                do {
                    let userData = try await loadExistingUserData(uid: mockUserId)
                    if let user = userData {
                        self.currentUser = user
                        self.isAuthenticated = true
                        
                        // Save mock auth state for persistence
                        saveMockAuthState(user)
                        
                        print("🎉 User signed in successfully: \(user.name)")
                        return
                    } else {
                        print("⚠️ User document exists but data is invalid")
                        throw AuthError.userNotFound
                    }
                } catch {
                    print("❌ Error loading existing user data: \(error)")
                    throw AuthError.userNotFound
                }
            }
            
            // User doesn't exist - this is expected for signup flow
            // Throw userNotFound so the app knows to show signup
            print("🧪 New user - OTP verified, needs to sign up...")
            throw AuthError.userNotFound
        }
        
        do {
            let credential = PhoneAuthProvider.provider()
                .credential(withVerificationID: verificationID,
                           verificationCode: verificationCode)
            
            let result = try await auth.signIn(with: credential)
            
            // Check if user exists in Firestore
            let userExists = try await checkUserExists(uid: result.user.uid)
            if !userExists {
                throw AuthError.userNotFound
            }
            
            // User exists, load their data
            await loadUserData(uid: result.user.uid)
            
        } catch {
            if let authError = error as? AuthError {
                throw authError
            } else {
                errorMessage = "Invalid OTP. Please try again."
                throw AuthError.invalidOTP
            }
        }
    }
    
    // MARK: - User Management
    func createUser(_ userData: UserData) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Development mode: use mock user creation
        if isDevelopmentMode {
            print("🧪 Development mode: Creating mock user")
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Use the same ID as verifyOTP for consistency
            let mockUserId = "mock-user-" + mockOTPCode
            let user = User(
                id: mockUserId,
                name: userData.name,
                email: userData.email,
                phoneNumber: userData.phoneNumber,
                societyId: userData.societyId,
                societyName: userData.societyName,
                blockName: userData.blockName,
                flatNumber: userData.flatNumber,
                fcmToken: nil,
                lastTokenUpdate: nil
            )
            
            // Save to Firestore for consistency
            try await db.collection("users")
                .document(mockUserId)
                .setData(user.toDictionary())
            
            self.currentUser = user
            self.isAuthenticated = true
            
            // Save mock auth state for persistence
            saveMockAuthState(user)
            
            return
        }
        
        guard let currentAuthUser = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        do {
            // Get current FCM token
            let fcmToken = try await getCurrentFCMToken()
            
            let user = User(
                id: currentAuthUser.uid,
                name: userData.name,
                email: userData.email,
                phoneNumber: userData.phoneNumber,
                societyId: userData.societyId,
                societyName: userData.societyName,
                blockName: userData.blockName,
                flatNumber: userData.flatNumber,
                fcmToken: fcmToken,
                lastTokenUpdate: fcmToken != nil ? Date() : nil
            )
            
            try await db.collection("users")
                .document(currentAuthUser.uid)
                .setData(user.toDictionary())
            
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            errorMessage = "Failed to create user profile. Please try again."
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Development mode: simple mock sign out
        if isDevelopmentMode {
            print("🧪 Development mode: Mock sign out")
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
            
            // Clear saved mock auth state
            clearMockAuthState()
            
            return
        }
        
        do {
            // Clear FCM token from user profile before signing out
            if let userId = auth.currentUser?.uid {
                try await clearFCMToken(for: userId)
            }
            
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = "Failed to sign out. Please try again."
            throw error
        }
    }
    
    // MARK: - FCM Token Management
    func updateFCMToken() async {
        guard let userId = auth.currentUser?.uid else {
            print("No authenticated user to update FCM token")
            return
        }
        
        do {
            let fcmToken = try await getCurrentFCMToken()
            if let token = fcmToken {
                try await saveFCMToken(token, for: userId)
            }
        } catch {
            print("Error updating FCM token: \(error)")
        }
    }
    
    private func getCurrentFCMToken() async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            Messaging.messaging().token { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: token)
                }
            }
        }
    }
    
    private func saveFCMToken(_ token: String, for userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "lastTokenUpdate": FieldValue.serverTimestamp()
        ])
        
        print("FCM token saved successfully for user: \(userId)")
    }
    
    private func clearFCMToken(for userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcmToken": FieldValue.delete(),
            "lastTokenUpdate": FieldValue.delete()
        ])
        
        print("FCM token cleared for user: \(userId)")
    }
    
    // MARK: - Private Methods
    private func loadUserData(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let data = document.data() {
                self.currentUser = User.fromDictionary(data, id: uid)
                self.isAuthenticated = true
            }
        } catch {
            print("Error loading user data: \(error)")
            errorMessage = "Failed to load user data."
        }
    }
    
    private func loadExistingUserData(uid: String) async throws -> User? {
        let document = try await db.collection("users").document(uid).getDocument()
        if let data = document.data() {
            return User.fromDictionary(data, id: uid)
        }
        return nil
    }
    
    private func checkUserExists(uid: String) async throws -> Bool {
        let document = try await db.collection("users").document(uid).getDocument()
        return document.exists
    }
    
    private func restoreMockAuthState() {
        // Check if there's a saved mock user in UserDefaults
        do {
            guard let userData = UserDefaults.standard.data(forKey: "MockAuthUser") else {
                print("🧪 No saved mock authentication state found")
                return
            }
            
            guard let userDict = try JSONSerialization.jsonObject(with: userData, options: []) as? [String: Any] else {
                print("⚠️ Invalid saved authentication data, clearing...")
                clearMockAuthState()
                return
            }
            
            guard let user = User.fromUserDefaultsDictionary(userDict) else {
                print("⚠️ Could not restore user from saved data, clearing...")
                clearMockAuthState()
                return
            }
            
            print("🧪 Restoring mock authentication state for user: \(user.name)")
            self.currentUser = user
            self.isAuthenticated = true
            
        } catch {
            print("❌ Error restoring mock authentication state: \(error)")
            print("🧪 Clearing corrupted authentication data...")
            clearMockAuthState()
        }
    }
    
    private func saveMockAuthState(_ user: User) {
        // Save the user data to UserDefaults for persistence using JSON-safe dictionary
        do {
            let jsonSafeDict = user.toUserDefaultsDictionary()
            let userData = try JSONSerialization.data(withJSONObject: jsonSafeDict, options: [])
            UserDefaults.standard.set(userData, forKey: "MockAuthUser")
            print("🧪 Mock authentication state saved for user: \(user.name)")
        } catch {
            print("❌ Failed to save mock authentication state: \(error)")
        }
    }
    
    private func clearMockAuthState() {
        // Clear the saved mock authentication state
        UserDefaults.standard.removeObject(forKey: "MockAuthUser")
        print("🧪 Mock authentication state cleared")
    }
    
    private func clearCorruptedAuthState() {
        // Check if there's any corrupted authentication data
        if let userData = UserDefaults.standard.data(forKey: "MockAuthUser") {
            do {
                let _ = try JSONSerialization.jsonObject(with: userData, options: [])
                // If we can parse it as JSON, it's probably fine
                print("🧪 Existing authentication data appears valid")
            } catch {
                // If we can't parse it, clear the corrupted data
                print("⚠️ Found corrupted authentication data, clearing...")
                clearMockAuthState()
            }
        }
    }
}

// MARK: - UserData Structure
struct UserData {
    let name: String
    let email: String?
    let phoneNumber: String
    let societyId: String
    let societyName: String
    let blockName: String
    let flatNumber: String
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case userNotFound
    case notAuthenticated
    case invalidOTP
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please sign up first."
        case .notAuthenticated:
            return "User not authenticated."
        case .invalidOTP:
            return "Invalid OTP. Please try again."
        }
    }
} 