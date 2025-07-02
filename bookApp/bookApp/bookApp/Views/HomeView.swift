import SwiftUI

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search books, authors, genres...", text: $homeViewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Genre Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(homeViewModel.genres, id: \.self) { genre in
                            GenreFilterButton(
                                title: genre,
                                isSelected: homeViewModel.selectedGenre == genre
                            ) {
                                homeViewModel.selectedGenre = genre
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Books List
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
                    List(homeViewModel.filteredBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                    .listStyle(PlainListStyle())
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
        }
    }
}

struct GenreFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(15)
        }
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack {
            // Book Cover Placeholder
            AsyncImage(url: URL(string: book.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .overlay(
                        Image(systemName: "book")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("by \(book.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(book.genre)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                HStack {
                    Text("Owner: \(book.ownerName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(book.isAvailable ? "Available" : "Borrowed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(book.isAvailable ? .green : .orange)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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