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
        ZStack {
            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                Text(isOwner ? "Verify Borrower" : "Your Ticket")
                    .font(AppTheme.headerFont(size: 24))
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    .padding(.top)
                
                // Ticket Card
                TicketView(isOwner: isOwner, viewModel: viewModel)
                    .padding(.horizontal, 24)
                    .shadow(color: AppTheme.shadowCard, radius: 20, x: 0, y: 10)
                
                if isOwner {
                    // Input Field (Hidden but active)
                    TextField("", text: $viewModel.enteredCode)
                        .keyboardType(.numberPad)
                        .opacity(0.01)
                        .frame(width: 0, height: 0)
                        .onChange(of: viewModel.enteredCode) { _, newValue in
                            if newValue.count > 4 {
                                viewModel.enteredCode = String(newValue.prefix(4))
                            }
                        }
                    
                    // Confirm Button
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
                        .background(viewModel.isValidCode ? AppTheme.primaryAccent : AppTheme.tertiaryText)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.buttonRadius)
                        .shadow(color: viewModel.isValidCode ? AppTheme.primaryAccent.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!viewModel.isValidCode || viewModel.isLoading)
                    .padding(.horizontal, 24)
                } else {
                    Text("Show this code to the owner")
                        .font(AppTheme.bodyFont(size: 16))
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                }
                
                Spacer()
            }
        }
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
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

struct TicketView: View {
    let isOwner: Bool
    @ObservedObject var viewModel: OTPHandoverViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section (Info)
            VStack(spacing: 16) {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppTheme.primaryAccent)
                
                Text(isOwner ? "Enter Code" : "Scan Code")
                    .font(AppTheme.headerFont(size: 20))
                    .foregroundColor(AppTheme.primaryText)
                
                Divider()
                    .background(AppTheme.secondaryText.opacity(0.2))
            }
            .padding(24)
            .background(Color.white)
            
            // Perforation
            HStack(spacing: 4) {
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 10)
            .background(Color.white)
            .mask(Rectangle().padding(.horizontal, -10)) // Clip edges if needed
            
            // Bottom Section (Code)
            VStack(spacing: 20) {
                if isOwner {
                    HStack(spacing: 16) {
                        ForEach(0..<4) { index in
                            let digit = viewModel.enteredCode.count > index ? String(Array(viewModel.enteredCode)[index]) : ""
                            let isActive = viewModel.enteredCode.count == index
                            
                            Text(digit)
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: 50, height: 60)
                                .background(isActive ? AppTheme.primaryAccent.opacity(0.1) : AppTheme.primaryBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isActive ? AppTheme.primaryAccent : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                } else {
                    Text(viewModel.otpCode)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.primaryText)
                        .kerning(10)
                    
                    Text("Expires in \(viewModel.timeRemaining)")
                        .font(AppTheme.bodyFont(size: 14, weight: .medium))
                        .foregroundColor(viewModel.timeRemainingInt < 60 ? AppTheme.errorColor : AppTheme.secondaryText)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .cornerRadius(20)
        .mask(TicketShape())
    }
}

struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 20
        let notchRadius: CGFloat = 10
        let notchY = rect.height * 0.4 // Position of the notch
        
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.width, y: notchY - notchRadius))
        path.addArc(center: CGPoint(x: rect.width, y: notchY), radius: notchRadius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 90), clockwise: true) // Notch
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(center: CGPoint(x: rect.width - cornerRadius, y: rect.height), radius: cornerRadius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        
        path.addLine(to: CGPoint(x: 0, y: notchY + notchRadius))
        path.addArc(center: CGPoint(x: 0, y: notchY), radius: notchRadius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: -90), clockwise: true) // Notch
        
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        
        return path
    }
}

// Keep ViewModel as is
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
