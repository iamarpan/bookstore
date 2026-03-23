import SwiftUI

/// View for displaying and managing group members
struct GroupMembersView: View {
    let group: BookClub
    
    @StateObject private var viewModel: GroupMembersViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedRole: MemberRole? = nil
    @State private var showingRoleSheet: GroupMember? = nil
    @State private var showingRemoveAlert: GroupMember? = nil
    
    init(group: BookClub) {
        self.group = group
        self._viewModel = StateObject(wrappedValue: GroupMembersViewModel(group: group))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Role Filter
            if group.canManageMembers {
                roleFilterPicker
            }
            
            // Members List
            if viewModel.isLoading {
                loadingView
            } else if viewModel.members.isEmpty {
                emptyStateView
            } else {
                membersList
            }
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Members (\(group.memberCount))")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadMembers()
        }
        .refreshable {
            await viewModel.refreshMembers()
        }
        .sheet(item: $showingRoleSheet) { member in
            RoleSelectionSheet(
                member: member,
                currentRole: member.role,
                onRoleSelected: { newRole in
                    Task {
                        await viewModel.updateMemberRole(member: member, newRole: newRole)
                    }
                }
            )
            .presentationDetents([.height(300)])
        }
        .alert("Remove Member", isPresented: .constant(showingRemoveAlert != nil)) {
            Button("Cancel", role: .cancel) {
                showingRemoveAlert = nil
            }
            Button("Remove", role: .destructive) {
                if let member = showingRemoveAlert {
                    Task {
                        await viewModel.removeMember(member: member)
                        showingRemoveAlert = nil
                    }
                }
            }
        } message: {
            if let member = showingRemoveAlert {
                Text("Are you sure you want to remove \(member.user.name) from this group?")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Role Filter Picker
    
    private var roleFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                filterChip(label: "All", role: nil)
                filterChip(label: "Creator", role: .creator)
                filterChip(label: "Admin", role: .admin)
                filterChip(label: "Moderator", role: .moderator)
                filterChip(label: "Member", role: .member)
            }
            .padding()
        }
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
    }
    
    private func filterChip(label: String, role: MemberRole?) -> some View {
        Button(action: {
            selectedRole = role
            Task {
                await viewModel.filterByRole(role: role)
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(selectedRole == role ? .white : AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedRole == role ? AppTheme.primaryAccent : AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.primaryAccent, lineWidth: selectedRole == role ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Members List
    
    private var membersList: some View {
        List {
            ForEach(viewModel.members) { member in
                MemberDetailRow(
                    member: member,
                    isDarkMode: themeManager.isDarkMode,
                    canManage: group.canManageMembers && member.role != .creator,
                    onChangeRole: {
                        showingRoleSheet = member
                    },
                    onRemove: {
                        showingRemoveAlert = member
                    }
                )
                .listRowBackground(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading members...")
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            
            Text("No members found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Spacer()
        }
    }
}

// MARK: - Member Detail Row

struct MemberDetailRow: View {
    let member: GroupMember
    let isDarkMode: Bool
    let canManage: Bool
    let onChangeRole: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Profile Image
                Circle()
                    .fill(AppTheme.primaryAccent.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(member.user.name.prefix(1).uppercased())
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryAccent)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.user.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.colorPrimaryText(for: isDarkMode))
                    
                    HStack(spacing: 12) {
                        Label("\(member.user.booksShared) books", systemImage: "books.vertical.fill")
                            .font(.caption)
                        
                        if let rating = member.user.averageRating {
                            Label(String(format: "%.1f", rating), systemImage: "star.fill")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(AppTheme.colorSecondaryText(for: isDarkMode))
                    
                    Text("Joined \(member.joinedAt.timeAgo())")
                        .font(.caption2)
                        .foregroundColor(AppTheme.colorTertiaryText(for: isDarkMode))
                }
                
                Spacer()
                
                // Role Badge
                roleBadge(role: member.role)
            }
            
            // Management Actions (if allowed)
            if canManage {
                HStack(spacing: 12) {
                    Button(action: onChangeRole) {
                        Label("Change Role", systemImage: "person.badge.shield.checkmark")
                            .font(.caption)
                            .foregroundColor(AppTheme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(AppTheme.primaryAccent.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onRemove) {
                        Label("Remove", systemImage: "person.badge.minus")
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: isDarkMode))
        .cornerRadius(12)
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
        .padding(.horizontal, 10)
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

// MARK: - Role Selection Sheet

struct RoleSelectionSheet: View {
    let member: GroupMember
    let currentRole: MemberRole
    let onRoleSelected: (MemberRole) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    let availableRoles: [MemberRole] = [.member, .moderator, .admin]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(availableRoles, id: \.self) { role in
                    Button(action: {
                        onRoleSelected(role)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: roleIcon(for: role))
                                .foregroundColor(roleColor(for: role))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(role.rawValue.capitalized)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                
                                Text(roleDescription(for: role))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if role == currentRole {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Change Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
    
    private func roleDescription(for role: MemberRole) -> String {
        switch role {
        case .creator: return "Full control over the group"
        case .admin: return "Can manage members and settings"
        case .moderator: return "Can moderate content"
        case .member: return "Regular member"
        }
    }
}

// MARK: - Group Members ViewModel

@MainActor
class GroupMembersViewModel: ObservableObject {
    @Published var members: [GroupMember] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let group: BookClub
    private let groupService: GroupService
    private var allMembers: [GroupMember] = []
    
    init(group: BookClub) {
        self.group = group
        self.groupService = GroupService()
    }
    
    func loadMembers() {
        Task {
            isLoading = true
            
            do {
                let fetchedMembers = try await groupService.fetchGroupMembers(groupId: group.id)
                allMembers = fetchedMembers
                members = fetchedMembers
            } catch {
                errorMessage = "Failed to load members: \(error.localizedDescription)"
                showError = true
            }
            
            isLoading = false
        }
    }
    
    func refreshMembers() async {
        do {
            let fetchedMembers = try await groupService.fetchGroupMembers(groupId: group.id)
            allMembers = fetchedMembers
            members = fetchedMembers
        } catch {
            errorMessage = "Failed to refresh members: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func filterByRole(role: MemberRole?) async {
        if let role = role {
            do {
                members = try await groupService.fetchGroupMembers(groupId: group.id, role: role)
            } catch {
                errorMessage = "Failed to filter members: \(error.localizedDescription)"
                showError = true
            }
        } else {
            members = allMembers
        }
    }
    
    func updateMemberRole(member: GroupMember, newRole: MemberRole) async {
        do {
            _ = try await groupService.updateMemberRole(
                groupId: group.id,
                userId: member.userId,
                role: newRole
            )
            
            // Refresh members list
            await refreshMembers()
        } catch {
            errorMessage = "Failed to update role: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func removeMember(member: GroupMember) async {
        do {
            try await groupService.removeMember(groupId: group.id, userId: member.userId)
            
            // Remove from local list
            members.removeAll { $0.id == member.id }
            allMembers.removeAll { $0.id == member.id }
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Preview

struct GroupMembersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GroupMembersView(group: BookClub.mockClubs[0])
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
}
