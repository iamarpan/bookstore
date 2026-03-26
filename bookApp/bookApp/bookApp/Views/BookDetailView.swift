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
                        BookInfoSection(
                            book: viewModel.book,
                            statusText: viewModel.availabilityText,
                            statusColor: availabilityColor,
                            isDarkMode: themeManager.isDarkMode
                        )
                        
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
                // No Spacer() here — ZStack(alignment: .bottom) already pins this to the bottom.
                // A Spacer() would grow this VStack to full screen height, blocking the ScrollView.
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).opacity(0),
                            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).opacity(0.9),
                            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .allowsHitTesting(false) // purely decorative — never block touches
                    
                    RequestButtonView(
                        title: viewModel.requestButtonTitle,
                        canRequest: viewModel.canRequestBook,
                        isLoading: viewModel.isLoading,
                        hasRequested: viewModel.hasRequestedBook
                    ) {
                        if viewModel.canRequestBook {
                            showBorrowRequest = true
                        } else if viewModel.hasRequestedBook {
                            viewModel.showTransactionDetail()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBorrowRequest, onDismiss: {
            Task {
                await viewModel.fetchExistingRequest()
            }
        }) {
            NavigationView {
                BorrowRequestView(book: viewModel.book)
            }
        }
        .background(
            Group {
                if let transaction = viewModel.navigateToTransaction {
                    NavigationLink(
                        destination: TransactionDetailView(transaction: transaction),
                        isActive: Binding(
                            get: { viewModel.navigateToTransaction != nil },
                            set: { if !$0 { viewModel.navigateToTransaction = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            }
        )
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
    
    private var availabilityColor: Color {
        if let transaction = viewModel.existingTransaction {
            switch transaction.status {
            case .pending, .approved:
                return AppTheme.warningColor
            case .active:
                return AppTheme.primaryAccent
            default:
                break
            }
        }
        return viewModel.book.isAvailable ? AppTheme.successColor : AppTheme.warningColor
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
                    // Removed per-frame .blur() — was recalculating on every scroll event at 60-120fps
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
            .tilt()
        }
    }
}

struct BookInfoSection: View {
    let book: Book
    let statusText: String
    let statusColor: Color
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

            // Genre + Availability row
            HStack(spacing: 12) {
                Text(book.genre.uppercased())
                    .font(AppTheme.bodyFont(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.secondaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.secondaryAccent.opacity(0.1))
                    .cornerRadius(AppTheme.buttonRadius)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusText)
                        .font(AppTheme.bodyFont(size: 14, weight: .medium))
                        .foregroundColor(statusColor)
                }
            }

            // Condition dots + price
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Condition")
                        .font(AppTheme.bodyFont(size: 11))
                        .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                    ConditionDotsView(condition: book.condition)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Price")
                        .font(AppTheme.bodyFont(size: 11))
                        .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                    Text(book.formattedPrice)
                        .font(AppTheme.bodyFont(size: 18, weight: .bold))
                        .foregroundColor(book.lendingPricePerWeek == 0 ? AppTheme.successColor : AppTheme.primaryAccent)
                }
            }
            .padding(.top, 4)

            // Lending Terms card
            LendingTermsView(book: book, isDarkMode: isDarkMode)
        }
    }
}

// MARK: - Lending Terms
struct LendingTermsView: View {
    let book: Book
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lending Terms")
                .font(AppTheme.bodyFont(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))

            HStack(spacing: 16) {
                // Price per week
                HStack(spacing: 6) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundColor(AppTheme.primaryAccent)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(book.formattedPrice)
                            .font(AppTheme.bodyFont(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                        Text("per week")
                            .font(AppTheme.bodyFont(size: 10))
                            .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                    }
                }

                Divider().frame(height: 30)

                // Condition
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppTheme.successColor)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(book.condition.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(AppTheme.bodyFont(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                        Text("condition")
                            .font(AppTheme.bodyFont(size: 10))
                            .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(AppTheme.colorSecondaryBackground(for: isDarkMode))
            .cornerRadius(12)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("About the Owner")
                .font(AppTheme.bodyFont(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))

            HStack(spacing: 16) {
                // Avatar
                if let imageUrl = book.ownerProfileImageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ownerPlaceholder
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    ownerPlaceholder
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.ownerName)
                        .font(AppTheme.headerFont(size: 18))
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                    HStack(spacing: 12) {
                        if let rating = book.ownerRating, rating > 0 {
                            Label(String(format: "%.1f", rating), systemImage: "star.fill")
                                .font(AppTheme.bodyFont(size: 13))
                                .foregroundColor(.orange)
                        }
                        if let booksCount = book.ownerBooksCount, booksCount > 0 {
                            Label("\(booksCount) books", systemImage: "books.vertical.fill")
                                .font(AppTheme.bodyFont(size: 13))
                                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        }
                    }
                }

                Spacer()

                NavigationLink(destination: PublicProfileView(userId: book.ownerId)) {
                    Text("View Profile")
                        .foregroundColor(AppTheme.primaryAccent)
                        .font(AppTheme.bodyFont(size: 14, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.primaryAccent.opacity(0.1))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(14)

            // Visible in Groups
            if !book.visibleInGroups.isEmpty {
                GroupsVisibilityRow(groupIds: book.visibleInGroups, isDarkMode: themeManager.isDarkMode)
            }
        }
    }

    private var ownerPlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 50))
            .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
    }
}

// MARK: - Groups Visibility
struct GroupsVisibilityRow: View {
    let groupIds: [String]
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Shared in \(groupIds.count) group\(groupIds.count == 1 ? "" : "s")", systemImage: "person.3.fill")
                .font(AppTheme.bodyFont(size: 13))
                .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
        }
        .padding(.horizontal, 4)
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
            .padding(.vertical, 16)
            .background(buttonColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain) // suppress SwiftUI's default button chrome (the second rectangle)
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
            return AppTheme.secondaryAccent
        } else {
            return .blue
        }
    }
}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let book = Book.mockBooks[0]
        NavigationView {
            BookDetailView(book: book)
                .environmentObject(AuthViewModel())
                .environmentObject(ThemeManager())
                .environmentObject(TabManager())
        }
    }
}
