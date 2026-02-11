import SwiftUI

/// Detailed view for a specific group showing members, books, and management options
struct GroupDetailView: View {
    let group: BookClub
    
    @StateObject private var viewModel: GroupDetailViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingSettings = false
    
    init(group: BookClub) {
        self.group = group
        self._viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                groupHeaderSection
                
                // Stats Section
                statsSection
                
                // Rules Section (if any)
                if let rules = group.rules, !rules.isEmpty {
                    rulesSection(rules: rules)
                }
                
                // Members Section
                membersSection
                
                // Books Section
                booksSection
                
                // Actions Section
                actionsSection
            }
            .padding()
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .onAppear {
            viewModel.loadGroupData()
        }
        .alert("Leave Group", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await viewModel.leaveGroup()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to leave this group? Your books will be removed from the group.")
        }
        .alert("Delete Group", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteGroup()
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this group? This action cannot be undone.")
        }
        .sheet(isPresented: $showingSettings) {
            GroupSettingsView(group: group)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Header Section
    
    private var groupHeaderSection: some View {
        VStack(spacing: 12) {
            // Group Icon
            Image(systemName: group.privacy == .public_ ? "person.3.fill" : "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.primaryAccent)
                .frame(width: 120, height: 120)
                .background(AppTheme.primaryAccent.opacity(0.1))
                .clipShape(Circle())
            
            // Group Name
            Text(group.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            // Description
            Text(group.description)
                .font(.body)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Category and Privacy
            HStack(spacing: 16) {
                Label(group.category.displayName, systemImage: categoryIcon(for: group.category))
                    .font(.caption)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                
                Label(
                    group.privacy == .public_ ? "Public" : "Private",
                    systemImage: group.privacy == .public_ ? "globe" : "lock.fill"
                )
                .font(.caption)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            }
            
            // User's Role Badge
            if let role = group.role {
                roleBadge(role: role)
            }
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            statCard(icon: "person.2.fill", value: "\(group.memberCount)", label: "Members")
            statCard(icon: "books.vertical.fill", value: "\(group.booksCount)", label: "Books")
            if let joinedAt = group.joinedAt {
                statCard(icon: "calendar", value: joinedAt.timeAgo(), label: "Joined")
            }
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.primaryAccent)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Rules Section
    
    private func rulesSection(rules: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Group Rules", systemImage: "list.bullet.clipboard")
                .font(.headline)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Text(rules)
                .font(.body)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    // MARK: - Members Section
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Members", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                
                Spacer()
                
                NavigationLink(destination: GroupMembersView(group: group)) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
            
            if viewModel.isLoadingMembers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.members.isEmpty {
                Text("No members to display")
                    .font(.caption)
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.members.prefix(3)) { member in
                    MemberRowView(member: member, isDarkMode: themeManager.isDarkMode)
                }
            }
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    // MARK: - Books Section
    
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Books", systemImage: "books.vertical.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                
                Spacer()
                
                Text("\(group.booksCount) total")
                    .font(.caption)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            }
            
            if viewModel.isLoadingBooks {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.books.isEmpty {
                Text("No books in this group yet")
                    .font(.caption)
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.books.prefix(5)) { book in
                            BookThumbnailView(book: book, isDarkMode: themeManager.isDarkMode)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share Invite Code (Admin/Creator only)
            if group.canUpdateSettings {
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Invite Code")
                        Spacer()
                        Text(group.inviteCode)
                            .font(.caption)
                            .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    }
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    .padding()
                    .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                    .cornerRadius(12)
                }
            }
            
            // Leave Group (if not creator)
            if !group.isCreator {
                Button(action: { showingLeaveAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Group")
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                    .cornerRadius(12)
                }
            }
            
            // Delete Group (Creator only)
            if group.isCreator {
                Button(action: { showingDeleteAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Group")
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if group.canUpdateSettings {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func categoryIcon(for category: GroupCategory) -> String {
        switch category {
        case .friends: return "person.2.fill"
        case .office: return "briefcase.fill"
        case .neighborhood: return "house.fill"
        case .bookClub: return "books.vertical.fill"
        case .school: return "graduationcap.fill"
        }
    }
    
    private func roleBadge(role: MemberRole) -> some View {
        HStack(spacing: 4) {
            Image(systemName: roleIcon(for: role))
                .font(.caption2)
            Text(role.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(roleColor(for: role))
        .cornerRadius(8)
    }
    
    private func roleIcon(for role: MemberRole) -> String {
        switch role {
        case .creator: return "crown.fill"
        case .admin: return "star.fill"
        case .moderator: return "shield.fill"
        case .member: return "person.fill"
        }
    }
    
    private func roleColor(for role: MemberRole) -> Color {
        switch role {
        case .creator: return .purple
        case .admin: return .orange
        case .moderator: return .blue
        case .member: return .gray
        }
    }
}

// MARK: - Member Row View

struct MemberRowView: View {
    let member: GroupMember
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image Placeholder
            Circle()
                .fill(AppTheme.primaryAccent.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.user.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryAccent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.user.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                
                HStack(spacing: 8) {
                    Label("\(member.user.booksShared) books", systemImage: "books.vertical.fill")
                        .font(.caption2)
                    
                    if let rating = member.user.averageRating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(.caption2)
                    }
                }
                .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
            }
            
            Spacer()
            
            // Role Badge
            Text(member.role.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor(for: member.role))
                .cornerRadius(6)
        }
        .padding(.vertical, 8)
    }
    
    private func roleColor(for role: MemberRole) -> Color {
        switch role {
        case .creator: return .purple
        case .admin: return .orange
        case .moderator: return .blue
        case .member: return .gray
        }
    }
}

// MARK: - Book Thumbnail View

struct BookThumbnailView: View {
    let book: Book
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book Cover
            AsyncImage(url: URL(string: book.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.primaryAccent.opacity(0.2))
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(AppTheme.primaryAccent)
                    )
            }
            .frame(width: 100, height: 140)
            .cornerRadius(8)
            
            // Book Title
            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                .lineLimit(2)
                .frame(width: 100)
        }
    }
}

// MARK: - Group Detail ViewModel

@MainActor
class GroupDetailViewModel: ObservableObject {
    @Published var members: [GroupMember] = []
    @Published var books: [Book] = []
    @Published var isLoadingMembers = false
    @Published var isLoadingBooks = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let group: BookClub
    private let groupService: GroupService
    
    init(group: BookClub) {
        self.group = group
        self.groupService = GroupService()
    }
    
    func loadGroupData() {
        Task {
            await loadMembers()
            await loadBooks()
        }
    }
    
    func loadMembers() async {
        isLoadingMembers = true
        
        do {
            members = try await groupService.fetchGroupMembers(groupId: group.id)
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
            showError = true
        }
        
        isLoadingMembers = false
    }
    
    func loadBooks() async {
        isLoadingBooks = true
        
        do {
            let result = try await groupService.fetchGroupBooks(groupId: group.id, limit: 10)
            books = result.books
        } catch {
            errorMessage = "Failed to load books: \(error.localizedDescription)"
            showError = true
        }
        
        isLoadingBooks = false
    }
    
    func leaveGroup() async {
        do {
            try await groupService.leaveGroup(id: group.id)
        } catch {
            errorMessage = "Failed to leave group: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func deleteGroup() async {
        do {
            try await groupService.deleteGroup(id: group.id)
        } catch {
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Date Extension

extension Date {
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .month, .year], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)y ago"
        } else if let month = components.month, month > 0 {
            return "\(month)mo ago"
        } else if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else {
            return "Today"
        }
    }
}

// MARK: - Preview

struct GroupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupDetailView(group: BookClub.mockClubs[0])
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
}
