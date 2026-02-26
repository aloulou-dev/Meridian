//
//  SettingsViewModel.swift
//  Meridian
//
//  ViewModel for the settings screen.
//

import SwiftUI
import FamilyControls
import Combine

/// ViewModel for the settings screen
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    // Blocked apps
    @Published var blockedAppsSelection = FamilyActivitySelection()
    @Published var showAppPicker = false

    // Morning session
    @Published var isMorningEnabled: Bool {
        didSet {
            settingsService.isMorningEnabled = isMorningEnabled
            rescheduleTasksIfNeeded()
        }
    }

    @Published var morningTimes: [DayOfWeek: Date] = [:]

    // Night session
    @Published var bedtimes: [DayOfWeek: Date] = [:]
    @Published var nightGraceMinutes: Int {
        didSet {
            settingsService.nightGraceMinutes = max(1, nightGraceMinutes)
        }
    }

    // MARK: - Services

    private let settingsService = SettingsService.shared
    private let screenTimeService = ScreenTimeService.shared
    private let schedulingService = SchedulingService.shared
    private let lockStateManager = LockStateManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var blockedAppsCount: Int {
        blockedAppsSelection.applicationTokens.count +
        blockedAppsSelection.categoryTokens.count
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Totem Properties

    /// Whether a totem has been configured
    var hasTotemConfigured: Bool {
        settingsService.hasTotemConfigured
    }

    /// Whether totem scanning is enabled
    var isTotemEnabled: Bool {
        settingsService.isTotemEnabled
    }

    /// Status text for totem section
    var totemStatusText: String {
        if hasTotemConfigured {
            return "Active"
        } else {
            return "Not configured"
        }
    }

    /// Clear the registered totem
    func clearTotem() {
        settingsService.clearTotem()
        objectWillChange.send()
    }

    // MARK: - Initialization

    init() {
        self.isMorningEnabled = settingsService.isMorningEnabled
        self.nightGraceMinutes = settingsService.nightGraceMinutes
        loadSettings()
        observeScreenTimeChanges()
    }

    // MARK: - Load Settings

    private func loadSettings() {
        // Load blocked apps
        blockedAppsSelection = screenTimeService.blockedAppsSelection

        // Load morning times
        if let times = settingsService.getMorningTimes() {
            morningTimes = times
        } else {
            for day in DayOfWeek.allCases {
                morningTimes[day] = DayOfWeek.defaultMorningTime
            }
        }

        // Load bedtimes
        if let times = settingsService.getBedtimes() {
            bedtimes = times
        } else {
            for day in DayOfWeek.allCases {
                bedtimes[day] = day.defaultBedtime
            }
        }
    }

    // MARK: - Observe Changes

    private func observeScreenTimeChanges() {
        screenTimeService.$blockedAppsSelection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection in
                self?.blockedAppsSelection = selection
            }
            .store(in: &cancellables)
    }

    // MARK: - Time Setters

    func setMorningTime(_ time: Date, for day: DayOfWeek) {
        morningTimes[day] = time
        settingsService.setMorningTime(time, for: day)
        rescheduleTasksIfNeeded()
    }

    func getMorningTime(for day: DayOfWeek) -> Date {
        morningTimes[day] ?? DayOfWeek.defaultMorningTime
    }

    func setBedtime(_ time: Date, for day: DayOfWeek) {
        bedtimes[day] = time
        settingsService.setBedtime(time, for: day)
        rescheduleTasksIfNeeded()
    }

    func getBedtime(for day: DayOfWeek) -> Date {
        bedtimes[day] ?? day.defaultBedtime
    }

    // MARK: - Blocked Apps

    func saveBlockedApps() {
        screenTimeService.blockedAppsSelection = blockedAppsSelection
        screenTimeService.rescheduleNightMonitoring()
    }

    // MARK: - Scheduling

    private func rescheduleTasksIfNeeded() {
        schedulingService.scheduleAllTasks()
        if !lockStateManager.isLocked {
            lockStateManager.startForegroundTimer()
        }
    }

    // MARK: - Notifications

    @Published var isSendingTestNotification = false

    func sendTestNotification() {
        isSendingTestNotification = true
        Task {
            await schedulingService.sendTestNotification()
            await MainActor.run { isSendingTestNotification = false }
        }
    }

    // MARK: - Demo Controls

    func triggerMorningLockNow() {
        lockStateManager.enterMorningLock()
    }

    func triggerNightSoftLockNow() {
        lockStateManager.enterNightSoftLock()
    }

    func triggerGraceNow() {
        lockStateManager.beginNightGracePeriod()
    }

    func triggerHardLockNow() {
        lockStateManager.enterNightHardLock()
    }

    // MARK: - App Blocking Test Controls

    @Published var blockingStatusMessage: String?

    var areAppsBlocked: Bool {
        screenTimeService.areAppsLocked
    }

    var isScreenTimeAuthorized: Bool {
        screenTimeService.isAuthorized
    }

    var hasAppsSelected: Bool {
        screenTimeService.hasBlockedApps
    }

    func blockAppsNow() {
        if !screenTimeService.isAuthorized {
            blockingStatusMessage = "Screen Time not authorized. Grant permission in Blocked Apps section first."
            return
        }
        if !screenTimeService.hasBlockedApps {
            blockingStatusMessage = "No apps selected. Select apps to block first."
            return
        }
        screenTimeService.lockApps()
        blockingStatusMessage = "Apps blocked successfully!"
        objectWillChange.send()
    }

    func unblockAppsNow() {
        screenTimeService.unlockApps()
        blockingStatusMessage = "Apps unblocked."
        objectWillChange.send()
    }

    // MARK: - Reset

    func resetAllSettings() {
        settingsService.resetAllSettings()
        screenTimeService.reset()
        loadSettings()
        rescheduleTasksIfNeeded()
    }
}
