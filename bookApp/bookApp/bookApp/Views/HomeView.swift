import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar with Filter Button
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search books, authors, genres...", text: $homeViewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: {
                        showingFilterSheet.toggle()
                    }) {
                        Image(systemName: homeViewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(homeViewModel.hasActiveFilters ? .blue : .gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Books Grid
                if homeViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading books...")
                    Spacer()
                } else if homeViewModel.filteredBooks.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No books found")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Try adjusting your search or filters")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 16) {
                            ForEach(homeViewModel.filteredBooks) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookTileView(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        homeViewModel.refreshBooks()
                    }
                }
            }
            .navigationTitle("BookStore")
            .alert("Error", isPresented: $homeViewModel.showError) {
                Button("OK") { }
            } message: {
                Text(homeViewModel.errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet()
                    .environmentObject(homeViewModel)
            }
        }
    }
}

struct FilterSheet: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Genre Filter Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Genre")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(homeViewModel.genres, id: \.self) { genre in
                            FilterOptionButton(
                                title: genre,
                                isSelected: homeViewModel.selectedGenre == genre
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
                    
                    VStack(spacing: 8) {
                        ForEach(homeViewModel.availabilityOptions, id: \.self) { availability in
                            FilterOptionButton(
                                title: availability,
                                isSelected: homeViewModel.selectedAvailability == availability
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
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FilterOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(10)
        }
    }
}

struct BookTileView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Cover
            AsyncImage(url: URL(string: book.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .overlay(
                        Image(systemName: "book")
                            .font(.title)
                            .foregroundColor(.gray)
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
                
                Text("by \(book.author)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(book.genre)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer(minLength: 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Owner: \(book.ownerName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text(book.isAvailable ? "Available" : "Borrowed")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(book.isAvailable ? .green : .orange)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(HomeViewModel())
        }
    }
} 