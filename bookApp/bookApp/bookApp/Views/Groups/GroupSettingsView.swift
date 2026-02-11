import SwiftUI

/// View for editing group settings (admin/creator only)
struct GroupSettingsView: View {
    let group: BookClub
    
    @StateObject private var viewModel: GroupSettingsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingRegenerateAlert = false
    
    init(group: BookClub) {
        self.group = group
        self._viewModel = StateObject(wrappedValue: GroupSettingsViewModel(group: group))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Group Name", text: $viewModel.name)
                    
                    TextField("Description", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $viewModel.category) {
                        ForEach([GroupCategory.friends, .office, .neighborhood, .bookClub, .school], id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Picker("Privacy", selection: $viewModel.privacy) {
                        Text("Public").tag(PrivacySetting.public_)
                        Text("Private").tag(PrivacySetting.private_)
                    }
                }
                
                // Cover Image Section
                Section("Cover Image") {
                    TextField("Image URL (optional)", text: Binding(
                        get: { viewModel.coverImageUrl ?? "" },
                        set: { viewModel.coverImageUrl = $0.isEmpty ? nil : $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }
                
                // Rules Section
                Section("Group Rules") {
                    TextEditor(text: Binding(
                        get: { viewModel.rules ?? "" },
                        set: { viewModel.rules = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 100)
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                
                // Invite Code Section
                Section("Invite Code") {
                    HStack {
                        Text(group.inviteCode)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = group.inviteCode
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(AppTheme.primaryAccent)
                        }
                    }
                    
                    Button(action: { showingRegenerateAlert = true }) {
                        Label("Regenerate Invite Code", systemImage: "arrow.clockwise")
                            .foregroundColor(AppTheme.primaryAccent)
                    }
                }
                
                // Save Button
                Section {
                    Button(action: {
                        Task {
                            await viewModel.saveChanges()
                            if !viewModel.showError {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSaving || !viewModel.hasChanges)
                    .foregroundColor(viewModel.hasChanges ? AppTheme.primaryAccent : .gray)
                }
            }
            .navigationTitle("Group Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Regenerate Invite Code", isPresented: $showingRegenerateAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Regenerate") {
                    Task {
                        await viewModel.regenerateInviteCode()
                    }
                }
            } message: {
                Text("This will invalidate the current invite code. Members who have the old code will no longer be able to join.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

// MARK: - Group Settings ViewModel

@MainActor
class GroupSettingsViewModel: ObservableObject {
    @Published var name: String
    @Published var description: String
    @Published var category: GroupCategory
    @Published var privacy: PrivacySetting
    @Published var coverImageUrl: String?
    @Published var rules: String?
    
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let group: BookClub
    private let groupService: GroupService
    
    init(group: BookClub) {
        self.group = group
        self.groupService = GroupService()
        
        // Initialize with current values
        self.name = group.name
        self.description = group.description
        self.category = group.category
        self.privacy = group.privacy
        self.coverImageUrl = group.coverImageUrl
        self.rules = group.rules
    }
    
    var hasChanges: Bool {
        return name != group.name ||
               description != group.description ||
               category != group.category ||
               privacy != group.privacy ||
               coverImageUrl != group.coverImageUrl ||
               rules != group.rules
    }
    
    func saveChanges() async {
        guard hasChanges else { return }
        
        isSaving = true
        
        do {
            _ = try await groupService.updateGroup(
                id: group.id,
                name: name != group.name ? name : nil,
                description: description != group.description ? description : nil,
                category: category != group.category ? category : nil,
                privacy: privacy != group.privacy ? privacy : nil,
                coverImageUrl: coverImageUrl != group.coverImageUrl ? coverImageUrl : nil,
                rules: rules != group.rules ? rules : nil
            )
            
            print("✅ Group settings saved successfully")
        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
        }
        
        isSaving = false
    }
    
    func regenerateInviteCode() async {
        do {
            let (newCode, _) = try await groupService.regenerateInviteCode(groupId: group.id)
            print("✅ New invite code: \(newCode)")
        } catch {
            errorMessage = "Failed to regenerate invite code: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Preview

struct GroupSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GroupSettingsView(group: BookClub.mockClubs[0])
            .environmentObject(ThemeManager())
    }
}
