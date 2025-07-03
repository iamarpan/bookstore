// bookAppApp.swift
import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@main
struct BookstoreApp: App {
    // Register app delegate for Firebase and FCM setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
        
        // Configure emulators for local testing
        // Comment out these lines when deploying to production
        #if DEBUG
        configureEmulators()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ThemeManager())
        }
    }
    
    // MARK: - Emulator Configuration
    private func configureEmulators() {
        // Configure Firestore emulator
        let settings = Firestore.firestore().settings
        settings.host = "127.0.0.1:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        // Configure Storage emulator
        Storage.storage().useEmulator(withHost: "127.0.0.1", port: 9199)
        
        // Note: Auth emulator not configured - using production auth for now
        // To use Auth emulator, start with: firebase emulators:start --only auth,firestore,storage,ui
        // Then uncomment: Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
        
        print("🧪 Firebase emulators configured for local testing")
        print("🔥 Firestore: 127.0.0.1:8080")
        print("📁 Storage: 127.0.0.1:9199")
        print("🔐 Auth: Production (not emulated)")
    }
}
