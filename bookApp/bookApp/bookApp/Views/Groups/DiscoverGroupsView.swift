import SwiftUI

/// Screen for discovering and joining new book clubs
struct DiscoverGroupsView: View {
    @StateObject private var viewModel = DiscoverGroupsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
            
            // Filters
            filterScrollView
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.groups.isEmpty {
                emptyStateView
            } else {
                groupsList
            }
        }
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .navigationTitle("Discover Groups")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadGroups()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            
            TextField("Search groups...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .onChange(of: viewModel.searchText) { _, _ in
                    Task {
                        await viewModel.performSearch()
                    }
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    Task {
                        await viewModel.performSearch()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                }
            }
        }
        .padding()
        .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
        .cornerRadius(10)
        .padding()
    }
    
    // MARK: - Filters
    
    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Distance Filter
                Menu {
                    Button("Any Distance") { viewModel.selectedDistance = nil }
                    Button("Within 5 km") { viewModel.selectedDistance = 5 }
                    Button("Within 10 km") { viewModel.selectedDistance = 10 }
                    Button("Within 25 km") { viewModel.selectedDistance = 25 }
                    Button("Within 50 km") { viewModel.selectedDistance = 50 }
                } label: {
                    filterChip(
                        title: viewModel.distanceLabel,
                        isSelected: viewModel.selectedDistance != nil,
                        icon: "location"
                    )
                }
                
                // Privacy Filter
                Menu {
                    Button("All") { viewModel.selectedPrivacy = nil }
                    Button("Public") { viewModel.selectedPrivacy = .public_ }
                    Button("Private") { viewModel.selectedPrivacy = .private_ }
                } label: {
                    filterChip(
                        title: viewModel.privacyLabel,
                        isSelected: viewModel.selectedPrivacy != nil,
                        icon: "lock"
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isSelected ? "\(icon).fill" : icon)
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? AppTheme.primaryAccent.opacity(0.1) : AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
        .foregroundColor(isSelected ? AppTheme.primaryAccent : AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? AppTheme.primaryAccent : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - Groups List
    
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupCardView(
                            group: group,
                            isDarkMode: themeManager.isDarkMode,
                            showJoinButton: !group.isMember(userId: authViewModel.currentUser?.id ?? ""),
                            onTap: { },
                            onJoin: {
                                Task {
                                    await viewModel.joinGroup(group)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Loading & Empty States
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Searching groups...")
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                .accentColor(AppTheme.primaryAccent)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            
            Text("No groups found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
            
            Text("Try adjusting your search or filters")
                .font(.body)
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadGroups() {
        Task {
            await viewModel.fetchGroups()
        }
    }
}

// MARK: - ViewModel

@MainActor
class DiscoverGroupsViewModel: ObservableObject {
    @Published var groups: [BookClub] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedDistance: Double?
    @Published var selectedPrivacy: PrivacySetting?
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let groupService: GroupService
    
    init() {
        self.groupService = GroupService()
    }
    
    var distanceLabel: String {
        if let distance = selectedDistance {
            return "Within \(Int(distance)) km"
        }
        return "Distance"
    }
    
    var privacyLabel: String {
        if let privacy = selectedPrivacy {
            return privacy == .public_ ? "Public" : "Private"
        }
        return "Privacy"
    }
    
    func fetchGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, we'd pass filters to the API
            // For now, we'll fetch all and filter locally or use mock data
            if let _ = User.loadFromUserDefaults() {
                // Real API call would go here
                // let fetchedGroups = try await groupService.searchGroups(query: searchText, ...)
                // For now, use mock data since backend search might not be ready
                loadMockGroups()
            } else {
                loadMockGroups()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func performSearch() async {
        // Debounce could be added here
        await fetchGroups()
    }
    
    func joinGroup(_ group: BookClub) async {
        // Implement join logic
        print("Joining group: \(group.name)")
        // try? await groupService.joinGroup(id: group.id)
    }
    
    private func loadMockGroups() {
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            var filtered = BookClub.mockClubs
            
            // Apply search filter
            if !self.searchText.isEmpty {
                filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(self.searchText) }
            }
            
            // Apply privacy filter
            if let privacy = self.selectedPrivacy {
                filtered = filtered.filter { $0.privacy == privacy }
            }
            
            // Apply distance filter (mock logic)
            if let maxDist = self.selectedDistance {
                filtered = filtered.filter { ($0.distance ?? 0) <= maxDist }
            }
            
            self.groups = filtered
            self.isLoading = false
        }
    }
}

// MARK: - Helper Extension
extension BookClub {
    func isMember(userId: String) -> Bool {
        return memberIds.contains(userId) || adminIds.contains(userId) || moderatorIds.contains(userId) || creatorId == userId
    }
}

// MARK: - Preview
struct DiscoverGroupsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DiscoverGroupsView()
                .environmentObject(ThemeManager())
                .environmentObject(AuthViewModel())
        }
    }
}
