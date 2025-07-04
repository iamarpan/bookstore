import Foundation
import FirebaseFirestore

struct Society: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String
    let pincode: String
    let totalBlocks: [String]
    let amenities: [String]
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, address: String, city: String, state: String, pincode: String, totalBlocks: [String], amenities: [String] = []) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.pincode = pincode
        self.totalBlocks = totalBlocks
        self.amenities = amenities
        self.createdAt = Date()
    }
    
    // Firebase initializer
    init(id: String, name: String, address: String, city: String, state: String, pincode: String, totalBlocks: [String], amenities: [String], createdAt: Date) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.pincode = pincode
        self.totalBlocks = totalBlocks
        self.amenities = amenities
        self.createdAt = createdAt
    }
    
    // MARK: - Firebase Serialization
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "address": address,
            "city": city,
            "state": state,
            "pincode": pincode,
            "totalBlocks": totalBlocks,
            "amenities": amenities,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> Society? {
        guard let name = data["name"] as? String,
              let address = data["address"] as? String,
              let city = data["city"] as? String,
              let state = data["state"] as? String,
              let pincode = data["pincode"] as? String,
              let totalBlocks = data["totalBlocks"] as? [String],
              let amenities = data["amenities"] as? [String] else {
            return nil
        }
        
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        return Society(
            id: id,
            name: name,
            address: address,
            city: city,
            state: state,
            pincode: pincode,
            totalBlocks: totalBlocks,
            amenities: amenities,
            createdAt: createdAt
        )
    }
}

// MARK: - Mock Data
extension Society {
    static let mockSocieties: [Society] = [
        Society(
            name: "Green Valley Apartments",
            address: "123 Garden Street",
            city: "Mumbai",
            state: "Maharashtra", 
            pincode: "400001",
            totalBlocks: ["A", "B", "C", "D"],
            amenities: ["Swimming Pool", "Gym", "Playground", "Clubhouse"]
        ),
        Society(
            name: "Sunrise Heights",
            address: "456 Hill Road",
            city: "Pune",
            state: "Maharashtra",
            pincode: "411001", 
            totalBlocks: ["Block 1", "Block 2", "Block 3"],
            amenities: ["Garden", "Security", "Parking"]
        ),
        Society(
            name: "Royal Residency",
            address: "789 Palace Avenue",
            city: "Delhi",
            state: "Delhi",
            pincode: "110001",
            totalBlocks: ["Tower A", "Tower B", "Tower C", "Tower D", "Tower E"],
            amenities: ["Pool", "Gym", "Library", "Security", "Power Backup"]
        ),
        Society(
            name: "Ocean View Complex",
            address: "321 Marine Drive",
            city: "Mumbai",
            state: "Maharashtra",
            pincode: "400002",
            totalBlocks: ["Sea View", "Garden View", "City View"],
            amenities: ["Beach Access", "Gym", "Rooftop Garden"]
        ),
        Society(
            name: "Tech Park Residences",
            address: "654 IT Corridor",
            city: "Bangalore",
            state: "Karnataka", 
            pincode: "560001",
            totalBlocks: ["Alpha", "Beta", "Gamma", "Delta"],
            amenities: ["Co-working Space", "High-speed Internet", "Gym", "Cafeteria"]
        )
    ]
} 