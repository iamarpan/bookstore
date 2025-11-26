import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel = EditProfileViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section(header: Text("Public Info")) {
                TextField("Name", text: $viewModel.name)
                TextField("Bio", text: $viewModel.bio)
            }
            
            Section {
                Button(action: {
                    Task {
                        await viewModel.saveProfile()
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            viewModel.loadUserData()
        }
        .alert("Success", isPresented: $viewModel.showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Profile updated successfully")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var name = ""
    @Published var bio = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    
    func loadUserData() {
        if let user = User.loadFromUserDefaults() {
            name = user.name
            bio = user.bio ?? ""
        }
    }
    
    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.updateProfile(name: name, bio: bio)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}
