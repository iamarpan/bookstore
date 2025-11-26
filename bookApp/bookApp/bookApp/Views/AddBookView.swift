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
                
                Section(header: Text("Lending Details").foregroundColor(AppTheme.primaryText)) {
                    HStack {
                        Text("Lending Price (per week)")
                            .foregroundColor(AppTheme.primaryText)
                        Spacer()
                        TextField("0.00", text: $viewModel.price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(AppTheme.primaryText)
                            .frame(width: 100)
                    }
                    
                    Picker("Condition", selection: $viewModel.selectedCondition) {
                        ForEach(viewModel.conditions, id: \.self) { condition in
                            Text(condition.rawValue.capitalized)
                                .foregroundColor(AppTheme.primaryText)
                                .tag(condition)
                        }
                    }
                    .accentColor(AppTheme.primaryGreen)
                    
                    Toggle("Available for Lending", isOn: $viewModel.isAvailable)
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                }
                
                Section(header: Text("Visible In Groups").foregroundColor(AppTheme.primaryText)) {
                    if viewModel.userGroups.isEmpty {
                        Text("No groups found. Join a group to share books.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(viewModel.userGroups) { group in
                            HStack {
                                Text(group.name)
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                if viewModel.selectedGroupIds.contains(group.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.primaryGreen)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewModel.selectedGroupIds.contains(group.id) {
                                    viewModel.selectedGroupIds.remove(group.id)
                                } else {
                                    viewModel.selectedGroupIds.insert(group.id)
                                }
                            }
                        }
                    }
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
            .onAppear {
                Task {
                    await viewModel.fetchUserGroups()
                }
            }
            .alert(isPresented: $viewModel.showSuccessAlert) {
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
            .onChange(of: cameraPermission.permissionGranted) { _, granted in
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
    @Published var price = ""
    @Published var selectedCondition: BookCondition = .good
    @Published var isAvailable = true
    @Published var selectedGroupIds: Set<String> = []
    @Published var userGroups: [BookClub] = []
    
    @Published var isLoading = false
    @Published var isLoadingFromISBN = false
    @Published var showSuccessAlert = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let bookService = BookService()
    private let groupService = GroupService()
    
    let genres = ["Fiction", "Biography", "Science", "History", "Technology", "Romance", "Mystery", "Other"]
    let conditions: [BookCondition] = [.new, .likeNew, .good, .fair, .poor]
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedGroupIds.isEmpty
    }
    
    func fetchUserGroups() async {
        guard let userId = User.loadFromUserDefaults()?.id else { return }
        
        do {
            let groups = try await groupService.fetchMyGroups()
            userGroups = groups
            // Select first group by default if none selected
            if selectedGroupIds.isEmpty, let firstGroup = groups.first {
                selectedGroupIds.insert(firstGroup.id)
            }
        } catch {
            print("Error fetching groups: \(error)")
        }
    }
    
    func addBook() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields and select at least one group"
            showError = true
            return
        }
        
        guard let user = User.loadFromUserDefaults() else {
            errorMessage = "Please sign in first"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            let priceValue = Double(price) ?? 0.0
            
            let newBook = Book(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                genre: selectedGenre,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: "https://via.placeholder.com/150", // Placeholder
                condition: selectedCondition,
                lendingPricePerWeek: priceValue,
                isAvailable: isAvailable,
                ownerId: user.id,
                ownerName: user.name,
                visibleInGroups: Array(selectedGroupIds)
            )
            
            let addedBook = try await bookService.createBook(newBook)
            print("✅ Book added successfully with ID: \(addedBook.id)")
            showSuccessAlert = true
            resetForm()
        } catch {
            print("❌ Error adding book: \(error)")
            errorMessage = "Failed to add book: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func fetchBookDetails(from isbn: String) async {
        isLoadingFromISBN = true
        
        do {
            let bookInfo = try await ISBNService.shared.fetchBookInfo(isbn: isbn)
            
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
        price = ""
        selectedCondition = .good
        isAvailable = true
        // Keep selected groups
    }
}

struct AddBookView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookView()
            .environmentObject(ThemeManager())
    }
} 