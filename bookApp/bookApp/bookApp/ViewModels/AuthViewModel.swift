import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authService = FirebaseAuthService()
    @Published var showRegistrationForm = false
    @Published var showError = false
    @Published var needsRegistration = false
    
    // User profile data for registration
    @Published var name: String = ""
    
    // Available societies for selection
    @Published var availableSocieties: [Society] = Society.mockSocieties
    
    // Computed properties that delegate to authService
    var currentUser: User? { authService.currentUser }
    var isAuthenticated: Bool { authService.isAuthenticated }
    var isLoading: Bool { authService.isLoading }
    var errorMessage: String? { 
        get { authService.errorMessage }
        set { authService.errorMessage = newValue }
    }
    
    init() {
        // Check for existing authentication session
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Firebase Auth automatically handles auth state persistence
        // The authService will automatically update isAuthenticated when the state changes
    }
    
    // MARK: - Google Sign-In Flow
    func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
            // User signed in successfully
            needsRegistration = false
            showRegistrationForm = false
            
        } catch AuthError.userNotFound {
            // User needs to complete registration
            self.name = authService.googleUserName ?? ""
            needsRegistration = true
            showRegistrationForm = true
            
            // Clear any error messages since this is expected behavior
            errorMessage = nil
            showError = false
            
        } catch {
            errorMessage = "Google Sign-In failed. Please try again."
            showError = true
        }
    }
    
    // MARK: - User Registration
    func completeRegistration(mobile: String, society: Society?, floor: String, flat: String) async {
        guard let society = society else {
            errorMessage = "Please select a society."
            showError = true
            return
        }

        let userData = UserData(
            name: self.name,
            email: authService.googleUserEmail,
            mobile: mobile,
            societyId: society.id,
            societyName: society.name,
            floor: floor,
            flat: flat
        )
        
        do {
            try await authService.completeRegistration(userData: userData)
            
            // Clear all registration-related state
            needsRegistration = false
            showRegistrationForm = false
            
            print("🎉 Registration completed successfully, navigating to home")
            
        } catch {
            errorMessage = "Registration failed. Please try again."
            showError = true
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await authService.signOut()
            resetRegistrationState()
            
        } catch {
            errorMessage = "Failed to sign out. Please try again."
            showError = true
        }
    }
    
    func quickSignOut() {
        // For emergency logout - attempt to sign out without waiting
        Task {
            try? await authService.signOut()
            resetRegistrationState()
        }
    }
    
    // MARK: - State Management
    func resetRegistrationState() {
        showRegistrationForm = false
        needsRegistration = false
        errorMessage = nil
        showError = false
        name = ""
    }
    
    // MARK: - Data Management
    private func clearAllAppData() {
        // Clear any cached data
        errorMessage = nil
        showError = false
        resetRegistrationState()
    }
    
    // MARK: - Validation Methods
    func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        // Basic phone number validation for Indian numbers
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Development Helpers
    #if DEBUG
    /// Clear all authentication data (development only)
    func clearAllAuthenticationData() {
        resetRegistrationState()
        clearAllAppData()
        print("🧪 Development: All authentication data cleared")
    }
    
    /// Get debug information about current state
    func getDebugInfo() -> String {
        return """
        Auth Debug Info:
        - Is Authenticated: \(isAuthenticated)
        - Current User: \(currentUser?.name ?? "None")
        - Needs Registration: \(needsRegistration)
        - Show Registration Form: \(showRegistrationForm)
        - Current Name: \(name)
        - Error Message: \(errorMessage ?? "None")
        """
    }
    #endif
} 