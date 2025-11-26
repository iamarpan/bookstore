import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable, CaseIterable {
    case bookRequest = "book_request"
    case requestApproved = "request_approved"
    case requestRejected = "request_rejected"
    case returnReminder = "return_reminder"
    case overdue = "overdue"
    case bookReturned = "book_returned"
    
    var displayName: String {
        switch self {
        case .bookRequest: return "Book Request"
        case .requestApproved: return "Request Approved"
        case .requestRejected: return "Request Rejected"
        case .returnReminder: return "Return Reminder"
        case .overdue: return "Overdue"
        case .bookReturned: return "Book Returned"
        }
    }
    
    var icon: String {
        switch self {
        case .bookRequest: return "book.circle"
        case .requestApproved: return "checkmark.circle.fill"
        case .requestRejected: return "xmark.circle.fill"
        case .returnReminder: return "clock.circle"
        case .overdue: return "exclamationmark.triangle.fill"
        case .bookReturned: return "arrow.uturn.backward.circle.fill"
        }
    }
}

struct BookNotification: Identifiable, Codable {
    var id: String?
    let userId: String
    let title: String
    let message: String
    let type: NotificationType
    let relatedBookId: String?
    let relatedRequestId: String?
    let bookClubId: String
    var timestamp: Date
    var isRead: Bool
    
    init(userId: String, title: String, message: String, type: NotificationType, relatedBookId: String? = nil, relatedRequestId: String? = nil, bookClubId: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        self.relatedBookId = relatedBookId
        self.relatedRequestId = relatedRequestId
        self.bookClubId = bookClubId
        self.timestamp = Date()
        self.isRead = false
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "title": title,
            "message": message,
            "type": type.rawValue,
            "relatedBookId": relatedBookId ?? NSNull(),
            "relatedRequestId": relatedRequestId ?? NSNull(),
            "bookClubId": bookClubId,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> BookNotification? {
        guard let userId = data["userId"] as? String,
              let title = data["title"] as? String,
              let message = data["message"] as? String,
              let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let bookClubId = data["bookClubId"] as? String else {
            return nil
        }
        
        let relatedBookId = data["relatedBookId"] as? String
        let relatedRequestId = data["relatedRequestId"] as? String
        let isRead = data["isRead"] as? Bool ?? false
        
        let timestamp: Date
        if let ts = data["timestamp"] as? Timestamp {
            timestamp = ts.dateValue()
        } else {
            timestamp = Date()
        }
        
        var notification = BookNotification(
            userId: userId,
            title: title,
            message: message,
            type: type,
            relatedBookId: relatedBookId,
            relatedRequestId: relatedRequestId,
            bookClubId: bookClubId
        )
        notification.id = id
        notification.timestamp = timestamp // Override with actual timestamp
        notification.isRead = isRead
        
        return notification
    }
}

// MARK: - Mock Data
extension BookNotification {
    static let mockNotifications: [BookNotification] = [
        BookNotification(
            userId: "user1",
            title: "New Book Request",
            message: "Someone requested your book 'The Great Gatsby'",
            type: .bookRequest,
            relatedBookId: "book1",
            bookClubId: "club1"
        ),
        BookNotification(
            userId: "user1",
            title: "Request Approved",
            message: "Your request for 'Dune' has been approved",
            type: .requestApproved,
            relatedBookId: "book2",
            relatedRequestId: "request1",
            bookClubId: "club1"
        )
    ]
} 