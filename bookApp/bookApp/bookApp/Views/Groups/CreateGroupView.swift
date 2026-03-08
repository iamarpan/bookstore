import SwiftUI

/// Screen for creating a new book club
struct CreateGroupView: View {
    @StateObject private var viewModel = CreateGroupViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            // MARK: - Cover Photo
            Section {
                Button(action: {
                    // Image picker would go here
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryAccent)

                        VStack(alignment: .leading) {
                            Text("Add Cover Photo")
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                            Text("Choose a photo for your group")
                                .font(.caption)
                                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    }
                }
            }

            // MARK: - Group Details
            Section(
                header: Text("Group Details")
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            ) {
                TextField("Group Name", text: $viewModel.name)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                TextField("Description", text: $viewModel.description, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                Picker("Category", selection: $viewModel.category) {
                    ForEach(GroupCategory.availableCategories, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .accentColor(AppTheme.primaryAccent)
            }

            // MARK: - Privacy
            Section(
                header: Text("Privacy")
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            ) {
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

            // MARK: - Location
            Section(
                header: Text("Location")
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            ) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppTheme.primaryAccent)
                    Text("Current Location")
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    Spacer()
                    Button("Update") {
                        // Location update action
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primaryAccent)
                }
            }

            // MARK: - Create Button (mirrors AddBookView pattern)
            Section {
                Button(action: {
                    guard let userId = authViewModel.currentUser?.id else {
                        viewModel.errorMessage = "You must be logged in to create a group."
                        viewModel.showError = true
                        return
                    }
                    Task {
                        await viewModel.createGroup(userId: userId)
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .accentColor(.white)
                            Text("Creating Group...")
                                .foregroundColor(.white)
                        } else {
                            Text("Create Group")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        viewModel.isValid && !viewModel.isLoading
                            ? AppTheme.primaryAccent
                            : AppTheme.colorTertiaryText(for: themeManager.isDarkMode)
                    )
                    .cornerRadius(10)
                }
                .disabled(viewModel.isLoading || !viewModel.isValid)
                .listRowBackground(Color.clear)
            }
        }
        // Mirrors AddBookView: hide default Form background, apply app theme
        .scrollContentBackground(.hidden)
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        // Mirrors AddBookView: pushes content above FloatingDock/tab bar
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 100)
        }
        .navigationTitle("Create Group")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(AppTheme.primaryAccent)
        // Validation hint — shown when user taps Create with empty fields
        .alert("Missing Fields", isPresented: $viewModel.showValidationAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.validationMessage)
        }
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

    // MARK: - Privacy Row Helper

    private func privacyOption(
        title: String,
        description: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(
                        isSelected
                            ? AppTheme.primaryAccent
                            : AppTheme.colorTertiaryText(for: themeManager.isDarkMode)
                    )
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                        .foregroundColor(
                            isSelected
                                ? AppTheme.primaryAccent
                                : AppTheme.colorPrimaryText(for: themeManager.isDarkMode)
                        )
                    Text(description)
                        .font(.caption)
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(
                        isSelected
                            ? AppTheme.primaryAccent
                            : AppTheme.colorTertiaryText(for: themeManager.isDarkMode)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
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
    @Published var showValidationAlert = false
    @Published var validationMessage = ""

    private var groupService: GroupService = GroupService()
    init() {}

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func createGroup(userId: String) async {
        guard isValid else {
            validationMessage = buildValidationMessage()
            showValidationAlert = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let _ = try await groupService.createGroup(
                name: name,
                description: description,
                category: category,
                privacy: privacy
            )
            showSuccess = true
            print("✅ Group created: \(name)")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    // MARK: - Private Helpers

    private func buildValidationMessage() -> String {
        var missing: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("Group Name")
        }
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("Description")
        }
        return "Please fill in: \(missing.joined(separator: ", "))."
    }
}

// MARK: - GroupCategory Extension

extension GroupCategory {
    /// Single source of truth for the picker — no hardcoded arrays in the View
    static let availableCategories: [GroupCategory] = [
        .friends, .office, .neighborhood, .bookClub, .school
    ]
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
