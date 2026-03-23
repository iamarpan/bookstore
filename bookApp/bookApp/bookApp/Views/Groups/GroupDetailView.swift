import SwiftUI
import Combine

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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Profile Section
                GroupHeaderProfileView(group: viewModel.group, isDarkMode: themeManager.isDarkMode)
                
                // Stats Section
                GroupStatsBarView(group: viewModel.group, isDarkMode: themeManager.isDarkMode)
                
                // Rules Section (if any)
                if let rules = viewModel.group.rules, !rules.isEmpty {
                    GroupRulesCard(rules: rules, isDarkMode: themeManager.isDarkMode)
                }
                
                // Members Section (Horizontal Scroll like Android)
                GroupMembersPreviewSection(
                    members: viewModel.members,
                    totalCount: viewModel.group.memberCount,
                    isLoading: viewModel.isLoadingMembers,
                    isDarkMode: themeManager.isDarkMode,
                    group: viewModel.group
                )
                
                // Books Section (Grid like Android)
                GroupBooksGridSection(
                    books: viewModel.books,
                    isLoading: viewModel.isLoadingBooks,
                    isDarkMode: themeManager.isDarkMode
                )
                
                // Actions Section
                GroupActionsSection(
                    group: viewModel.group,
                    isDarkMode: themeManager.isDarkMode,
                    onShare: { showingShareSheet = true },
                    onLeave: { showingLeaveAlert = true },
                    onDelete: { showingDeleteAlert = true }
                )
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.group.canUpdateSettings {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppTheme.primaryAccent)
                    }
                }
            }
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
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["Join my group \"\(viewModel.group.name)\" on BookShare! Use invite code: \(viewModel.group.inviteCode)"])
        }
    }
}

// MARK: - Subviews

struct GroupHeaderProfileView: View {
    let group: BookClub
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Group Icon with premium glow
            ZStack {
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: group.privacy == .public_ ? "person.3.fill" : "lock.shield.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(AppTheme.primaryAccent)
            }
            .overlay(
                Circle()
                    .stroke(AppTheme.primaryAccent.opacity(0.2), lineWidth: 2)
            )
            .shadow(color: AppTheme.primaryAccent.opacity(0.15), radius: 15, x: 0, y: 10)
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(AppTheme.headerFont(size: 28))
                        .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                        .multilineTextAlignment(.center)
                    
                    Image(systemName: group.privacy == .public_ ? "globe" : "lock.fill")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                }
                
                if let role = group.role {
                    RoleBadgeView(role: role)
                }
                
                Text(group.description)
                    .font(AppTheme.bodyFont(size: 16))
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 10)
    }
}

struct RoleBadgeView: View {
    let role: MemberRole
    
    var body: some View {
        Text(role.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(roleColor.cornerRadius(4))
            .shadow(color: roleColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var roleColor: Color {
        switch role {
        case .creator: return .purple
        case .admin: return .orange
        case .moderator: return .blue
        case .member: return .gray
        }
    }
}

struct GroupStatsBarView: View {
    let group: BookClub
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            statItem(icon: "person.2.fill", value: "\(group.memberCount)", label: "Members")
            Divider().frame(height: 30).padding(.horizontal, 10)
            statItem(icon: "books.vertical.fill", value: "\(group.booksCount)", label: "Books")
            
            if let joinedAt = group.joinedAt {
                Divider().frame(height: 30).padding(.horizontal, 10)
                statItem(icon: "calendar", value: joinedAt.timeAgoShort(), label: "Joined")
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.colorCardBackground(for: isDarkMode))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primaryAccent)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
        }
        .frame(maxWidth: .infinity)
    }
}

