import SwiftUI
import PhotosUI
import AVFoundation

struct AddBookView: View {
    @StateObject private var viewModel = AddBookViewModel()
    @StateObject private var cameraPermission = CameraPermissionManager()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingISBNScanner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Add")) {
                    Button(action: {
                        if cameraPermission.checkPermission() == .authorized {
                            showingISBNScanner = true
                        } else {
                            cameraPermission.requestPermission()
                        }
                    }) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Scan ISBN Barcode")
                                    .fontWeight(.medium)
                                Text("Auto-fill book details")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.isLoadingFromISBN {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(viewModel.isLoadingFromISBN)
                }
                
                Section(header: Text("Book Cover")) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let image = viewModel.selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(10)
                        } else {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("Tap to select book cover")
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                
                Section(header: Text("Book Details")) {
                    TextField("Book Title", text: $viewModel.title)
                    TextField("Author", text: $viewModel.author)
                    
                    Picker("Genre", selection: $viewModel.selectedGenre) {
                        ForEach(viewModel.genres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.addBook()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Adding Book...")
                            } else {
                                Text("Add Book")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                }
            }
            .navigationTitle("Add Book")
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") { 
                    viewModel.resetForm()
                }
            } message: {
                Text("Book added successfully!")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let newItem = newItem {
                        await viewModel.loadImage(from: newItem)
                    }
                }
            }
            .onChange(of: cameraPermission.permissionGranted) { granted in
                if granted {
                    showingISBNScanner = true
                }
            }
            .sheet(isPresented: $showingISBNScanner) {
                ISBNScannerView(isPresented: $showingISBNScanner) { isbn in
                    showingISBNScanner = false
                    Task {
                        await viewModel.fetchBookDetails(from: isbn)
                    }
                }
            }
        }
    }
}

@MainActor
class AddBookViewModel: ObservableObject {
    @Published var title = ""
    @Published var author = ""
    @Published var selectedGenre = "Fiction"
    @Published var description = ""
    @Published var selectedImage: UIImage?
    @Published var isLoading = false
    @Published var isLoadingFromISBN = false
    @Published var showSuccessAlert = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    let genres = ["Fiction", "Biography", "Science", "History", "Technology", "Romance", "Mystery", "Other"]
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func loadImage(from photoItem: PhotosPickerItem) async {
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func addBook() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        isLoading = true
        
        // Simulate API call
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showSuccessAlert = true
        } catch {
            errorMessage = "Failed to add book: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func fetchBookDetails(from isbn: String) async {
        isLoadingFromISBN = true
        
        do {
            let bookInfo = try await ISBNService.shared.fetchBookInfo(isbn: isbn)
            
            // Update form fields with fetched data
            title = bookInfo.title
            author = bookInfo.authors
            selectedGenre = bookInfo.genre
            description = bookInfo.description
            
            // Load cover image if available
            if !bookInfo.imageURL.isEmpty {
                await loadImageFromURL(bookInfo.imageURL)
            }
            
        } catch {
            errorMessage = "Failed to fetch book details: \(error.localizedDescription)"
            showError = true
        }
        
        isLoadingFromISBN = false
    }
    
    private func loadImageFromURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            // Silently fail - image loading is not critical
            print("Failed to load image from URL: \(error)")
        }
    }
    
    func resetForm() {
        title = ""
        author = ""
        selectedGenre = "Fiction"
        description = ""
        selectedImage = nil
    }
}

struct AddBookView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookView()
    }
} 