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

    // MARK: - Star Color Spectrum

    /// Cool blue-white for night entries
    static let starSpectrumCool = Color(hex: "#B8D4E8")

    /// Neutral cream for anytime entries
    static let starSpectrumNeutral = Color(hex: "#F5F5DC")

    /// Warm orange for morning entries
    static let starSpectrumWarm = Color(hex: "#FFB347")

    /// Calculate star color based on temperature (0.0 = cool, 0.5 = neutral, 1.0 = warm)
    static func starColor(temperature: Double) -> Color {
        let clampedTemp = max(0, min(1, temperature))

        if clampedTemp < 0.5 {
            // Interpolate between cool and neutral
            let t = clampedTemp * 2
            return interpolate(from: starSpectrumCool, to: starSpectrumNeutral, t: t)
        } else {
            // Interpolate between neutral and warm
            let t = (clampedTemp - 0.5) * 2
            return interpolate(from: starSpectrumNeutral, to: starSpectrumWarm, t: t)
        }
    }

    /// Linear interpolation between two colors
    static func interpolate(from: Color, to: Color, t: Double) -> Color {
        // Convert to RGB components
        let fromComponents = from.rgbComponents
        let toComponents = to.rgbComponents

        let r = fromComponents.red + (toComponents.red - fromComponents.red) * t
        let g = fromComponents.green + (toComponents.green - fromComponents.green) * t
        let b = fromComponents.blue + (toComponents.blue - fromComponents.blue) * t

        return Color(red: r, green: g, blue: b)
    }

    /// RGB components of a color
    var rgbComponents: (red: Double, green: Double, blue: Double) {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
        #else
        return (0.5, 0.5, 0.5)
        #endif
    }

    // MARK: - Background Star Colors

    /// Cool blue-white for background stars
    static let bgStarCoolBlue = Color(hex: "#AAD4FF")

    /// Warm peach for background stars
    static let bgStarWarmPeach = Color(hex: "#FFE4B5")

    /// Calculate background star color based on temperature
    /// - Parameter temperature: 0.0 = cool blue, 0.5 = white, 1.0 = warm peach
    static func backgroundStarColor(temperature: Double) -> Color {
        let clampedTemp = max(0, min(1, temperature))

        if clampedTemp < 0.5 {
            // Interpolate between cool blue and white
            let t = clampedTemp * 2
            return interpolate(from: bgStarCoolBlue, to: .white, t: t)
        } else {
            // Interpolate between white and warm peach
            let t = (clampedTemp - 0.5) * 2
            return interpolate(from: .white, to: bgStarWarmPeach, t: t)
        }
    }

    // MARK: - Nebula Colors

    /// Deep blue for nebula clouds
    static let nebulaBlue = Color(hex: "#1E3A5F")

    /// Deep purple for nebula clouds
    static let nebulaPurple = Color(hex: "#2D1B4E")

    /// Deep rose for nebula clouds
    static let nebulaRose = Color(hex: "#4A1C40")

    /// Deep teal for nebula clouds
    static let nebulaTeal = Color(hex: "#1A3A4A")

    /// Deep indigo for nebula clouds
    static let nebulaIndigo = Color(hex: "#252050")

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

    /// Sanctuary purple (hard lock / sleep mode)
    static let sanctuary = Color(hex: "#9F7AEA")

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
