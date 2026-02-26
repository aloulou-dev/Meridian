//
//  LockStateManager.swift
//  Meridian
//
//  Central state machine for managing app lock states.
//

import Foundation
import Combine

/// Manages the app lock state machine and coordinates with ScreenTimeService
final class LockStateManager: ObservableObject {
    // MARK: - Singleton

    static let shared = LockStateManager()

    // MARK: - Published Properties

    /// The current lock state
    @Published private(set) var currentState: LockState = .unlocked

    /// Whether the app is currently in a locked state
    var isLocked: Bool {
        currentState != .unlocked
    }

    /// The current session type based on lock state
    var currentSessionType: SessionType {
        currentState.sessionType ?? .anytime
    }

    // MARK: - Private Properties

    private let settingsService = SettingsService.shared
    private let screenTimeService = ScreenTimeService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        loadState()
    }

    // MARK: - State Loading

    /// Load the persisted lock state
    private func loadState() {
        currentState = settingsService.lockState
        syncScreenTimeState()
    }

    /// Save the current state to UserDefaults
    private func saveState() {
        settingsService.lockState = currentState
    }

    /// Sync ScreenTimeService with current state
    private func syncScreenTimeState() {
        if currentState.isLocked {
            screenTimeService.lockApps()
        } else {
            screenTimeService.unlockApps()
        }
    }

    // MARK: - State Transitions

    /// Enter morning lock state
    func enterMorningLock() {
        guard settingsService.isMorningEnabled else {
            print("Morning session is disabled, skipping lock")
            return
        }

        guard screenTimeService.hasBlockedApps else {
            print("No blocked apps configured, skipping lock")
            return
        }

        // Check for forfeited night entry if transitioning from night lock
        if currentState == .nightLocked {
            handleForfeitedEntry(for: .night)
        }

        currentState = .morningLocked
        saveState()
        screenTimeService.lockApps()

        print("Entered morning lock state")
    }

    /// Enter night lock state
    func enterNightLock() {
        guard screenTimeService.hasBlockedApps else {
            print("No blocked apps configured, skipping lock")
            return
        }

        // Check for forfeited morning entry if transitioning from morning lock
        if currentState == .morningLocked {
            handleForfeitedEntry(for: .morning)
        }

        currentState = .nightLocked
        saveState()
        screenTimeService.lockApps()

        print("Entered night lock state")
    }

    /// Unlock apps after successful journal entry
    func unlockApps() {
        let previousState = currentState

        currentState = .unlocked
        saveState()
        screenTimeService.unlockApps()

        // Record successful completion
        if let sessionType = previousState.sessionType {
            settingsService.recordEntryCreated(for: sessionType)
        }

        print("Apps unlocked from \(previousState.displayName)")
    }

    /// Force unlock without recording entry (for testing/admin)
    func forceUnlock() {
        currentState = .unlocked
        saveState()
        screenTimeService.unlockApps()
        print("Force unlocked apps")
    }

    // MARK: - Forfeit Logic

    /// Handle a forfeited entry (session not completed in time)
    private func handleForfeitedEntry(for sessionType: SessionType) {
        print("Forfeited \(sessionType.rawValue) entry - no star will be created")
        // The entry is simply not created, so no star appears
        // Future: Could track forfeited entries for analytics
    }

    /// Check for expired locks on app launch
    func checkForExpiredLocks() {
        let now = Date()
        let today = DayOfWeek.today

        switch currentState {
        case .unlocked:
            // Check if we should be locked
            checkIfShouldBeLocked(now: now, today: today)

        case .morningLocked:
            // Check if night time has arrived (forfeit morning, enter night)
            let nightLockTime = settingsService.getNightLockTime(for: today)
            if now.isAfter(timeOf: nightLockTime) {
                handleForfeitedEntry(for: .morning)
                enterNightLock()
            }

        case .nightLocked:
            // Check if morning time has arrived (forfeit night, maybe enter morning)
            if settingsService.isMorningEnabled {
                if let morningTime = settingsService.getMorningTime(for: today),
                   now.isAfter(timeOf: morningTime) {
                    handleForfeitedEntry(for: .night)
                    enterMorningLock()
                }
            } else {
                // Check if we're past morning (forfeit and unlock)
                let defaultMorningTime = Date.today(hour: 8)
                if now.isAfter(timeOf: defaultMorningTime) {
                    handleForfeitedEntry(for: .night)
                    forceUnlock()
                }
            }
        }
    }

    /// Check if the app should currently be in a locked state
    private func checkIfShouldBeLocked(now: Date, today: DayOfWeek) {
        let nightLockTime = settingsService.getNightLockTime(for: today)

        // Check night lock first (takes precedence)
        if now.isAfter(timeOf: nightLockTime) {
            // We're past night lock time, should be night locked
            // But only if we haven't already completed tonight's entry
            if settingsService.lastNightEntryDate == nil ||
               !Calendar.current.isDateInToday(settingsService.lastNightEntryDate!) {
                enterNightLock()
                return
            }
        }

        // Check morning lock
        if settingsService.isMorningEnabled,
           let morningTime = settingsService.getMorningTime(for: today),
           now.isAfter(timeOf: morningTime) && now.isBefore(timeOf: nightLockTime) {
            // We're past morning time but before night time
            // Should be morning locked if we haven't completed today's entry
            if settingsService.lastMorningEntryDate == nil ||
               !Calendar.current.isDateInToday(settingsService.lastMorningEntryDate!) {
                enterMorningLock()
            }
        }
    }

    // MARK: - Scheduling Helpers

    /// Get the next scheduled lock time
    func nextScheduledLockTime() -> (type: SessionType, date: Date)? {
        let now = Date()
        let today = DayOfWeek.today

        var nextEvents: [(SessionType, Date)] = []

        // Calculate next morning lock time
        if settingsService.isMorningEnabled {
            if let morningTime = settingsService.getMorningTime(for: today) {
                let todayMorning = combineDateWithTime(date: now, time: morningTime)
                if todayMorning > now {
                    nextEvents.append((.morning, todayMorning))
                } else {
                    // Try tomorrow
                    let tomorrow = today.next
                    if let tomorrowMorningTime = settingsService.getMorningTime(for: tomorrow) {
                        let tomorrowMorning = combineDateWithTime(
                            date: now.addingDays(1),
                            time: tomorrowMorningTime
                        )
                        nextEvents.append((.morning, tomorrowMorning))
                    }
                }
            }
        }

        // Calculate next night lock time
        let nightLockTime = settingsService.getNightLockTime(for: today)
        let todayNight = combineDateWithTime(date: now, time: nightLockTime)
        if todayNight > now {
            nextEvents.append((.night, todayNight))
        } else {
            // Try tomorrow
            let tomorrow = today.next
            let tomorrowNightLockTime = settingsService.getNightLockTime(for: tomorrow)
            let tomorrowNight = combineDateWithTime(
                date: now.addingDays(1),
                time: tomorrowNightLockTime
            )
            nextEvents.append((.night, tomorrowNight))
        }

        // Return the soonest event
        return nextEvents.min(by: { $0.1 < $1.1 })
    }

    /// Combine a date with a time (taking hour/minute from time)
    private func combineDateWithTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = 0

        return calendar.date(from: combined) ?? date
    }
}
