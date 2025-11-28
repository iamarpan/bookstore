import SwiftUI

/// Screen for handling book return with OTP
struct OTPReturnView: View {
    let transaction: Transaction
    let isOwner: Bool // Determined by current user ID
    
    @StateObject private var viewModel = OTPReturnViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 32) {
                    // Instructions
                    instructionsView
                    
                    // OTP Section
                    if isOwner {
                        ownerView
                    } else {
                        borrowerView
                    }
                    
                    // Timer/Status
                    statusView
                    
                    // Book Condition (only for Owner to verify)
                    if isOwner {
                        conditionSection
                    }
                }
                .padding()
            }
            
            // Action Button (for Borrower)
            if !isOwner {
                confirmButton
                    .padding()
                    .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
            }
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Return Book")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Return confirmed! The transaction is now complete.")
        }
        .onAppear {
            viewModel.setup(transaction: transaction, isOwner: isOwner)
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.uturn.left.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primaryAccent)
                .padding()
                .background(AppTheme.primaryAccent.opacity(0.1))
                .clipShape(Circle())
            
            Text(isOwner ? "Show Code to Borrower" : "Verify Return")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
        }
        .padding(.vertical, 20)
    }
    
    private var instructionsView: some View {
        Text(isOwner
             ? "Show this 4-digit code to the borrower when they return the book."
             : "Ask the owner for the 4-digit code displayed on their screen and enter it below to confirm return.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            .padding(.horizontal)
    }
    
    // MARK: - Owner View (Display Code)
    
    private var ownerView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    otpDigitBox(digit: viewModel.otpCode.count > index ? String(Array(viewModel.otpCode)[index]) : "")
                }
            }
            
            Button(action: {
                UIPasteboard.general.string = viewModel.otpCode
            }) {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy Code")
                }
                .font(.caption)
                .foregroundColor(AppTheme.primaryAccent)
            }
        }
    }
    
    private func otpDigitBox(digit: String) -> some View {
        Text(digit)
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            .frame(width: 60, height: 70)
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primaryAccent.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Borrower View (Enter Code)
    
    private var borrowerView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    otpInputBox(index: index)
                }
            }
            
            // Hidden text field for input handling
            TextField("", text: $viewModel.enteredCode)
                .keyboardType(.numberPad)
                .opacity(0.01) // Invisible but focusable
                .frame(width: 0, height: 0)
                .onChange(of: viewModel.enteredCode) { _, newValue in
                    if newValue.count > 4 {
                        viewModel.enteredCode = String(newValue.prefix(4))
                    }
                }
        }
    }
    
    private func otpInputBox(index: Int) -> some View {
        let digit = viewModel.enteredCode.count > index ? String(Array(viewModel.enteredCode)[index]) : ""
        let isActive = viewModel.enteredCode.count == index
        
        return Text(digit)
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            .frame(width: 60, height: 70)
            .background(isActive ? AppTheme.primaryAccent.opacity(0.1) : AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? AppTheme.primaryAccent : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
            )
            .onTapGesture {
                // Focus logic would go here
            }
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: 8) {
            if isOwner {
                Text("Code expires in")
                    .font(.caption)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                
                Text(viewModel.timeRemaining)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundColor(viewModel.timeRemainingInt < 60 ? .red : AppTheme.primaryAccent)
            }
        }
    }
    
    // MARK: - Condition Section
    
    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Book Condition")
                .font(.headline)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Text("Please verify the book is in good condition before the borrower confirms the return.")
                .font(.caption)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            
            // Toggle or checklist could go here
        }
        .padding()
        .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button(action: {
            Task {
                await viewModel.confirmReturn()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Confirm Return")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isValidCode ? AppTheme.primaryAccent : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isValidCode || viewModel.isLoading)
    }
}

// MARK: - ViewModel

@MainActor
class OTPReturnViewModel: ObservableObject {
    @Published var otpCode = "5678" // Mock code
    @Published var enteredCode = ""
    @Published var timeRemaining = "10:00"
    @Published var timeRemainingInt = 600
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private var timer: Timer?
    private let transactionService = TransactionService()
    private var transactionId: String = ""
    
    func setup(transaction: Transaction, isOwner: Bool) {
        self.transactionId = transaction.id
        
        if isOwner {
            // Generate or fetch OTP
            // In real app: otpCode = transaction.returnOtp ?? generateOTP()
            startTimer()
        }
    }
    
    var isValidCode: Bool {
        return enteredCode.count == 4
    }
    
    func confirmReturn() async {
        guard isValidCode else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Verify OTP with backend
            // try await transactionService.verifyReturnOTP(transactionId: transactionId, code: enteredCode)
            
            // Mock verification
            if enteredCode == "5678" {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                showSuccess = true
            } else {
                throw NSError(domain: "App", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid code. Please try again."])
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timeRemainingInt > 0 {
                    self.timeRemainingInt -= 1
                    let minutes = self.timeRemainingInt / 60
                    let seconds = self.timeRemainingInt % 60
                    self.timeRemaining = String(format: "%02d:%02d", minutes, seconds)
                } else {
                    self.timer?.invalidate()
                    // Refresh OTP logic
                }
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Preview
struct OTPReturnView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OTPReturnView(
                transaction: Transaction.mockTransactions[0],
                isOwner: true
            )
            .environmentObject(ThemeManager())
        }
        
        NavigationView {
            OTPReturnView(
                transaction: Transaction.mockTransactions[0],
                isOwner: false
            )
            .environmentObject(ThemeManager())
        }
    }
}
