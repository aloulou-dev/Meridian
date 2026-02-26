//
//  SettingsService.swift
//  Meridian
//
//  UserDefaults wrapper for app settings and preferences.
//

import Foundation
import Combine

/// Service for managing user settings and preferences stored in UserDefaults
final class SettingsService: ObservableObject {
    static let appGroupIdentifier = "group.com.meridian.app"
    // MARK: - Singleton

    static let shared = SettingsService()

    // MARK: - Keys

    private enum Keys {
        static let onboardingComplete = "meridian.onboardingComplete"
        static let morningEnabled = "meridian.morningEnabled"
        static let morningTimes = "meridian.morningTimes"
        static let bedtimes = "meridian.bedtimes"
        static let lockState = "meridian.lockState"
        static let blockedAppsData = "meridian.blockedAppsData"
        static let lastMorningEntryDate = "meridian.lastMorningEntryDate"
        static let lastNightEntryDate = "meridian.lastNightEntryDate"
        static let appVersion = "meridian.appVersion"
        static let entriesCreatedToday = "meridian.entriesCreatedToday"
        static let lastEntryTimestamp = "meridian.lastEntryTimestamp"
        static let entriesCountDate = "meridian.entriesCountDate"
        static let morningEntryMode = "meridian.morningEntryMode"
        static let nightGraceMinutes = "meridian.nightGraceMinutes"
        static let nightGraceEndsAt = "meridian.nightGraceEndsAt"
        static let aiPromptsEnabled = "meridian.aiPromptsEnabled"
        static let aiModelName = "meridian.aiModelName"
    }

    // MARK: - UserDefaults

    private let defaults: UserDefaults

    // MARK: - Published Properties

    @Published var isOnboardingComplete: Bool {
        didSet { defaults.set(isOnboardingComplete, forKey: Keys.onboardingComplete) }
    }

    @Published var isMorningEnabled: Bool {
        didSet { defaults.set(isMorningEnabled, forKey: Keys.morningEnabled) }
    }

    @Published var morningEntryMode: MorningEntryMode {
        didSet { defaults.set(morningEntryMode.rawValue, forKey: Keys.morningEntryMode) }
    }

    @Published var isAIPromptsEnabled: Bool {
        didSet { defaults.set(isAIPromptsEnabled, forKey: Keys.aiPromptsEnabled) }
    }

    @Published var aiModelName: String {
        didSet { defaults.set(aiModelName, forKey: Keys.aiModelName) }
    }

    // MARK: - Initialization

    private init(defaults: UserDefaults = .standard) {
        self.defaults = UserDefaults(suiteName: Self.appGroupIdentifier) ?? defaults

        // Load initial values
        self.isOnboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
        self.isMorningEnabled = defaults.bool(forKey: Keys.morningEnabled)
        self.morningEntryMode = MorningEntryMode(
            rawValue: defaults.string(forKey: Keys.morningEntryMode) ?? MorningEntryMode.digital.rawValue
        ) ?? .digital
        self.isAIPromptsEnabled = defaults.object(forKey: Keys.aiPromptsEnabled) as? Bool ?? true
        self.aiModelName = defaults.string(forKey: Keys.aiModelName) ?? "gpt-4.1-mini"

        // Set default morning enabled to true if not set
        if !defaults.bool(forKey: Keys.morningEnabled) && !defaults.bool(forKey: Keys.onboardingComplete) {
            self.isMorningEnabled = true
        }
    }

    // MARK: - Grace Period

    var nightGraceMinutes: Int {
        get {
            let value = defaults.integer(forKey: Keys.nightGraceMinutes)
            return value > 0 ? value : 15
        }
        set {
            defaults.set(max(1, newValue), forKey: Keys.nightGraceMinutes)
        }
    }

    var nightGraceEndsAt: Date? {
        get { defaults.object(forKey: Keys.nightGraceEndsAt) as? Date }
        set { defaults.set(newValue, forKey: Keys.nightGraceEndsAt) }
    }

    // MARK: - Morning Times

    /// Get the morning time for a specific day
    func getMorningTime(for day: DayOfWeek) -> Date? {
        guard isMorningEnabled else { return nil }

        if let times = getMorningTimes(), let time = times[day] {
            return time
        }
        return DayOfWeek.defaultMorningTime
    }

    /// Get all morning times as a dictionary
    func getMorningTimes() -> [DayOfWeek: Date]? {
        guard let data = defaults.data(forKey: Keys.morningTimes),
              let times = try? JSONDecoder().decode([Int: Date].self, from: data) else {
            return nil
        }

        var result: [DayOfWeek: Date] = [:]
        for (rawValue, date) in times {
            if let day = DayOfWeek(rawValue: rawValue) {
                result[day] = date
            }
        }
        return result
    }

    /// Set the morning time for a specific day
    func setMorningTime(_ time: Date, for day: DayOfWeek) {
        var times = getMorningTimes() ?? [:]
        times[day] = time
        saveMorningTimes(times)
    }

