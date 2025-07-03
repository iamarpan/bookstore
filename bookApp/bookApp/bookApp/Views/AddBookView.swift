import SwiftUI
import AVFoundation

struct AddBookView: View {
    @StateObject private var viewModel = AddBookViewModel()
    @StateObject private var cameraPermission = CameraPermissionManager()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingISBNScanner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Add").foregroundColor(AppTheme.primaryText)) {
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
                                .foregroundColor(AppTheme.primaryGreen)
                            
                            VStack(alignment: .leading) {
                                Text("Scan ISBN Barcode")
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.primaryText)
                                Text("Auto-fill book details")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            if viewModel.isLoadingFromISBN {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .accentColor(AppTheme.primaryGreen)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.tertiaryText)
                            }
                        }
                    }
                    .disabled(viewModel.isLoadingFromISBN)
                }
                
                Section(header: Text("Book Details").foregroundColor(AppTheme.primaryText)) {
                    TextField("Book Title", text: $viewModel.title)
                        .foregroundColor(AppTheme.primaryText)
                    TextField("Author", text: $viewModel.author)
                        .foregroundColor(AppTheme.primaryText)
                    
                    Picker("Genre", selection: $viewModel.selectedGenre) {
                        ForEach(viewModel.genres, id: \.self) { genre in
                            Text(genre)
                                .foregroundColor(AppTheme.primaryText)
                                .tag(genre)
                        }
                    }
                    .accentColor(AppTheme.primaryGreen)
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(AppTheme.primaryText)
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
                                    .accentColor(.white)
                                Text("Adding Book...")
                                    .foregroundColor(.white)
                            } else {
                                Text("Add Book")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(viewModel.isFormValid && !viewModel.isLoading ? AppTheme.primaryGreen : AppTheme.tertiaryText)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
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
            .onAppear {
                setupFormAppearance()
            }
        }
        .accentColor(AppTheme.primaryGreen)
    }
    
    private func setupFormAppearance() {
        // Customize form appearance for current theme
        UITableView.appearance().backgroundColor = UIColor(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode))
        UITextField.appearance().textColor = UIColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
        UITextView.appearance().textColor = UIColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
    }
}

@MainActor
class AddBookViewModel: ObservableObject {
    @Published var title = ""
    @Published var author = ""
    @Published var selectedGenre = "Fiction"
    @Published var description = ""
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
            
        } catch {
            errorMessage = "Failed to fetch book details: \(error.localizedDescription)"
            showError = true
        }
        
        isLoadingFromISBN = false
    }
    
    func resetForm() {
        title = ""
        author = ""
        selectedGenre = "Fiction"
        description = ""
    }
}

struct AddBookView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookView()
            .environmentObject(ThemeManager())
    }
} 