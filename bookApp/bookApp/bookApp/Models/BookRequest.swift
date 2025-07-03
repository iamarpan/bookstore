import Foundation
import FirebaseFirestore

enum RequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case returned = "returned"
    case overdue = "overdue"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .returned: return "Returned"
        case .overdue: return "Overdue"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .returned: return "blue"
        case .overdue: return "red"
        }
    }
}

struct BookRequest: Identifiable, Codable {
    var id: String?
    let bookId: String
    let borrowerId: String
    let borrowerName: String
    let borrowerFlatNumber: String
    let ownerId: String
    let societyId: String
    let requestDate: Date
    var status: RequestStatus
    var responseDate: Date?
    var returnDate: Date?
    var dueDate: Date?
    var notes: String?
    
    init(bookId: String, borrowerId: String, borrowerName: String, borrowerFlatNumber: String, ownerId: String, societyId: String) {
        self.id = UUID().uuidString
        self.bookId = bookId
        self.borrowerId = borrowerId
        self.borrowerName = borrowerName
        self.borrowerFlatNumber = borrowerFlatNumber
        self.ownerId = ownerId
        self.societyId = societyId
        self.requestDate = Date()
        self.status = .pending
    }
    
    // Firebase initializer
    init(id: String, bookId: String, borrowerId: String, borrowerName: String, borrowerFlatNumber: String, ownerId: String, societyId: String, requestDate: Date, status: RequestStatus, responseDate: Date? = nil, returnDate: Date? = nil, dueDate: Date? = nil, notes: String? = nil) {
        self.id = id
        self.bookId = bookId
        self.borrowerId = borrowerId
        self.borrowerName = borrowerName
        self.borrowerFlatNumber = borrowerFlatNumber
        self.ownerId = ownerId
        self.societyId = societyId
        self.requestDate = requestDate
        self.status = status
        self.responseDate = responseDate
        self.returnDate = returnDate
        self.dueDate = dueDate
        self.notes = notes
    }
    
    // MARK: - Firebase Serialization
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "bookId": bookId,
            "borrowerId": borrowerId,
            "borrowerName": borrowerName,
            "borrowerFlatNumber": borrowerFlatNumber,
            "ownerId": ownerId,
            "societyId": societyId,
            "requestDate": Timestamp(date: requestDate),
            "status": status.rawValue
        ]
        
        if let responseDate = responseDate {
            dict["responseDate"] = Timestamp(date: responseDate)
        }
        
        if let returnDate = returnDate {
            dict["returnDate"] = Timestamp(date: returnDate)
        }
        
        if let dueDate = dueDate {
            dict["dueDate"] = Timestamp(date: dueDate)
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        return dict
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> BookRequest? {
        guard let bookId = data["bookId"] as? String,
              let borrowerId = data["borrowerId"] as? String,
              let borrowerName = data["borrowerName"] as? String,
              let borrowerFlatNumber = data["borrowerFlatNumber"] as? String,
              let ownerId = data["ownerId"] as? String,
              let societyId = data["societyId"] as? String,
              let statusString = data["status"] as? String,
              let status = RequestStatus(rawValue: statusString) else {
            return nil
        }
        
        let requestDate: Date
        if let timestamp = data["requestDate"] as? Timestamp {
            requestDate = timestamp.dateValue()
        } else {
            requestDate = Date()
        }
        
        let responseDate: Date?
        if let timestamp = data["responseDate"] as? Timestamp {
            responseDate = timestamp.dateValue()
        } else {
            responseDate = nil
        }
        
        let returnDate: Date?
        if let timestamp = data["returnDate"] as? Timestamp {
            returnDate = timestamp.dateValue()
        } else {
            returnDate = nil
        }
        
        let dueDate: Date?
        if let timestamp = data["dueDate"] as? Timestamp {
            dueDate = timestamp.dateValue()
        } else {
            dueDate = nil
        }
        
        let notes = data["notes"] as? String
        
        return BookRequest(
            id: id,
            bookId: bookId,
            borrowerId: borrowerId,
            borrowerName: borrowerName,
            borrowerFlatNumber: borrowerFlatNumber,
            ownerId: ownerId,
            societyId: societyId,
            requestDate: requestDate,
            status: status,
            responseDate: responseDate,
            returnDate: returnDate,
            dueDate: dueDate,
            notes: notes
        )
    }
}

// MARK: - Mock Data
extension BookRequest {
    static let mockRequests: [BookRequest] = [
        BookRequest(
            bookId: "1",
            borrowerId: "user1",
            borrowerName: "Demo User",
            borrowerFlatNumber: "A-101",
            ownerId: "owner1",
            societyId: "society1"
        )
    ]
} 