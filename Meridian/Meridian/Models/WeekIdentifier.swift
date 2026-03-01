//
//  WeekIdentifier.swift
//  Meridian
//
//  Week grouping key for constellation line connections.
//

import Foundation

/// Identifies a specific week for grouping stars into constellations
struct WeekIdentifier: Hashable {
    let weekOfYear: Int
    let year: Int

    /// Create a WeekIdentifier from a date
    init(from date: Date) {
        let calendar = Calendar.current
        self.weekOfYear = calendar.component(.weekOfYear, from: date)
        self.year = calendar.component(.yearForWeekOfYear, from: date)
    }

    /// Create a WeekIdentifier with explicit values
    init(weekOfYear: Int, year: Int) {
        self.weekOfYear = weekOfYear
        self.year = year
    }
}
