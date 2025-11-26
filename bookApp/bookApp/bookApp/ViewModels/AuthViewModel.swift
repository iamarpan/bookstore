import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authService = AuthService()
    @Published var showRegistrationForm = false
    @Published var showError = false
    @Published var needsRegistration = false
    
    // User profile data for OTP registration
    @Published var phoneNumber: String = ""
    @Published var otp: String = ""
    @Published var name: String = ""
    @Published var bio: String = ""
    
    // Validation
    var isPhoneValid: Bool {
        phoneNumber.count >= 10
    }
    
    var isOTPValid: Bool {
        otp.count == 4 || otp.count == 6
    }
    
    var isRegistrationValid: Bool {
        !name.isEmpty && isPhoneValid
    }
    
    // Computed properties that delegate to authService
    var currentUser: User? { authService.currentUser }
    var isAuthenticated: Bool { authService.isAuthenticated }
    var isLoading: Bool { authService.isLoading }
    var errorMessage: String? {
        get { authService.error }
        set { authService.error = newValue }
    }
    
    init() {
        // Check for existing authentication session
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Auth service automatically loads user from UserDefaults
    }
    
    // MARK: - Phone OTP Flow
    
    func sendOTP() async {
        guard isPhoneValid else {
            errorMessage = "Please enter a valid phone number"
            showError = true
            return
        }
        
        do {
            try await authService.sendOTP(to: phoneNumber)
            print("✅ OTP sent successfully")
        } catch {
            errorMessage = "Failed to send OTP: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func verifyOTP() async {
        guard isOTPValid else {
            errorMessage = "Please enter a valid OTP"
            showError = true
            return
        }
        
        do {
            // Try verification (this will auto-register if new user)
            try await authService.verifyOTP(
                phoneNumber: phoneNumber,
                otp: otp,
                name: name.isEmpty ? nil : name,
                bio: bio.isEmpty ? nil : bio
            )
            
            // Success!
            needsRegistration = false
            showRegistrationForm = false
            resetForm()
            
        } catch {
            errorMessage = "Verification failed: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        authService.logout()
        resetForm()
    }
    
    // MARK: - State Management
    func resetForm() {
        phoneNumber = ""
        otp = ""
        name = ""
        bio = ""
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Validation Methods
    func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        // Basic phone number validation for Indian numbers
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    // MARK: - Mock Login (for development)
    func mockLogin() {
        authService.mockLogin()
        needsRegistration = false
        showRegistrationForm = false
    }
}