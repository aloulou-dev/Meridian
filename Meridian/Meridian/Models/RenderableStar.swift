//
//  RenderableStar.swift
//  Meridian
//
//  Pre-computed star render data for Canvas-based rendering.
//

import SwiftUI

/// Pre-computed star data optimized for Canvas rendering
struct RenderableStar: Identifiable {
    let id: Date
    let normalizedPosition: CGPoint    // 0.0-1.0 range
    let depthLayer: DepthLayer
    let baseSize: CGFloat              // 12-32pt based on wordCount
    let colorTemperature: Double       // 0.0 (cool) to 1.0 (warm)
    let weekIdentifier: WeekIdentifier
    let entries: [JournalEntry]

    /// Total word count across all entries for this day
    var totalWordCount: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    /// Calculate screen position with parallax offset applied
    func screenPosition(in size: CGSize, parallaxOffset: CGSize) -> CGPoint {
        let parallaxedOffset = CGSize(
            width: parallaxOffset.width * depthLayer.parallaxMultiplier,
            height: parallaxOffset.height * depthLayer.parallaxMultiplier
        )

        return CGPoint(
            x: normalizedPosition.x * size.width + parallaxedOffset.width,
            y: normalizedPosition.y * size.height + parallaxedOffset.height
        )
    }

    /// Effective size after applying depth multiplier
    var effectiveSize: CGFloat {
        baseSize * depthLayer.sizeMultiplier
    }

    /// Whether this star should show diffraction spikes (larger stars only)
    var showsDiffractionSpikes: Bool {
        effectiveSize > 20
    }

    /// Create a RenderableStar from a DayStar
    static func from(dayStar: DayStar) -> RenderableStar {
        let position = dayStar.position
        let normalizedPos = CGPoint(x: position.x, y: position.y)

        // Calculate base size from word count
        let totalWords = dayStar.entries.reduce(0) { $0 + $1.wordCount }
        let baseSize = computeStarSize(wordCount: totalWords)

        // Assign depth layer based on date hash for variety
        let depthLayer = assignDepthLayer(for: dayStar.date)

        // Calculate color temperature based on entry types
        let colorTemp = computeColorTemperature(entries: dayStar.entries)

        return RenderableStar(
            id: dayStar.date,
            normalizedPosition: normalizedPos,
            depthLayer: depthLayer,
            baseSize: baseSize,
            colorTemperature: colorTemp,
            weekIdentifier: WeekIdentifier(from: dayStar.date),
            entries: dayStar.entries
        )
    }

    /// Calculate star size based on word count
    private static func computeStarSize(wordCount: Int) -> CGFloat {
        let base = Theme.Star.minSize
        let wordBonus = CGFloat(wordCount) * Theme.Star.sizeWordCountFactor
        return min(base + wordBonus, Theme.Star.maxSize)
    }

    /// Assign depth layer based on date hash for visual variety
    private static func assignDepthLayer(for date: Date) -> DepthLayer {
        let hash = date.hashValue
        switch abs(hash) % 10 {
        case 0...2: return .background   // 30%
        case 3...5: return .midground    // 30%
        default: return .foreground      // 40%
        }
    }

    /// Calculate color temperature based on entry types
    /// 0.0 = cool (night), 0.5 = neutral (anytime), 1.0 = warm (morning)
    private static func computeColorTemperature(entries: [JournalEntry]) -> Double {
        guard !entries.isEmpty else { return 0.5 }

        var totalWeight: Double = 0
        var weightedTemp: Double = 0

        for entry in entries {
            let weight = Double(entry.wordCount)
            let temp: Double

            switch entry.sessionType {
            case .morning:
                // Warm range: 0.7-1.0
                temp = 0.7 + Double.random(in: 0...0.3)
            case .night:
                // Cool range: 0.0-0.3
                temp = Double.random(in: 0...0.3)
            case .anytime:
                // Neutral range: 0.35-0.65
                temp = 0.35 + Double.random(in: 0...0.3)
            }

            totalWeight += weight
            weightedTemp += temp * weight
        }

        return totalWeight > 0 ? weightedTemp / totalWeight : 0.5
    }
}
