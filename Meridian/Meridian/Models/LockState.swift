//
//  LockState.swift
//  Meridian
//
//  Defines the app lock states for the state machine.
//

import Foundation

/// Represents the current lock state of the app
enum LockState: String, Codable {
    case unlocked = "unlocked"
    case morningLocked = "morningLocked"
    case nightLocked = "nightLocked"

    /// Whether apps are currently blocked
    var isLocked: Bool {
        switch self {
        case .unlocked:
            return false
        case .morningLocked, .nightLocked:
            return true
        }
    }

    /// The associated session type for this lock state
    var sessionType: SessionType? {
        switch self {
        case .unlocked:
            return nil
        case .morningLocked:
            return .morning
        case .nightLocked:
            return .night
        }
    }

    /// Display name for this lock state
    var displayName: String {
        switch self {
        case .unlocked:
            return "Unlocked"
        case .morningLocked:
            return "Morning Session"
        case .nightLocked:
            return "Night Session"
        }
    }
}
