import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode)
                .ignoresSafeArea()
            
            if authViewModel.showOTPVerification {
                // OTP Verification View
                OTPVerificationView(isSignUp: isSignUp)
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            } else if isSignUp {
                // Full-screen SignUp with toggle at bottom
                VStack(spacing: 0) {
                    SignUpView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                    
                    // Toggle at bottom
                    AuthToggleView(isSignUp: $isSignUp, isDarkMode: themeManager.isDarkMode)
                        .padding(.bottom, 40)
                        .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode))
                }
            } else {
                // Original layout for SignIn
                VStack(spacing: 0) {
                    // Header
                    AuthHeaderView(isDarkMode: themeManager.isDarkMode)
                    
                    // SignIn Form
                    SignInView()
                        .environmentObject(authViewModel)
                        .environmentObject(themeManager)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Toggle at bottom
                    AuthToggleView(isSignUp: $isSignUp, isDarkMode: themeManager.isDarkMode)
                        .padding(.bottom, 40)
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

struct AuthHeaderView: View {
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Logo/Icon - Smaller
            VStack(spacing: 8) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.primaryGreen)
                
                Text("BookstoreApp")
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
        .padding(.bottom, 20)
        .padding(.horizontal, 32)
    }
}

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var countryCode = "+91"
    @State private var phoneNumber = ""
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome Back!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                
                Text("Enter your phone number to continue")
                    .font(.body)
                    .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Phone Number Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                
                HStack(spacing: 12) {
                    // Country Code Picker
                    Menu {
                        Button("+91 India") { countryCode = "+91" }
                        Button("+1 USA") { countryCode = "+1" }
                        Button("+44 UK") { countryCode = "+44" }
                        Button("+61 Australia") { countryCode = "+61" }
                        Button("+81 Japan") { countryCode = "+81" }
                        Button("+49 Germany") { countryCode = "+49" }
                        Button("+33 France") { countryCode = "+33" }
                        Button("+86 China") { countryCode = "+86" }
                        Button("+7 Russia") { countryCode = "+7" }
                        Button("+55 Brazil") { countryCode = "+55" }
                    } label: {
                        HStack {
                            Text(countryCode)
                                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .background(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.dynamicTertiaryText(themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Phone Number Input
                    TextField("Enter your phone number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                }
            }
            
            // Sign In Button
            Button {
                Task {
                    await authViewModel.sendOTP(phoneNumber: countryCode + phoneNumber)
                }
            } label: {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(phoneNumber.isEmpty || authViewModel.isLoading)
            .opacity(phoneNumber.isEmpty ? 0.6 : 1.0)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var name = ""
    @State private var email = ""
    @State private var countryCode = "+91"
    @State private var phoneNumber = ""
    @State private var selectedSociety: Society?
    @State private var selectedBlock = ""
    @State private var flatNumber = ""
    @State private var showSocietyPicker = false
    
    var isFormValid: Bool {
        !name.isEmpty &&
        !phoneNumber.isEmpty &&
        selectedSociety != nil &&
        !selectedBlock.isEmpty &&
        !flatNumber.isEmpty &&
        (email.isEmpty || authViewModel.validateEmail(email)) &&
        authViewModel.validatePhoneNumber(countryCode + phoneNumber)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // App Header Section
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Text("BookstoreApp")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        Text("Share books with your neighbors")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // Form Header Section  
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Account")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    
                    Text("Join your society's book sharing community")
                        .font(.body)
                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Form Fields Section
                VStack(spacing: 20) {
                    // Name Field
                    FormField(
                        title: "Full Name",
                        text: $name,
                        placeholder: "Enter your full name",
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    // Email Field (Optional)
                    FormField(
                        title: "Email (Optional)",
                        text: $email,
                        placeholder: "Enter your email",
                        keyboardType: .emailAddress,
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    // Phone Number Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        HStack(spacing: 12) {
                            // Country Code Picker
                            Menu {
                                Button("+91 India") { countryCode = "+91" }
                                Button("+1 USA") { countryCode = "+1" }
                                Button("+44 UK") { countryCode = "+44" }
                                Button("+61 Australia") { countryCode = "+61" }
                                Button("+81 Japan") { countryCode = "+81" }
                                Button("+49 Germany") { countryCode = "+49" }
                                Button("+33 France") { countryCode = "+33" }
                                Button("+86 China") { countryCode = "+86" }
                                Button("+7 Russia") { countryCode = "+7" }
                                Button("+55 Brazil") { countryCode = "+55" }
                            } label: {
                                HStack {
                                    Text(countryCode)
                                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .background(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppTheme.dynamicTertiaryText(themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Phone Number Input
                            TextField("Enter your phone number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textFieldStyle(CustomTextFieldStyle(isDarkMode: themeManager.isDarkMode))
                        }
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
                                    .foregroundColor(selectedSociety != nil ? 
                                        AppTheme.dynamicPrimaryText(themeManager.isDarkMode) : 
                                        AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                            }
                            .padding()
                            .background(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.dynamicTertiaryText(themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Block Field
                    if selectedSociety != nil {
                        FormField(
                            title: "Block",
                            text: $selectedBlock,
                            placeholder: "Enter your block (e.g., A, Tower 1, Block A)",
                            isDarkMode: themeManager.isDarkMode
                        )
                    }
                    
                    // Flat Number Field
                    FormField(
                        title: "Flat Number",
                        text: $flatNumber,
                        placeholder: "Enter your flat number",
                        isDarkMode: themeManager.isDarkMode
                    )
                }
                
                // Sign Up Button Section
                VStack(spacing: 20) {
                    Button {
                        Task {
                            await authViewModel.signUp(
                                name: name,
                                email: email.isEmpty ? nil : email,
                                phoneNumber: countryCode + phoneNumber,
                                society: selectedSociety!,
                                blockName: selectedBlock,
                                flatNumber: flatNumber
                            )
                        }
                    } label: {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? AppTheme.primaryGreen : AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                }
                .padding(.top, 20)
                
                // Bottom spacer to ensure button is always visible above toggle
                Color.clear
                    .frame(height: 120) // Space for toggle section + safe area
            }
            .padding(.horizontal, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showSocietyPicker) {
            SocietyPickerView(
                societies: authViewModel.availableSocieties,
                selectedSociety: $selectedSociety,
                isDarkMode: themeManager.isDarkMode
            )
            .onDisappear {
                if selectedSociety != nil {
                    selectedBlock = "" // Reset block when society changes
                }
            }
        }
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isDarkMode: Bool
    
    init(title: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default, isDarkMode: Bool) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isDarkMode = isDarkMode
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(CustomTextFieldStyle(isDarkMode: isDarkMode))
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    let isDarkMode: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.dynamicCardBackground(isDarkMode))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.dynamicTertiaryText(isDarkMode).opacity(0.3), lineWidth: 1)
            )
    }
}

struct AuthToggleView: View {
    @Binding var isSignUp: Bool
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignUp.toggle()
                }
            } label: {
                Text(isSignUp ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryGreen)
            }
        }
        .padding(.top, 20)
    }
}

struct SocietyPickerView: View {
    let societies: [Society]
    @Binding var selectedSociety: Society?
    let isDarkMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(societies) { society in
                Button {
                    selectedSociety = society
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(society.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
                        
                        Text("\(society.address), \(society.city)")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
                        
                        Text("\(society.totalBlocks.count) blocks available")
                            .font(.caption)
                            .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(AppTheme.dynamicCardBackground(isDarkMode))
            }
            .navigationTitle("Select Society")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppTheme.dynamicPrimaryBackground(isDarkMode))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
}

struct OTPVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var otpCode = ""
    @State private var isSignUp: Bool
    @FocusState private var isOTPFieldFocused: Bool
    
    // For signup completion
    @State private var name = ""
    @State private var email = ""
    @State private var selectedSociety: Society?
    @State private var selectedBlock = ""
    @State private var flatNumber = ""
    @State private var showSocietyPicker = false
    
    init(isSignUp: Bool = false) {
        self._isSignUp = State(initialValue: isSignUp)
    }
    
    var isSignUpFormValid: Bool {
        !name.isEmpty &&
        selectedSociety != nil &&
        !selectedBlock.isEmpty &&
        !flatNumber.isEmpty &&
        (email.isEmpty || authViewModel.validateEmail(email))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryGreen)
                    
                    VStack(spacing: 8) {
                        Text("Verify Your Phone")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        Text("Enter the 6-digit code sent to")
                            .font(.body)
                            .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                        
                        Text(authViewModel.pendingPhoneNumber)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
                .padding(.top, 60)
                
                // OTP Input
                VStack(spacing: 16) {
                    ZStack {
                        // Hidden TextField for input - larger and properly positioned
                        TextField("", text: $otpCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .foregroundColor(.clear)
                            .accentColor(.clear)
                            .background(Color.clear)
                            .frame(maxWidth: .infinity, maxHeight: 55)
                            .focused($isOTPFieldFocused)
                            .onChange(of: otpCode) { _, newValue in
                                // Only allow numbers
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count > 6 {
                                    otpCode = String(filtered.prefix(6))
                                } else {
                                    otpCode = filtered
                                }
                                
                                // Auto-verify when 6 digits are entered
                                if otpCode.count == 6 {
                                    Task {
                                        await authViewModel.verifyOTP(otpCode)
                                    }
                                }
                            }
                        
                        // Visible digit boxes overlay
                        HStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { index in
                                OTPDigitView(
                                    digit: otpCode.count > index ? String(Array(otpCode)[index]) : "",
                                    isDarkMode: themeManager.isDarkMode
                                )
                            }
                        }
                        .onTapGesture {
                            isOTPFieldFocused = true
                        }
                    }
                    
                    // Instruction text
                    Text("Tap here and enter the 6-digit code")
                        .font(.caption)
                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                }
                
                // Timer and Resend
                VStack(spacing: 12) {
                    if authViewModel.otpTimeRemaining > 0 {
                        Text("Resend code in \(authViewModel.otpTimeRemaining)s")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                    } else {
                        Button {
                            Task {
                                await authViewModel.resendOTP()
                            }
                        } label: {
                            Text("Resend Code")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                        .disabled(authViewModel.isLoading)
                    }
                }
                
                // Manual Verify Button (for cases where auto-verify doesn't work)
                if otpCode.count == 6 {
                    Button {
                        Task {
                            await authViewModel.verifyOTP(otpCode)
                        }
                    } label: {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Verify Code")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppTheme.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(authViewModel.isLoading)
                }
                
                // Signup Form (only shown if this is for signup and user needs to complete profile)
                if isSignUp && authViewModel.showError && authViewModel.errorMessage?.contains("complete your profile") == true {
                    Divider()
                        .padding(.vertical, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Complete Your Profile")
                            .font(.headline)
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        
                        VStack(spacing: 16) {
                            FormField(
                                title: "Full Name",
                                text: $name,
                                placeholder: "Enter your full name",
                                isDarkMode: themeManager.isDarkMode
                            )
                            
                            FormField(
                                title: "Email (Optional)",
                                text: $email,
                                placeholder: "Enter your email",
                                keyboardType: .emailAddress,
                                isDarkMode: themeManager.isDarkMode
                            )
                            
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
                                            .foregroundColor(selectedSociety != nil ?
                                                AppTheme.dynamicPrimaryText(themeManager.isDarkMode) :
                                                AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                    }
                                    .padding()
                                    .background(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AppTheme.dynamicTertiaryText(themeManager.isDarkMode).opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            
                            if selectedSociety != nil {
                                FormField(
                                    title: "Block",
                                    text: $selectedBlock,
                                    placeholder: "Enter your block (e.g., A, Tower 1, Block A)",
                                    isDarkMode: themeManager.isDarkMode
                                )
                            }
                            
                            FormField(
                                title: "Flat Number",
                                text: $flatNumber,
                                placeholder: "Enter your flat number",
                                isDarkMode: themeManager.isDarkMode
                            )
                        }
                        
                        Button {
                            Task {
                                await authViewModel.completeSignUpAfterOTP(
                                    name: name,
                                    email: email.isEmpty ? nil : email,
                                    society: selectedSociety!,
                                    blockName: selectedBlock,
                                    flatNumber: flatNumber
                                )
                            }
                        } label: {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Complete Registration")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isSignUpFormValid ? AppTheme.primaryGreen : AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isSignUpFormValid || authViewModel.isLoading)
                    }
                }
                
                // Back Button
                Button {
                    authViewModel.showOTPVerification = false
                    authViewModel.resetOTPState()
                } label: {
                    Text("← Change Phone Number")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            // Auto-focus the OTP input when the screen appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isOTPFieldFocused = true
            }
        }
        .sheet(isPresented: $showSocietyPicker) {
            SocietyPickerView(
                societies: authViewModel.availableSocieties,
                selectedSociety: $selectedSociety,
                isDarkMode: themeManager.isDarkMode
            )
        }
    }
}

struct OTPDigitView: View {
    let digit: String
    let isDarkMode: Bool
    
    var body: some View {
        Text(digit)
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
            .frame(width: 45, height: 55)
            .background(AppTheme.dynamicCardBackground(isDarkMode))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(digit.isEmpty ? 
                        AppTheme.dynamicTertiaryText(isDarkMode).opacity(0.3) : 
                        AppTheme.primaryGreen, lineWidth: 1.5)
            )
    }
}


#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
        .environmentObject(ThemeManager())
} 