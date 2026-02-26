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

    // MARK: - Services

    private let settingsService = SettingsService.shared
    private let screenTimeService = ScreenTimeService.shared
    private let schedulingService = SchedulingService.shared
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

    // MARK: - Initialization

    init() {
        self.isMorningEnabled = settingsService.isMorningEnabled
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
    }

    // MARK: - Scheduling

    private func rescheduleTasksIfNeeded() {
        schedulingService.scheduleAllTasks()
    }

    // MARK: - Reset

    func resetAllSettings() {
        settingsService.resetAllSettings()
        screenTimeService.reset()
        loadSettings()
    }
}
