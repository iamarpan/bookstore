import SwiftUI

// MARK: - Condition Dots (shared component)
struct ConditionDotsView: View {
    let condition: BookCondition

    private var filledCount: Int {
        switch condition {
        case .new: return 5
        case .likeNew: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? AppTheme.primaryAccent : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var libraryViewModel: MyLibraryViewModel
    @State private var showingFilterSheet = false
    @State private var hasConfiguredNavBar = false

    var body: some View {
        NavigationView {
            mainContent
                .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
                .navigationTitle("BookShare")
                .navigationBarTitleDisplayMode(.large)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .alert("Error", isPresented: $homeViewModel.showError) {
                    Button("OK") { }
                } message: {
                    Text(homeViewModel.errorMessage ?? "An unknown error occurred")
                }
                .sheet(isPresented: $showingFilterSheet) {
                    FilterSheet()
                        .environmentObject(homeViewModel)
                }
                .onAppear {
                    if !hasConfiguredNavBar { setupNavigationBarAppearance() }
                }
                .onChange(of: themeManager.isDarkMode) { _, _ in
                    setupNavigationBarAppearance()
                }
        }
        .accentColor(AppTheme.primaryAccent)
    }

    private var mainContent: some View {
        VStack(spacing: 16) {
            searchSection
            contentSection
        }
    }

    private var searchSection: some View {
        HStack {
            searchBar
            filterButton
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))

            TextField("Search books, authors...", text: $homeViewModel.searchText.animation(nil))
                .font(AppTheme.bodyFont())
                .autocorrectionDisabled()
                .appTextFieldStyle(isDarkMode: themeManager.isDarkMode)
        }
        .shadow(color: AppTheme.shadowCard, radius: 10, x: 0, y: 4)
    }

