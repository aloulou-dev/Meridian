//
//  Theme.swift
//  Meridian
//
//  Design system constants for the Meridian app.
//

import SwiftUI

/// Central theme configuration for the Meridian app
enum Theme {
    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 4
        static let xxs: CGFloat = 8
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 32
        static let xl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Typography

    enum Typography {
        /// Title: 34pt bold rounded
        static let title = Font.system(size: 34, weight: .bold, design: .rounded)

        /// Heading: 24pt semibold rounded
        static let heading = Font.system(size: 24, weight: .semibold, design: .rounded)

        /// Subheading: 18pt medium rounded
        static let subheading = Font.system(size: 18, weight: .medium, design: .rounded)

        /// Body: 16pt regular
        static let body = Font.system(size: 16, weight: .regular)

        /// Button: 18pt semibold rounded
        static let button = Font.system(size: 18, weight: .semibold, design: .rounded)

        /// Caption: 14pt regular
        static let caption = Font.system(size: 14, weight: .regular)

        /// Small: 12pt regular
        static let small = Font.system(size: 12, weight: .regular)
    }

    // MARK: - Animation

    enum Animation {
        /// Fast: 0.2s ease-out
        static let fast = SwiftUI.Animation.easeOut(duration: 0.2)

        /// Standard: 0.3s ease-in-out
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)

        /// Slow: 0.5s ease-in-out
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)

        /// Spring: 0.5s response, 0.7 damping
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)

        /// Bouncy spring for star appearance
        static let starAppear = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.6)
    }

    // MARK: - Sizes

    enum Size {
        /// Standard button height
        static let buttonHeight: CGFloat = 56

        /// Star sizes
        static let starSmall: CGFloat = 16
        static let starMedium: CGFloat = 24
        static let starLarge: CGFloat = 32

        /// Glow blur radius
        static let glowRadius: CGFloat = 8

        /// FAB button size
        static let fabSize: CGFloat = 60

        /// Icon sizes
        static let iconSmall: CGFloat = 20
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
    }

    // MARK: - Shadows

    enum Shadow {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let glow = (color: Color.white.opacity(0.3), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(0))
    }

    // MARK: - Validation

    enum Validation {
        /// Minimum words required for locked sessions
        static let minimumWordCount = 5

        /// Maximum content length
        static let maximumContentLength = 50_000

        /// Maximum word length (to prevent abuse)
        static let maximumWordLength = 100

        /// Maximum entries per day
        static let maximumEntriesPerDay = 100

        /// Minimum seconds between entries
        static let minimumEntryInterval: TimeInterval = 1.0
    }
}
