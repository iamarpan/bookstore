import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if authViewModel.showRegistrationForm {
                    // Registration Form
                    RegistrationView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else {
                    // Phone OTP Sign-In View
                    PhoneSignInView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                }
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.showError = false
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An unknown error occurred")
        }
    }
}

struct PhoneSignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var otpSent = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            AuthHeaderView(isDarkMode: themeManager.isDarkMode)
            
            Spacer()
            
            // Phone Sign-In Section
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    
                    Text(otpSent ? "Enter the OTP sent to your phone" : "Enter your phone number to continue")
                        .font(.body)
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if !otpSent {
                    // Phone Number Field
                    TextField("Phone Number", text: $authViewModel.phoneNumber.animation(nil))
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .autocorrectionDisabled()
                        .appTextFieldStyle(isDarkMode: themeManager.isDarkMode)
                    
                    Button {
                        Task {
                            await authViewModel.sendOTP()
                            otpSent = true
                        }
                    } label: {
                        Text("Send OTP")
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: authViewModel.isPhoneValid))
                    .disabled(!authViewModel.isPhoneValid)
                } else {
                    // OTP Field
                    TextField("Enter OTP", text: $authViewModel.otp.animation(nil))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .appTextFieldStyle(isDarkMode: themeManager.isDarkMode)
                    
                    Button {
                        Task {
                            await authViewModel.verifyOTP()
                        }
                    } label: {
                        Text("Verify OTP")
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: authViewModel.isOTPValid))
                    .disabled(!authViewModel.isOTPValid)
                    
                    Button("Resend OTP") {
                        Task {
                            await authViewModel.sendOTP()
                        }
                    }
                    .buttonStyle(TertiaryButtonStyle())
                }
                
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
                        .scaleEffect(1.2)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Privacy Notice
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                
                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Handle terms of service
                    }
                    .buttonStyle(TertiaryButtonStyle())
                    .font(.caption)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    
                    Button("Privacy Policy") {
                        // Handle privacy policy
                    }
                    .buttonStyle(TertiaryButtonStyle())
                    .font(.caption)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Complete Your Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                
                Text("Set up your account and join a club")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            // Registration Form
            ScrollView {
                VStack(spacing: 24) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                        
                        TextField("Enter your full name", text: $authViewModel.name.animation(nil))
                            .textContentType(.name)
                            .appTextFieldStyle(isDarkMode: themeManager.isDarkMode)
                    }
                    
                    // Phone Number Field (Optional for extra validation)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                        
                        TextField("Enter your phone number", text: $authViewModel.phoneNumber.animation(nil))
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .appTextFieldStyle(isDarkMode: themeManager.isDarkMode)
                    }
                    
                    // Note: Club joining will be implemented later
                    Text("You'll be able to join or create clubs after registration")
                        .font(.caption)
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        .padding(.vertical, 8)
                    
                    // Complete Registration Button
                    Button {
                        Task {
                            await authViewModel.verifyOTP()
                        }
                    } label: {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Complete Registration")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(isEnabled: authViewModel.isRegistrationValid && !authViewModel.isLoading))
                    .disabled(!authViewModel.isRegistrationValid || authViewModel.isLoading)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
            }
        }
    }
}

struct AuthHeaderView: View {
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // App Logo
            VStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                Text("BookShare")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                
                Text("Create or join clubs to share books")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 32)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager())
} 