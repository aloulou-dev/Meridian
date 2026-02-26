//
//  ScreenTimeService.swift
//  Meridian
//
//  Service for managing app blocking via iOS FamilyControls/ScreenTime API.
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Service for managing app blocking using iOS ScreenTime API
final class ScreenTimeService: ObservableObject {
    // MARK: - Singleton

    static let shared = ScreenTimeService()

    // MARK: - Properties

    /// The authorization center for FamilyControls
    private let authorizationCenter = AuthorizationCenter.shared

    /// The managed settings store for applying shields
    private let store = ManagedSettingsStore()

    /// Published authorization status
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    /// Published blocked apps selection
    @Published var blockedAppsSelection = FamilyActivitySelection() {
        didSet {
            saveBlockedAppsSelection()
        }
    }

    // MARK: - Initialization

    private init() {
        loadBlockedAppsSelection()
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Request authorization for FamilyControls
    /// - Returns: True if authorization was granted
    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            updateAuthorizationStatus()
            return authorizationStatus == .approved
        } catch {
            print("FamilyControls authorization failed: \(error)")
            updateAuthorizationStatus()
            return false
        }
    }

    /// Check if FamilyControls is authorized
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    /// Update the current authorization status
    private func updateAuthorizationStatus() {
        authorizationStatus = authorizationCenter.authorizationStatus
    }

    // MARK: - Blocked Apps Management

    /// Save the blocked apps selection to UserDefaults
    private func saveBlockedAppsSelection() {
        do {
            let data = try PropertyListEncoder().encode(blockedAppsSelection)
            SettingsService.shared.blockedAppsData = data
        } catch {
            print("Error saving blocked apps selection: \(error)")
        }
    }

    /// Load the blocked apps selection from UserDefaults
    private func loadBlockedAppsSelection() {
        guard let data = SettingsService.shared.blockedAppsData else { return }

        do {
            blockedAppsSelection = try PropertyListDecoder().decode(
                FamilyActivitySelection.self,
                from: data
            )
        } catch {
            print("Error loading blocked apps selection: \(error)")
        }
    }

    /// Check if any apps are selected for blocking
    var hasBlockedApps: Bool {
        !blockedAppsSelection.applicationTokens.isEmpty ||
        !blockedAppsSelection.categoryTokens.isEmpty ||
        !blockedAppsSelection.webDomainTokens.isEmpty
    }

    /// Get the count of blocked items
    var blockedItemsCount: Int {
        blockedAppsSelection.applicationTokens.count +
        blockedAppsSelection.categoryTokens.count +
        blockedAppsSelection.webDomainTokens.count
    }

    // MARK: - App Blocking

    /// Lock the selected apps by applying shields
    func lockApps() {
        guard isAuthorized, hasBlockedApps else {
            print("Cannot lock apps: not authorized or no apps selected")
            return
        }

        // Apply shields to selected applications
        store.shield.applications = blockedAppsSelection.applicationTokens

        // Apply shields to selected categories
        store.shield.applicationCategories = .specific(blockedAppsSelection.categoryTokens)

        // Apply shields to web domains
        store.shield.webDomains = blockedAppsSelection.webDomainTokens

        print("Apps locked: \(blockedItemsCount) items")
    }

    /// Unlock all apps by clearing shields
    func unlockApps() {
        // Clear all shields
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        print("Apps unlocked")
    }

    /// Check if apps are currently locked
    var areAppsLocked: Bool {
        store.shield.applications != nil ||
        store.shield.applicationCategories != nil ||
        store.shield.webDomains != nil
    }

    // MARK: - Reset

    /// Clear all blocked apps selection
    func clearBlockedApps() {
        blockedAppsSelection = FamilyActivitySelection()
        unlockApps()
    }

    /// Reset all ScreenTime settings
    func reset() {
        clearBlockedApps()
        SettingsService.shared.blockedAppsData = nil
    }
}

// MARK: - Authorization Status Extension

extension AuthorizationStatus {
    /// Human-readable description of the status
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }
}
