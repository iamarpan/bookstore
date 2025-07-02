import SwiftUI

struct MyLibraryView: View {
    @EnvironmentObject var viewModel: MyLibraryViewModel
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
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading library...")
                    Spacer()
                } else {
                    if selectedSegment == 0 {
                        BorrowedBooksView(requests: viewModel.borrowedBooks)
                    } else {
                        LentBooksView(requests: viewModel.lentBooks, viewModel: viewModel)
                    }
                }
            }
            .navigationTitle("My Library")
            .refreshable {
                viewModel.refreshLibraryData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

struct BorrowedBooksView: View {
    let requests: [BookRequest]
    
    var body: some View {
        if requests.isEmpty {
            EmptyStateView(
                icon: "books.vertical",
                title: "No Borrowed Books",
                message: "Books you borrow will appear here"
            )
        } else {
            List(requests) { request in
                RequestRowView(request: request, showActions: false)
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct LentBooksView: View {
    let requests: [BookRequest]
    let viewModel: MyLibraryViewModel
    
    var body: some View {
        if requests.isEmpty {
            EmptyStateView(
                icon: "person.2",
                title: "No Lent Books",
                message: "Books you lend will appear here"
            )
        } else {
            List(requests) { request in
                RequestRowView(request: request, showActions: true) { action in
                    handleRequestAction(request: request, action: action)
                }
            }
            .listStyle(PlainListStyle())
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
    let onAction: ((RequestAction) -> Void)?
    
    init(request: BookRequest, showActions: Bool, onAction: ((RequestAction) -> Void)? = nil) {
        self.request = request
        self.showActions = showActions
        self.onAction = onAction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Great Gatsby") // Mock book title
                        .font(.headline)
                    
                    Text(showActions ? "Requested by: \(request.borrowerName)" : "Lent by: John Smith")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Flat: \(request.borrowerFlatNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: request.status)
            }
            
            HStack {
                Text("Requested: \(request.requestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !showActions {
                    Button("View Details") {
                        // Navigate to book details
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if showActions && request.status == .pending {
                HStack(spacing: 12) {
                    Button("Approve") {
                        onAction?(.approve)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reject") {
                        onAction?(.reject)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
            
            if showActions && request.status == .approved {
                Button("Mark as Returned") {
                    onAction?(.markReturned)
                }
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
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
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .returned: return .blue
        case .overdue: return .red
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
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
        }
    }
} 