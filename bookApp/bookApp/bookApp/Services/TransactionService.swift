import Foundation

/// Service for transaction/borrowing workflow operations
@MainActor
class TransactionService: ObservableObject {
    // MARK: - Published Properties
    @Published var transactions: [Transaction] = []
    @Published var activeTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private Properties
    private nonisolated let apiClient: APIClient
    
    // MARK: - Initialization
    
    nonisolated init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Fetch Transactions
    
    /// Fetch user's transactions
    func fetchTransactions(
        role: String? = nil,  // "BORROWER", "OWNER", or nil for all
        status: TransactionStatus? = nil,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> [Transaction] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        var queryParams: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if let role = role {
            queryParams["role"] = role
        }
        if let status = status {
            queryParams["status"] = status.rawValue
        }
        
        struct TransactionsResponse: Codable {
            let transactions: [Transaction]
        }
        
        do {
            let response: TransactionsResponse = try await apiClient.get(
                "/transactions/my",
                queryParams: queryParams
            )
            
            transactions = response.transactions
            updateActiveTransactions()
            
            return response.transactions
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Update active transactions list
    private func updateActiveTransactions() {
        activeTransactions = transactions.filter { $0.status == .active }
    }
    
    // MARK: - Create Borrow Request
    
    /// Create a borrow request for a book
    func createBorrowRequest(
        bookId: String,
        duration: BorrowDuration,
        durationDays: Int? = nil,
        message: String? = nil
    ) async throws -> Transaction {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct BorrowRequest: Codable {
            let bookId: String
            let duration: String
            let durationDays: Int?
            let message: String?
        }
        
        do {
            let request = BorrowRequest(
                bookId: bookId,
                duration: duration.rawValue,
                durationDays: durationDays ?? duration.days,
                message: message
            )
            
            let transaction: Transaction = try await apiClient.post(
                "/transactions/request",
                body: request
            )
            
            // Add to local list
            transactions.insert(transaction, at: 0)
            
            print("✅ Borrow request created: \(transaction.id)")
            return transaction
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Approve/Reject Requests
    
    /// Approve a borrow request (owner only)
    func approveRequest(id: String) async throws -> Transaction {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let transaction: Transaction = try await apiClient.post(
                "/transactions/\(id)/approve",
                body: EmptyRequest()
            )
            
            // Update in local list
            updateLocalTransaction(transaction)
            
            print("✅ Request approved: \(id)")
            return transaction
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Reject a borrow request (owner only)
    func rejectRequest(id: String, reason: String? = nil) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct RejectRequest: Codable {
            let reason: String?
        }
        
        do {
            let request = RejectRequest(reason: reason)
            let transaction: Transaction = try await apiClient.post(
                "/transactions/\(id)/reject",
                body: request
            )
            
            // Update in local list
            updateLocalTransaction(transaction)
            
            print("✅ Request rejected: \(id)")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - OTP Handover/Return
    
    /// Generate 4-digit OTP for handover (borrower side)
    func generateHandoverOTP() -> String {
        return String(format: "%04d", Int.random(in: 0...9999))
    }
    
    /// Confirm book handover with OTP (owner enters borrower's OTP)
    func confirmHandover(id: String, otp: String) async throws -> Transaction {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct HandoverRequest: Codable {
            let otp: String
        }
        
        do {
            let request = HandoverRequest(otp: otp)
            let transaction: Transaction = try await apiClient.post(
                "/transactions/\(id)/confirm-handover",
                body: request
            )
            
            // Update in local list
            updateLocalTransaction(transaction)
            updateActiveTransactions()
            
            print("✅ Handover confirmed: \(id)")
            return transaction
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    /// Generate 4-digit OTP for return (owner side)
    func generateReturnOTP() -> String {
        return String(format: "%04d", Int.random(in: 0...9999))
    }
    
    /// Confirm book return with OTP (borrower enters owner's OTP)
    func confirmReturn(id: String, otp: String) async throws -> Transaction {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct ReturnRequest: Codable {
            let otp: String
        }
        
        do {
            let request = ReturnRequest(otp: otp)
            let transaction: Transaction = try await apiClient.post(
                "/transactions/\(id)/confirm-return",
                body: request
            )
            
            // Update in local list
            updateLocalTransaction(transaction)
            updateActiveTransactions()
            
            print("✅ Return confirmed: \(id)")
            return transaction
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Payment Management
    
    /// Mark payment as complete (offline payment confirmation)
    func markPaymentComplete(id: String, role: String) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct PaymentRequest: Codable {
            let role: String  // "BORROWER" or "OWNER"
        }
        
        do {
            let request = PaymentRequest(role: role)
            let transaction: Transaction = try await apiClient.post(
                "/transactions/\(id)/mark-payment",
                body: request
            )
            
            // Update in local list
            updateLocalTransaction(transaction)
            
            print("✅ Payment marked complete by \(role): \(id)")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Ratings
    
    /// Rate a transaction after completion
    func rateTransaction(
        id: String,
        rating: Int,
        comment: String? = nil,
        bookConditionRating: Int? = nil  // Only for owner
    ) async throws {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        struct RatingRequest: Codable {
            let rating: Int
            let comment: String?
            let bookConditionRating: Int?
        }
        
        do {
            let request = RatingRequest(
                rating: rating,
                comment: comment,
                bookConditionRating: bookConditionRating
            )
            
            try await apiClient.post(
                "/transactions/\(id)/rate",
                body: request
            )
            
            print("✅ Transaction rated: \(id)")
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    /// Update transaction in local list
    private func updateLocalTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
        }
    }
    
    /// Get transactions by role and status
    func getTransactions(role: String, status: TransactionStatus) -> [Transaction] {
        return transactions.filter { transaction in
            let matchesRole = (role == "BORROWER" && transaction.isBorrower(userId: "current")) ||
                            (role == "OWNER" && transaction.isOwner(userId: "current"))
            let matchesStatus = transaction.status == status
            return matchesRole && matchesStatus
        }
    }
    
    // MARK: - OTP Storage (Client-side)
    
    /// Store OTP locally with expiry
    func storeOTP(_ otp: String, for transactionId: String, expiryMinutes: Int = 10) {
        let key = "otp_\(transactionId)"
        let expiry = Date().addingTimeInterval(TimeInterval(expiryMinutes * 60))
        
        let otpData: [String: Any] = [
            "otp": otp,
            "expiry": expiry.timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(otpData, forKey: key)
        print("💾 Stored OTP for transaction \(transactionId), expires at \(expiry)")
    }
    
    /// Retrieve stored OTP if not expired
    func retrieveOTP(for transactionId: String) -> String? {
        let key = "otp_\(transactionId)"
        
        guard let otpData = UserDefaults.standard.dictionary(forKey: key),
              let otp = otpData["otp"] as? String,
              let expiryTimestamp = otpData["expiry"] as? TimeInterval else {
            return nil
        }
        
        let expiry = Date(timeIntervalSince1970: expiryTimestamp)
        
        if Date() > expiry {
            // OTP expired, remove it
            UserDefaults.standard.removeObject(forKey: key)
            print("⏰ OTP expired for transaction \(transactionId)")
            return nil
        }
        
        return otp
    }
    
    /// Clear stored OTP
    func clearOTP(for transactionId: String) {
        let key = "otp_\(transactionId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - Mock Data (for development)
    
    /// Load mock transactions
    func loadMockTransactions() {
        transactions = Transaction.mockTransactions
        updateActiveTransactions()
        print("✅ Loaded \(transactions.count) mock transactions")
    }
}

// MARK: - Helper Types

private struct EmptyRequest: Codable {}
