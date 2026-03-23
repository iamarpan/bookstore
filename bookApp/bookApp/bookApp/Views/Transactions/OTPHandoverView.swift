import SwiftUI

/// Screen for confirming book handover (owner generates OTP; borrower enters it to confirm receipt)
struct OTPHandoverView: View {
    let transaction: Transaction
    let isOwner: Bool

    @StateObject private var viewModel = HandoverConfirmViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryAccent.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.primaryAccent)
                }

                if isOwner {
                    ownerContent
                } else {
                    borrowerContent
                }

                Spacer()

                if !isOwner {
                    borrowerActionButton
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if isOwner {
                Task { await viewModel.generateOTP(transactionId: transaction.id) }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Handover Complete", isPresented: $viewModel.showSuccess) {
            Button("Done") { presentationMode.wrappedValue.dismiss() }
        } message: {
            Text("The book has been handed over. The transaction is now active.")
        }
    }

    // MARK: - Owner Side: show the generated OTP

    private var ownerContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Show Handover Code")
                    .font(AppTheme.headerFont(size: 24))
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)

                Text("Share this code with \(transaction.borrowerName). They will enter it on their device to confirm receipt of \"\(transaction.bookTitle)\".")
                    .font(AppTheme.bodyFont(size: 15))
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // OTP card
            VStack(spacing: 12) {
                Text("Handover Code")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .textCase(.uppercase)
                    .tracking(1.5)

                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryAccent))
                        .scaleEffect(1.5)
                        .padding(.vertical, 14)
                } else if let otp = viewModel.generatedOTP {
                    Text(otp)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.primaryAccent)
                        .tracking(8)

                    Text("Expires in 10 min")
                        .font(.caption)
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                } else {
                    Text("Failed to generate code")
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(20)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Borrower Side: enter the OTP shown by owner

    private var borrowerContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Confirm Handover")
                    .font(AppTheme.headerFont(size: 26))
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                Text("Ask \(transaction.ownerName) for the handover code and enter it below to confirm you received \"\(transaction.bookTitle)\".")
                    .font(AppTheme.bodyFont(size: 16))
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // OTP entry field
            VStack(spacing: 8) {
                Text("Handover Code from Owner")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Enter 6-digit code", text: $viewModel.enteredOTP.animation(nil))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .tracking(6)
                    .padding()
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(12)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            }
            .padding(.horizontal, 24)

            // Checklist
            VStack(alignment: .leading, spacing: 14) {
                checkRow("I have received the book")
                checkRow("Book is in good condition")
                checkRow("Owner is present")
            }
            .padding(20)
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }

    private var borrowerActionButton: some View {
        Button(action: {
            Task { await viewModel.confirmHandover(transactionId: transaction.id) }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirm Receipt")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.enteredOTP.count == 6 ? AppTheme.primaryAccent : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(AppTheme.buttonRadius)
            .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isLoading || viewModel.enteredOTP.count != 6)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }

    private func checkRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.primaryAccent)
            Text(text)
                .font(AppTheme.bodyFont(size: 15))
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
        }
    }
}

// MARK: - ViewModel

@MainActor
class HandoverConfirmViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var generatedOTP: String?
    @Published var enteredOTP: String = ""

    private let transactionService = TransactionService()

    /// Owner: generate the handover OTP from the backend
    func generateOTP(transactionId: String) async {
        isGenerating = true
        do {
            generatedOTP = try await transactionService.generateHandoverOTP(id: transactionId)
        } catch {
            errorMessage = "Could not generate handover code: \(error.localizedDescription)"
            showError = true
        }
        isGenerating = false
    }

    /// Borrower: confirm handover using the OTP they got from the owner
    func confirmHandover(transactionId: String) async {
        guard !enteredOTP.isEmpty else {
            errorMessage = "Please enter the handover code from the owner."
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await transactionService.confirmHandover(id: transactionId, otp: enteredOTP)
            AppDataStore.shared.invalidateOwnerTransactions()
            AppDataStore.shared.invalidateBorrowerTransactions()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        OTPHandoverView(
            transaction: Transaction.mockTransactions[0],
            isOwner: false
        )
        .environmentObject(ThemeManager())
    }
}
