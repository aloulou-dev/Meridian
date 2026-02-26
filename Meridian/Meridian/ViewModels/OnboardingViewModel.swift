//
//  OnboardingViewModel.swift
//  Meridian
//
//  ViewModel for managing onboarding flow state.
//

import Combine
import FamilyControls
import SwiftUI

/// ViewModel for the onboarding flow
final class OnboardingViewModel: ObservableObject {
    // MARK: - Onboarding Steps

    enum Step: Int, CaseIterable {
        case welcome = 0
        case permission = 1
        case appSelection = 2
        case morningConfig = 3
        case nightConfig = 4
        case ready = 5

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .permission: return "Permission"
            case .appSelection: return "Select Apps"
            case .morningConfig: return "Morning Ritual"
            case .nightConfig: return "Evening Wind Down"
            case .ready: return "Ready"
            }
        }

        var stepNumber: Int {
            rawValue + 1
        }

        static var totalSteps: Int {
            allCases.count
        }
    }

    // MARK: - Published Properties

    @Published var currentStep: Step = .welcome
    @Published var isAnimating = false

    // Permission state
    @Published var permissionGranted = false
    @Published var permissionSkipped = false  // Skip Screen Time for testing
    @Published var permissionError: String?

    // App selection
    @Published var blockedAppsSelection = FamilyActivitySelection()

    // Morning configuration
    @Published var isMorningEnabled = true
    @Published var morningTimes: [DayOfWeek: Date] = [:]

    // Night configuration
    @Published var bedtimes: [DayOfWeek: Date] = [:]

    // MARK: - Services

    private let settingsService = SettingsService.shared
    private let screenTimeService = ScreenTimeService.shared
    private let schedulingService = SchedulingService.shared

    // MARK: - Initialization

    init() {
        setupDefaultTimes()
    }

    // MARK: - Setup

    private func setupDefaultTimes() {
        // Set default morning times (8:00 AM for all days)
        for day in DayOfWeek.allCases {
            morningTimes[day] = DayOfWeek.defaultMorningTime
        }

        // Set default bedtimes
        for day in DayOfWeek.allCases {
            bedtimes[day] = day.defaultBedtime
        }
    }

    // MARK: - Navigation

    var canGoBack: Bool {
        currentStep.rawValue > 0
    }

    var canGoNext: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .permission:
            return permissionGranted || permissionSkipped
        case .appSelection:
            return true  // Screen Time optional: allow continuing without selecting apps
        case .morningConfig:
            return true
        case .nightConfig:
            return true
        case .ready:
            return true
        }
    }

    var isLastStep: Bool {
        currentStep == .ready
    }

    var nextButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .permission:
            return permissionGranted ? "Continue" : "Grant Permission"
        case .appSelection:
            return "Continue"
        case .morningConfig:
            return "Continue"
        case .nightConfig:
            return "Continue"
        case .ready:
            return "Start My Journey"
        }
    }

    func goToNextStep() {
        guard canGoNext else { return }

        withAnimation(Theme.Animation.standard) {
            if let nextStep = Step(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
    }

    func goToPreviousStep() {
        guard canGoBack else { return }

        withAnimation(Theme.Animation.standard) {
            if let prevStep = Step(rawValue: currentStep.rawValue - 1) {
                currentStep = prevStep
            }
        }
    }

    func goToStep(_ step: Step) {
        withAnimation(Theme.Animation.standard) {
            currentStep = step
        }
    }

    // MARK: - Permission

    /// Skip Screen Time permission (for testing UI without Family Controls access)
    func skipPermission() {
        permissionSkipped = true
        permissionError = nil
    }

    @MainActor
    func requestPermission() async {
        permissionError = nil
        let granted = await screenTimeService.requestAuthorization()

        if granted {
            permissionGranted = true
        } else {
            permissionError = "Permission was denied. Please enable Screen Time access in Settings."
        }
    }

    // MARK: - App Selection

    var hasSelectedApps: Bool {
        !blockedAppsSelection.applicationTokens.isEmpty ||
        !blockedAppsSelection.categoryTokens.isEmpty
    }

    var selectedAppsCount: Int {
        blockedAppsSelection.applicationTokens.count +
        blockedAppsSelection.categoryTokens.count
    }

    // MARK: - Time Configuration

    func setMorningTime(_ time: Date, for day: DayOfWeek) {
        morningTimes[day] = time
    }

    func getMorningTime(for day: DayOfWeek) -> Date {
        morningTimes[day] ?? DayOfWeek.defaultMorningTime
    }

    func setBedtime(_ time: Date, for day: DayOfWeek) {
        bedtimes[day] = time
    }

    func getBedtime(for day: DayOfWeek) -> Date {
        bedtimes[day] ?? day.defaultBedtime
    }

    /// Set the same morning time for all days
    func setMorningTimeForAllDays(_ time: Date) {
        for day in DayOfWeek.allCases {
            morningTimes[day] = time
        }
    }

    /// Set the same bedtime for all weekdays
    func setBedtimeForWeekdays(_ time: Date) {
        for day in DayOfWeek.allCases where day.isWeekday {
            bedtimes[day] = time
        }
    }

    /// Set the same bedtime for all weekends
    func setBedtimeForWeekends(_ time: Date) {
        for day in DayOfWeek.allCases where day.isWeekend {
            bedtimes[day] = time
        }
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() {
        // Save blocked apps
        screenTimeService.blockedAppsSelection = blockedAppsSelection

        // Save morning settings
        settingsService.isMorningEnabled = isMorningEnabled
        settingsService.saveMorningTimes(morningTimes)

        // Save bedtimes
        settingsService.saveBedtimes(bedtimes)

        // Schedule background tasks
        schedulingService.scheduleAllTasks()
        screenTimeService.rescheduleNightMonitoring()

        // Request notification permission so "Time to journal" can be delivered
        Task {
            _ = await schedulingService.requestNotificationAuthorization()
        }

        // Mark onboarding complete
        settingsService.isOnboardingComplete = true

        print("Onboarding completed successfully")
    }
}
