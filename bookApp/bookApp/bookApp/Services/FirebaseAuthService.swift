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
    
    init() {
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
        guard let currentAuthUser = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
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
    
    private func checkUserExists(uid: String) async throws -> Bool {
        let document = try await db.collection("users").document(uid).getDocument()
        return document.exists
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