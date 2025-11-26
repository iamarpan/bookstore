import Foundation

/// Service for group/club operations
@MainActor
class GroupService: ObservableObject {
    // MARK: - Published Properties
    @Published var myGroups: [BookClub] = []
    @Published var discoveredGroups: [BookClub] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private let apiClient: APIClient
    
    // MARK: - Initialization
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Fetch Groups
    
    /// Fetch user's groups
    func fetchMyGroups() async throws -> [BookClub] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct GroupsResponse: Codable {
            let groups: [BookClub]
        }
        
        do {
            let response: GroupsResponse = try await apiClient.get("/groups/my")
            myGroups = response.groups
            return response.groups
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Discover public groups
    func discoverGroups(
        category: GroupCategory? = nil,
        search: String? = nil
    ) async throws -> [BookClub] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        var queryParams: [String: Any] = [:]
        
        if let category = category {
            queryParams["category"] = category.rawValue
        }
        if let search = search {
            queryParams["search"] = search
        }
        
        struct GroupsResponse: Codable {
            let groups: [BookClub]
        }
        
        do {
            let response: GroupsResponse = try await apiClient.get(
                "/groups/discover",
                queryParams: queryParams
            )
            discoveredGroups = response.groups
            return response.groups
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Fetch group details
    func fetchGroup(id: String) async throws -> BookClub {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let group: BookClub = try await apiClient.get("/groups/\(id)")
            return group
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Create Group
    
    /// Create a new group
    func createGroup(
        name: String,
        description: String,
        category: GroupCategory,
        privacy: PrivacySetting,
        rules: String? = nil,
        coverImageUrl: String? = nil
    ) async throws -> BookClub {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct CreateGroupRequest: Codable {
            let name: String
            let description: String
            let category: String
            let privacy: String
            let rules: String?
            let coverImageUrl: String?
        }
        
        struct CreateGroupResponse: Codable {
            let id: String
            let name: String
            let inviteCode: String
            let inviteUrl: String
        }
        
        do {
            let request = CreateGroupRequest(
                name: name,
                description: description,
                category: category.rawValue,
                privacy: privacy.rawValue,
                rules: rules,
                coverImageUrl: coverImageUrl
            )
            
            let response: CreateGroupResponse = try await apiClient.post(
                "/groups",
                body: request
            )
            
            print("✅ Group created: \(response.name)")
            print("   Invite code: \(response.inviteCode)")
            print("   Invite URL: \(response.inviteUrl)")
            
            // Fetch full group details
            let group = try await fetchGroup(id: response.id)
            myGroups.insert(group, at: 0)
            
            return group
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Join/Leave Groups
    
    /// Join a public group or request to join private
    func joinGroup(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct JoinResponse: Codable {
            let status: String  // "JOINED" or "PENDING_APPROVAL"
        }
        
        do {
            let response: JoinResponse = try await apiClient.post(
                "/groups/\(id)/join",
                body: EmptyRequest()
            )
            
            if response.status == "JOINED" {
                print("✅ Joined group successfully")
                // Refresh my groups
                _ = try await fetchMyGroups()
            } else {
                print("⏳ Join request pending approval")
            }
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Join group via invite code
    func joinViaInvite(code: String) async throws -> BookClub {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct JoinViaInviteResponse: Codable {
            let group: BookClub
        }
        
        do {
            let response: JoinViaInviteResponse = try await apiClient.post(
                "/groups/join-invite/\(code)",
                body: EmptyRequest()
            )
            
            print("✅ Joined group via invite: \(response.group.name)")
            
            // Add to my groups
            myGroups.insert(response.group, at: 0)
            
            return response.group
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Leave a group
    func leaveGroup(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            try await apiClient.post("/groups/\(id)/leave", body: EmptyRequest())
            
            // Remove from my groups
            myGroups.removeAll { $0.id == id }
            
            print("✅ Left group successfully")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Invite Management
    
    /// Generate invite link for group
    func generateInvite(
        for groupId: String,
        expiryDays: Int? = nil
    ) async throws -> (code: String, url: String) {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct InviteRequest: Codable {
            let expiryDays: Int?
        }
        
        struct InviteResponse: Codable {
            let inviteCode: String
            let inviteUrl: String
            let expiresAt: Date?
        }
        
        do {
            let request = InviteRequest(expiryDays: expiryDays)
            let response: InviteResponse = try await apiClient.post(
                "/groups/\(groupId)/invite",
                body: request
            )
            
            print("✅ Invite generated: \(response.inviteCode)")
            return (response.inviteCode, response.inviteUrl)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Mock Data (for development)
    
    /// Load mock groups
    func loadMockGroups() {
        myGroups = BookClub.mockClubs
        print("✅ Loaded \(myGroups.count) mock groups")
    }
}

// MARK: - Helper Types

private struct EmptyRequest: Codable {}
