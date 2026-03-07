import SwiftUI

/// Screen for confirming book handover (owner confirms they have handed over the book)
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
                         ? "Confirm that you have handed the book \"\(transaction.bookTitle)\" to \(transaction.borrowerName)."
                         : "The owner is confirming the handover of \"\(transaction.bookTitle)\".")
                        .font(AppTheme.bodyFont(size: 16))
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if isOwner {
                    // Checklist card
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
                        .background(AppTheme.primaryAccent)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.buttonRadius)
                        .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false

    private let transactionService = TransactionService()

    func confirmHandover(transactionId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await transactionService.confirmHandover(id: transactionId, otp: "")
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
