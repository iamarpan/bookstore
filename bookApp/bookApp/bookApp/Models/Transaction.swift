import Foundation

// MARK: - Transaction Status Enum
enum TransactionStatus: String, Codable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case active = "ACTIVE"
    case returned = "RETURNED"
    case rejected = "REJECTED"
    case cancelled = "CANCELLED"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .active: return "Active"
        case .returned: return "Returned"
        case .rejected: return "Rejected"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .active: return "blue"
        case .returned: return "purple"
        case .rejected, .cancelled: return "red"
        }
    }
}

// MARK: - Borrow Duration Enum
enum BorrowDuration: String, Codable {
    case oneWeek = "1_WEEK"
    case twoWeeks = "2_WEEKS"
    case oneMonth = "1_MONTH"
    case custom = "CUSTOM"
    
    var displayName: String {
        switch self {
        case .oneWeek: return "1 Week"
        case .twoWeeks: return "2 Weeks"
        case .oneMonth: return "1 Month"
        case .custom: return "Custom"
        }
    }
    
    var days: Int {
        switch self {
        case .oneWeek: return 7
        case .twoWeeks: return 14
        case .oneMonth: return 30
        case .custom: return 0  // Will use durationDays field
        }
    }
}

// MARK: - Payment Status
struct PaymentStatus: Codable {
    var borrowerConfirmed: Bool
    var ownerConfirmed: Bool
    
    var isComplete: Bool {
        borrowerConfirmed && ownerConfirmed
    }
    
    init(borrowerConfirmed: Bool = false, ownerConfirmed: Bool = false) {
        self.borrowerConfirmed = borrowerConfirmed
        self.ownerConfirmed = ownerConfirmed
    }
}

// MARK: - Transaction Model
struct Transaction: Identifiable, Codable {
    let id: String
    
    // Book info (denormalized for display)
    let bookId: String
    var bookTitle: String
    var bookImageUrl: String?
    
    // Parties involved
    let borrowerId: String
    var borrowerName: String
    var borrowerProfileImageUrl: String?
    
    let ownerId: String
    var ownerName: String
    var ownerProfileImageUrl: String?
    
    // Group context
    let groupId: String
    
    // Status and workflow
    var status: TransactionStatus
    
    // Duration
    var duration: BorrowDuration
    var durationDays: Int  // Actual days, for custom duration
    
    // Pricing
    var lendingFee: Double
    
    // Messages and notes
    var requestMessage: String?
    var rejectionReason: String?
    
    // OTP fields (client-side generated, server validates)
    var handoverOTP: String?
    var handoverOTPExpiry: Date?
    var returnOTP: String?
    var returnOTPExpiry: Date?
    
    // Payment tracking (offline)
    var paymentStatus: PaymentStatus
    
    // Timeline
    let requestedAt: Date
    var approvedAt: Date?
    var handoverAt: Date?
    var dueDate: Date?
    var returnedAt: Date?
    
