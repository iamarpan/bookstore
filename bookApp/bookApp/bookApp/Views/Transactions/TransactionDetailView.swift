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
            .padding(.bottom, 100)
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
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
                case .rating:
                    RatingView(
                        transaction: viewModel.transaction,
                        isOwner: viewModel.isOwner(userId: authViewModel.currentUser?.id ?? "")
                    )
                }
            }
        }
        .alert("Reject Request", isPresented: $viewModel.showRejectPrompt) {
            TextField("Reason (Optional)", text: $viewModel.rejectReason)
            Button("Cancel", role: .cancel) {
                viewModel.rejectReason = ""
            }
            Button("Reject", role: .destructive) {
                Task { await viewModel.rejectRequest() }
            }
        } message: {
            Text("Are you sure you want to reject this request? You can provide an optional reason.")
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
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            HStack(spacing: 16) {
                // Book Cover
                if let imageUrl = viewModel.transaction.bookImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(Image(systemName: "book.fill").foregroundColor(.gray))
                    }
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .overlay(Image(systemName: "book.fill").foregroundColor(.gray))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.transaction.bookTitle)
                        .font(.headline)
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
    
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.isOwner(userId: authViewModel.currentUser?.id ?? "") ? "Borrower" : "Owner")
                .font(.headline)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.otherPartyName(currentUserId: authViewModel.currentUser?.id ?? ""))
                        .font(.headline)
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    
                    Text("Tap to contact")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryAccent)
                }
                
                Spacer()
                
                NavigationLink(destination: ChatView(transactionId: viewModel.transaction.id)) {
                    Image(systemName: "message.circle.fill")
                        .font(.title)
                        .foregroundColor(AppTheme.primaryAccent)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            VStack(alignment: .leading, spacing: 0) {
                timelineItem(title: "Requested", date: viewModel.transaction.requestedAt, isCompleted: true)
                timelineItem(title: "Approved", date: viewModel.transaction.approvedAt, isCompleted: viewModel.transaction.status != .pending)
                timelineItem(title: "Handed Over", date: viewModel.transaction.handoverAt, isCompleted: viewModel.transaction.status == .active || viewModel.transaction.status == .returned || viewModel.transaction.status == .returned)
                timelineItem(title: "Returned", date: viewModel.transaction.returnedAt, isCompleted: viewModel.transaction.status == .returned)
                timelineItem(title: "Payment Received", date: nil, isCompleted: viewModel.transaction.paymentStatus.isComplete)
                timelineItem(title: "Rating Given", date: nil, isCompleted: viewModel.isOwner(userId: authViewModel.currentUser?.id ?? "") ? viewModel.transaction.borrowerRating != nil : viewModel.transaction.ownerRating != nil, isLast: true)
            }
            .padding()
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
    
    private func timelineItem(title: String, date: Date?, isCompleted: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? AppTheme.primaryAccent : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? AppTheme.primaryAccent : Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 30)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isCompleted ? .semibold : .regular)
                    .foregroundColor(isCompleted ? AppTheme.colorPrimaryText(for: themeManager.isDarkMode) : AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                
                if let date = date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                }
            }
            
            Spacer()
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if viewModel.canApprove(userId: authViewModel.currentUser?.id ?? "") {
                actionButton(title: "Approve Request", icon: "checkmark.circle.fill", color: AppTheme.primaryAccent) {
                    Task { await viewModel.approveRequest() }
                }
                
                actionButton(title: "Reject Request", icon: "xmark.circle.fill", color: .red) {
                    viewModel.showRejectPrompt = true
                }
            }
            
            if viewModel.canHandover {
                actionButton(title: "Handover Book", icon: "hand.wave.fill", color: AppTheme.primaryAccent) {
                    viewModel.activeSheet = .handover
                }
            }
            
            if viewModel.canReturn {
                actionButton(title: "Return Book", icon: "arrow.uturn.left.circle.fill", color: AppTheme.primaryAccent) {
                    viewModel.activeSheet = .returnBook
                }
            }
            
            if viewModel.canCancel(userId: authViewModel.currentUser?.id ?? "") {
                actionButton(title: "Cancel Request", icon: "xmark.circle", color: .gray) {
                    Task { await viewModel.cancelTransaction() }
                }
            }
            
            if viewModel.canMarkPayment(userId: authViewModel.currentUser?.id ?? "") {
                actionButton(title: "Mark Payment Completed", icon: "dollarsign.circle.fill", color: .green) {
                    Task { await viewModel.markPayment(userId: authViewModel.currentUser?.id ?? "") }
                }
            }
            
            if viewModel.canRate(userId: authViewModel.currentUser?.id ?? "") {
                actionButton(title: "Rate Transaction", icon: "star.fill", color: .orange) {
                    viewModel.activeSheet = .rating
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
        .buttonStyle(.plain)
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
    @Published var showRejectPrompt = false
    @Published var rejectReason = ""
    
    enum SheetType: Identifiable {
        case handover, returnBook, rating
        var id: Int {
            switch self {
            case .handover: return 1
            case .returnBook: return 2
            case .rating: return 3
            }
        }
    }
    
    private let transactionService = TransactionService()
    
    init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    func loadDetails() {
        Task {
            do {
                let refreshed = try await transactionService.fetchTransactionById(id: transaction.id)
                self.transaction = refreshed
            } catch {
                print("⚠️ TransactionDetailView: could not refresh transaction — \(error.localizedDescription)")
            }
        }
    }
    
    func isOwner(userId: String) -> Bool {
        return transaction.ownerId == userId
    }
    
    func otherPartyName(currentUserId: String) -> String {
        return isOwner(userId: currentUserId) ? transaction.borrowerName : transaction.ownerName
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
    
    func canCancel(userId: String) -> Bool {
        // Both can cancel if pending. Borrower can cancel if approved but not active.
        if transaction.status == .pending { return true }
        if transaction.status == .approved && transaction.borrowerId == userId { return true }
        return false
    }
    
    func canMarkPayment(userId: String) -> Bool {
        return transaction.status == .returned && 
               !transaction.paymentStatus.isComplete && 
               isOwner(userId: userId)
    }
    
    func canRate(userId: String) -> Bool {
        guard transaction.status == .returned else { return false }
        if isOwner(userId: userId) {
            return transaction.borrowerRating == nil
        } else {
            return transaction.ownerRating == nil
        }
    }
    
    func approveRequest() async {
        isLoading = true
        do {
            let updated = try await transactionService.approveRequest(id: transaction.id)
            transaction = updated
            AppDataStore.shared.invalidateOwnerTransactions()
            AppDataStore.shared.invalidateBorrowerTransactions()
        } catch {
            print("❌ Failed to approve request: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func rejectRequest() async {
        isLoading = true
        do {
            let reason = rejectReason.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalReason = reason.isEmpty ? nil : reason
            let updated = try await transactionService.rejectRequest(id: transaction.id, reason: finalReason)
            transaction = updated
            refreshStores()
            rejectReason = ""
        } catch {
            print("❌ Failed to reject request: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func cancelTransaction() async {
        isLoading = true
        do {
            let updated = try await transactionService.cancelTransaction(id: transaction.id)
            transaction = updated
            refreshStores()
        } catch {
            print("❌ Failed to cancel transaction: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func markPayment(userId: String) async {
        isLoading = true
        do {
            let role = isOwner(userId: userId) ? "OWNER" : "BORROWER"
            let updated = try await transactionService.markPaymentComplete(id: transaction.id, role: role)
            transaction = updated
            refreshStores()
        } catch {
            print("❌ Failed to mark payment: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    private func refreshStores() {
        AppDataStore.shared.invalidateOwnerTransactions()
        AppDataStore.shared.invalidateBorrowerTransactions()
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
