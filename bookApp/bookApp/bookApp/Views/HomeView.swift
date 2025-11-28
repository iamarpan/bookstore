import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingFilterSheet = false
    @State private var showQuickLogoutAlert = false

    var body: some View {
        NavigationView {
            mainContent
                .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
                .navigationTitle("Book Club")
                .navigationBarTitleDisplayMode(.large)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .toolbar {
                    toolbarContent
                }
                .alert("Quick Logout", isPresented: $showQuickLogoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Logout", role: .destructive) {
                        authViewModel.signOut()
                    }
                } message: {
                    Text("Are you sure you want to logout?")
                }
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
                    setupNavigationBarAppearance()
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
            
            TextField("Search books, authors...", text: $homeViewModel.searchText)
                .font(AppTheme.bodyFont())
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(AppTheme.inputRadius)
        .shadow(color: AppTheme.shadowCard, radius: 10, x: 0, y: 4)
    }
    
    private var filterButton: some View {
        Button(action: {
            showingFilterSheet.toggle()
        }) {
            Image(systemName: homeViewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "slider.horizontal.3")
                .font(.title2)
                .foregroundColor(homeViewModel.hasActiveFilters ? AppTheme.primaryAccent : AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                .padding(12)
                .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                .clipShape(Circle())
                .shadow(color: AppTheme.shadowCard, radius: 10, x: 0, y: 4)
        }
    }
    
    private var contentSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Removed activeBookClub section - will be implemented when groups are ready
                
                if homeViewModel.isLoading {
                    loadingView
                } else if homeViewModel.filteredBooks.isEmpty {
                    emptyStateView
                } else {
                    booksGrid
                }
            }
            .padding(.vertical, 8)
        }
        .refreshable {
            Task {
                await homeViewModel.refreshBooks()
            }
        }
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
        VStack {
            Spacer()
            VStack {
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
            Spacer()
        }
        .frame(height: 300)
    }
    
    private var booksGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 20) {
            ForEach(homeViewModel.filteredBooks) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookTileView(book: book, isDarkMode: themeManager.isDarkMode)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Load Mock Data") {
                    homeViewModel.loadMockBooks()
                }
                
                Button("Quick Logout", role: .destructive) {
                    showQuickLogoutAlert = true
                }
                Button("Profile") {
                    // Switch to profile tab - this would need tab coordination
                }
            } label: {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(AppTheme.primaryAccent)
            }
        }
    }

    private func setupNavigationBarAppearance() {
        // Customize navigation bar appearance based on theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

struct FilterSheet: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            filterContent
                .padding()
                .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryAccent)
                )
        }
        .accentColor(AppTheme.primaryAccent)
    }
    
    private var filterContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            genreFilterSection
            availabilityFilterSection
            Spacer()
            clearFiltersButton
        }
    }
    
    private var genreFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Genre")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(homeViewModel.genres, id: \.self) { genre in
                    FilterOptionButton(
                        title: genre,
                        isSelected: homeViewModel.selectedGenre == genre,
                        isDarkMode: themeManager.isDarkMode
                    ) {
                        homeViewModel.selectedGenre = genre
                    }
                }
            }
        }
    }
    
    private var availabilityFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Availability")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            VStack(spacing: 8) {
                ForEach(homeViewModel.availabilityOptions, id: \.self) { availability in
                    FilterOptionButton(
                        title: availability,
                        isSelected: homeViewModel.selectedAvailability == availability,
                        isDarkMode: themeManager.isDarkMode
                    ) {
                        homeViewModel.selectedAvailability = availability
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var clearFiltersButton: some View {
        if homeViewModel.hasActiveFilters {
            Button(action: {
                homeViewModel.clearFilters()
            }) {
                Text("Clear All Filters")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.errorColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.errorColor.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
}

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
    }
}

struct BookTileView: View {
    let book: Book
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book Cover with Deep Shadow
            AsyncImage(url: URL(string: book.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.colorSecondaryBackground(for: isDarkMode))
                    .overlay(
                        Image(systemName: "book.closed.fill")
                            .font(.largeTitle)
                            .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                    )
            }
            .frame(height: 200) // Taller cover
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4) // Cover shadow
            
            VStack(alignment: .leading, spacing: 6) {
                // Title (Serif)
                Text(book.title)
                    .font(AppTheme.headerFont(size: 18)) // Serif font
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Author
                Text("by \(book.author)")
                    .font(AppTheme.bodyFont(size: 14))
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                    .lineLimit(1)
                
                // Genre Tag
                Text(book.genre.uppercased())
                    .font(AppTheme.bodyFont(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.secondaryAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.secondaryAccent.opacity(0.1))
                    .cornerRadius(AppTheme.buttonRadius)
                
                Spacer(minLength: 8)
                
                // Footer: Owner & Availability
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
                    
                    // Availability Dot
                    Circle()
                        .fill(book.isAvailable ? AppTheme.successColor : AppTheme.warningColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .padding(12)
        .appCardStyle() // New card style
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(HomeViewModel())
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
} 