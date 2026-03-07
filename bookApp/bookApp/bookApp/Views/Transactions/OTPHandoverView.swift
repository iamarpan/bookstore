import SwiftUI

/// Screen for confirming book handover (owner shows OTP to borrower, then confirms)
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

                // Title & description
                VStack(spacing: 12) {
                    Text(isOwner ? "Confirm Handover" : "Awaiting Handover")
                        .font(AppTheme.headerFont(size: 26))
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                    Text(isOwner
                         ? "Your one-time code is shown below. Confirm once the borrower acknowledges receipt of \"\(transaction.bookTitle)\"."
                         : "The owner is confirming the handover of \"\(transaction.bookTitle)\". Please wait.")
                        .font(AppTheme.bodyFont(size: 16))
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if isOwner {
                    // OTP display card
                    VStack(spacing: 16) {
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
                        } else if let otp = viewModel.generatedOTP {
                            Text(otp)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.primaryAccent)
                                .tracking(8)
                        } else {
                            Text("Failed to generate code")
                                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                        }

                        if viewModel.generatedOTP != nil {
                            Text("Show this to \(transaction.borrowerName) • expires in 10 min")
                                .font(.caption)
                                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)

                    // Checklist
                    VStack(alignment: .leading, spacing: 14) {
                        checkRow("Book is in good condition")
                        checkRow("Borrower is present and confirmed identity")
                        checkRow("Both parties agree on the handover")
                    }
                    .padding(20)
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                }

                Spacer()

                if isOwner {
                    Button(action: {
                        Task { await viewModel.confirmHandover(transactionId: transaction.id) }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Handover")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.generatedOTP != nil ? AppTheme.primaryAccent : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.buttonRadius)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(viewModel.isLoading || viewModel.generatedOTP == nil)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
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

    /// Owner: confirm handover using the OTP they just generated
    func confirmHandover(transactionId: String) async {
        guard let otp = generatedOTP else {
            errorMessage = "Handover code not generated yet. Please wait."
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await transactionService.confirmHandover(id: transactionId, otp: otp)
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
            isOwner: true
        )
        .environmentObject(ThemeManager())
    }
}
