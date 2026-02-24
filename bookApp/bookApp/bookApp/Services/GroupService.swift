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
        
        do {
            // Backend returns array directly, not wrapped in object
            let groups: [BookClub] = try await apiClient.get("/groups/my-groups")
            myGroups = groups
            return groups
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
    func fetchGroupDetails(id: String) async throws -> BookClub {
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
    
    /// Fetch all groups visible to user (public + own)
    func getAllGroups() async throws -> [BookClub] {
        return try await apiClient.get("/groups")
    }
    
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
        
        do {
            let request = CreateGroupRequest(
                name: name,
                description: description,
                category: category.rawValue,
                privacy: privacy.rawValue,
                rules: rules,
                coverImageUrl: coverImageUrl
            )
            
            // Backend returns full group object with role included
            let group: BookClub = try await apiClient.post(
                "/groups",
                body: request
            )
            
            print("✅ Group created: \(group.name)")
            print("   Invite code: \(group.inviteCode)")
            
            myGroups.insert(group, at: 0)
            
            return group
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Join/Leave Groups
    
    /// Join a public group directly by group ID.
    /// For private groups, use joinViaInvite(code:) instead.
    func joinGroup(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct JoinResponse: Codable {
            let status: String  // "JOINED"
        }
        
        do {
            let _: JoinResponse = try await apiClient.post(
                "/groups/\(id)/join",
                body: EmptyRequest()
            )
            print("✅ Joined group successfully")
            _ = try await fetchMyGroups()
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
        
        struct JoinRequest: Codable {
            let inviteCode: String
        }
        
        struct JoinResponse: Codable {
            let message: String
            let group: BookClub
        }
        
        do {
            let request = JoinRequest(inviteCode: code)
            let response: JoinResponse = try await apiClient.post(
                "/groups/join",
                body: request
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
    
    // MARK: - Group Management
    
    /// Update group details (admin/creator only)
    func updateGroup(
        id: String,
        name: String? = nil,
        description: String? = nil,
        category: GroupCategory? = nil,
        privacy: PrivacySetting? = nil,
        coverImageUrl: String? = nil,
        rules: String? = nil
    ) async throws -> BookClub {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct UpdateGroupRequest: Codable {
            let name: String?
            let description: String?
            let category: String?
            let privacy: String?
            let coverImageUrl: String?
            let rules: String?
        }
        
        do {
            let request = UpdateGroupRequest(
                name: name,
                description: description,
                category: category?.rawValue,
                privacy: privacy?.rawValue,
                coverImageUrl: coverImageUrl,
                rules: rules
            )
            
            let group: BookClub = try await apiClient.put(
                "/groups/\(id)",
                body: request
            )
            
            // Update in local array
            if let index = myGroups.firstIndex(where: { $0.id == id }) {
                myGroups[index] = group
            }
            
            print("✅ Group updated successfully")
            return group
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Delete group (creator only)
    func deleteGroup(id: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct DeleteResponse: Codable {
            let message: String
        }
        
        do {
            let _: DeleteResponse = try await apiClient.delete("/groups/\(id)")
            
            // Remove from local array
            myGroups.removeAll { $0.id == id }
            
            print("✅ Group deleted successfully")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Member Management
    
    /// Fetch group members
    func fetchGroupMembers(
        groupId: String,
        role: MemberRole? = nil
    ) async throws -> [GroupMember] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct MembersResponse: Codable {
            let members: [GroupMember]
            let total: Int
        }
        
        var queryParams: [String: Any] = [:]
        if let role = role {
            queryParams["role"] = role.rawValue
        }
        
        do {
            let response: MembersResponse = try await apiClient.get(
                "/groups/\(groupId)/members",
                queryParams: queryParams
            )
            return response.members
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Update member role (admin/creator only)
    func updateMemberRole(
        groupId: String,
        userId: String,
        role: MemberRole
    ) async throws -> GroupMember {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct UpdateRoleRequest: Codable {
            let role: String
        }
        
        struct UpdateRoleResponse: Codable {
            let message: String
            let member: GroupMember
        }
        
        do {
            let request = UpdateRoleRequest(role: role.rawValue)
            let response: UpdateRoleResponse = try await apiClient.put(
                "/groups/\(groupId)/members/\(userId)",
                body: request
            )
            
            print("✅ Member role updated: \(response.message)")
            return response.member
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Remove member from group (admin/creator only)
    func removeMember(
        groupId: String,
        userId: String
    ) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct RemoveResponse: Codable {
            let message: String
        }
        
        do {
            let _: RemoveResponse = try await apiClient.delete(
                "/groups/\(groupId)/members/\(userId)"
            )
            print("✅ Member removed successfully")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Group Books
    
    /// Fetch books in a group
    func fetchGroupBooks(
        groupId: String,
        page: Int = 1,
        limit: Int = 20,
        availability: Bool? = nil,
        genre: String? = nil,
        sortBy: String = "RECENT"
    ) async throws -> (books: [Book], total: Int) {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct BooksResponse: Codable {
            let books: [Book]
            let pagination: Pagination
        }
        
        struct Pagination: Codable {
            let page: Int
            let limit: Int
            let total: Int
            let totalPages: Int
        }
        
        var queryParams: [String: Any] = [
            "page": page,
            "limit": limit,
            "sortBy": sortBy
        ]
        
        if let availability = availability {
            queryParams["availability"] = availability ? "AVAILABLE" : "NOT_AVAILABLE"
        }
        if let genre = genre {
            queryParams["genre"] = genre
        }
        
        do {
            let response: BooksResponse = try await apiClient.get(
                "/groups/\(groupId)/books",
                queryParams: queryParams
            )
            return (response.books, response.pagination.total)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Invite Management
    
    /// Regenerate invite code for group (admin/creator only)
    func regenerateInviteCode(
        groupId: String,
        expiresInDays: Int? = nil
    ) async throws -> (code: String, expiry: Date?) {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct RegenerateRequest: Codable {
            let expiresInDays: Int?
        }
        
        struct RegenerateResponse: Codable {
            let inviteCode: String
            let inviteCodeExpiry: Date?
        }
        
        do {
            let request = RegenerateRequest(expiresInDays: expiresInDays)
            let response: RegenerateResponse = try await apiClient.post(
                "/groups/\(groupId)/regenerate-invite",
                body: request
            )
            
            print("✅ Invite code regenerated: \(response.inviteCode)")
            return (response.inviteCode, response.inviteCodeExpiry)
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
