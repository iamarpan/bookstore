import Foundation
import FirebaseFirestore

struct BookClub: Identifiable, Codable {
    var id: String?
    let name: String
    let description: String
    let inviteCode: String
    let memberIds: [String]
    let adminIds: [String]
    let createdAt: Date
    
    init(name: String, description: String, inviteCode: String, creatorId: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.inviteCode = inviteCode
        self.memberIds = [creatorId]
        self.adminIds = [creatorId]
        self.createdAt = Date()
    }
    
    // Firebase initializer
    init(id: String, name: String, description: String, inviteCode: String, memberIds: [String], adminIds: [String], createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.inviteCode = inviteCode
        self.memberIds = memberIds
        self.adminIds = adminIds
        self.createdAt = createdAt
    }
    
    // MARK: - Firebase Serialization
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "description": description,
            "inviteCode": inviteCode,
            "memberIds": memberIds,
            "adminIds": adminIds,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> BookClub? {
        guard let name = data["name"] as? String,
              let description = data["description"] as? String,
              let inviteCode = data["inviteCode"] as? String,
              let memberIds = data["memberIds"] as? [String],
              let adminIds = data["adminIds"] as? [String] else {
            return nil
        }
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        return BookClub(
            id: id,
            name: name,
            description: description,
            inviteCode: inviteCode,
            memberIds: memberIds,
            adminIds: adminIds,
            createdAt: createdAt
        )
    }
}
