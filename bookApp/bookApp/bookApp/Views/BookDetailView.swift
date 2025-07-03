import SwiftUI

struct BookDetailView: View {
    @StateObject private var viewModel: BookDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(book: Book) {
        self._viewModel = StateObject(wrappedValue: BookDetailViewModel(book: book))
    }
    
    var body: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .alert("Request Sent!", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Your request has been sent to \(viewModel.book.ownerName). They will be notified about your request.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BookHeaderView(book: viewModel.book)
                BookDescriptionView(book: viewModel.book)
                OwnerInfoView(book: viewModel.book)
                requestStatusSection
                requestButtonSection
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var requestStatusSection: some View {
        if let status = viewModel.requestStatus {
            RequestStatusView(status: status, requestStatus: viewModel.existingRequest?.status)
        }
    }
    
    private var requestButtonSection: some View {
        RequestButtonView(
            title: viewModel.requestButtonTitle,
            canRequest: viewModel.canRequestBook,
            isLoading: viewModel.isLoading,
            hasRequested: viewModel.hasRequestedBook
        ) {
            if viewModel.hasRequestedBook {
                Task {
                    await viewModel.cancelRequest()
                }
            } else {
                Task {
                    await viewModel.requestBook()
                }
            }
        }
    }
}

struct BookHeaderView: View {
    let book: Book
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Book cover
            AsyncImage(url: URL(string: book.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .overlay(
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 120, height: 180)
            .cornerRadius(12)
            .shadow(radius: 5)
            
            // Book info
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(3)
                
                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Genre tag
                Text(book.genre)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(12)
                
                // Availability status
                HStack {
                    Circle()
                        .fill(book.isAvailable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(book.isAvailable ? "Available" : "Currently Borrowed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(book.isAvailable ? .green : .orange)
                }
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

struct BookDescriptionView: View {
    let book: Book
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Book")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(book.description)
                .font(.body)
                .lineLimit(isExpanded ? nil : 4)
                .foregroundColor(.secondary)
            
            if book.description.count > 200 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OwnerInfoView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Book Owner")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.ownerName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Flat \(book.ownerFlatNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Contact button (placeholder)
                Button(action: {
                    // Contact functionality
                }) {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RequestStatusView: View {
    let status: String
    let requestStatus: RequestStatus?
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.system(size: 20))
                .foregroundColor(statusColor)
            
            Text(status)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
            
            Spacer()
        }
        .padding()
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch requestStatus {
        case .pending:
            return "clock.circle.fill"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .returned:
            return "arrow.uturn.left.circle.fill"
        case .overdue:
            return "exclamationmark.triangle.fill"
        default:
            return "info.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch requestStatus {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .returned:
            return .blue
        case .overdue:
            return .red
        default:
            return .gray
        }
    }
}

struct RequestButtonView: View {
    let title: String
    let canRequest: Bool
    let isLoading: Bool
    let hasRequested: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .foregroundColor(.white)
                    
                    Text(hasRequested ? "Canceling..." : "Sending Request...")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: buttonIcon)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(title)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding()
            .background(buttonColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!canRequest && !hasRequested || isLoading)
    }
    
    private var buttonIcon: String {
        if hasRequested {
            return "xmark.circle"
        } else {
            return "hand.raised"
        }
    }
    
    private var buttonColor: Color {
        if !canRequest && !hasRequested {
            return .gray
        } else if hasRequested {
            return .red
        } else {
            return .blue
        }
    }
}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BookDetailView(book: Book.mockBooks[0])
        }
    }
} 