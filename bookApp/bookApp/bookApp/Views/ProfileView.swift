import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSignOutAlert = false
    @State private var notificationsEnabled = true
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppTheme.primaryAccent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                                
                                if !user.joinedGroupIds.isEmpty || !user.createdGroupIds.isEmpty {
                                    Text("Member of Book Club")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                                }
                                
                                Text(user.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                                
                                if let email = user.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        NavigationLink(destination: EditProfileView()) {
                            Text("Edit Profile")
                                .foregroundColor(AppTheme.primaryAccent)
                        }
                    }
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                
                Section(header: Text("Library Stats").foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))) {
                    ProfileStatRow(
                        icon: "books.vertical.fill",
                        iconColor: AppTheme.primaryAccent,
                        title: "Books Added",
                        value: "\(viewModel.booksAddedCount)",
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    ProfileStatRow(
                        icon: "book.fill",
                        iconColor: AppTheme.successColor,
                        title: "Books Borrowed",
                        value: "\(viewModel.booksBorrowedCount)",
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    ProfileStatRow(
                        icon: "person.2.fill",
                        iconColor: AppTheme.warningColor,
                        title: "Books Lent",
                        value: "\(viewModel.booksLentCount)",
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    ProfileStatRow(
                        icon: "star.fill",
                        iconColor: .purple,
                        title: "Reputation",
                        value: String(format: "%.1f", viewModel.reputationScore),
                        isDarkMode: themeManager.isDarkMode
                    )
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                
                Section(header: Text("Settings").foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.errorColor)
                            .frame(width: 24)
                        Text("Notifications")
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .accentColor(AppTheme.primaryAccent)
                    }
                    
                    HStack {
                        Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(themeManager.isDarkMode ? .purple : .orange)
                            .frame(width: 24)
                        Text("Dark Mode")
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                        Spacer()
                        Toggle("", isOn: $themeManager.isDarkMode)
                            .accentColor(AppTheme.primaryAccent)
                    }
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                
                Section(header: Text("Support").foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))) {
                    ProfileMenuRow(
                        icon: "questionmark.circle.fill",
                        iconColor: AppTheme.primaryAccent,
                        title: "Help & Support",
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    ProfileMenuRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Rate App",
                        isDarkMode: themeManager.isDarkMode
                    )
                    
                    ProfileMenuRow(
                        icon: "envelope.fill",
                        iconColor: AppTheme.primaryAccent,
                        title: "Contact Us",
                        isDarkMode: themeManager.isDarkMode
                    )
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                
                Section {
                    Button(action: {
                        // About app functionality
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppTheme.primaryAccent)
                                .frame(width: 24)
                            Text("About App")
                                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                                .font(.caption)
                        }
                    }
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                
                Section {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.errorColor))
                                    .scaleEffect(0.8)
                                    .frame(width: 24)
                            } else {
                                Image(systemName: "arrow.right.square.fill")
                                    .foregroundColor(AppTheme.errorColor)
                                    .frame(width: 24)
                            }
                            Text("Sign Out")
                                .foregroundColor(AppTheme.errorColor)
                            Spacer()
                        }
                    }
                    .disabled(authViewModel.isLoading)
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("Profile")
            .onAppear {
                Task {
                    await viewModel.fetchStats()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
        }
        .accentColor(AppTheme.primaryAccent)
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    authViewModel.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out? This will clear all your local data.")
        }
    }
}

struct ProfileStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                .fontWeight(.medium)
        }
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(title)
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                .font(.caption)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(ThemeManager())
        }
    }
} 