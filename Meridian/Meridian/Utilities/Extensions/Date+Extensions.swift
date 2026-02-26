//
//  Date+Extensions.swift
//  Meridian
//
//  Date extensions for formatting and manipulation.
//

import Foundation

extension Date {
    // MARK: - Formatting

    /// Format as "Oct 24"
    var shortMonthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    /// Format as "October 24, 2024"
    var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    /// Format as "Oct 24 • Morning" or "Oct 24 • Night"
    func formattedWithSession(_ sessionType: SessionType) -> String {
        "\(shortMonthDay) • \(sessionType.headerTitle)"
    }

    /// Format time as "8:00 AM"
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }

    /// Format as relative time ("2 hours ago", "Yesterday")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    // MARK: - Calendar Helpers

    /// Start of the current day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of the current day (11:59:59 PM)
    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }

    /// Start of tomorrow
    var startOfTomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? self
    }

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Get the day of week
    var dayOfWeek: DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: self)
        return DayOfWeek(rawValue: weekday) ?? .sunday
    }

    /// Get just the time components (hour and minute) as a new date
    var timeOnly: Date {
        let components = Calendar.current.dateComponents([.hour, .minute], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    // MARK: - Time Manipulation

    /// Create a date with specific hour and minute on the current day
    static func today(hour: Int, minute: Int = 0) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Get the next occurrence of a specific time (today if not passed, tomorrow if passed)
    func nextOccurrence(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let targetTime = calendar.date(from: components) else { return self }

        if targetTime > self {
            return targetTime
        } else {
            return calendar.date(byAdding: .day, value: 1, to: targetTime) ?? targetTime
        }
    }

    /// Subtract hours from this date
    func subtractingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: -hours, to: self) ?? self
    }

    /// Add hours to this date
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// Add days to this date
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Deterministic star position (0.1...0.9) for one-star-per-day night sky
    static func starPositionForDay(_ date: Date) -> (x: Double, y: Double) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let seed = Int(start.timeIntervalSince1970)
        let seed1 = abs(seed)
        let seed2 = abs(seed &* 31)
        let x = 0.1 + (Double(seed1 % 1000) / 1000.0) * 0.8
        let y = 0.1 + (Double(seed2 % 1000) / 1000.0) * 0.8
        return (x, y)
    }

    // MARK: - Comparison

    /// Check if this date is before the given date on the same day
    func isBefore(timeOf other: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.hour, .minute], from: self)
        let otherComponents = calendar.dateComponents([.hour, .minute], from: other)

        let selfMinutes = (selfComponents.hour ?? 0) * 60 + (selfComponents.minute ?? 0)
        let otherMinutes = (otherComponents.hour ?? 0) * 60 + (otherComponents.minute ?? 0)

        return selfMinutes < otherMinutes
    }

    /// Check if this date is after the given date on the same day
    func isAfter(timeOf other: Date) -> Bool {
        let calendar = Calendar.current
        let selfComponents = calendar.dateComponents([.hour, .minute], from: self)
        let otherComponents = calendar.dateComponents([.hour, .minute], from: other)

        let selfMinutes = (selfComponents.hour ?? 0) * 60 + (selfComponents.minute ?? 0)
        let otherMinutes = (otherComponents.hour ?? 0) * 60 + (otherComponents.minute ?? 0)

        return selfMinutes > otherMinutes
    }
}

// MARK: - Date Range

extension ClosedRange where Bound == Date {
    /// Check if a date falls within this range
    func contains(date: Date) -> Bool {
        date >= lowerBound && date <= upperBound
    }
}
