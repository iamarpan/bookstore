import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Search Bar with Filter Button
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                        
                        TextField("Search books, authors, genres...", text: $homeViewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    }
                    .padding()
                    .background(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
                    .cornerRadius(10)
                    
                    Button(action: {
                        showingFilterSheet.toggle()
                    }) {
                        Image(systemName: homeViewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(homeViewModel.hasActiveFilters ? AppTheme.primaryGreen : AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Books Grid
                if homeViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading books...")
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        .accentColor(AppTheme.primaryGreen)
                    Spacer()
                } else if homeViewModel.filteredBooks.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                        Text("No books found")
                            .font(.title2)
                            .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                        Text("Try adjusting your search or filters")
                            .font(.caption)
                            .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                    }
                    Spacer()
                } else {
                    ScrollView {
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
                        .padding(.top, 4)
                    }
                    .refreshable {
                        homeViewModel.refreshBooks()
                    }
                }
            }
            .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("BookStore")
            .navigationBarTitleDisplayMode(.large)
            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
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
            .onChange(of: themeManager.isDarkMode) { _ in
                setupNavigationBarAppearance()
            }
        }
        .accentColor(AppTheme.primaryGreen)
    }
    
    private func setupNavigationBarAppearance() {
        // Customize navigation bar appearance based on theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode))
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))]
        
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
            VStack(alignment: .leading, spacing: 24) {
                // Genre Filter Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Genre")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    
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
                
                // Availability Filter Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Availability")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                    
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
                
                Spacer()
                
                // Clear Filters Button
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
            .padding()
            .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppTheme.primaryGreen)
            )
        }
        .accentColor(AppTheme.primaryGreen)
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
                .foregroundColor(isSelected ? .white : AppTheme.dynamicPrimaryText(isDarkMode))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(isSelected ? AppTheme.primaryGreen : AppTheme.dynamicSecondaryBackground(isDarkMode))
                .cornerRadius(10)
        }
    }
}

struct BookTileView: View {
    let book: Book
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Cover
            AsyncImage(url: URL(string: book.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.dynamicSecondaryBackground(isDarkMode))
                    .overlay(
                        Image(systemName: "book")
                            .font(.title)
                            .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                    )
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .cornerRadius(8)
            .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
                
                Text("by \(book.author)")
                    .font(.caption)
                    .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
                    .lineLimit(1)
                
                Text(book.genre)
                    .font(.caption2)
                    .foregroundColor(AppTheme.primaryGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.lightGreen)
                    .cornerRadius(4)
                
                Spacer(minLength: 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Owner: \(book.ownerName)")
                        .font(.caption2)
                        .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                        .lineLimit(1)
                    
                    Text(book.isAvailable ? "Available" : "Borrowed")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(book.isAvailable ? AppTheme.successColor : AppTheme.warningColor)
                }
            }
        }
        .padding(12)
        .background(AppTheme.dynamicCardBackground(isDarkMode))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(HomeViewModel())
                .environmentObject(ThemeManager())
        }
    }
} 