//
//  DeviceActivityMonitorExtension.swift
//  MeridianSheildAction
//
//  Applies app shields when scheduled night intervals begin.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let appGroupDefaults = UserDefaults(suiteName: "group.com.meridian.app")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity.rawValue.hasPrefix("night-lock-") else { return }
        lockSelectedApps()
    }

    private func lockSelectedApps() {
        guard
            let data = appGroupDefaults?.data(forKey: "meridian.blockedAppsData"),
            let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return
        }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }
}
