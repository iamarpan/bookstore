import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let senderId: String
    let transactionId: String
    let createdAt: String
    let isRead: Bool?
    let sender: MessageSender?
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}

struct MessageSender: Codable {
    let id: String
    let name: String
    let profileImageUrl: String?
}
