//
//  Color+Theme.swift
//  Meridian
//
//  Color extensions for the Meridian design system.
//

import SwiftUI

extension Color {
    // MARK: - Initializer

    /// Initialize a Color from a hex string (e.g., "#FF5733" or "FF5733")
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
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Night Sky Colors

    /// Deep blue-black for top of night sky gradient
    static let skyTop = Color(hex: "#0A0E27")

    /// Medium blue for middle of night sky gradient
    static let skyMiddle = Color(hex: "#1B2838")

    /// Blue-gray for bottom of night sky gradient
    static let skyBottom = Color(hex: "#2D3E50")

    // MARK: - Star Colors

    /// Sunrise orange for morning stars
    static let morningStar = Color(hex: "#FFB347")

    /// Orange glow for morning star effect
    static let morningGlow = Color(hex: "#FFA500")

    /// Cool white for night/anytime stars
    static let nightStar = Color(hex: "#E8F4F8")

    /// Light blue glow for night star effect
    static let nightGlow = Color(hex: "#B0E0E6")

    /// Warm gold for star shine
    static let starGold = Color(hex: "#FFD700")

    /// Cyan accent for star highlights
    static let starCyan = Color(hex: "#A5F3FC")

    // MARK: - UI Colors

    /// Primary button blue
    static let primaryButton = Color(hex: "#4A90E2")

    /// Primary button hover/pressed state
    static let primaryButtonPressed = Color(hex: "#3A7BC8")

    /// Disabled button gray
    static let disabledButton = Color(hex: "#4A5568")

    /// Card background
    static let cardBackground = Color(hex: "#1A202C")

    /// Surface dark (for panels, modals)
    static let surfaceDark = Color(hex: "#161525")

    /// Background dark (alternate)
    static let backgroundDark = Color(hex: "#0B0A16")

    // MARK: - Text Colors

    /// Primary text (white)
    static let textPrimary = Color.white

    /// Secondary text (light gray)
    static let textSecondary = Color(hex: "#A0AEC0")

    /// Muted text
    static let textMuted = Color(hex: "#718096")

    // MARK: - Feedback Colors

    /// Error red
    static let error = Color(hex: "#FC8181")

    /// Success green
    static let success = Color(hex: "#68D391")

    /// Warning amber
    static let warning = Color(hex: "#F6AD55")

    // MARK: - Gradients

    /// Night sky gradient
    static var nightSkyGradient: LinearGradient {
        LinearGradient(
            colors: [.skyTop, .skyMiddle, .skyBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Morning star glow gradient (radial)
    static var morningGlowGradient: RadialGradient {
        RadialGradient(
            colors: [.morningGlow.opacity(0.8), .morningGlow.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: 20
        )
    }

    /// Night star glow gradient (radial)
    static var nightGlowGradient: RadialGradient {
        RadialGradient(
            colors: [.nightGlow.opacity(0.6), .nightGlow.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: 16
        )
    }
}
