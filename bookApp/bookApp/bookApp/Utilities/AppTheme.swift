import SwiftUI

struct AppTheme {
    // MARK: - Colors
    
    // Background Colors
    static let primaryBackground = Color(red: 0.11, green: 0.11, blue: 0.12) // Dark gray
    static let secondaryBackground = Color(red: 0.15, green: 0.15, blue: 0.16) // Slightly lighter
    static let cardBackground = Color(red: 0.18, green: 0.18, blue: 0.19) // Card background
    
    // Green Accent Colors
    static let primaryGreen = Color(red: 0.2, green: 0.8, blue: 0.4) // Bright green
    static let secondaryGreen = Color(red: 0.15, green: 0.6, blue: 0.3) // Darker green
    static let lightGreen = Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1) // Light green background
    
    // Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    // Status Colors
    static let successColor = primaryGreen
    static let warningColor = Color.orange
    static let errorColor = Color.red
    
    // Border and Separator Colors
    static let borderColor = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let separatorColor = Color(red: 0.25, green: 0.25, blue: 0.25)
}

// MARK: - Custom Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ? 
                (configuration.isPressed ? AppTheme.secondaryGreen : AppTheme.primaryGreen) :
                AppTheme.tertiaryText
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppTheme.primaryGreen)
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.lightGreen)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primaryGreen, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AppCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardStyle())
    }
} 