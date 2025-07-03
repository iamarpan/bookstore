import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isAuthenticated = false
    
    // OTP verification states
    @Published var showOTPVerification = false
    @Published var otpSent = false
    @Published var pendingPhoneNumber = ""
    @Published var generatedOTP = "" // In real app, this would be on backend
    @Published var otpTimeRemaining = 0
    @Published var canResendOTP = false
    
    // Available societies for selection
    @Published var availableSocieties: [Society] = Society.mockSocieties
    
    init() {
        // Check for existing user session
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // In a real app, this would check UserDefaults or Keychain
        // For now, we'll start with no user to show the authentication flow
        isAuthenticated = false
        currentUser = nil
    }
    
    func signUp(name: String, email: String?, phoneNumber: String, society: Society, blockName: String, flatNumber: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First verify OTP if not already verified
            if !otpSent || pendingPhoneNumber != phoneNumber {
                await sendOTP(phoneNumber: phoneNumber)
                return // Wait for OTP verification
            }
            
            // OTP verified, proceed with signup
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Create new user
            let newUser = User(
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                societyId: society.id,
                societyName: society.name,
                blockName: blockName,
                flatNumber: flatNumber
            )
            
            // Simulate successful signup
            currentUser = newUser
            isAuthenticated = true
            
            // In a real app, save to UserDefaults/Keychain
            saveUserSession(user: newUser)
            resetOTPState()
            
        } catch {
            errorMessage = "Signup failed. Please try again."
            showError = true
        }
        
        isLoading = false
    }
    
    func completeSignUpAfterOTP(name: String, email: String?, society: Society, blockName: String, flatNumber: String) async {
        await signUp(name: name, email: email, phoneNumber: pendingPhoneNumber, society: society, blockName: blockName, flatNumber: flatNumber)
    }
    
    func sendOTP(phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call to send OTP
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Generate a mock OTP (in real app, this would be done on backend)
            let otp = String(format: "%06d", Int.random(in: 100000...999999))
            generatedOTP = otp
            pendingPhoneNumber = phoneNumber
            
            // Show OTP verification screen
            showOTPVerification = true
            otpSent = true
            
            // Start countdown timer
            startOTPTimer()
            
            print("DEBUG: Generated OTP for \(phoneNumber): \(otp)") // For demo purposes
            
        } catch {
            errorMessage = "Failed to send OTP. Please try again."
            showError = true
        }
        
        isLoading = false
    }
    
    func verifyOTP(_ enteredOTP: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            if enteredOTP == generatedOTP {
                // OTP is correct, proceed with authentication
                await completeAuthentication(phoneNumber: pendingPhoneNumber)
            } else {
                errorMessage = "Invalid OTP. Please try again."
                showError = true
            }
            
        } catch {
            errorMessage = "OTP verification failed. Please try again."
            showError = true
        }
        
        isLoading = false
    }
    
    func resendOTP() async {
        guard canResendOTP else { return }
        await sendOTP(phoneNumber: pendingPhoneNumber)
    }
    
    private func completeAuthentication(phoneNumber: String) async {
        // Check if user exists (for sign in) or proceed with signup
        if phoneNumber == User.mockUser.phoneNumber {
            currentUser = User.mockUser
            isAuthenticated = true
            saveUserSession(user: User.mockUser)
            resetOTPState()
        } else {
            // User doesn't exist, they need to sign up
            // Keep OTP verification open and show signup form
            errorMessage = "User not found. Please complete your profile."
            showError = true
        }
    }
    
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
        generatedOTP = ""
        otpTimeRemaining = 0
        canResendOTP = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            // Simulate logout API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Clear all user data
            currentUser = nil
            isAuthenticated = false
            
            // Reset OTP state
            resetOTPState()
            
            // Clear user session
            clearUserSession()
            
            // Clear any cached data (in real app, this would clear more data)
            clearAllAppData()
            
        } catch {
            errorMessage = "Failed to sign out. Please try again."
            showError = true
        }
        
        isLoading = false
    }
    
    func quickSignOut() {
        // Immediate logout without loading states (for emergency situations)
        currentUser = nil
        isAuthenticated = false
        resetOTPState()
        clearUserSession()
        clearAllAppData()
    }
    
    private func clearAllAppData() {
        // In a real app, this would clear:
        // - UserDefaults
        // - Keychain data
        // - Cached images
        // - Downloaded books data
        // - Notification tokens
        // - Any temporary files
        
        // For now, just reset basic state
        errorMessage = nil
        showError = false
    }
    
    private func saveUserSession(user: User) {
        // In a real app, save to UserDefaults or Keychain
        // For now, just set the authenticated state
        isAuthenticated = true
    }
    
    private func clearUserSession() {
        // In a real app, clear UserDefaults or Keychain
        // For now, just set the authenticated state to false
        isAuthenticated = false
    }
    
    func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        // Basic phone number validation
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