    // Ratings
    var ownerRating: Int?  // 1-5
    var ownerComment: String?
    var borrowerRating: Int?  // 1-5
    var borrowerComment: String?
    var bookConditionRating: Int?  // Only for owner
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case bookId, bookTitle, bookImageUrl
        case borrowerId, borrowerName, borrowerProfileImageUrl
        case ownerId, ownerName, ownerProfileImageUrl
        case groupId
        case status
        case duration, durationDays
        case lendingFee
        case requestMessage, rejectionReason
        case handoverOTP, handoverOTPExpiry, returnOTP, returnOTPExpiry
        case paymentStatus
        case requestedAt, approvedAt, handoverAt, dueDate, returnedAt
        case ownerRating, ownerComment, borrowerRating, borrowerComment, bookConditionRating
    }
    
    // MARK: - Initializers
    
    init(
        id: String = UUID().uuidString,
        bookId: String,
        bookTitle: String,
        bookImageUrl: String? = nil,
        borrowerId: String,
        borrowerName: String,
        borrowerProfileImageUrl: String? = nil,
        ownerId: String,
        ownerName: String,
        ownerProfileImageUrl: String? = nil,
        groupId: String,
        status: TransactionStatus = .pending,
        duration: BorrowDuration,
        durationDays: Int? = nil,
        lendingFee: Double,
        requestMessage: String? = nil,
        rejectionReason: String? = nil,
        handoverOTP: String? = nil,
        handoverOTPExpiry: Date? = nil,
        returnOTP: String? = nil,
        returnOTPExpiry: Date? = nil,
        paymentStatus: PaymentStatus = PaymentStatus(),
        requestedAt: Date = Date(),
        approvedAt: Date? = nil,
        handoverAt: Date? = nil,
        dueDate: Date? = nil,
        returnedAt: Date? = nil,
        ownerRating: Int? = nil,
        ownerComment: String? = nil,
        borrowerRating: Int? = nil,
        borrowerComment: String? = nil,
        bookConditionRating: Int? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.bookImageUrl = bookImageUrl
        self.borrowerId = borrowerId
        self.borrowerName = borrowerName
        self.borrowerProfileImageUrl = borrowerProfileImageUrl
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.ownerProfileImageUrl = ownerProfileImageUrl
        self.groupId = groupId
        self.status = status
        self.duration = duration
        self.durationDays = durationDays ?? duration.days
        self.lendingFee = lendingFee
        self.requestMessage = requestMessage
        self.rejectionReason = rejectionReason
        self.handoverOTP = handoverOTP
        self.handoverOTPExpiry = handoverOTPExpiry
        self.returnOTP = returnOTP
        self.returnOTPExpiry = returnOTPExpiry
        self.paymentStatus = paymentStatus
        self.requestedAt = requestedAt
        self.approvedAt = approvedAt
        self.handoverAt = handoverAt
        self.dueDate = dueDate
        self.returnedAt = returnedAt
        self.ownerRating = ownerRating
        self.ownerComment = ownerComment
        self.borrowerRating = borrowerRating
        self.borrowerComment = borrowerComment
        self.bookConditionRating = bookConditionRating
    }
}

// MARK: - Helper Properties
extension Transaction {
    /// Check if transaction is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate, status == .active else {
            return false
        }
        return Date() > dueDate
    }
    
    /// Days until due (negative if overdue)
    var daysUntilDue: Int? {
        guard let dueDate = dueDate, status == .active else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day
    }
    
    /// Formatted due date string
    var dueDateDisplay: String? {
        guard let dueDate = dueDate else { return nil }
        
        if let days = daysUntilDue {
            if days < 0 {
                return "Overdue by \(abs(days)) day\(abs(days) == 1 ? "" : "s")"
            } else if days == 0 {
                return "Due today"
            } else if days == 1 {
                return "Due tomorrow"
            } else {
                return "Due in \(days) days"
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Due: \(formatter.string(from: dueDate))"
    }
    
    /// Check if user is owner
    func isOwner(userId: String) -> Bool {
        return ownerId == userId
    }
    
    /// Check if user is borrower
    func isBorrower(userId: String) -> Bool {
        return borrowerId == userId
    }
    
    /// Total cost display
    var totalCostDisplay: String {
        if lendingFee == 0 {
            return "Free"
        }
        let totalWeeks = Double(durationDays) / 7.0
        let total = lendingFee * totalWeeks
        return "₹\(Int(total))"
    }
}

// MARK: - Mock Data
extension Transaction {
    static let mockTransactions: [Transaction] = [
        Transaction(
            id: "txn_001",
            bookId: "bk_123",
            bookTitle: "Clean Code",
            borrowerId: "usr_demo",
            borrowerName: "Demo User",
            ownerId: "3",
            ownerName: "Alex Rodriguez",
            groupId: "club1",
            status: .active,
            duration: .twoWeeks,
            lendingFee: 40,
            requestedAt: Date().addingTimeInterval(-86400 * 2),  // 2 days ago
            approvedAt: Date().addingTimeInterval(-86400 * 1),   // 1 day ago
            handoverAt: Date().addingTimeInterval(-86400),        // Yesterday
            dueDate: Date().addingTimeInterval(86400 * 12)       // 12 days from now
        ),
        Transaction(
            id: "txn_002",
            bookId: "bk_124",
            bookTitle: "Sapiens",
            borrowerId: "2",
            borrowerName: "Sarah Johnson",
            ownerId: "usr_demo",
            ownerName: "Demo User",
            groupId: "club1",
            status: .pending,
            duration: .oneWeek,
            lendingFee: 45,
            requestMessage: "I'd love to read this book!",
            requestedAt: Date().addingTimeInterval(-3600 * 2)  // 2 hours ago
        )
    ]
}
