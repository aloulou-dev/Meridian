//
//  DayOfWeek.swift
//  Meridian
//
//  Represents days of the week for scheduling.
//

import Foundation

/// Represents a day of the week for session scheduling
enum DayOfWeek: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    /// Short display name (e.g., "Mon")
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    /// Full display name (e.g., "Monday")
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    /// Single letter abbreviation (e.g., "M")
    var letter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    /// Whether this is a weekday (Mon-Fri)
    var isWeekday: Bool {
        switch self {
        case .monday, .tuesday, .wednesday, .thursday, .friday:
            return true
        case .saturday, .sunday:
            return false
        }
    }

    /// Whether this is a weekend day (Sat-Sun)
    var isWeekend: Bool {
        !isWeekday
    }

    /// Creates a DayOfWeek from a Calendar weekday component (1 = Sunday)
    static func fromWeekday(_ weekday: Int) -> DayOfWeek? {
        DayOfWeek(rawValue: weekday)
    }

    /// Gets the DayOfWeek for today
    static var today: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return DayOfWeek(rawValue: weekday) ?? .sunday
    }

    /// Gets the next day after this one
    var next: DayOfWeek {
        let nextRawValue = (rawValue % 7) + 1
        return DayOfWeek(rawValue: nextRawValue) ?? .sunday
    }

    /// Gets the previous day before this one
    var previous: DayOfWeek {
        let prevRawValue = rawValue == 1 ? 7 : rawValue - 1
        return DayOfWeek(rawValue: prevRawValue) ?? .sunday
    }

    /// Days from this day to the target day (0-6)
    func daysUntil(_ target: DayOfWeek) -> Int {
        let diff = target.rawValue - self.rawValue
        return diff >= 0 ? diff : diff + 7
    }
}

// MARK: - Default Times

extension DayOfWeek {
    /// Default morning time (8:00 AM) for all days
    static let defaultMorningTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    /// Default bedtime (10:00 PM for weekdays, 11:00 PM for weekends)
    var defaultBedtime: Date {
        var components = DateComponents()
        if isWeekday {
            components.hour = 22
            components.minute = 0
        } else {
            components.hour = 23
            components.minute = 0
        }
        return Calendar.current.date(from: components) ?? Date()
    }
}
