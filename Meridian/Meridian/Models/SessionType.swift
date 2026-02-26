//
//  SessionType.swift
//  Meridian
//
//  Defines the types of journal sessions available in the app.
//

import Foundation

/// Represents the type of journal entry session
enum SessionType: String, Codable, CaseIterable {
    case morning = "morning"
    case night = "night"
    case anytime = "anytime"

    /// The prompt text shown to the user for this session type
    var prompt: String {
        switch self {
        case .morning:
            return "Write 3 goals for today, or reflect on how you're feeling..."
        case .night:
            return "How did it go? Reflect on your day..."
        case .anytime:
            return "What's on your mind?"
        }
    }

    /// The header title for the journal entry screen
    var headerTitle: String {
        switch self {
        case .morning:
            return "Morning"
        case .night:
            return "Night"
        case .anytime:
            return "Journal"
        }
    }

    /// Whether this session type requires a minimum word count to submit
    var requiresMinimumWords: Bool {
        switch self {
        case .morning, .night:
            return true
        case .anytime:
            return false
        }
    }

    /// Whether this session type is associated with app locking
    var triggersLock: Bool {
        switch self {
        case .morning, .night:
            return true
        case .anytime:
            return false
        }
    }

    /// Icon name for this session type
    var iconName: String {
        switch self {
        case .morning:
            return "sun.max.fill"
        case .night:
            return "moon.stars.fill"
        case .anytime:
            return "pencil.and.outline"
        }
    }
}
