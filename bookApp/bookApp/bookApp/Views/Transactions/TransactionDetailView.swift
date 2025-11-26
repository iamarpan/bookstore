import SwiftUI

/// Screen for viewing transaction details and performing actions
struct TransactionDetailView: View {
    let transaction: Transaction
    @StateObject private var viewModel: TransactionDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    init(transaction: Transaction) {
        self.transaction = transaction
        self._viewModel = StateObject(wrappedValue: TransactionDetailViewModel(transaction: transaction))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Banner
                statusBanner
                
                // Book Info
                bookInfoSection
                
                // User Info (Other Party)
                userInfoSection
                
                // Timeline
                timelineSection
                
                // Actions
                actionSection
            }
            .padding()
        }
        .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadDetails()
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            NavigationView {
                switch sheet {
                case .handover:
                    OTPHandoverView(
                        transaction: viewModel.transaction,
                        isOwner: viewModel.isOwner(userId: authViewModel.currentUser?.id ?? "")
                    )
                case .returnBook:
                    OTPReturnView(
                        transaction: viewModel.transaction,
                        isOwner: viewModel.isOwner(userId: authViewModel.currentUser?.id ?? "")
                    )
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var statusBanner: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.title2)
            Text(viewModel.transaction.status.rawValue.capitalized)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .foregroundColor(statusColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor, lineWidth: 1)
        )
    }
    
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Book")
                .font(.headline)
                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            
            HStack(spacing: 16) {
                // Book Cover Placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Book Title Placeholder") // In real app, fetch book details
                        .font(.headline)
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    
                    Text("Author Name")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
    
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.isOwner(userId: authViewModel.currentUser?.id ?? "") ? "Borrower" : "Owner")
                .font(.headline)
                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.otherPartyName)
                        .font(.headline)
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    
                    Text("Tap to contact")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                
                Spacer()
                
                Button(action: {
                    // Message action
                }) {
                    Image(systemName: "message.circle.fill")
                        .font(.title)
                        .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .padding()
            .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            
            VStack(alignment: .leading, spacing: 0) {
                timelineItem(title: "Requested", date: viewModel.transaction.requestedAt, isCompleted: true)
                timelineItem(title: "Approved", date: viewModel.transaction.approvedAt, isCompleted: viewModel.transaction.status != .pending)
                timelineItem(title: "Handed Over", date: viewModel.transaction.handoverAt, isCompleted: viewModel.transaction.status == .active || viewModel.transaction.status == .returned)
                timelineItem(title: "Returned", date: viewModel.transaction.returnedAt, isCompleted: viewModel.transaction.status == .returned, isLast: true)
            }
            .padding()
            .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
    
    private func timelineItem(title: String, date: Date?, isCompleted: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? AppTheme.primaryGreen : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? AppTheme.primaryGreen : Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 30)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isCompleted ? .semibold : .regular)
                    .foregroundColor(isCompleted ? AppTheme.dynamicPrimaryText(themeManager.isDarkMode) : AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                
                if let date = date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                }
            }
            
            Spacer()
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if viewModel.canApprove(userId: authViewModel.currentUser?.id ?? "") {
                actionButton(title: "Approve Request", icon: "checkmark.circle.fill", color: AppTheme.primaryGreen) {
                    Task { await viewModel.approveRequest() }
                }
                
                actionButton(title: "Reject Request", icon: "xmark.circle.fill", color: .red) {
                    Task { await viewModel.rejectRequest() }
                }
            }
            
            if viewModel.canHandover {
                actionButton(title: "Handover Book", icon: "hand.wave.fill", color: AppTheme.primaryGreen) {
                    viewModel.activeSheet = .handover
                }
            }
            
            if viewModel.canReturn {
                actionButton(title: "Return Book", icon: "arrow.uturn.left.circle.fill", color: AppTheme.primaryGreen) {
                    viewModel.activeSheet = .returnBook
                }
            }
        }
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        if viewModel.transaction.isOverdue { return .red }
        switch viewModel.transaction.status {
        case .pending: return .orange
        case .approved: return .blue
        case .active: return .green
        case .returned: return .gray
        case .rejected, .cancelled: return .red
        }
    }
    
    private var statusIcon: String {
        if viewModel.transaction.isOverdue { return "exclamationmark.circle.fill" }
        switch viewModel.transaction.status {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.seal.fill"
        case .active: return "book.fill"
        case .returned: return "checkmark.circle.fill"
        case .rejected, .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - ViewModel

@MainActor
class TransactionDetailViewModel: ObservableObject {
    @Published var transaction: Transaction
    @Published var activeSheet: SheetType?
    @Published var isLoading = false
    
    enum SheetType: Identifiable {
        case handover, returnBook
        var id: Int { hashValue }
    }
    
    private let transactionService = TransactionService()
    
    init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    func loadDetails() {
        // Fetch updated transaction details if needed
    }
    
    func isOwner(userId: String) -> Bool {
        return transaction.ownerId == userId
    }
    
    var otherPartyName: String {
        // In real app, resolve name from ID
        return isOwner(userId: User.mockUser.id) ? transaction.borrowerName : transaction.ownerName
    }
    
    // Action Logic
    
    func canApprove(userId: String) -> Bool {
        return transaction.status == .pending && isOwner(userId: userId)
    }
    
    var canHandover: Bool {
        return transaction.status == .approved
    }
    
    var canReturn: Bool {
        return transaction.status == .active
    }
    
    func approveRequest() async {
        isLoading = true
        // Call API
        // transaction = try await transactionService.updateStatus(...)
        // Mock update
        var updated = transaction
        updated.status = .approved
        transaction = updated
        isLoading = false
    }
    
    func rejectRequest() async {
        isLoading = true
        // Call API
        var updated = transaction
        updated.status = .rejected
        transaction = updated
        isLoading = false
    }
}

// MARK: - Preview
struct TransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionDetailView(transaction: Transaction.mockTransactions[0])
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
}
