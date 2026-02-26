//
//  MorningEntryMode.swift
//  Meridian
//
//  Defines how users complete morning entries.
//

import Foundation

enum MorningEntryMode: String, Codable, CaseIterable {
    case digital = "digital"
    case physical = "physical"

    var title: String {
        switch self {
        case .digital: return "Digital"
        case .physical: return "Physical"
        }
    }

    var subtitle: String {
        switch self {
        case .digital: return "Type your morning reflection in the app"
        case .physical: return "Write physically, then add a photo or quick text note"
        }
    }
}
