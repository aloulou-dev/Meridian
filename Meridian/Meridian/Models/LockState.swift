//
//  LockState.swift
//  Meridian
//
//  Defines the app lock states for the state machine.
//

import Foundation
import SwiftUI

/// Represents the current lock state of the app
enum LockState: String, Codable {
    case unlocked = "unlocked"
    case morningLocked = "morningLocked"
    case nightSoftLocked = "nightSoftLocked"
    case nightGracePeriod = "nightGracePeriod"
    case nightHardLocked = "nightHardLocked"

    /// Whether apps are currently blocked
    var isLocked: Bool {
        switch self {
        case .unlocked:
            return false
        case .morningLocked, .nightSoftLocked, .nightHardLocked:
            return true
        case .nightGracePeriod:
            return false
        }
    }

    /// The associated session type for this lock state
    var sessionType: SessionType? {
        switch self {
        case .unlocked:
            return nil
        case .morningLocked:
            return .morning
        case .nightSoftLocked, .nightGracePeriod, .nightHardLocked:
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
        case .nightSoftLocked:
            return "Night Session"
        case .nightGracePeriod:
            return "Grace Period"
        case .nightHardLocked:
            return "Sanctuary Mode"
        }
    }

    // MARK: - Cycle Phase Indicator

    var phaseLabel: String {
        switch self {
        case .unlocked:       return "Free Time"
        case .morningLocked:  return "Morning Session"
        case .nightSoftLocked: return "Night Session"
        case .nightGracePeriod: return "Grace Period"
        case .nightHardLocked: return "Sanctuary Mode"
        }
    }

    var phaseIcon: String {
        switch self {
        case .unlocked:        return "checkmark.circle.fill"
        case .morningLocked:   return "sun.max.fill"
        case .nightSoftLocked: return "moon.fill"
        case .nightGracePeriod: return "timer"
        case .nightHardLocked: return "moon.zzz.fill"
        }
    }

    var phaseColor: Color {
        switch self {
        case .unlocked:        return .success
        case .morningLocked:   return .morningStar
        case .nightSoftLocked: return .primaryButton
        case .nightGracePeriod: return .warning
        case .nightHardLocked: return .sanctuary
        }
    }
}
