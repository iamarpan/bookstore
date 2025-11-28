import SwiftUI

struct AppTheme {
    // MARK: - 1. Color Palette (Warm & Paper-Like)
    
    // Backgrounds
    static let primaryBackground = Color(hex: "F9F7F2") // Warm Alabaster
    static let cardBackground = Color(hex: "FFFFFF") // Pure White
    static let glassBackground = Color.white.opacity(0.85) // Glassmorphism
    
    // Text
    static let primaryText = Color(hex: "1A1A1A") // Soft Black
    static let secondaryText = Color(hex: "585858") // Dark Grey
    static let tertiaryText = Color(hex: "8A8A8A") // Medium Grey
    
    // Brand & Actions
    static let primaryAccent = Color(hex: "C2410C") // Burnt Orange/Terracotta
    static let secondaryAccent = Color(hex: "334155") // Slate Blue
    
    // Status Colors (Pastel/Soft)
    static let successColor = Color(hex: "059669") // Emerald
    static let successBg = Color(hex: "ECFDF5") // Light Emerald
    static let warningColor = Color(hex: "D97706") // Amber
    static let errorColor = Color(hex: "DC2626") // Rose
    static let separatorColor = Color(hex: "E5E5EA") // Light Gray
    
    // MARK: - 2. Typography
    // Using system fonts for now, but styled to match the spec.
    // Ideally we would load custom fonts like Libre Baskerville.
    
    static func headerFont(size: CGFloat = 24) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
    
    static func bodyFont(size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    // MARK: - 3. Surfaces & Depth
    
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 100 // Pill shape
    static let inputRadius: CGFloat = 16
    
    static let shadowCard = Color.black.opacity(0.08)
    static let shadowFloating = Color.black.opacity(0.1)
    
    // MARK: - Dynamic Colors (Adapting to Dark Mode if needed, but prioritizing the Warm Theme)
    
    static func colorPrimaryBackground(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: "1C1C1E") : primaryBackground
    }
    
    static func colorCardBackground(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: "2C2C2E") : cardBackground
    }
    
    static func colorPrimaryText(for isDarkMode: Bool) -> Color {
        isDarkMode ? .white : primaryText
    }
    
    static func colorSecondaryText(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: "AEAEB2") : secondaryText
    }
    
    static func colorTertiaryText(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: "636366") : tertiaryText
    }
    
    static func colorSecondaryBackground(for isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: "2C2C2E") : Color(hex: "F2F2F7")
    }
    
    static func dynamicBorderColor(for isDarkMode: Bool) -> Color {
        isDarkMode ? separatorColor : Color(hex: "E5E5EA")
    }
    
    static func dynamicSeparatorColor(for isDarkMode: Bool) -> Color {
        isDarkMode ? separatorColor : Color(hex: "E5E5EA")
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
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
            .font(AppTheme.bodyFont(size: 17, weight: .semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isEnabled ? 
                (configuration.isPressed ? AppTheme.primaryAccent.opacity(0.9) : AppTheme.primaryAccent) :
                AppTheme.tertiaryText
            )
            .cornerRadius(AppTheme.buttonRadius)
            .shadow(color: AppTheme.primaryAccent.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppTheme.primaryAccent)
            .font(AppTheme.bodyFont(size: 17, weight: .medium))
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primaryAccent.opacity(0.1))
            .cornerRadius(AppTheme.buttonRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AppCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.cardBackground)
            .cornerRadius(AppTheme.cardRadius)
            .shadow(color: AppTheme.shadowCard, radius: 20, x: 0, y: 10)
    }
}

struct GlassmorphicStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(AppTheme.cardRadius)
    }
}

extension View {
    func appCardStyle() -> some View {
        modifier(AppCardStyle())
    }
    
    func glassmorphic() -> some View {
        modifier(GlassmorphicStyle())
    }
}