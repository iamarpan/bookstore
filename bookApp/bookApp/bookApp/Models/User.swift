import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String?
    let name: String
    let email: String?
    let mobile: String
    let societyId: String
    let societyName: String
    let floor: String
    let flat: String
    let profileImageURL: String?
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?
    let fcmToken: String?
    let lastTokenUpdate: Date?
    
    init(name: String, email: String? = nil, mobile: String, societyId: String, societyName: String, floor: String, flat: String, profileImageURL: String? = nil, isActive: Bool = true) {
        self.id = UUID().uuidString
        self.name = name
        self.email = email
        self.mobile = mobile
        self.societyId = societyId
        self.societyName = societyName
        self.floor = floor
        self.flat = flat
        self.profileImageURL = profileImageURL
        self.isActive = isActive
        self.createdAt = Date()
        self.lastLoginAt = nil
        self.fcmToken = nil
        self.lastTokenUpdate = nil
    }
    
    // Firebase initializer
    init(id: String, name: String, email: String? = nil, mobile: String, societyId: String, societyName: String, floor: String, flat: String, profileImageURL: String? = nil, isActive: Bool = true, createdAt: Date = Date(), lastLoginAt: Date? = nil, fcmToken: String? = nil, lastTokenUpdate: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.mobile = mobile
        self.societyId = societyId
        self.societyName = societyName
        self.floor = floor
        self.flat = flat
        self.profileImageURL = profileImageURL
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.fcmToken = fcmToken
        self.lastTokenUpdate = lastTokenUpdate
    }
    
    // Convenience computed property for display
    var fullAddress: String {
        return "\(floor)-\(flat), \(societyName)"
    }
    
    // MARK: - Firebase Serialization
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "email": email ?? "",
            "mobile": mobile,
            "societyId": societyId,
            "societyName": societyName,
            "floor": floor,
            "flat": flat,
            "profileImageURL": profileImageURL ?? "",
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt),
            "lastLoginAt": lastLoginAt != nil ? Timestamp(date: lastLoginAt!) : NSNull(),
            "fcmToken": fcmToken ?? "",
            "lastTokenUpdate": lastTokenUpdate != nil ? Timestamp(date: lastTokenUpdate!) : NSNull()
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> User? {
        guard let name = data["name"] as? String,
              let mobile = data["mobile"] as? String,
              let societyId = data["societyId"] as? String,
              let societyName = data["societyName"] as? String,
              let floor = data["floor"] as? String,
              let flat = data["flat"] as? String,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        let email = (data["email"] as? String)?.isEmpty == false ? data["email"] as? String : nil
        let profileImageURL = (data["profileImageURL"] as? String)?.isEmpty == false ? data["profileImageURL"] as? String : nil
        let fcmToken = (data["fcmToken"] as? String)?.isEmpty == false ? data["fcmToken"] as? String : nil
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        let lastLoginAt: Date?
        if let timestamp = data["lastLoginAt"] as? Timestamp {
            lastLoginAt = timestamp.dateValue()
        } else {
            lastLoginAt = nil
        }
        
        let lastTokenUpdate: Date?
        if let timestamp = data["lastTokenUpdate"] as? Timestamp {
            lastTokenUpdate = timestamp.dateValue()
        } else {
            lastTokenUpdate = nil
        }
        
        return User(
            id: id,
            name: name,
            email: email,
            mobile: mobile,
            societyId: societyId,
            societyName: societyName,
            floor: floor,
            flat: flat,
            profileImageURL: profileImageURL,
            isActive: isActive,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            fcmToken: fcmToken,
            lastTokenUpdate: lastTokenUpdate
        )
    }
    
    // MARK: - UserDefaults Serialization (JSON-safe)
    func toUserDefaultsDictionary() -> [String: Any] {
        let dateFormatter = ISO8601DateFormatter()
        
        return [
            "id": id ?? "",
            "name": name,
            "email": email ?? "",
            "mobile": mobile,
            "societyId": societyId,
            "societyName": societyName,
            "floor": floor,
            "flat": flat,
            "profileImageURL": profileImageURL ?? "",
            "isActive": isActive,
            "createdAt": dateFormatter.string(from: createdAt),
            "lastLoginAt": lastLoginAt != nil ? dateFormatter.string(from: lastLoginAt!) : "",
            "fcmToken": fcmToken ?? "",
            "lastTokenUpdate": lastTokenUpdate != nil ? dateFormatter.string(from: lastTokenUpdate!) : ""
        ]
    }
    
    static func fromUserDefaultsDictionary(_ data: [String: Any]) -> User? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let mobile = data["mobile"] as? String,
              let societyId = data["societyId"] as? String,
              let societyName = data["societyName"] as? String,
              let floor = data["floor"] as? String,
              let flat = data["flat"] as? String,
              let isActive = data["isActive"] as? Bool,
              let createdAtString = data["createdAt"] as? String else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        
        let email = (data["email"] as? String)?.isEmpty == false ? data["email"] as? String : nil
        let profileImageURL = (data["profileImageURL"] as? String)?.isEmpty == false ? data["profileImageURL"] as? String : nil
        let fcmToken = (data["fcmToken"] as? String)?.isEmpty == false ? data["fcmToken"] as? String : nil
        
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        
        let lastLoginAt: Date?
        if let lastLoginAtString = data["lastLoginAt"] as? String, !lastLoginAtString.isEmpty {
            lastLoginAt = dateFormatter.date(from: lastLoginAtString)
        } else {
            lastLoginAt = nil
        }
        
        let lastTokenUpdate: Date?
        if let lastTokenUpdateString = data["lastTokenUpdate"] as? String, !lastTokenUpdateString.isEmpty {
            lastTokenUpdate = dateFormatter.date(from: lastTokenUpdateString)
        } else {
            lastTokenUpdate = nil
        }
        
        return User(
            id: id,
            name: name,
            email: email,
            mobile: mobile,
            societyId: societyId,
            societyName: societyName,
            floor: floor,
            flat: flat,
            profileImageURL: profileImageURL,
            isActive: isActive,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            fcmToken: fcmToken,
            lastTokenUpdate: lastTokenUpdate
        )
    }
}

// MARK: - Mock Data
extension User {
    static let mockUser = User(
        name: "Demo User",
        email: "demo@example.com",
        mobile: "+919876543210",
        societyId: Society.mockSocieties[0].id,
        societyName: Society.mockSocieties[0].name,
        floor: "A",
        flat: "101"
    )
} 
