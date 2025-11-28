import SwiftUI

/// Screen for creating a new book club
struct CreateGroupView: View {
    @StateObject private var viewModel = CreateGroupViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Image Placeholder
                    headerImageSection
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Name
                        inputField(
                            title: "Group Name",
                            placeholder: "e.g., Downtown Readers",
                            text: $viewModel.name
                        )
                        
                        // Description
                        inputField(
                            title: "Description",
                            placeholder: "What is this group about?",
                            text: $viewModel.description,
                            isMultiline: true
                        )
                        
                        // Category
                        categoryPicker
                        
                        // Privacy
                        privacySection
                        
                        // Location (Mock)
                        locationSection
                    }
                    .padding()
                }
            }
            
            // Create Button
            createButton
                .padding()
                .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your group has been created successfully!")
        }
    }
    
    // MARK: - Sections
    
    private var headerImageSection: some View {
        Button(action: {
            // Image picker would go here
        }) {
            ZStack {
                Rectangle()
                    .fill(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .frame(height: 150)
                
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundColor(AppTheme.primaryAccent)
                    Text("Add Cover Photo")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
        }
    }
    
    private func inputField(title: String, placeholder: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            if isMultiline {
                TextEditor(text: text)
                    .frame(height: 100)
                    .padding(8)
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: text)
                    .padding()
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Menu {
                ForEach([GroupCategory.friends, .office, .neighborhood, .bookClub, .school], id: \.self) { category in
                    Button(category.displayName) {
                        viewModel.category = category
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.category.displayName)
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                }
                .padding()
                .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            HStack(spacing: 16) {
                privacyOption(
                    title: "Public",
                    description: "Anyone can find and join",
                    icon: "globe",
                    isSelected: viewModel.privacy == .public_,
                    action: { viewModel.privacy = .public_ }
                )
                
                privacyOption(
                    title: "Private",
                    description: "Invite only",
                    icon: "lock.fill",
                    isSelected: viewModel.privacy == .private_,
                    action: { viewModel.privacy = .private_ }
                )
            }
        }
    }
    
    private func privacyOption(title: String, description: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(isSelected ? AppTheme.primaryAccent : AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.primaryAccent)
                    }
                }
                
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? AppTheme.primaryAccent : AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(isSelected ? AppTheme.primaryAccent.opacity(0.1) : AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.primaryAccent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(AppTheme.primaryAccent)
                Text("Current Location")
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                Spacer()
                Text("Update")
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryAccent)
            }
            .padding()
            .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
            .cornerRadius(8)
        }
    }
    
    private var createButton: some View {
        Button(action: {
            Task {
                await viewModel.createGroup(userId: authViewModel.currentUser?.id ?? "")
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create Group")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isValid ? AppTheme.primaryAccent : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.isValid || viewModel.isLoading)
    }
}

// MARK: - ViewModel

@MainActor
class CreateGroupViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var category: GroupCategory = .bookClub
    @Published var privacy: PrivacySetting = .public_
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    
    private let groupService: GroupService
    
    init() {
        self.groupService = GroupService()
    }
    
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func createGroup(userId: String) async {
        guard isValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, we'd call the API
            // let group = try await groupService.createGroup(...)
            
            // For now, simulate success with mock delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            showSuccess = true
            print("✅ Group created: \(name)")
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview
struct CreateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateGroupView()
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
}
