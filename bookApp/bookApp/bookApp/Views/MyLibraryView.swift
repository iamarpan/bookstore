import SwiftUI

struct MyLibraryView: View {
    @EnvironmentObject var viewModel: MyLibraryViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Segmented Control
                Picker("Library Section", selection: $selectedSegment) {
                    Text("Borrowed").tag(0)
                    Text("Lent").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .accentColor(AppTheme.primaryGreen)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading library...")
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        .accentColor(AppTheme.primaryGreen)
                    Spacer()
                } else {
                    if selectedSegment == 0 {
                        BorrowedBooksView(requests: viewModel.borrowedBooks, isDarkMode: themeManager.isDarkMode)
                    } else {
                        LentBooksView(requests: viewModel.lentBooks, viewModel: viewModel, isDarkMode: themeManager.isDarkMode)
                    }
                }
            }
            .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("My Library")
            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
            .refreshable {
                viewModel.refreshLibraryData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
        .accentColor(AppTheme.primaryGreen)
    }
}

struct BorrowedBooksView: View {
    let requests: [BookRequest]
    let isDarkMode: Bool
    
    var body: some View {
        if requests.isEmpty {
            EmptyStateView(
                icon: "books.vertical",
                title: "No Borrowed Books",
                message: "Books you borrow will appear here",
                isDarkMode: isDarkMode
            )
        } else {
            List(requests) { request in
                RequestRowView(request: request, showActions: false, isDarkMode: isDarkMode)
                    .listRowBackground(AppTheme.dynamicCardBackground(isDarkMode))
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(AppTheme.dynamicPrimaryBackground(isDarkMode))
        }
    }
}

struct LentBooksView: View {
    let requests: [BookRequest]
    let viewModel: MyLibraryViewModel
    let isDarkMode: Bool
    
    var body: some View {
        if requests.isEmpty {
            EmptyStateView(
                icon: "person.2",
                title: "No Lent Books",
                message: "Books you lend will appear here",
                isDarkMode: isDarkMode
            )
        } else {
            List(requests) { request in
                RequestRowView(request: request, showActions: true, isDarkMode: isDarkMode) { action in
                    handleRequestAction(request: request, action: action)
                }
                .listRowBackground(AppTheme.dynamicCardBackground(isDarkMode))
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(AppTheme.dynamicPrimaryBackground(isDarkMode))
        }
    }
    
    private func handleRequestAction(request: BookRequest, action: RequestAction) {
        switch action {
        case .approve:
            viewModel.updateRequestStatus(request, newStatus: .approved)
        case .reject:
            viewModel.updateRequestStatus(request, newStatus: .rejected)
        case .markReturned:
            viewModel.updateRequestStatus(request, newStatus: .returned)
        }
    }
}

enum RequestAction {
    case approve, reject, markReturned
}

struct RequestRowView: View {
    let request: BookRequest
    let showActions: Bool
    let isDarkMode: Bool
    let onAction: ((RequestAction) -> Void)?
    
    init(request: BookRequest, showActions: Bool, isDarkMode: Bool, onAction: ((RequestAction) -> Void)? = nil) {
        self.request = request
        self.showActions = showActions
        self.isDarkMode = isDarkMode
        self.onAction = onAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Great Gatsby") // Mock book title
                        .font(.headline)
                        .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
                    
                    Text(showActions ? "Requested by: \(request.borrowerName)" : "Lent by: John Smith")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
                    
                    Text("Flat: \(request.borrowerFlatNumber)")
                        .font(.caption)
                        .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                }
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            HStack {
                Text("Requested: \(request.requestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                
                Spacer()
                
                if !showActions {
                    Button("View Details") {
                        // Navigate to book details
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            
            if showActions && request.status == .pending {
                HStack(spacing: 12) {
                    Button("Approve") {
                        onAction?(.approve)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    
                    Button("Reject") {
                        onAction?(.reject)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
            
            if showActions && request.status == .approved {
                Button("Mark as Returned") {
                    onAction?(.markReturned)
                }
                .buttonStyle(SecondaryButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppTheme.dynamicCardBackground(isDarkMode))
        .cornerRadius(10)
    }
}

struct StatusBadge: View {
    let status: BookRequest.RequestStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForStatus(status))
            .cornerRadius(8)
    }
    
    private func colorForStatus(_ status: BookRequest.RequestStatus) -> Color {
        switch status {
        case .pending: return AppTheme.warningColor
        case .approved: return AppTheme.successColor
        case .rejected: return AppTheme.errorColor
        case .returned: return AppTheme.primaryGreen
        case .overdue: return AppTheme.errorColor
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
            
            Text(message)
                .font(.body)
                .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct MyLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyLibraryView()
                .environmentObject(MyLibraryViewModel())
                .environmentObject(ThemeManager())
        }
    }
} 