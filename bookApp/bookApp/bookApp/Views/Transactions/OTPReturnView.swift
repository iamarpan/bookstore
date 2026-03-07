import SwiftUI

/// Screen for confirming book return (borrower confirms they have returned the book)
struct OTPReturnView: View {
    let transaction: Transaction
    let isOwner: Bool

    @StateObject private var viewModel = ReturnConfirmViewModel()
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
                    Image(systemName: "arrow.uturn.left.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.primaryAccent)
                }

                // Title & description
                VStack(spacing: 12) {
                    Text(isOwner ? "Awaiting Return" : "Confirm Return")
                        .font(AppTheme.headerFont(size: 26))
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                    Text(isOwner
                         ? "\(transaction.borrowerName) is confirming the return of \"\(transaction.bookTitle)\"."
                         : "Confirm that you have returned the book \"\(transaction.bookTitle)\" to \(transaction.ownerName).")
                        .font(AppTheme.bodyFont(size: 16))
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if !isOwner {
                    // Checklist card for borrower
                    VStack(alignment: .leading, spacing: 14) {
                        checkRow("Book has been returned to the owner")
                        checkRow("Book is in the same condition as received")
                        checkRow("Owner is present and confirmed receipt")
                    }
                    .padding(20)
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                }

                Spacer()

                if !isOwner {
                    Button(action: {
                        Task { await viewModel.confirmReturn(transactionId: transaction.id) }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Return")
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
        .alert("Return Complete", isPresented: $viewModel.showSuccess) {
            Button("Done") { presentationMode.wrappedValue.dismiss() }
        } message: {
            Text("The book has been returned. The transaction is now complete.")
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
class ReturnConfirmViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false

    private let transactionService = TransactionService()

    func confirmReturn(transactionId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await transactionService.confirmReturn(id: transactionId, otp: "")
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
        OTPReturnView(
            transaction: Transaction.mockTransactions[0],
            isOwner: false
        )
        .environmentObject(ThemeManager())
    }
}
