import SwiftUI

/// Main screen for viewing user's groups (joined and created)
struct MyGroupsView: View {
    @StateObject private var viewModel = GroupViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedSegment = 0 // 0 = Joined, 1 = Created
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Groups", selection: $selectedSegment) {
                    Text("Joined").tag(0)
                    Text("Created by Me").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .accentColor(AppTheme.primaryAccent)
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    if selectedSegment == 0 {
                        joinedGroupsView
                    } else {
                        createdGroupsView
                    }
                }
            }
            .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
            .navigationTitle("My Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                loadGroups()
            }
            .refreshable {
                await viewModel.refreshGroups()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
        .accentColor(AppTheme.primaryAccent)
    }
    
    // MARK: - Joined Groups View
    
    private var joinedGroupsView: some View {
        Group {
            if viewModel.joinedGroups.isEmpty {
                emptyStateView(
                    icon: "person.2.fill",
                    title: "No Joined Groups",
                    message: "Discover and join book clubs to start sharing books with your community"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.joinedGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupCardView(
                                    group: group,
                                    isDarkMode: themeManager.isDarkMode,
                                    showJoinButton: false,
                                    onTap: { }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
        }
    }
    
    // MARK: - Created Groups View
    
    private var createdGroupsView: some View {
        Group {
            if viewModel.createdGroups.isEmpty {
                emptyStateView(
                    icon: "plus.circle.fill",
                    title: "No Created Groups",
                    message: "Create your own book club and invite friends to join"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.createdGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group)) {
                                GroupCardView(
                                    group: group,
                                    isDarkMode: themeManager.isDarkMode,
                                    showJoinButton: false,
                                    onTap: { }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading groups...")
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .accentColor(AppTheme.primaryAccent)
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                
                Text(message)
                    .font(.body)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if selectedSegment == 0 {
                // Discover Groups button
                NavigationLink(destination: DiscoverGroupsView()) {
                    Text("Discover Groups")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryAccent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            } else {
                // Create Group button
                NavigationLink(destination: CreateGroupView()) {
                    Text("Create Your First Group")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryAccent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // Add Group button
            NavigationLink(destination: CreateGroupView()) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.primaryAccent)
            }
            
            // Discover Groups button
            NavigationLink(destination: DiscoverGroupsView()) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.primaryAccent)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadGroups() {
        Task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.fetchUserGroups(userId: userId)
            } else {
                // Load mock data for testing
                viewModel.loadMockGroups()
            }
        }
    }
}

// MARK: - Group ViewModel

@MainActor
class GroupViewModel: ObservableObject {
    @Published var joinedGroups: [BookClub] = []
    @Published var createdGroups: [BookClub] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let groupService: GroupService
    
    init() {
        self.groupService = GroupService()
    }
    
    /// Fetch user's groups from API
    func fetchUserGroups(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let groups = try await groupService.fetchMyGroups()
            
            // Split into joined vs created
            joinedGroups = groups.filter { !$0.isCreatedByUser(userId: userId) }
            createdGroups = groups.filter { $0.isCreatedByUser(userId: userId) }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error fetching groups: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh groups
    func refreshGroups() async {
        // Get current user ID from UserDefaults or mock user
        if let user = User.loadFromUserDefaults() {
            await fetchUserGroups(userId: user.id)
        } else {
            loadMockGroups()
        }
    }
    
    /// Load mock data for testing
    func loadMockGroups() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let allGroups = BookClub.mockClubs
            let mockUserId = User.mockUser.id
            
            self.joinedGroups = allGroups.filter { !$0.isCreatedByUser(userId: mockUserId) }
            self.createdGroups = allGroups.filter { $0.isCreatedByUser(userId: mockUserId) }
            
            self.isLoading = false
            print("✅ Loaded \(allGroups.count) mock groups")
        }
    }
}

// MARK: - Helper Extension

extension BookClub {
    func isCreatedByUser(userId: String) -> Bool {
        return creatorId == userId
    }
}

// MARK: - Preview Stubs





/// Placeholder view for GroupDetailView (will be implemented next)
struct GroupDetailView: View {
    let group: BookClub
    
    var body: some View {
        Text("Group Detail: \(group.name)")
            .navigationTitle(group.name)
    }
}

// MARK: - Preview

struct MyGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        MyGroupsView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel())
    }
}
