import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        // Check if user has set a preference, otherwise use system default
        if let savedPreference = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            self.isDarkMode = savedPreference
        } else {
            // First launch - use system default
            self.isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            UserDefaults.standard.set(self.isDarkMode, forKey: "isDarkMode")
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