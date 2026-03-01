//
//  ConstellationLine.swift
//  Meridian
//
//  Line connection between two stars in a constellation.
//

import Foundation

/// Represents a line connecting two stars in the same week
struct ConstellationLine: Identifiable {
    let id: UUID
    let startStarID: Date
    let endStarID: Date
    let weekIdentifier: WeekIdentifier
    let opacity: Double

    init(startStarID: Date, endStarID: Date, weekIdentifier: WeekIdentifier, opacity: Double = 0.15) {
        self.id = UUID()
        self.startStarID = startStarID
        self.endStarID = endStarID
        self.weekIdentifier = weekIdentifier
        self.opacity = opacity
    }
}