struct GroupRulesCard: View {
    let rules: String
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(AppTheme.primaryAccent)
                Text("Group Rules")
                    .font(.headline)
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
            }
            
            Text(rules)
                .font(AppTheme.bodyFont(size: 14))
                .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.primaryAccent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.primaryAccent.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct GroupMembersPreviewSection: View {
    let members: [GroupMember]
    let totalCount: Int
    let isLoading: Bool
    let isDarkMode: Bool
    let group: BookClub
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Members (\(totalCount))")
                    .font(AppTheme.headerFont(size: 20))
                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                
                Spacer()
                
                NavigationLink(destination: GroupMembersView(group: group)) {
                    HStack(spacing: 4) {
                        Text("See All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primaryAccent)
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(members) { member in
                            VStack(spacing: 8) {
                                MemberAvatarView(member: member)
                                Text(member.user.name.split(separator: " ").first ?? "")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                                    .lineLimit(1)
                            }
                            .frame(width: 65)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct MemberAvatarView: View {
    let member: GroupMember
    
    var body: some View {
        ZStack {
            if let imageUrl = member.user.profileImageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(radius: 2)
    }
    
    private var initialsView: some View {
        Circle()
            .fill(AppTheme.primaryAccent.opacity(0.2))
            .overlay(
                Text(member.user.name.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryAccent)
            )
    }
}

struct GroupBooksGridSection: View {
    let books: [Book]
    let isLoading: Bool
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Group Books")
                .font(AppTheme.headerFont(size: 20))
                .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                .padding(.horizontal)
            
            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if books.isEmpty {
                Text("No books shared yet")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.dynamicBorderColor(for: isDarkMode), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(books) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: book.imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(AppTheme.primaryAccent.opacity(0.1))
                                        .overlay(Image(systemName: "book.fill").foregroundColor(AppTheme.primaryAccent.opacity(0.3)))
                                }
                                .frame(height: 140)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Text(book.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct GroupActionsSection: View {
    let group: BookClub
    let isDarkMode: Bool
    let onShare: () -> Void
    let onLeave: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if group.canUpdateSettings {
                actionButton(title: "Share Invite Code", icon: "square.and.arrow.up", color: AppTheme.primaryAccent, accessory: group.inviteCode, action: onShare)
            }
            
            if !group.isCreator {
                actionButton(title: "Leave Group", icon: "rectangle.portrait.and.arrow.right", color: .red, action: onLeave)
            }
            
            if group.isCreator {
                actionButton(title: "Delete Group", icon: "trash", color: .red, action: onDelete)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func actionButton(title: String, icon: String, color: Color, accessory: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                if let accessory = accessory {
                    Text(accessory)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(6)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.5)
            }
            .foregroundColor(color)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDarkMode ? Color(white: 0.15) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ViewModel

@MainActor
class GroupDetailViewModel: ObservableObject {
    @Published private(set) var members: [GroupMember] = []
    @Published private(set) var books: [Book] = []
    @Published var isLoadingMembers = false
    @Published var isLoadingBooks = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    @Published var group: BookClub
    private let store = AppDataStore.shared
    private let refresher: any AppDataRefresherProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(group: BookClub, refresher: (any AppDataRefresherProtocol)? = nil) {
        self.group = group
        self.refresher = refresher ?? AppDataRefresher.shared
        setupObservations()
    }
    
    private func setupObservations() {
        // Observe members for this group
        store.$groupMembersByGroup
            .map { $0[self.group.id] ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: \.members, on: self)
            .store(in: &cancellables)
            
        // Observe books for this group
        store.$groupBooksByGroup
            .map { $0[self.group.id] ?? [] }
            .receive(on: DispatchQueue.main)
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
    }
    
    func loadGroupData() {
        Task {
            await loadGroupDetail()
            await loadMembers()
            await loadBooks()
        }
    }
    
    func loadGroupDetail() async {
        do {
            let updatedGroup = try await refresher.refreshGroupDetailIfNeeded(id: group.id, forceRefresh: false)
            self.group = updatedGroup
        } catch {
            print("Error refreshing group detail: \(error)")
        }
    }
    
    func loadMembers() async {
        isLoadingMembers = true
        do {
            _ = try await refresher.refreshGroupMembersIfNeeded(groupId: group.id, forceRefresh: false)
        } catch {
            errorMessage = "Failed to load members: \(error.localizedDescription)"
            showError = true
        }
        isLoadingMembers = false
    }
    
    func loadBooks() async {
        isLoadingBooks = true
        do {
            _ = try await refresher.refreshGroupBooksIfNeeded(groupId: group.id, forceRefresh: false)
        } catch {
            errorMessage = "Failed to load books: \(error.localizedDescription)"
            showError = true
        }
        isLoadingBooks = false
    }
    
    func leaveGroup() async {
        do {
            try await GroupService().leaveGroup(id: group.id)
            // Invalidating cache so other views update (like MyGroups)
            store.invalidateMyGroups()
        } catch {
            errorMessage = "Failed to leave group: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func deleteGroup() async {
        do {
            try await GroupService().deleteGroup(id: group.id)
            store.invalidateMyGroups()
        } catch {
            errorMessage = "Failed to delete group: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Date Extensions

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
    
    func timeAgoShort() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .month, .year], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)y"
        } else if let month = components.month, month > 0 {
            return "\(month)mo"
        } else if let day = components.day, day > 0 {
            return "\(day)d"
        } else {
            return "Today"
        }
    }
}

// MARK: - Share Sheet Helper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
