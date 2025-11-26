import SwiftUI

/// Screen for requesting to borrow a book
struct BorrowRequestView: View {
    let book: Book
    @StateObject private var viewModel = BorrowRequestViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Summary
                    bookSummarySection
                    
                    // Duration Selector
                    durationSection
                    
                    // Message Input
                    messageSection
                    
                    // Terms & Info
                    termsSection
                }
                .padding()
            }
            
            // Action Button
            actionButton
                .padding()
                .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Request to Borrow")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Request Sent", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your request has been sent to the owner. You'll be notified when they respond.")
        }
    }
    
    // MARK: - Sections
    
    private var bookSummarySection: some View {
        HStack(spacing: 16) {
            // Book Cover
            AsyncImage(url: URL(string: book.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 120)
            .cornerRadius(8)
            .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                
                // Owner info
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                    
                    Text("Owner: \(book.ownerId)") // In real app, resolve owner name
                        .font(.caption)
                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
        .cornerRadius(12)
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Borrow Duration")
                .font(.headline)
                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            
            HStack(spacing: 12) {
                durationOption(weeks: 1)
                durationOption(weeks: 2)
                durationOption(weeks: 4)
            }
        }
    }
    
    private func durationOption(weeks: Int) -> some View {
        let isSelected = viewModel.selectedDurationWeeks == weeks
        
        return Button(action: { viewModel.selectedDurationWeeks = weeks }) {
            VStack(spacing: 4) {
                Text("\(weeks)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(weeks == 1 ? "Week" : "Weeks")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? AppTheme.primaryGreen.opacity(0.1) : AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
            .foregroundColor(isSelected ? AppTheme.primaryGreen : AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.primaryGreen : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message to Owner (Optional)")
                .font(.headline)
                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            
            TextEditor(text: $viewModel.message)
                .frame(height: 100)
                .padding(8)
                .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(AppTheme.primaryGreen)
                    .font(.caption)
                
                Text("By sending this request, you agree to return the book in the same condition. The owner will review your request.")
                    .font(.caption)
                    .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
            }
        }
        .padding()
        .background(AppTheme.primaryGreen.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var actionButton: some View {
        Button(action: {
            Task {
                await viewModel.sendRequest(bookId: book.id, ownerId: book.ownerId, borrowerId: authViewModel.currentUser?.id ?? "")
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Request")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
    }
}

// MARK: - ViewModel

@MainActor
class BorrowRequestViewModel: ObservableObject {
    @Published var selectedDurationWeeks = 2
    @Published var message = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let transactionService: TransactionService
    
    init() {
        self.transactionService = TransactionService()
    }
    
    func sendRequest(bookId: String, ownerId: String, borrowerId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, we'd calculate the due date based on duration
            // let dueDate = Calendar.current.date(byAdding: .weekOfYear, value: selectedDurationWeeks, to: Date())
            
            // Call service
            // try await transactionService.createTransaction(...)
            
            // For now, simulate success
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            showSuccess = true
            print("✅ Request sent for book: \(bookId)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview
struct BorrowRequestView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BorrowRequestView(book: Book.mockBooks[0])
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
}
