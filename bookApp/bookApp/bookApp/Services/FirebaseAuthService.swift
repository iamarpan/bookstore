import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import GoogleSignIn
import UIKit

// MARK: - User Data for Registration
struct UserData {
    let name: String
    let email: String?
    let mobile: String
    let societyId: String
    let societyName: String
    let floor: String
    let flat: String
}

// MARK: - Authentication Errors
enum AuthError: Error, LocalizedError {
    case googleSignInFailed
    case userNotFound
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again."
        case .userNotFound:
            return "User not found. Please sign up first."
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - Firebase Auth Service with Google Sign-In
@MainActor
class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Properties to hold Google Sign-In user info before registration
    @Published var googleUserName: String?
    @Published var googleUserEmail: String?
    
    private var auth: Auth { Auth.auth() }
    private var db: Firestore { Firestore.firestore() }
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Check for existing user session
        checkAuthenticationState()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication State Management
    
    private func checkAuthenticationState() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserData(for: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get the client ID from Firebase configuration
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleSignInFailed
            }
            
            // Configure Google Sign-In
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Get the root view controller
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = scene.windows.first?.rootViewController else {
                throw AuthError.googleSignInFailed
            }
            
            // Start Google Sign-In flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            // Store Google user info
            self.googleUserName = result.user.profile?.name
            self.googleUserEmail = result.user.profile?.email
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleSignInFailed
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Sign in with Firebase
            let authResult = try await auth.signIn(with: credential)
            
            // Check if user exists in Firestore
            let userExists = try await checkUserExists(uid: authResult.user.uid)
            
            if userExists {
                // Load existing user data
                await loadUserData(for: authResult.user.uid)
            } else {
                // User needs to complete registration
                throw AuthError.userNotFound
            }
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - User Registration
    
    func completeRegistration(userData: UserData) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get current Firebase user
            guard let firebaseUser = auth.currentUser else {
                throw AuthError.invalidCredentials
            }
            
            #if targetEnvironment(simulator)
            let fcmToken: String? = nil
            print("📲 Simulator detected. Skipping FCM token fetch for registration.")
            #else
            // Get FCM token only on a real device
            let fcmToken = try await getCurrentFCMToken()
            #endif
            
            // Create user object
            let user = User(
                id: firebaseUser.uid,
                name: userData.name,
                email: userData.email ?? firebaseUser.email,
                mobile: userData.mobile,
                societyId: userData.societyId,
                societyName: userData.societyName,
                floor: userData.floor,
                flat: userData.flat,
                profileImageURL: firebaseUser.photoURL?.absoluteString,
                fcmToken: fcmToken,
                lastTokenUpdate: fcmToken != nil ? Date() : nil
            )
            
            // Save to Firestore
            try await db.collection("users")
                .document(firebaseUser.uid)
                .setData(user.toDictionary())
            
            // Update current user
            self.currentUser = user
            self.isAuthenticated = true
            
            print("✅ User registration completed successfully: \(user.name)")
            
        } catch {
            errorMessage = "Failed to complete registration. Please try again."
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Clear FCM token from user profile
            if let userId = currentUser?.id {
                try await clearFCMToken(for: userId)
            }
            
            // Sign out from Firebase
            try auth.signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Clear local session
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
            
            print("✅ User signed out successfully")
            
        } catch {
            errorMessage = "Failed to sign out. Please try again."
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func checkUserExists(uid: String) async throws -> Bool {
        let document = try await db.collection("users").document(uid).getDocument()
        return document.exists
    }
    
    private func loadUserData(for uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            guard let data = document.data(),
                  let user = User.fromDictionary(data, id: uid) else {
                print("❌ Failed to load user data")
                return
            }
            
            // Update FCM token if needed
            try await updateFCMToken(for: uid)
            
            self.currentUser = user
            self.isAuthenticated = true
            
            print("✅ User data loaded successfully")
            
        } catch {
            print("❌ Failed to load user data: \(error)")
        }
    }
    
    private func getCurrentFCMToken() async throws -> String? {
        return try await Messaging.messaging().token()
    }
    
    private func updateFCMToken(for userId: String) async throws {
        guard let token = try await getCurrentFCMToken() else { return }
        
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "lastTokenUpdate": Timestamp(date: Date())
        ])
    }
    
    private func clearFCMToken(for userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcmToken": "",
            "lastTokenUpdate": NSNull()
        ])
    }
} 