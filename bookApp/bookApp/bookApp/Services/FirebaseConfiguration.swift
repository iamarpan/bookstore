import Foundation
import FirebaseCore

class FirebaseConfiguration {
    static let shared = FirebaseConfiguration()
    
    private init() {}
    
    func configure() -> Bool {
        // Check if Firebase is already configured
        if FirebaseApp.app() != nil {
            return true
        }
        
        // Check for GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
            print("❌ CRITICAL ERROR: GoogleService-Info.plist not found!")
            print("📝 Please download GoogleService-Info.plist from the Firebase Console and add it to the project.")
            return false
        }
        
        // Validate plist content
        guard let plist = NSDictionary(contentsOfFile: path),
              let _ = plist["CLIENT_ID"] as? String,
              let _ = plist["API_KEY"] as? String,
              let _ = plist["GCM_SENDER_ID"] as? String,
              let _ = plist["PROJECT_ID"] as? String else {
            print("❌ CRITICAL ERROR: GoogleService-Info.plist is missing required fields.")
            return false
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
        return true
    }
}
