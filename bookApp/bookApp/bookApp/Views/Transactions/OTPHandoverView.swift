import SwiftUI
import Combine

/// Screen for handling book handover with OTP
struct OTPHandoverView: View {
    let transaction: Transaction
    let isOwner: Bool // Determined by current user ID
    
    @StateObject private var viewModel = OTPHandoverViewModel()
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
                }
                .padding()
            }
            
            // Action Button (for Owner)
            if isOwner {
                confirmButton
                    .padding()
                    .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode))
            }
        }
        .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Handover Book")
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
            Text("Handover confirmed! The transaction is now active.")
        }
        .onAppear {
            viewModel.setup(transaction: transaction, isOwner: isOwner)
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.primaryGreen)
                .padding()
                .background(AppTheme.lightGreen)
                .clipShape(Circle())
            
            Text(isOwner ? "Verify Borrower" : "Show Code to Owner")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
        }
        .padding(.vertical, 20)
    }
    
    private var instructionsView: some View {
        Text(isOwner 
             ? "Ask the borrower for the 4-digit code displayed on their screen and enter it below to confirm handover."
             : "Show this 4-digit code to the owner when you meet to pick up the book.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
            .padding(.horizontal)
    }
    
    // MARK: - Borrower View (Display Code)
    
    private var borrowerView: some View {
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
                .foregroundColor(AppTheme.primaryGreen)
            }
        }
    }
    
    private func otpDigitBox(digit: String) -> some View {
        Text(digit)
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            .frame(width: 60, height: 70)
            .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primaryGreen.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Owner View (Enter Code)
    
    private var ownerView: some View {
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
            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            .frame(width: 60, height: 70)
            .background(isActive ? AppTheme.primaryGreen.opacity(0.1) : AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? AppTheme.primaryGreen : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
            )
            .onTapGesture {
                // Focus logic would go here
            }
    }
    
    // MARK: - Status View
    
    private var statusView: some View {
        VStack(spacing: 8) {
            if !isOwner {
                Text("Code expires in")
                    .font(.caption)
                    .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                
                Text(viewModel.timeRemaining)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundColor(viewModel.timeRemainingInt < 60 ? .red : AppTheme.primaryGreen)
            }
        }
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button(action: {
            Task {
                await viewModel.confirmHandover()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Confirm Handover")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isValidCode ? AppTheme.primaryGreen : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isValidCode || viewModel.isLoading)
    }
}

// MARK: - ViewModel

@MainActor
class OTPHandoverViewModel: ObservableObject {
    @Published var otpCode = "1234" // Mock code
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
        
        if !isOwner {
            // Generate or fetch OTP
            // In real app: otpCode = transaction.otp ?? generateOTP()
            startTimer()
        }
    }
    
    var isValidCode: Bool {
        return enteredCode.count == 4
    }
    
    func confirmHandover() async {
        guard isValidCode else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Verify OTP with backend
            // try await transactionService.verifyHandoverOTP(transactionId: transactionId, code: enteredCode)
            
            // Mock verification
            if enteredCode == "1234" {
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
struct OTPHandoverView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OTPHandoverView(
                transaction: Transaction.mockTransactions[0],
                isOwner: true
            )
            .environmentObject(ThemeManager())
        }
        
        NavigationView {
            OTPHandoverView(
                transaction: Transaction.mockTransactions[0],
                isOwner: false
            )
            .environmentObject(ThemeManager())
        }
    }
}
