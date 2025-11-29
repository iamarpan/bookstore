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
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                }
                
                Section(header: Text("Book Details").foregroundColor(AppTheme.primaryText)) {
                    ZStack(alignment: .leading) {
                        if viewModel.title.isEmpty {
                            Text("Book Title")
                                .foregroundStyle(themeManager.isDarkMode ? Color.gray.opacity(0.6) : Color.gray.opacity(0.5))
                        }
                        TextField("", text: $viewModel.title)
                            .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                    }
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                    ZStack(alignment: .leading) {
                        if viewModel.author.isEmpty {
                            Text("Author")
                                .foregroundStyle(themeManager.isDarkMode ? Color.gray.opacity(0.6) : Color.gray.opacity(0.5))
                        }
                        TextField("", text: $viewModel.author)
                            .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                    }
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                    
                    HStack {
                        Text("Genre")
                            .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                        Spacer()
                        Picker("", selection: $viewModel.selectedGenre) {
                            ForEach(viewModel.genres, id: \.self) { genre in
                                Text(genre)
                                    .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                                    .tag(genre)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(AppTheme.primaryGreen)
                    }
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.description.isEmpty {
                            Text("Description")
                                .foregroundStyle(themeManager.isDarkMode ? Color.gray.opacity(0.6) : Color.gray.opacity(0.5))
                                .padding(.top, 8)
                        }
                        TextField("", text: $viewModel.description, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                    }
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                }
                
                Section(header: Text("Lending Details").foregroundColor(AppTheme.primaryText)) {
                    HStack {
                        Text("Lending Price (per week)")
                            .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                        Spacer()
                        ZStack(alignment: .trailing) {
                            if viewModel.price.isEmpty {
                                Text("0.00")
                                    .foregroundStyle(themeManager.isDarkMode ? Color.gray.opacity(0.6) : Color.gray.opacity(0.5))
                            }
                            TextField("", text: $viewModel.price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                        }
                        .frame(width: 100)
                    }
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                    
                    HStack {
                        Text("Condition")
                            .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                        Spacer()
                        Picker("", selection: $viewModel.selectedCondition) {
                            ForEach(viewModel.conditions, id: \.self) { condition in
                                Text(condition.rawValue.capitalized)
                                    .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                                    .tag(condition)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(AppTheme.primaryGreen)
                    }
                    .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                    
                    Toggle("Available for Lending", isOn: $viewModel.isAvailable)
                        .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                        .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                }
                
                Section(header: Text("Visible In Groups").foregroundColor(AppTheme.primaryText)) {
                    if viewModel.userGroups.isEmpty {
                        Text("No groups found. Join a group to share books.")
                            .foregroundStyle(themeManager.isDarkMode ? Color.gray : Color.secondary)
                            .font(.caption)
                            .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                    } else {
                        ForEach(viewModel.userGroups) { group in
                            HStack {
                                Text(group.name)
                                    .foregroundStyle(themeManager.isDarkMode ? Color.white : Color.black)
                                Spacer()
                                if viewModel.selectedGroupIds.contains(group.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.primaryGreen)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(AppTheme.tertiaryText)
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
                            .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
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
        
        // Configure TextField placeholder colors based on theme
        if themeManager.isDarkMode {
            UITextField.appearance().attributedPlaceholder = nil
            UITextField.appearance().keyboardAppearance = .dark
        } else {
            UITextField.appearance().attributedPlaceholder = nil
            UITextField.appearance().keyboardAppearance = .light
        }
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
        guard User.loadFromUserDefaults() != nil else { return }
        
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