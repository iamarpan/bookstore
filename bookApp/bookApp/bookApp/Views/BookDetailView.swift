import SwiftUI

struct BookDetailView: View {
    @StateObject private var viewModel: BookDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var tabManager: TabManager
    @State private var showBorrowRequest = false
    
    init(book: Book) {
        self._viewModel = StateObject(wrappedValue: BookDetailViewModel(book: book))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Parallax Header
                    ParallaxHeader(book: viewModel.book)
                        .frame(height: 300)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 24) {
                        BookInfoSection(book: viewModel.book, isDarkMode: themeManager.isDarkMode)
                        
                        Divider()
                            .background(AppTheme.separatorColor)
                        
                        BookDescriptionView(book: viewModel.book)
                        
                        OwnerInfoView(book: viewModel.book)
                        
                        if let status = viewModel.requestStatus {
                            RequestStatusView(status: status, requestStatus: viewModel.existingTransaction?.status)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(24)
                    .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(30, corners: [.topLeft, .topRight])
                    .offset(y: -30) // Overlap the header
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // Floating Action Bar
            if viewModel.canRequestBook || viewModel.hasRequestedBook {
                VStack {
                    Spacer()
                    RequestButtonView(
                        title: viewModel.requestButtonTitle,
                        canRequest: viewModel.canRequestBook,
                        isLoading: viewModel.isLoading,
                        hasRequested: viewModel.hasRequestedBook
                    ) {
                        if viewModel.canRequestBook {
                            showBorrowRequest = true
                        } else if viewModel.hasRequestedBook {
                            Task {
                                await viewModel.cancelRequest()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).opacity(0),
                            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).opacity(0.9),
                            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBorrowRequest) {
            NavigationView {
                BorrowRequestView(book: viewModel.book)
            }
        }
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
        .onAppear {
            tabManager.hide()
        }
        .onDisappear {
            tabManager.show()
        }
    }
}

struct ParallaxHeader: View {
    let book: Book
    
    var body: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .global).minY
            
            ZStack {
                AsyncImage(url: URL(string: book.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height + (minY > 0 ? minY : 0))
                        .clipped()
                        .offset(y: (minY > 0 ? -minY : 0))
                        .blur(radius: minY < 0 ? abs(minY) / 20 : 0) // Blur on scroll up
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
            }
        }
    }
}

struct BookInfoSection: View {
    let book: Book
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .font(AppTheme.headerFont(size: 28))
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                .fixedSize(horizontal: false, vertical: true)
            
            Text("by \(book.author)")
                .font(AppTheme.bodyFont(size: 18, weight: .medium))
                .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
            
            HStack(spacing: 12) {
                // Genre Tag
                Text(book.genre.uppercased())
                    .font(AppTheme.bodyFont(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.secondaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.secondaryAccent.opacity(0.1))
                    .cornerRadius(AppTheme.buttonRadius)
                
                // Availability
                HStack(spacing: 4) {
                    Circle()
                        .fill(book.isAvailable ? AppTheme.successColor : AppTheme.warningColor)
                        .frame(width: 8, height: 8)
                    Text(book.isAvailable ? "Available" : "Borrowed")
                        .font(AppTheme.bodyFont(size: 14, weight: .medium))
                        .foregroundColor(book.isAvailable ? AppTheme.successColor : AppTheme.warningColor)
                }
            }
            
            // Condition & Price
            HStack(spacing: 16) {
                Label(book.condition.rawValue.capitalized, systemImage: "star.fill")
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                
                if book.lendingPricePerWeek > 0 {
                    Label(String(format: "$%.2f/week", book.lendingPricePerWeek), systemImage: "tag.fill")
                        .font(AppTheme.bodyFont(size: 14))
                        .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                } else {
                    Label("Free to Borrow", systemImage: "gift.fill")
                        .font(AppTheme.bodyFont(size: 14))
                        .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                }
            }
            .padding(.top, 8)
        }
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct BookDescriptionView: View {
    let book: Book
    @State private var isExpanded = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Book")
                .font(AppTheme.headerFont(size: 20))
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Text(book.description)
                .font(AppTheme.bodyFont(size: 16))
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                .lineLimit(isExpanded ? nil : 4)
                .lineSpacing(4)
            
            Button(action: { isExpanded.toggle() }) {
                Text(isExpanded ? "Read Less" : "Read More")
                    .font(AppTheme.bodyFont(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryAccent)
            }
        }
    }
}

struct OwnerInfoView: View {
    let book: Book
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Owned by")
                    .font(AppTheme.bodyFont(size: 12))
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                
                Text(book.ownerName)
                    .font(AppTheme.headerFont(size: 18))
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            }
            
            Spacer()
            
            Button(action: {
                // View Profile action
            }) {
                Text("View Profile")
                    .font(AppTheme.bodyFont(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.primaryAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryAccent.opacity(0.1))
                    .cornerRadius(AppTheme.buttonRadius)
            }
        }
        .padding()
        .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
        .cornerRadius(AppTheme.cardRadius)
    }
}

struct RequestStatusView: View {
    let status: RequestStatus
    let requestStatus: TransactionStatus?
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
            Text(statusMessage)
                .font(AppTheme.bodyFont(size: 14, weight: .medium))
            Spacer()
        }
        .padding()
        .background(backgroundColor.opacity(0.1))
        .foregroundColor(backgroundColor)
        .cornerRadius(AppTheme.inputRadius)
    }
    
    var iconName: String {
        switch status {
        case .canRequest: return "arrow.right.circle"
        case .requested: return "clock.fill"
        case .borrowed: return "book.fill"
        case .unavailable: return "xmark.circle.fill"
        case .ownBook: return "person.fill"
        }
    }
    
    var statusMessage: String {
        switch status {
        case .canRequest: return "Available to borrow"
        case .requested: return "Request Pending"
        case .borrowed: return "Currently Borrowed"
        case .unavailable: return "Currently Unavailable"
        case .ownBook: return "This is your book"
        }
    }
    
    var backgroundColor: Color {
        switch status {
        case .canRequest: return AppTheme.successColor
        case .requested: return AppTheme.warningColor
        case .borrowed: return AppTheme.primaryAccent
        case .unavailable: return AppTheme.errorColor
        case .ownBook: return AppTheme.secondaryAccent
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
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
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