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
                // MARK: - Profile Header
                Section {
                    if let user = authViewModel.currentUser {
                        VStack(spacing: 12) {
                            // Avatar
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 72))
                                .foregroundColor(AppTheme.primaryAccent)

                            VStack(spacing: 4) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))

                                // Phone / handle
                                Text(user.phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))

                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 2)
                                }

                                if let email = user.email {
                                    Label(email, systemImage: "envelope.fill")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                                }
                            }

                            NavigationLink(destination: EditProfileView()) {
                                Text("Edit Profile")
                                    .font(AppTheme.bodyFont(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryAccent)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.primaryAccent.opacity(0.1))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))

                // MARK: - Your Impact
                Section(header: Text("Your Impact").foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ImpactCard(value: "\(viewModel.booksAddedCount)", label: "Books Added", icon: "books.vertical.fill", color: AppTheme.primaryAccent, isDarkMode: themeManager.isDarkMode)
                            ImpactCard(value: "\(viewModel.booksLentCount)", label: "Lent Out", icon: "arrow.up.forward.circle.fill", color: AppTheme.warningColor, isDarkMode: themeManager.isDarkMode)
                            ImpactCard(value: "\(viewModel.booksBorrowedCount)", label: "Borrowed", icon: "book.fill", color: AppTheme.successColor, isDarkMode: themeManager.isDarkMode)
                            ImpactCard(value: String(format: "%.1f", viewModel.reputationScore), label: "Reputation", icon: "star.fill", color: .purple, isDarkMode: themeManager.isDarkMode)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))

                // MARK: - Activity Summary
                if viewModel.booksLentCount > 0 || viewModel.booksBorrowedCount > 0 {
                    Section(header: Text("Activity").foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))) {
                        if viewModel.booksLentCount > 0 {
                            HStack {
                                Image(systemName: "arrow.up.forward.circle.fill")
                                    .foregroundColor(AppTheme.warningColor)
                                    .frame(width: 24)
                                Text("Currently lending \(viewModel.booksLentCount) book\(viewModel.booksLentCount == 1 ? "" : "s")")
                                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                            }
                        }
                        if viewModel.booksBorrowedCount > 0 {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(AppTheme.successColor)
                                    .frame(width: 24)
                                Text("Borrowed \(viewModel.booksBorrowedCount) book\(viewModel.booksBorrowedCount == 1 ? "" : "s")")
                                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                            }
                        }
                    }
                    .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                }
                
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
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 100)
            }
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

// MARK: - Impact Card
struct ImpactCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let isDarkMode: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
            Text(label)
                .font(AppTheme.bodyFont(size: 11))
                .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                .multilineTextAlignment(.center)
        }
        .frame(width: 90, height: 100)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(16)
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