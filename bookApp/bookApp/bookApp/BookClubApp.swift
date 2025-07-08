// BookClubApp.swift
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@main
struct BookClubApp: App {
    // Register app delegate for Firebase and FCM setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        print("🚀 Book Club app starting up...")
        
        // Configure emulators for local testing
        #if DEBUG
        //configureEmulators()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ThemeManager())
        }
    }
    
    // MARK: - Emulator Configuration
//    private func configureEmulators() {
//        print("🔧 Configuring Firebase emulators for local development...")
//        
//        // Firestore emulator configuration
//        let settings = Firestore.firestore().settings
//        settings.host = "127.0.0.1:8080"
//        settings.cacheSettings = MemoryCacheSettings()
//        settings.isSSLEnabled = false
//        Firestore.firestore().settings = settings
//        
//        // Storage emulator configuration
//        Storage.storage().useEmulator(withHost: "127.0.0.1", port: 9199)
//        
//        // NOTE: Auth emulator is disabled because it doesn't support real phone authentication
//        // The app uses mock authentication in development mode instead
//        // If you need to test with Auth emulator, use test phone numbers like +1 650-555-3434
//        
//        print("✅ Firebase emulators configured")
//        print("📋 Firestore: 127.0.0.1:8080")
//        print("📋 Storage: 127.0.0.1:9199")
//        print("📋 Auth: Using production Firebase (with mock mode in FirebaseAuthService)")
//    }
}
