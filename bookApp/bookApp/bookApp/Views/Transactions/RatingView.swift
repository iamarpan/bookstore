import SwiftUI

/// View for rating a transaction experience
struct RatingView: View {
    let transaction: Transaction
    let isOwner: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var isLoading = false
    @EnvironmentObject var themeManager: ThemeManager
    
    private let transactionService = TransactionService()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rate your experience")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Text(isOwner ? "How was \(transaction.borrowerName) as a borrower?" : "How was \(transaction.ownerName) as an owner?")
                .font(.subheadline)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .onTapGesture {
                            rating = index
                        }
                }
            }
            .padding(.vertical)
            
            TextField("Add an optional comment...", text: $comment)
                .padding()
                .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                .cornerRadius(12)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Button {
                Task { await submitRating() }
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Submit Rating")
                        .fontWeight(.bold)
                }
            }
            .disabled(isLoading)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryAccent)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Button("Skip for now") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
        }
        .padding(32)
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
    }
    
    private func submitRating() async {
        isLoading = true
        do {
            _ = try await transactionService.rateTransaction(
                id: transaction.id,
                rating: rating,
                comment: comment.isEmpty ? nil : comment
            )
            // Invalidate stores to refresh UI
            AppDataStore.shared.invalidateOwnerTransactions()
            AppDataStore.shared.invalidateBorrowerTransactions()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("❌ Failed to submit rating: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
