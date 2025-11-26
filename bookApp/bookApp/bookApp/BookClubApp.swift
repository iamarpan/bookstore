// BookClubApp.swift
import SwiftUI

@main
struct BookClubApp: App {
    // Register app delegate for APNs setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        print("🚀 BookShare app starting up...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ThemeManager())
        }
    }
}
