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
    let type: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let relatedId: String? // bookId or requestId
    let createdAt: Date
    let societyId: String
    
    init(userId: String, type: NotificationType, title: String, message: String, relatedId: String? = nil, societyId: String, isRead: Bool = false) {
        self.id = UUID().uuidString
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.relatedId = relatedId
        self.createdAt = Date()
        self.societyId = societyId
    }
    
    // Firebase initializer
    init(id: String, userId: String, type: NotificationType, title: String, message: String, isRead: Bool, relatedId: String?, createdAt: Date, societyId: String) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.relatedId = relatedId
        self.createdAt = createdAt
        self.societyId = societyId
    }
    
    // MARK: - Firebase Serialization
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "message": message,
            "isRead": isRead,
            "createdAt": Timestamp(date: createdAt),
            "societyId": societyId
        ]
        
        if let relatedId = relatedId {
            dict["relatedId"] = relatedId
        }
        
        return dict
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> BookNotification? {
        guard let userId = data["userId"] as? String,
              let typeString = data["type"] as? String,
              let type = NotificationType(rawValue: typeString),
              let title = data["title"] as? String,
              let message = data["message"] as? String,
              let isRead = data["isRead"] as? Bool,
              let societyId = data["societyId"] as? String else {
            return nil
        }
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let relatedId = data["relatedId"] as? String
        
        return BookNotification(
            id: id,
            userId: userId,
            type: type,
            title: title,
            message: message,
            isRead: isRead,
            relatedId: relatedId,
            createdAt: createdAt,
            societyId: societyId
        )
    }
}

// MARK: - Mock Data
extension BookNotification {
    static let mockNotifications: [BookNotification] = [
        BookNotification(
            userId: "user1",
            type: .bookRequest,
            title: "New Book Request",
            message: "Someone requested your book 'The Great Gatsby'",
            relatedId: "book1",
            societyId: "society1"
        ),
        BookNotification(
            userId: "user1",
            type: .requestApproved,
            title: "Request Approved",
            message: "Your request for 'Dune' has been approved",
            relatedId: "request1",
            societyId: "society1"
        )
    ]
} 