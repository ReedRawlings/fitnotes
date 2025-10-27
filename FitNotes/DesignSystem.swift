import SwiftUI
import UIKit

// MARK: - Design System
// Complete design system for FitNotes app following ExerciseViewUpdate.md specification

// MARK: - Color Palette
extension Color {
    // Background Hierarchy
    static let primaryBg = Color(hex: "#0A0E14")      // Deep charcoal base
    static let secondaryBg = Color(hex: "#151922")    // Elevated surfaces (cards)
    static let tertiaryBg = Color(hex: "#1C2128")     // Input fields, nested cards
    
    // Accent Colors
    static let accentPrimary = Color(hex: "#FF6B35")   // Coral-orange for CTAs
    static let accentSecondary = Color(hex: "#F7931E") // Warm amber for secondary actions
    static let accentSuccess = Color(hex: "#00D9A3")   // Bright teal for save confirmation
    
    // Text Colors
    static let textPrimary = Color(hex: "#FFFFFF")
    static let textSecondary = Color(hex: "#8B92A0")   // Muted blue-gray
    static let textTertiary = Color(hex: "#5A6270")    // Deemphasized text/labels
    static let textInverse = Color(hex: "#0A0E14")     // For text on bright backgrounds
    
    // Interactive States
    static let hoverOverlay = Color.white.opacity(0.08)
    static let activeOverlay = Color.white.opacity(0.12)
    static let disabledOverlay = Color(hex: "#8B92A0").opacity(0.3)
    
    // Error State
    static let errorRed = Color(hex: "#FF4444")
    
    // Helper for hex colors
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    // Exercise Title
    static let exerciseTitle = Font.system(size: 28, weight: .bold, design: .default) // SF Pro Display Bold - Reduced from 36pt
    
    // Section Headers (WEIGHT, REPS, LAST SESSION)
    static let sectionHeader = Font.system(size: 10, weight: .semibold, design: .default) // SF Pro Text Semibold - Reduced from 11pt
    
    // Numeric Data (weights, reps, set values)
    static let dataFont = Font.system(size: 20, weight: .medium, design: .monospaced) // SF Mono Medium - Reduced from 24pt
    
    // Button Text
    static let buttonFont = Font.system(size: 17, weight: .semibold, design: .rounded) // SF Pro Rounded
    
    // Tab Labels
    static let tabFont = Font.system(size: 15, weight: .medium, design: .default) // SF Pro Text Medium
    
    // Body Text
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default) // SF Pro Text Regular
    
    // Last Session Data
    static let lastSessionData = Font.system(size: 16, weight: .medium, design: .monospaced)
    
    // History Set Data
    static let historySetData = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// MARK: - Animation Constants
struct AnimationConstants {
    // Timing
    static let quickFeedback: TimeInterval = 0.2      // Button presses, hover states
    static let contentTransition: TimeInterval = 0.35  // Tab switches, modal presentations
    static let celebration: TimeInterval = 0.5         // Save success animation
    
    // Spring Parameters
    static let standardDamping: CGFloat = 0.7
    static let standardVelocity: CGFloat = 0.3
    
    // Scale Values
    static let buttonPressScale: CGFloat = 0.96       // For primary CTAs
    static let cardPressScale: CGFloat = 0.98         // For tappable cards
    static let deleteScale: CGFloat = 0.9             // For deleting items
    static let tabSelectionScale: CGFloat = 1.02      // For tab selection
}

// MARK: - Animation Extensions
extension Animation {
    static let quickFeedback = Animation.easeInOut(duration: AnimationConstants.quickFeedback)
    static let contentTransition = Animation.easeInOut(duration: AnimationConstants.contentTransition)
    static let celebration = Animation.easeInOut(duration: AnimationConstants.celebration)
    
    static let standardSpring = Animation.spring(
        response: AnimationConstants.contentTransition,
        dampingFraction: AnimationConstants.standardDamping,
        blendDuration: 0
    )
    
    static let buttonPress = Animation.easeInOut(duration: 0.15)
    static let cardPress = Animation.easeInOut(duration: 0.15)
    static let deleteAnimation = Animation.easeInOut(duration: 0.25)
}

// MARK: - Spacing Constants
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 10      // Reduced from 12
    static let lg: CGFloat = 12      // Reduced from 16
    static let xl: CGFloat = 16      // Reduced from 20
    static let xxl: CGFloat = 20     // Reduced from 24
    static let xxxl: CGFloat = 24    // Reduced from 28
    static let xxxxl: CGFloat = 28   // Reduced from 32
}

// MARK: - Corner Radius Constants
struct CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let xl: CGFloat = 14
    static let xxl: CGFloat = 16
    static let xxxl: CGFloat = 20
    static let xxxxl: CGFloat = 24
}

// MARK: - Shadow Constants
struct Shadow {
    static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    static let md = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    static let lg = (color: Color.black.opacity(0.2), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    static let accentPrimary = (color: Color.accentPrimary.opacity(0.3), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(4))
    static let accentSuccess = (color: Color.accentSuccess.opacity(0.4), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(6))
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Color.secondaryBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}
