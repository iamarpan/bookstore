import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        // Default to dark mode, but allow user preference
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }
    
    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}

// Extended AppTheme for light mode colors
extension AppTheme {
    // Light mode colors
    static let lightPrimaryBackground = Color(UIColor.systemBackground)
    static let lightSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let lightCardBackground = Color(UIColor.systemBackground)
    
    static let lightPrimaryText = Color(UIColor.label)
    static let lightSecondaryText = Color(UIColor.secondaryLabel)
    static let lightTertiaryText = Color(UIColor.tertiaryLabel)
    
    static let lightBorderColor = Color(UIColor.separator)
    static let lightSeparatorColor = Color(UIColor.separator)
    
    // Dynamic colors that adapt to theme
    static func dynamicPrimaryBackground(_ isDarkMode: Bool) -> Color {
        isDarkMode ? primaryBackground : lightPrimaryBackground
    }
    
    static func dynamicSecondaryBackground(_ isDarkMode: Bool) -> Color {
        isDarkMode ? secondaryBackground : lightSecondaryBackground
    }
    
    static func dynamicCardBackground(_ isDarkMode: Bool) -> Color {
        isDarkMode ? cardBackground : lightCardBackground
    }
    
    static func dynamicPrimaryText(_ isDarkMode: Bool) -> Color {
        isDarkMode ? primaryText : lightPrimaryText
    }
    
    static func dynamicSecondaryText(_ isDarkMode: Bool) -> Color {
        isDarkMode ? secondaryText : lightSecondaryText
    }
    
    static func dynamicTertiaryText(_ isDarkMode: Bool) -> Color {
        isDarkMode ? tertiaryText : lightTertiaryText
    }
    
    static func dynamicBorderColor(_ isDarkMode: Bool) -> Color {
        isDarkMode ? borderColor : lightBorderColor
    }
    
    static func dynamicSeparatorColor(_ isDarkMode: Bool) -> Color {
        isDarkMode ? separatorColor : lightSeparatorColor
    }
} 