    /// Set all morning times at once
    func saveMorningTimes(_ times: [DayOfWeek: Date]) {
        let intTimes = Dictionary(uniqueKeysWithValues: times.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(intTimes) {
            defaults.set(data, forKey: Keys.morningTimes)
        }
    }

    // MARK: - Bedtimes

    /// Get the bedtime for a specific day
    func getBedtime(for day: DayOfWeek) -> Date {
        if let times = getBedtimes() {
            return times[day] ?? day.defaultBedtime
        }
        return day.defaultBedtime
    }

    /// Get the night lock time for a specific day.
    /// The configured "bedtime" is treated as the exact lock/session time.
    func getNightLockTime(for day: DayOfWeek) -> Date {
        getBedtime(for: day)
    }

    /// Get all bedtimes as a dictionary
    func getBedtimes() -> [DayOfWeek: Date]? {
        guard let data = defaults.data(forKey: Keys.bedtimes),
              let times = try? JSONDecoder().decode([Int: Date].self, from: data) else {
            return nil
        }

        var result: [DayOfWeek: Date] = [:]
        for (rawValue, date) in times {
            if let day = DayOfWeek(rawValue: rawValue) {
                result[day] = date
            }
        }
        return result
    }

    /// Set the bedtime for a specific day
    func setBedtime(_ time: Date, for day: DayOfWeek) {
        var times = getBedtimes() ?? [:]
        times[day] = time
        saveBedtimes(times)
    }

    /// Set all bedtimes at once
    func saveBedtimes(_ times: [DayOfWeek: Date]) {
        let intTimes = Dictionary(uniqueKeysWithValues: times.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(intTimes) {
            defaults.set(data, forKey: Keys.bedtimes)
        }
    }

    // MARK: - Lock State

    /// Get the current lock state
    var lockState: LockState {
        get {
            guard let rawValue = defaults.string(forKey: Keys.lockState),
                  let state = LockState(rawValue: rawValue) else {
                return .unlocked
            }
            return state
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.lockState)
        }
    }

    // MARK: - Entry Tracking

    /// Get the last morning entry date
    var lastMorningEntryDate: Date? {
        get { defaults.object(forKey: Keys.lastMorningEntryDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastMorningEntryDate) }
    }

    /// Get the last night entry date
    var lastNightEntryDate: Date? {
        get { defaults.object(forKey: Keys.lastNightEntryDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastNightEntryDate) }
    }

    /// Record that an entry was created for the current session
    func recordEntryCreated(for sessionType: SessionType) {
        let now = Date()
        switch sessionType {
        case .morning:
            lastMorningEntryDate = now
        case .night:
            lastNightEntryDate = now
        case .anytime:
            break
        }
    }

    // MARK: - Rate Limiting

    /// Get today's entry count
    private var todaysEntryCount: Int {
        // Reset counter if it's a new day
        if let countDate = defaults.object(forKey: Keys.entriesCountDate) as? Date,
           !Calendar.current.isDateInToday(countDate) {
            defaults.set(0, forKey: Keys.entriesCreatedToday)
            defaults.set(Date(), forKey: Keys.entriesCountDate)
            return 0
        }
        return defaults.integer(forKey: Keys.entriesCreatedToday)
    }

    /// Check if we can create a new entry (rate limiting)
    func canCreateEntry() -> Bool {
        // Check daily limit
        if todaysEntryCount >= Theme.Validation.maximumEntriesPerDay {
            return false
        }

        // Check minimum interval
        if let lastTimestamp = defaults.object(forKey: Keys.lastEntryTimestamp) as? Date {
            let elapsed = Date().timeIntervalSince(lastTimestamp)
            if elapsed < Theme.Validation.minimumEntryInterval {
                return false
            }
        }

        return true
    }

    /// Record that an entry was just created
    func recordEntryCreation() {
        // Update count
        let today = Date()
        if let countDate = defaults.object(forKey: Keys.entriesCountDate) as? Date,
           !Calendar.current.isDateInToday(countDate) {
            defaults.set(1, forKey: Keys.entriesCreatedToday)
        } else {
            defaults.set(todaysEntryCount + 1, forKey: Keys.entriesCreatedToday)
        }
        defaults.set(today, forKey: Keys.entriesCountDate)
        defaults.set(today, forKey: Keys.lastEntryTimestamp)
    }

    // MARK: - Blocked Apps Data

    /// Get raw blocked apps data (FamilyActivitySelection encoded)
    var blockedAppsData: Data? {
        get { defaults.data(forKey: Keys.blockedAppsData) }
        set { defaults.set(newValue, forKey: Keys.blockedAppsData) }
    }

    // MARK: - App Version

    /// Get/set the app version for migration tracking
    var appVersion: String? {
        get { defaults.string(forKey: Keys.appVersion) }
        set { defaults.set(newValue, forKey: Keys.appVersion) }
    }

    // MARK: - Reset

    /// Reset all settings to defaults
    func resetAllSettings() {
        let allKeys = [
            Keys.onboardingComplete,
            Keys.morningEnabled,
            Keys.morningTimes,
            Keys.bedtimes,
            Keys.lockState,
            Keys.blockedAppsData,
            Keys.lastMorningEntryDate,
            Keys.lastNightEntryDate,
            Keys.appVersion,
            Keys.entriesCreatedToday,
            Keys.lastEntryTimestamp,
            Keys.entriesCountDate,
            Keys.morningEntryMode,
            Keys.nightGraceMinutes,
            Keys.nightGraceEndsAt,
            Keys.aiPromptsEnabled,
            Keys.aiModelName
        ]

        for key in allKeys {
            defaults.removeObject(forKey: key)
        }

        // Reset published properties
        isOnboardingComplete = false
        isMorningEnabled = true
        morningEntryMode = .digital
        isAIPromptsEnabled = true
        aiModelName = "gpt-4.1-mini"
    }

    // MARK: - Default Times Setup

    /// Set up default times for all days
    func setupDefaultTimes() {
        // Set default morning times (8:00 AM for all days)
        var morningTimes: [DayOfWeek: Date] = [:]
        for day in DayOfWeek.allCases {
            morningTimes[day] = DayOfWeek.defaultMorningTime
        }
        saveMorningTimes(morningTimes)

        // Set default bedtimes (10 PM weekdays, 11 PM weekends)
        var bedtimes: [DayOfWeek: Date] = [:]
        for day in DayOfWeek.allCases {
            bedtimes[day] = day.defaultBedtime
        }
        saveBedtimes(bedtimes)
    }
}
