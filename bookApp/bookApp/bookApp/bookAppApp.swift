import SwiftUI

@main
struct BookstoreApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
        }
    }
}
