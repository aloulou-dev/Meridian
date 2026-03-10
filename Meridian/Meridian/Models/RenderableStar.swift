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
    let normalizedPosition: CGPoint    // 0.0-1.0 in virtual canvas space
    let zDepth: Double                 // 0.0 (far/background) → 1.0 (close/foreground)
    let baseSize: CGFloat              // 12-32pt based on wordCount
    let colorTemperature: Double       // 0.0 (cool) to 1.0 (warm)
    let weekIdentifier: WeekIdentifier
    let entries: [JournalEntry]

    // MARK: - Depth-derived computed vars (continuous, replaces DepthLayer 3-step)

    /// Backward-compat bucket for tap-sort ordering
    var depthLayer: DepthLayer {
        if zDepth < 0.33 { return .background }
        else if zDepth < 0.67 { return .midground }
        else { return .foreground }
    }

    /// Parallax multiplier: far stars barely move (0.3), close stars move fully (1.0)
    var parallaxMultiplier: CGFloat { CGFloat(0.3 + zDepth * 0.7) }

    /// Size multiplier: continuous gradient instead of 3-step
    var sizeMultiplier: CGFloat { CGFloat(0.6 + zDepth * 0.4) }

    /// Opacity multiplier: far stars dimmer, close stars brighter
    var opacityMultiplier: Double { 0.6 + zDepth * 0.4 }

    // MARK: - Derived Properties

    /// Total word count across all entries for this day
    var totalWordCount: Int {
        entries.reduce(0) { $0 + $1.wordCount }
    }

    /// Calculate screen position with parallax offset applied.
    /// normalizedPosition is in virtual canvas space (0.0–1.0 = full virtual canvas).
    func screenPosition(in size: CGSize, parallaxOffset: CGSize) -> CGPoint {
        let virtualWidth  = size.width  * Theme.VirtualCanvas.widthMultiplier
        let virtualHeight = size.height * Theme.VirtualCanvas.heightMultiplier

        // Convert from virtual canvas coords to screen coords
        // Virtual canvas is centered on screen, so subtract half the overflow
        let screenX = normalizedPosition.x * virtualWidth  - (virtualWidth  - size.width)  / 2
        let screenY = normalizedPosition.y * virtualHeight - (virtualHeight - size.height) / 2

        // Apply parallax — close stars drift more, far stars drift less
        return CGPoint(
            x: screenX + parallaxOffset.width  * parallaxMultiplier,
            y: screenY + parallaxOffset.height * parallaxMultiplier
        )
    }

    /// Effective size after applying depth multiplier
    var effectiveSize: CGFloat {
        baseSize * sizeMultiplier
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

        // Continuous z-depth from date (independent of X/Y hash path)
        let zDepth = computeZDepth(for: dayStar.date)

        // Calculate color temperature based on entry types
        let colorTemp = computeColorTemperature(entries: dayStar.entries)

        return RenderableStar(
            id: dayStar.date,
            normalizedPosition: normalizedPos,
            zDepth: zDepth,
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

    /// Deterministic continuous z-depth (0.0–1.0) for a date.
    /// Uses XOR mixing independent of the X/Y hash path to avoid correlation.
    private static func computeZDepth(for date: Date) -> Double {
        var h = date.hashValue
        h ^= h >> 17
        h = h &* 0x45d9f3b
        h ^= h >> 16
        return Double(abs(h) % 1000) / 1000.0
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
