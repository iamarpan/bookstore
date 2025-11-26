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
                                .foregroundColor(AppTheme.primaryGreen)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                                
                                if let clubId = user.joinedGroupIds.first ?? user.createdGroupIds.first {
                                    Text("Member of Book Club")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                }
                                
                                Text(user.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                                
                                if let email = user.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.dynamicSecondaryText(themeManager.isDarkMode))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        NavigationLink(destination: EditProfileView()) {
                            Text("Edit Profile")
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                    }
                }
                .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                
                Section(header: Text("Library Stats").foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))) {
                    ProfileStatRow(
                        icon: "books.vertical.fill",
                        iconColor: AppTheme.primaryGreen,
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
                .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                
                Section(header: Text("Settings").foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.errorColor)
                            .frame(width: 24)
                        Text("Notifications")
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .accentColor(AppTheme.primaryGreen)
                    }
                    
                    HStack {
                        Image(systemName: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(themeManager.isDarkMode ? .purple : .orange)
                            .frame(width: 24)
                        Text("Dark Mode")
                            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                        Spacer()
                        Toggle("", isOn: $themeManager.isDarkMode)
                            .accentColor(AppTheme.primaryGreen)
                    }
                }
                .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                
                Section(header: Text("Support").foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))) {
                    ProfileMenuRow(
                        icon: "questionmark.circle.fill",
                        iconColor: AppTheme.primaryGreen,
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
                        iconColor: AppTheme.primaryGreen,
                        title: "Contact Us",
                        isDarkMode: themeManager.isDarkMode
                    )
                }
                .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                
                Section {
                    Button(action: {
                        // About app functionality
                    }) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppTheme.primaryGreen)
                                .frame(width: 24)
                            Text("About App")
                                .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
                                .font(.caption)
                        }
                    }
                }
                .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
                
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
                .listRowBackground(AppTheme.dynamicCardBackground(themeManager.isDarkMode))
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("Profile")
            .onAppear {
                Task {
                    await viewModel.fetchStats()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .foregroundColor(AppTheme.dynamicPrimaryText(themeManager.isDarkMode))
        }
        .accentColor(AppTheme.primaryGreen)
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authViewModel.signOut()
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
                .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
            Spacer()
            Text(value)
                .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
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
                .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
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