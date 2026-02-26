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
    private let schedulingService = SchedulingService.shared
    private var cancellables = Set<AnyCancellable>()
    private var gracePeriodTask: Task<Void, Never>?
    private var foregroundLockTask: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        loadState()
    }

    // MARK: - State Loading

    /// Load the persisted lock state
    private func loadState() {
        currentState = settingsService.lockState
        restoreGracePeriodIfNeeded()
        syncScreenTimeState()
        if !currentState.isLocked {
            startForegroundTimer()
        }
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

    private func restoreGracePeriodIfNeeded() {
        guard currentState == .nightGracePeriod else { return }
        guard let endsAt = settingsService.nightGraceEndsAt else {
            currentState = .nightHardLocked
            saveState()
            return
        }
        if Date() >= endsAt {
            enterNightHardLock()
        } else {
            scheduleGracePeriodHardLock(endsAt: endsAt)
        }
    }

    // MARK: - State Transitions

    /// Enter morning lock state
    func enterMorningLock() {
        stopForegroundTimer()

        guard settingsService.isMorningEnabled else {
            print("Morning session is disabled, skipping lock")
            return
        }

        // When no blocked apps (e.g. Screen Time skipped), still enter lock state so the
        // journal UI is shown; we just won't apply any app shields.
        if screenTimeService.hasBlockedApps {
            screenTimeService.lockApps()
        }

        // Check for forfeited night entry if transitioning from night lock
        if currentState == .nightSoftLocked || currentState == .nightHardLocked {
            handleForfeitedEntry(for: .night)
        }

        currentState = .morningLocked
        saveState()

        print("Entered morning lock state")
    }

    /// Enter night soft-lock state (2h before bedtime)
    func enterNightSoftLock() {
        stopForegroundTimer()

        // When no blocked apps, still enter lock state so the journal UI is shown
        if screenTimeService.hasBlockedApps {
            screenTimeService.lockApps()
        }

        // Check for forfeited morning entry if transitioning from morning lock
        if currentState == .morningLocked {
            handleForfeitedEntry(for: .morning)
        }

        currentState = .nightSoftLocked
        settingsService.nightGraceEndsAt = nil
        saveState()

        print("Entered night soft-lock state")
    }

    /// Backward-compatible night lock entry point
    func enterNightLock() {
        enterNightSoftLock()
    }

    /// Enter hard lock (Sanctuary mode) after grace period expires
    func enterNightHardLock() {
        gracePeriodTask?.cancel()
        gracePeriodTask = nil
        settingsService.nightGraceEndsAt = nil
        currentState = .nightHardLocked
        saveState()
        if screenTimeService.hasBlockedApps {
            screenTimeService.lockApps()
        }
        print("Entered night hard-lock (Sanctuary mode)")
    }

    /// Start grace period after successful night reflection
    func beginNightGracePeriod() {
        let graceSeconds = TimeInterval(settingsService.nightGraceMinutes * 60)
        let endsAt = Date().addingTimeInterval(graceSeconds)
        settingsService.nightGraceEndsAt = endsAt
        currentState = .nightGracePeriod
        saveState()
        screenTimeService.unlockApps()
        scheduleGracePeriodHardLock(endsAt: endsAt)
        schedulingService.scheduleGraceExpiryNotification(at: endsAt)
        print("Night grace period started, ends at \(endsAt)")
    }

    private func scheduleGracePeriodHardLock(endsAt: Date) {
        gracePeriodTask?.cancel()
        gracePeriodTask = Task { [weak self] in
            let remaining = endsAt.timeIntervalSinceNow
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                if self.currentState == .nightGracePeriod {
                    self.enterNightHardLock()
                }
            }
        }
    }

    // MARK: - Foreground Timer

    /// Start a foreground timer that triggers locks at scheduled times.
    /// Critical for simulator testing where BGTasks don't work.
    func startForegroundTimer() {
        foregroundLockTask?.cancel()

        guard !currentState.isLocked else { return }
        guard let (sessionType, targetDate) = nextScheduledLockTime() else { return }

        let remaining = targetDate.timeIntervalSinceNow
        guard remaining > 0 else {
            // Time already passed, trigger immediately
            triggerScheduledLock(for: sessionType)
            return
        }

        print("Foreground timer scheduled for \(sessionType.rawValue) in \(Int(remaining))s")

        foregroundLockTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.triggerScheduledLock(for: sessionType)
            }
        }
    }

    private func triggerScheduledLock(for sessionType: SessionType) {
        guard !currentState.isLocked else { return }
        switch sessionType {
        case .morning: enterMorningLock()
        case .night: enterNightSoftLock()
        case .anytime: break
        }
        // Reschedule for next event
        startForegroundTimer()
    }

    func stopForegroundTimer() {
        foregroundLockTask?.cancel()
        foregroundLockTask = nil
    }

    /// Open app to morning or night prompt when user taps the notification (bypasses time/enabled checks)
    func openToPromptFromNotification(sessionType: SessionType) {
        switch sessionType {
        case .morning:
            currentState = .morningLocked
        case .night:
            currentState = .nightSoftLocked
        case .anytime:
            return
        }
        settingsService.nightGraceEndsAt = nil
        saveState()
        if screenTimeService.hasBlockedApps {
            screenTimeService.lockApps()
        }
    }

    /// Unlock apps after successful journal entry
    func unlockApps() {
        let previousState = currentState
        if previousState == .nightSoftLocked || previousState == .nightHardLocked {
            beginNightGracePeriod()
        } else {
            currentState = .unlocked
            saveState()
            screenTimeService.unlockApps()
        }

        // Record successful completion
        if let sessionType = previousState.sessionType {
            settingsService.recordEntryCreated(for: sessionType)
        }

        startForegroundTimer()
        print("Apps unlocked from \(previousState.displayName)")
    }

    /// Force unlock without recording entry (for testing/admin)
    func forceUnlock() {
        gracePeriodTask?.cancel()
        gracePeriodTask = nil
        settingsService.nightGraceEndsAt = nil
        currentState = .unlocked
        saveState()
        screenTimeService.unlockApps()
        startForegroundTimer()
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

        case .nightSoftLocked, .nightHardLocked:
            // If we're in the day window (after morning time, before night lock), show morning journal
            let nightLockTime = settingsService.getNightLockTime(for: today)
            if settingsService.isMorningEnabled,
               let morningTime = settingsService.getMorningTime(for: today),
               now.isAfter(timeOf: morningTime) && now.isBefore(timeOf: nightLockTime) {
                handleForfeitedEntry(for: .night)
                enterMorningLock()
            } else if !settingsService.isMorningEnabled {
                // Check if we're past morning (forfeit and unlock)
                let defaultMorningTime = Date.today(hour: 8)
                if now.isAfter(timeOf: defaultMorningTime) {
                    handleForfeitedEntry(for: .night)
                    forceUnlock()
                }
            }

        case .nightGracePeriod:
            if let endsAt = settingsService.nightGraceEndsAt, now >= endsAt {
                enterNightHardLock()
            }
        }
    }

    /// Check if the app should currently be in a locked state
    private func checkIfShouldBeLocked(now: Date, today: DayOfWeek) {
        let nightLockTime = settingsService.getNightLockTime(for: today)

        // Check morning lock first when we're in the "day" window (after morning time, before night lock).
        // This ensures we show morning journal during the day, not night.
        if settingsService.isMorningEnabled,
           let morningTime = settingsService.getMorningTime(for: today),
           now.isAfter(timeOf: morningTime) && now.isBefore(timeOf: nightLockTime) {
            if settingsService.lastMorningEntryDate == nil ||
               !Calendar.current.isDateInToday(settingsService.lastMorningEntryDate!) {
                enterMorningLock()
                return
            }
        }

        // Check night lock when we're in the night window (past night lock time)
        if now.isAfter(timeOf: nightLockTime) {
            if settingsService.lastNightEntryDate == nil ||
               !Calendar.current.isDateInToday(settingsService.lastNightEntryDate!) {
                enterNightLock()
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
