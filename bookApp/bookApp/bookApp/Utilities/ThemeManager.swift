import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        // 1. Try to load from UserDefaults
        if let savedPreference = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            self.isDarkMode = savedPreference
        } else {
            // 2. Fallback: Default to light mode (safer for startup)
            // TraitCollection access during init can be unreliable/crashy on some iOS versions
            self.isDarkMode = false
            UserDefaults.standard.set(false, forKey: "isDarkMode")
        }
    }
    
    /// Computed property to provide the color scheme based on the app's dark mode setting
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}