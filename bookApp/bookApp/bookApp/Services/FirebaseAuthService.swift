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
    // Book Club Info
    let isCreatingClub: Bool
    let clubName: String?
    let clubDescription: String?
    let inviteCode: String?
}

// MARK: - Authentication Errors
enum AuthError: Error, LocalizedError {
    case googleSignInFailed
    case userNotFound
    case invalidCredentials
    case networkError
    case unknown
    case invalidInviteCode
    case clubCreationError
    
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
        case .invalidInviteCode:
            return "Invalid invite code. Please check and try again."
        case .clubCreationError:
            return "Failed to create book club. Please try again."
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
                print("❌ Google Sign-In Error: Could not get Client ID from FirebaseApp")
                throw AuthError.googleSignInFailed
            }
            
            // Configure Google Sign-In
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Get the root view controller
            // improved lookup for SwiftUI
            guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
                  let presentingViewController = window.rootViewController else {
                print("❌ Google Sign-In Error: Could not find root view controller")
                throw AuthError.googleSignInFailed
            }
            
            // Start Google Sign-In flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            // Store Google user info
            self.googleUserName = result.user.profile?.name
            self.googleUserEmail = result.user.profile?.email
            
            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ Google Sign-In Error: Could not get ID Token")
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
                
                // Check if user needs to complete Book Club onboarding
                if currentUser?.activeBookClubId == nil {
                    print("⚠️ User exists but needs to join/create a book club")
                    throw AuthError.userNotFound // This will trigger the registration form
                }
            } else {
                // User needs to complete registration
                throw AuthError.userNotFound
            }
            
        } catch {
            print("❌ Google Sign-In Error: \(error.localizedDescription)")
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
            
            var bookClubId: String
            
            // Handle Book Club Logic
            if userData.isCreatingClub {
                // Create new club
                let inviteCode = String(Int.random(in: 100000...999999))
                let club = BookClub(
                    name: userData.clubName ?? "My Book Club",
                    description: userData.clubDescription ?? "",
                    inviteCode: inviteCode,
                    creatorId: firebaseUser.uid
                )
                
                let docRef = try await db.collection("bookClubs").addDocument(data: club.toDictionary())
                bookClubId = docRef.documentID
                
            } else {
                // Join existing club
                guard let code = userData.inviteCode else {
                    throw AuthError.invalidInviteCode
                }
                
                let snapshot = try await db.collection("bookClubs")
                    .whereField("inviteCode", isEqualTo: code)
                    .limit(to: 1)
                    .getDocuments()
                
                guard let document = snapshot.documents.first else {
                    throw AuthError.invalidInviteCode
                }
                
                bookClubId = document.documentID
                
                // Add user to club members
                try await db.collection("bookClubs").document(bookClubId).updateData([
                    "memberIds": FieldValue.arrayUnion([firebaseUser.uid])
                ])
            }
            
            #if targetEnvironment(simulator)
            let fcmToken: String? = nil
            print("📲 Simulator detected. Skipping FCM token fetch for registration.")
            #else
            // Get FCM token only on a real device
            let fcmToken = try await getCurrentFCMToken()
            #endif
            
            // Check if user already exists
            let userDoc = try await db.collection("users").document(firebaseUser.uid).getDocument()
            
            if userDoc.exists {
                // Update existing user with Book Club info
                try await db.collection("users")
                    .document(firebaseUser.uid)
                    .updateData([
                        "name": userData.name,
                        "mobile": userData.mobile,
                        "bookClubIds": FieldValue.arrayUnion([bookClubId]),
                        "activeBookClubId": bookClubId,
                        "lastLoginAt": FieldValue.serverTimestamp(),
                        "fcmToken": fcmToken ?? "",
                        "lastTokenUpdate": fcmToken != nil ? FieldValue.serverTimestamp() : NSNull()
                    ])
                
                print("✅ Existing user updated with Book Club: \(userData.name)")
            } else {
                // Create new user object
                let user = User(
                    id: firebaseUser.uid,
                    name: userData.name,
                    email: userData.email ?? firebaseUser.email,
                    mobile: userData.mobile,
                    bookClubIds: [bookClubId],
                    activeBookClubId: bookClubId,
                    profileImageURL: firebaseUser.photoURL?.absoluteString,
                    isActive: true,
                    createdAt: Date(),
                    lastLoginAt: Date(),
                    fcmToken: fcmToken,
                    lastTokenUpdate: fcmToken != nil ? Date() : nil
                )
                
                // Save to Firestore
                try await db.collection("users")
                    .document(firebaseUser.uid)
                    .setData(user.toDictionary())
                
                print("✅ New user registration completed: \(user.name)")
            }
            
            // Reload user data
            await loadUserData(for: firebaseUser.uid)
            
            print("✅ User registration/update completed successfully")
            
        } catch {
            errorMessage = "Failed to complete registration: \(error.localizedDescription)"
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
            
            #if !targetEnvironment(simulator)
            // Update FCM token only on real devices
            try await updateFCMToken(for: uid)
            #endif
            
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