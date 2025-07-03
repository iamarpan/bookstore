import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authService = FirebaseAuthService()
    @Published var showOTPVerification = false
    @Published var verificationID: String?
    @Published var pendingPhoneNumber = ""
    @Published var otpTimeRemaining = 0
    @Published var canResendOTP = false
    @Published var otpSent = false
    @Published var showError = false
    
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
    
    // MARK: - Phone Authentication Flow
    func sendOTP(phoneNumber: String) async {
        do {
            let verificationID = try await authService.sendOTP(phoneNumber: phoneNumber)
            self.verificationID = verificationID
            self.pendingPhoneNumber = phoneNumber
            self.showOTPVerification = true
            self.otpSent = true
            
            // Start countdown timer
            startOTPTimer()
            
        } catch {
            errorMessage = "Failed to send OTP. Please try again."
            showError = true
        }
    }
    
    func verifyOTP(_ enteredOTP: String) async {
        guard let verificationID = verificationID else { 
            errorMessage = "No verification ID available. Please request OTP again."
            showError = true
            return 
        }
        
        do {
            try await authService.verifyOTP(verificationID: verificationID, 
                                          verificationCode: enteredOTP)
            // User signed in successfully, reset OTP state
            resetOTPState()
            
        } catch AuthError.userNotFound {
            // User doesn't exist, they need to sign up
            // Keep OTP verification open but show signup form
            errorMessage = "User not found. Please complete your profile."
            showError = true
            
        } catch {
            errorMessage = "Invalid OTP. Please try again."
            showError = true
        }
    }
    
    func resendOTP() async {
        guard canResendOTP else { return }
        await sendOTP(phoneNumber: pendingPhoneNumber)
    }
    
    // MARK: - User Registration
    func signUp(name: String, email: String?, phoneNumber: String, society: Society, blockName: String, flatNumber: String) async {
        // First verify OTP if not already verified
        if !otpSent || pendingPhoneNumber != phoneNumber {
            await sendOTP(phoneNumber: phoneNumber)
            return // Wait for OTP verification
        }
        
        // OTP verified, proceed with signup
        let userData = UserData(
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            societyId: society.id,
            societyName: society.name,
            blockName: blockName,
            flatNumber: flatNumber
        )
        
        do {
            try await authService.createUser(userData)
            resetOTPState()
            
        } catch {
            errorMessage = "Signup failed. Please try again."
            showError = true
        }
    }
    
    func completeSignUpAfterOTP(name: String, email: String?, society: Society, blockName: String, flatNumber: String) async {
        let userData = UserData(
            name: name,
            email: email,
            phoneNumber: pendingPhoneNumber,
            societyId: society.id,
            societyName: society.name,
            blockName: blockName,
            flatNumber: flatNumber
        )
        
        do {
            try await authService.createUser(userData)
            resetOTPState()
            
        } catch {
            errorMessage = "Signup failed. Please try again."
            showError = true
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await authService.signOut()
            resetOTPState()
            clearAllAppData()
            
        } catch {
            errorMessage = "Failed to sign out. Please try again."
            showError = true
        }
    }
    
    func quickSignOut() {
        // For emergency logout - attempt to sign out without waiting
        Task {
            try? await authService.signOut()
            resetOTPState()
            clearAllAppData()
        }
    }
    
    // MARK: - OTP Timer Management
    private func startOTPTimer() {
        otpTimeRemaining = 60 // 60 seconds
        canResendOTP = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                if self.otpTimeRemaining > 0 {
                    self.otpTimeRemaining -= 1
                } else {
                    self.canResendOTP = true
                    timer.invalidate()
                }
            }
        }
    }
    
    func resetOTPState() {
        showOTPVerification = false
        otpSent = false
        pendingPhoneNumber = ""
        verificationID = nil
        otpTimeRemaining = 0
        canResendOTP = false
    }
    
    // MARK: - Data Management
    private func clearAllAppData() {
        // Clear any cached data
        errorMessage = nil
        showError = false
        resetOTPState()
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
} 