import Foundation

struct BookRequest: Identifiable, Codable {
    var id: String?
    let bookId: String
    let borrowerId: String
    let borrowerName: String
    let borrowerFlatNumber: String
    let ownerId: String
    let requestDate: Date
    var status: RequestStatus
    var responseDate: Date?
    var returnDate: Date?
    var dueDate: Date?
    
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
    
    init(bookId: String, borrowerId: String, borrowerName: String, borrowerFlatNumber: String, ownerId: String) {
        self.id = UUID().uuidString
        self.bookId = bookId
        self.borrowerId = borrowerId
        self.borrowerName = borrowerName
        self.borrowerFlatNumber = borrowerFlatNumber
        self.ownerId = ownerId
        self.requestDate = Date()
        self.status = .pending
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
            ownerId: "owner1"
        )
    ]
} 