    private var filterButton: some View {
        Button(action: { showingFilterSheet.toggle() }) {
            Image(systemName: homeViewModel.hasActiveFilters
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "slider.horizontal.3")
                .font(.title2)
                .foregroundColor(homeViewModel.hasActiveFilters
                                 ? AppTheme.primaryAccent
                                 : AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                .padding(12)
                .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                .clipShape(Circle())
                .shadow(color: AppTheme.shadowCard, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var contentSection: some View {
        ScrollView {
            if homeViewModel.isLoading {
                loadingView
            } else if homeViewModel.hasActiveFilters {
                // Filtered: flat grid
                VStack(alignment: .leading, spacing: 16) {
                    if homeViewModel.filteredBooks.isEmpty {
                        emptyStateView
                    } else {
                        Text("Results")
                            .font(AppTheme.headerFont(size: 20))
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                            .padding(.horizontal, 16)
                        flatGrid(homeViewModel.filteredBooks)
                    }
                }
                .padding(.vertical, 8)
            } else {
                // Default: curated carousels
                VStack(alignment: .leading, spacing: 28) {
                    if !availableBooks.isEmpty {
                        BookCarouselSection(
                            title: "Available Now",
                            icon: "checkmark.circle.fill",
                            iconColor: AppTheme.successColor,
                            books: availableBooks,
                            isDarkMode: themeManager.isDarkMode
                        )
                    }
                    if !recentBooks.isEmpty {
                        BookCarouselSection(
                            title: "Recently Added",
                            icon: "sparkles",
                            iconColor: AppTheme.primaryAccent,
                            books: recentBooks,
                            isDarkMode: themeManager.isDarkMode
                        )
                    }
                    if !popularBooks.isEmpty {
                        BookCarouselSection(
                            title: "Popular in Groups",
                            icon: "person.3.fill",
                            iconColor: AppTheme.secondaryAccent,
                            books: popularBooks,
                            isDarkMode: themeManager.isDarkMode
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 100) }
        .refreshable {
            Task { await homeViewModel.refreshBooks() }
        }
    }

    // MARK: - Carousel Data Sources
    private var availableBooks: [Book] {
        homeViewModel.books.filter { book in
            guard book.isAvailable else { return false }
            
            // Redundant check: Filter out if the current user has an active involvement with this book
            let isInvolved = libraryViewModel.borrowedBooks.contains { txn in
                txn.bookId == book.id && (txn.status == .pending || txn.status == .approved || txn.status == .active)
            }
            return !isInvolved
        }
    }
    private var recentBooks: [Book] {
        Array(homeViewModel.books.sorted { $0.createdAt > $1.createdAt }.prefix(10))
    }
    private var popularBooks: [Book] {
        Array(homeViewModel.books
            .filter { !$0.visibleInGroups.isEmpty || !homeViewModel.selectedGroupIds.isEmpty }
            .sorted { ($0.ownerRating ?? 0) > ($1.ownerRating ?? 0) }
            .prefix(10))
    }

    @ViewBuilder
    private func flatGrid(_ items: [Book]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 20) {
            ForEach(items) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookTileView(book: book, isDarkMode: themeManager.isDarkMode)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading books...")
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .accentColor(AppTheme.primaryAccent)
            Spacer()
        }
        .frame(height: 200)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            Text("No books found")
                .font(.title2)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            Text("Try adjusting your search or filters")
                .font(.caption)
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func setupNavigationBarAppearance() {
        hasConfiguredNavBar = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Book Carousel Section
struct BookCarouselSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let books: [Book]
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(AppTheme.headerFont(size: 20))
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(books) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            CarouselBookCard(book: book, isDarkMode: isDarkMode)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Carousel Book Card
struct CarouselBookCard: View {
    let book: Book
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: book.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.colorSecondaryBackground(for: isDarkMode))
                        .overlay(
                            Image(systemName: "book.closed.fill")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                        )
                }
                .frame(width: 130, height: 180)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])

                Text(bookStatusText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(bookStatusColor)
                    .cornerRadius(8)
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(AppTheme.bodyFont(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(book.author)
                    .font(AppTheme.bodyFont(size: 11))
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                    .lineLimit(1)

                ConditionDotsView(condition: book.condition)

                Text(book.formattedPrice)
                    .font(AppTheme.bodyFont(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.primaryAccent)
            }
            .padding(8)
        }
        .frame(width: 130)
        .background(AppTheme.colorCardBackground(for: isDarkMode))
        .cornerRadius(12)
        .shadow(color: AppTheme.shadowCard, radius: 6, x: 0, y: 3)
    }

    // MARK: - Status Helpers
    @EnvironmentObject var libraryViewModel: MyLibraryViewModel

    private var bookStatusText: String {
        if let txn = libraryViewModel.borrowedBooks.first(where: { $0.bookId == book.id }) {
            if txn.status == .pending || txn.status == .approved {
                return "Requested"
            } else if txn.status == .active {
                return "Borrowed"
            }
        }
        return book.isAvailable ? "Available" : "Borrowed"
    }

    private var bookStatusColor: Color {
        if let txn = libraryViewModel.borrowedBooks.first(where: { $0.bookId == book.id }) {
            if txn.status == .pending || txn.status == .approved {
                return AppTheme.warningColor // Orange/Yellow
            } else if txn.status == .active {
                return AppTheme.primaryAccent // Blue
            }
        }
        return book.isAvailable ? AppTheme.successColor : AppTheme.warningColor
    }
}

// MARK: - Book Tile View (flat grid)
struct BookTileView: View {
    let book: Book
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: book.imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.colorSecondaryBackground(for: isDarkMode))
                        .overlay(
                            Image(systemName: "book.closed.fill")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                        )
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .cornerRadius(12)

                Text(bookStatusText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(bookStatusColor)
                    .cornerRadius(8)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(AppTheme.headerFont(size: 18))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                    .fixedSize(horizontal: false, vertical: true)

                Text("by \(book.author)")
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                    .lineLimit(1)

                ConditionDotsView(condition: book.condition)

                Spacer(minLength: 8)

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                        Text(book.ownerName)
                            .font(AppTheme.bodyFont(size: 12))
                            .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(book.formattedPrice)
                        .font(AppTheme.bodyFont(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(12)
        .appCardStyle()
    }

    // MARK: - Status Helpers
    @EnvironmentObject var libraryViewModel: MyLibraryViewModel

    private var bookStatusText: String {
        if let txn = libraryViewModel.borrowedBooks.first(where: { $0.bookId == book.id }) {
            if txn.status == .pending || txn.status == .approved {
                return "Requested"
            } else if txn.status == .active {
                return "Borrowed"
            }
        }
        return book.isAvailable ? "Available" : "Borrowed"
    }

    private var bookStatusColor: Color {
        if let txn = libraryViewModel.borrowedBooks.first(where: { $0.bookId == book.id }) {
            if txn.status == .pending || txn.status == .approved {
                return AppTheme.warningColor
            } else if txn.status == .active {
                return AppTheme.primaryAccent
            }
        }
        return book.isAvailable ? AppTheme.successColor : AppTheme.warningColor
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                genreSection
                availabilitySection
                Spacer()
                clearButton
            }
            .padding()
            .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
        }
        .accentColor(AppTheme.primaryAccent)
    }

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genre").font(.headline).fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(homeViewModel.genres, id: \.self) { genre in
                    FilterOptionButton(title: genre, isSelected: homeViewModel.selectedGenre == genre, isDarkMode: themeManager.isDarkMode) {
                        homeViewModel.selectedGenre = genre
                    }
                }
            }
        }
    }

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Availability").font(.headline).fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            VStack(spacing: 8) {
                ForEach(homeViewModel.availabilityOptions, id: \.self) { avail in
                    FilterOptionButton(title: avail, isSelected: homeViewModel.selectedAvailability == avail, isDarkMode: themeManager.isDarkMode) {
                        homeViewModel.selectedAvailability = avail
                    }
                }
            }
        }
    }

    @ViewBuilder private var clearButton: some View {
        if homeViewModel.hasActiveFilters {
            Button(action: { homeViewModel.clearFilters() }) {
                Text("Clear All Filters")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.errorColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.errorColor.opacity(0.1))
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Filter Option Button
struct FilterOptionButton: View {
    let title: String
    let isSelected: Bool
    let isDarkMode: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppTheme.colorPrimaryText(for: isDarkMode))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(isSelected ? AppTheme.primaryAccent : AppTheme.colorSecondaryBackground(for: isDarkMode))
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(HomeViewModel())
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
                .environmentObject(MyLibraryViewModel())
        }
    }
}