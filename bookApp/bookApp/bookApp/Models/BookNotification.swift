import Foundation

// MARK: - Notification Type Enum (matching backend API contract)
enum NotificationType: String, Codable {
    case borrowRequest = "BORROW_REQUEST"
    case requestApproved = "REQUEST_APPROVED"
    case requestRejected = "REQUEST_REJECTED"
    case dueSoon = "DUE_SOON"
    case overdue = "OVERDUE"
    case returnRequested = "RETURN_REQUESTED"
    case newBookInGroup = "NEW_BOOK_IN_GROUP"
    
    var displayName: String {
        switch self {
        case .borrowRequest: return "New Borrow Request"
        case .requestApproved: return "Request Approved"
        case .requestRejected: return "Request Rejected"
        case .dueSoon: return "Book Due Soon"
        case .overdue: return "Book Overdue"
        case .returnRequested: return "Return Requested"
        case .newBookInGroup: return "New Book in Group"
        }
    }
    
    var icon: String {
        switch self {
        case .borrowRequest: return "book.circle.fill"
        case .requestApproved: return "checkmark.circle.fill"
        case .requestRejected: return "xmark.circle.fill"
        case .dueSoon: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .returnRequested: return "arrow.uturn.backward.circle.fill"
        case .newBookInGroup: return "sparkles"
        }
    }
    
    var color: String {
        switch self {
        case .borrowRequest: return "blue"
        case .requestApproved: return "green"
        case .requestRejected: return "red"
        case .dueSoon: return "orange"
        case .overdue: return "red"
        case .returnRequested: return "purple"
        case .newBookInGroup: return "teal"
        }
    }
}

// MARK: - Notification Model
struct BookNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    var title: String
    var message: String
    
    // Notification data (backend payload)
    var data: NotificationData?
    
    // Read status
    var isRead: Bool
    
    // Timestamp
    let createdAt: Date
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, type, title, message, data, isRead, createdAt
    }
    
    // MARK: - Initializers
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        message: String,
        data: NotificationData? = nil,
        isRead: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.data = data
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

// MARK: - Notification Data (backend payload)
struct NotificationData: Codable {
    var transactionId: String?
    var bookId: String?
    var groupId: String?
    var userId: String?
    
    enum CodingKeys: String, CodingKey {
        case transactionId, bookId, groupId, userId
    }
}

// MARK: - Helper Properties
extension BookNotification {
    /// Time ago string
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    /// Has associated action
    var hasAction: Bool {
        switch type {
        case .borrowRequest, .dueSoon, .overdue, .returnRequested:
            return true
        default:
            return false
        }
    }
    
    /// Action button text
    var actionText: String? {
        switch type {
        case .borrowRequest: return "View Request"
        case .dueSoon, .overdue: return "View Book"
        case .returnRequested: return "Arrange Return"
        default: return nil
        }
    }
}

// MARK: - Mock Data
extension BookNotification {
    static let mockNotifications: [BookNotification] = [
        BookNotification(
            id: "ntf_001",
            type: .borrowRequest,
            title: "New borrow request",
            message: "Jane Smith wants to borrow Clean Code",
            data: NotificationData(
                transactionId: "txn_456",
                bookId: "bk_123"
            ),
            createdAt: Date().addingTimeInterval(-3600 * 2)  // 2 hours ago
        ),
        BookNotification(
            id: "ntf_002",
            type: .requestApproved,
            title: "Request approved",
            message: "Your request for Sapiens has been approved",
            data: NotificationData(
                transactionId: "txn_457",
                bookId: "bk_124"
            ),
            isRead: true,
            createdAt: Date().addingTimeInterval(-86400)  // 1 day ago
        ),
        BookNotification(
            id: "ntf_003",
            type: .dueSoon,
            title: "Book due in 24 hours",
            message: "Clean Code is due tomorrow",
            data: NotificationData(
                transactionId: "txn_001",
                bookId: "bk_123"
            ),
            createdAt: Date().addingTimeInterval(-1800)  // 30 mins ago
        ),
        BookNotification(
            id: "ntf_004",
            type: .newBookInGroup,
            title: "New book in Office Book Club",
            message: "Alex Rodriguez added The Pragmatic Programmer",
            data: NotificationData(
                bookId: "bk_125",
                groupId: "club1"
            ),
            createdAt: Date().addingTimeInterval(-7200)  // 2 hours ago
        )
    ]
}