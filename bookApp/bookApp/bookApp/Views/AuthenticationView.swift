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
                    TextField("Phone Number", text: $authViewModel.phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    
                    Button {
                        Task {
                            await authViewModel.sendOTP()
                            otpSent = true
                        }
                    } label: {
                        Text("Send OTP")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.primaryAccent)
                            .cornerRadius(12)
                    }
                    .disabled(!authViewModel.isPhoneValid)
                } else {
                    // OTP Field
                    TextField("Enter OTP", text: $authViewModel.otp)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    
                    Button {
                        Task {
                            await authViewModel.verifyOTP()
                        }
                    } label: {
                        Text("Verify OTP")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.primaryAccent)
                            .cornerRadius(12)
                    }
                    .disabled(!authViewModel.isOTPValid)
                    
                    Button("Resend OTP") {
                        Task {
                            await authViewModel.sendOTP()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryAccent)
                }
                
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
                        .scaleEffect(1.2)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Dev Mode: Mock Login
            #if DEBUG
            Button("Mock Login (Dev)") {
                authViewModel.mockLogin()
            }
            .font(.caption)
            .foregroundColor(.orange)
            .padding(.bottom, 20)
            #endif
            
            // Privacy Notice
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                
                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Handle terms of service
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryAccent)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    
                    Button("Privacy Policy") {
                        // Handle privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryAccent)
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
                        
                        TextField("Enter your full name", text: $authViewModel.name)
                            .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    }
                    
                    // Phone Number Field (Optional for extra validation)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                        
                        TextField("Enter your phone number", text: $authViewModel.phoneNumber)
                            .keyboardType(.phonePad)
                            .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
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
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.primaryAccent)
                        .cornerRadius(12)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!authViewModel.isRegistrationValid || authViewModel.isLoading)
                    .opacity(authViewModel.isRegistrationValid && !authViewModel.isLoading ? 1.0 : 0.6)
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
            // Logo/Icon
            VStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.primaryAccent)
                
                Text("Book Club")
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

struct CustomTextFieldStyle: TextFieldStyle {
    let isDarkMode: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(AppTheme.colorCardBackground(for: isDarkMode))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.colorTertiaryText(for: isDarkMode).opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager())
} 