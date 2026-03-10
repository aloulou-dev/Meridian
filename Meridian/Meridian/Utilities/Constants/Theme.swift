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

    // MARK: - Star Rendering

    enum Star {
        /// Minimum star size in points
        static let minSize: CGFloat = 12

        /// Maximum star size in points
        static let maxSize: CGFloat = 32

        /// Size increase per word (capped at maxSize)
        static let sizeWordCountFactor: CGFloat = 0.15

        /// Number of glow layers for star rendering
        static let glowLayers: Int = 4

        /// Minimum hit target size for accessibility (44pt recommended)
        static let minHitTargetSize: CGFloat = 44

        /// Twinkle animation duration range
        static let twinkleDurationMin: Double = 2.0
        static let twinkleDurationMax: Double = 4.0

        /// Glow layer configurations (radius multiplier, opacity, blur)
        static let outerHaloRadiusMultiplier: CGFloat = 3.0
        static let outerHaloOpacity: Double = 0.1
        static let outerHaloBlur: CGFloat = 20

        static let midGlowRadiusMultiplier: CGFloat = 2.0
        static let midGlowOpacity: Double = 0.2
        static let midGlowBlur: CGFloat = 12

        static let innerGlowRadiusMultiplier: CGFloat = 1.3
        static let innerGlowOpacity: Double = 0.4
        static let innerGlowBlur: CGFloat = 6

        static let coreRadiusMultiplier: CGFloat = 0.4
        static let coreOpacity: Double = 0.9

        /// Diffraction spike settings
        static let diffractionSpikeThreshold: CGFloat = 20
        static let diffractionSpikeLengthMultiplier: CGFloat = 1.5
        static let diffractionSpikeWidth: CGFloat = 1.5
        static let diffractionSpikeOpacity: Double = 0.6
    }

    // MARK: - Constellation

    enum Constellation {
        /// Line width for constellation connections
        static let lineWidth: CGFloat = 0.5

        /// Line opacity (faint connections)
        static let lineOpacity: Double = 0.15

        /// Dash pattern for constellation lines
        static let lineDashPattern: [CGFloat] = [4, 8]

        /// Minimum stars in a week to form constellation
        static let minimumStarsForConstellation: Int = 2
    }

    // MARK: - Nebula

    enum Nebula {
        /// Number of nebula clouds in background
        static let cloudCount: Int = 4

        /// Blur radius for nebula effect
        static let blurRadius: CGFloat = 60

        /// Base opacity for nebula clouds
        static let opacity: Double = 0.08

        /// Parallax multiplier for nebula layer (barely moves)
        static let parallaxMultiplier: CGFloat = 0.15
    }

    // MARK: - Virtual Canvas

    enum VirtualCanvas {
        /// Width multiplier relative to screen width
        static let widthMultiplier: CGFloat = 1.5

        /// Height multiplier relative to screen height
        static let heightMultiplier: CGFloat = 3.0
    }

    // MARK: - Background Star Field

    enum BackgroundStarField {
        /// Number of decorative background stars
        static let count: Int = 150

        /// Minimum star size in points
        static let minSize: CGFloat = 0.5

        /// Maximum star size in points
        static let maxSize: CGFloat = 2.0

        /// Minimum opacity for background stars
        static let minOpacity: Double = 0.2

        /// Maximum opacity for background stars
        static let maxOpacity: Double = 0.8

        /// Parallax multiplier (moves slower than journal stars)
        static let parallaxMultiplier: CGFloat = 0.3

        /// Minimum twinkle animation duration
        static let twinkleMinDuration: Double = 2.0

        /// Maximum twinkle animation duration
        static let twinkleMaxDuration: Double = 5.0

        /// Maximum twinkle phase offset for staggered start
        static let twinkleMaxPhaseOffset: Double = 2.0

        /// Seed for deterministic star field generation
        static let seed: UInt64 = 12345
    }

    // MARK: - Parallax

    enum Parallax {
        /// Maximum drag offset in any direction
        static let maxOffset: CGFloat = 150

        /// Deceleration rate for momentum
        static let decelerationRate: CGFloat = 0.95

        /// Minimum velocity to trigger momentum
        static let minimumVelocity: CGFloat = 50
    }

    // MARK: - Zoom

    enum Zoom {
        /// Minimum zoom scale (zoomed out)
        static let minScale: CGFloat = 0.5

        /// Maximum zoom scale (zoomed in)
        static let maxScale: CGFloat = 3.0

        /// Default zoom scale
        static let defaultScale: CGFloat = 1.0

        /// Animation duration for zoom reset
        static let resetAnimationDuration: Double = 0.3

        /// Double-tap zoom scale
        static let doubleTapScale: CGFloat = 2.0
    }

    // MARK: - Fly Forward

    enum FlyForward {
        /// Duration of the fly-forward animation in seconds
        static let duration: Double = 1.75

        /// How far stars expand outward from the focal point
        static let maxExpansionFactor: CGFloat = 2.5

        /// Stars within this screen-point radius of the focal point fade out (they "pass" the camera)
        static let focalFadeRadius: CGFloat = 80

        /// Background decorative stars grow by this multiplier during the animation
        static let bgStarGrowthFactor: CGFloat = 3.0
    }

    // MARK: - Scene 3D

    enum Scene3D {
        // World space volume for journal stars (centered at origin)
        static let journalXSpread: Float = 1000   // -500 to +500
        static let journalYSpread: Float = 800    // -400 to +400
        static let journalZNear: Float  = -100    // closest journal star to camera
        static let journalZFar: Float   = -1100   // furthest journal star from camera

        // Background star sphere radius (surrounds the entire journal star volume)
        static let bgStarRadius: Float = 1400

        // Camera
        static let cameraStartZ: Float  = 600
        static let cameraFOV: Double    = 60       // degrees
        static let driftSpeed: Float    = 6.0      // world units per second
        static let driftResetThreshold: Float = -500  // Z position that triggers soft-reset

        // Journal star geometry (world units)
        static let journalStarMinRadius: Float = 1.5
        static let journalStarMaxRadius: Float = 4.0

        // Background star geometry
        static let bgStarMinRadius: Float = 0.3
        static let bgStarMaxRadius: Float = 1.2

        // Glow layers per journal star (2 layers: outer haze + inner bloom)
        static let glowRadiusMultipliers: [Float] = [8.0, 3.0]
        static let glowOpacities: [Float]          = [0.10, 0.40]

        // Point light per journal star
        static let starLightIntensity: CGFloat = 800

        // Constellation lines
        static let lineRadius: Float = 0.15       // SCNCylinder radius
        static let lineOpacity: Float = 0.12

        // Navigation feel
        static let orbitSensitivity: Float = 0.003      // radians per screen point
        static let pitchClamp: Float = 1.1              // max radians up/down (~63°)
        static let dollyUnitsPerPinchUnit: Float = 300
        static let interactionResumeDelay: Double = 3.0 // seconds before drift resumes

        // Zoom bounds — cumulative dolly relative to spawn position
        static let dollyMin: Float = -200   // can pull back 200 units (zoom out)
        static let dollyMax: Float =  300   // can push forward 300 units (zoom in)
    }
}
