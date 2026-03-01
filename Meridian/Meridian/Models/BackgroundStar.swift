//
//  BackgroundStar.swift
//  Meridian
//
//  Model for decorative background stars in the night sky.
//

import SwiftUI

/// A decorative background star for the galaxy effect
struct BackgroundStar: Identifiable {
    let id: Int
    /// Position in virtual canvas coordinates (absolute points)
    let virtualPosition: CGPoint
    /// Size in points (0.5-2.0)
    let size: CGFloat
    /// Base opacity before twinkle effect (0.2-0.8)
    let baseOpacity: Double
    /// Color temperature: 0.0 (cool blue) to 1.0 (warm peach)
    let colorTemperature: Double
    /// Duration of one twinkle cycle in seconds (2-5)
    let twinkleSpeed: Double
    /// Staggered start offset in seconds (0-2)
    let twinklePhaseOffset: Double
}

// MARK: - Star Field Generation

extension BackgroundStar {
    /// Generate a deterministic star field for the virtual canvas
    /// - Parameters:
    ///   - count: Number of stars to generate
    ///   - canvasSize: Size of the virtual canvas in points
    ///   - seed: Random seed for deterministic generation
    /// - Returns: Array of background stars
    static func generateStarField(
        count: Int = Theme.BackgroundStarField.count,
        canvasSize: CGSize,
        seed: UInt64 = Theme.BackgroundStarField.seed
    ) -> [BackgroundStar] {
        var rng = SeededRandomNumberGenerator(seed: seed)

        return (0..<count).map { i in
            BackgroundStar(
                id: i,
                virtualPosition: CGPoint(
                    x: CGFloat.random(in: 0...canvasSize.width, using: &rng),
                    y: CGFloat.random(in: 0...canvasSize.height, using: &rng)
                ),
                size: CGFloat.random(
                    in: Theme.BackgroundStarField.minSize...Theme.BackgroundStarField.maxSize,
                    using: &rng
                ),
                baseOpacity: Double.random(
                    in: Theme.BackgroundStarField.minOpacity...Theme.BackgroundStarField.maxOpacity,
                    using: &rng
                ),
                colorTemperature: Double.random(in: 0...1, using: &rng),
                twinkleSpeed: Double.random(
                    in: Theme.BackgroundStarField.twinkleMinDuration...Theme.BackgroundStarField.twinkleMaxDuration,
                    using: &rng
                ),
                twinklePhaseOffset: Double.random(
                    in: 0...Theme.BackgroundStarField.twinkleMaxPhaseOffset,
                    using: &rng
                )
            )
        }
    }
}

// MARK: - Seeded Random Number Generator

/// A deterministic random number generator using the LCG algorithm
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // Linear Congruential Generator constants
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
