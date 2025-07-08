import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if authViewModel.showRegistrationForm {
                    // Registration Form
                    RegistrationView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                } else {
                    // Google Sign-In View
                    GoogleSignInView()
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

struct GoogleSignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            AuthHeaderView(isDarkMode: themeManager.isDarkMode)
            
            Spacer()
            
            // Google Sign-In Section
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome!")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    
                    Text("Sign in with Google to continue")
                        .font(.body)
                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Google Sign-In Button
                Button {
                    Task {
                        await authViewModel.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Continue with Google")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.26, green: 0.52, blue: 0.96),
                                Color(red: 0.13, green: 0.42, blue: 0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0.26, green: 0.52, blue: 0.96).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(authViewModel.isLoading)
                .opacity(authViewModel.isLoading ? 0.7 : 1.0)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                        .scaleEffect(1.2)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Privacy Notice
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(.caption)
                    .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                
                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Handle terms of service
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryGreen)
                    
                    Text("and")
                        .font(.caption)
                        .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                    
                    Button("Privacy Policy") {
                        // Handle privacy policy
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .padding(.bottom, 40)
        }
    }
}

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var mobile = ""
    @State private var selectedSociety: Society?
    @State private var floor = ""
    @State private var flat = ""
    @State private var showSocietyPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Complete Your Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                
                Text("We need a few more details to set up your account")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.horizontal, 32)
            
            // Registration Form
            ScrollView {
                VStack(spacing: 20) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        TextField("Enter your full name", text: $authViewModel.name)
                            .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    }
                    
                    // Mobile Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mobile Number")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        TextField("Enter your mobile number", text: $mobile)
                            .keyboardType(.phonePad)
                            .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                    }
                    
                    // Society Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Society")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        Button {
                            showSocietyPicker = true
                        } label: {
                            HStack {
                                Text(selectedSociety?.name ?? "Select your society")
                                    .foregroundColor(selectedSociety != nil ? AppTheme.dynamicPrimaryText(themeManager.isDarkMode) : AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.dynamicTertiaryText(themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Floor and Flat Row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Floor")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                            
                            TextField("Floor", text: $floor)
                                .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Flat")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                            
                            TextField("Flat", text: $flat)
                                .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                        }
                    }
                    
                    // Complete Registration Button
                    Button {
                        Task {
                            await authViewModel.completeRegistration(
                                mobile: mobile,
                                society: selectedSociety,
                                floor: floor,
                                flat: flat
                            )
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
                        .background(AppTheme.primaryGreen)
                        .cornerRadius(12)
                        .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    .opacity(isFormValid && !authViewModel.isLoading ? 1.0 : 0.6)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
            }
        }
        .sheet(isPresented: $showSocietyPicker) {
            SocietyPickerView(selectedSociety: $selectedSociety, societies: authViewModel.availableSocieties)
                .environmentObject(themeManager)
        }
    }
    
    private var isFormValid: Bool {
        !authViewModel.name.isEmpty && !mobile.isEmpty && selectedSociety != nil && !floor.isEmpty && !flat.isEmpty
    }
}

struct SocietyPickerView: View {
    @Binding var selectedSociety: Society?
    let societies: [Society]
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(societies) { society in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(society.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        if !society.address.isEmpty {
                            Text(society.address)
                                .font(.caption)
                                .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                        }
                    }
                    
                    Spacer()
                    
                    if selectedSociety?.id == society.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(AppTheme.primaryGreen)
                            .fontWeight(.semibold)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSociety = society
                    dismiss()
                }
            }
            .navigationTitle("Select Society")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
                    .foregroundColor(AppTheme.primaryGreen)
                
                Text("Book Club")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
                
                Text("Share books with your neighbors")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
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
            .background(AppTheme.dynamicCardBackground(isDarkMode))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.dynamicTertiaryText(isDarkMode).opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager())
} 