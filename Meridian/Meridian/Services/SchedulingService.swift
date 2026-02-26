//
//  SchedulingService.swift
//  Meridian
//
//  Service for scheduling background tasks for lock triggers.
//

import Foundation
import BackgroundTasks
import UserNotifications

/// Service for scheduling and handling background lock tasks
final class SchedulingService {
    // MARK: - Singleton

    static let shared = SchedulingService()

    // MARK: - Task Identifiers

    static let morningLockTaskIdentifier = "com.meridian.morninglock"
    static let nightLockTaskIdentifier = "com.meridian.nightlock"
    static let graceHardLockTaskIdentifier = "com.meridian.gracehardlock"

    /// Fixed IDs for scheduled notifications (so we can replace them and handle tap)
    static let morningNotificationId = "com.meridian.notification.morning"
    static let nightNotificationId = "com.meridian.notification.night"
    static let graceEndingNotificationId = "com.meridian.notification.graceEnding"

    // MARK: - Properties

    private let settingsService = SettingsService.shared
    private let screenTimeService = ScreenTimeService.shared
    private var lockStateManager: LockStateManager { LockStateManager.shared }

    // MARK: - Initialization

    private init() {}

    // MARK: - Task Scheduling

    /// Schedule all lock tasks based on current settings
    func scheduleAllTasks() {
        // Cancel existing tasks first
        cancelAllTasks()

        // Schedule morning task if enabled
        if settingsService.isMorningEnabled {
            scheduleMorningTask()
        }

        // Always schedule night task
        scheduleNightTask()

        // Schedule local notifications at exact times (deliver even if app isn't running)
        scheduleScheduledNotifications()

        // Use Screen Time's monitor extension for reliable off-app locking.
        screenTimeService.rescheduleNightMonitoring()

        print("All background tasks scheduled")
    }

    /// Schedule the morning lock task
    private func scheduleMorningTask() {
        guard let nextMorningTime = calculateNextMorningTime() else {
            print("Could not calculate next morning time")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.morningLockTaskIdentifier)
        request.earliestBeginDate = nextMorningTime

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Morning task scheduled for: \(nextMorningTime)")
        } catch {
            print("Failed to schedule morning task: \(error)")
        }
    }

    /// Schedule the night lock task
    private func scheduleNightTask() {
        guard let nextNightTime = calculateNextNightTime() else {
            print("Could not calculate next night time")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: Self.nightLockTaskIdentifier)
        request.earliestBeginDate = nextNightTime

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Night task scheduled for: \(nextNightTime)")
        } catch {
            print("Failed to schedule night task: \(error)")
        }
    }

    /// Cancel all scheduled tasks
    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.morningLockTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.nightLockTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.graceHardLockTaskIdentifier)
        print("All background tasks cancelled")
    }

    // MARK: - Time Calculations

    /// Calculate the next morning lock time
    private func calculateNextMorningTime() -> Date? {
        guard settingsService.isMorningEnabled else { return nil }

        let now = Date()
        let calendar = Calendar.current
        let today = DayOfWeek.today

        // Get today's morning time
        guard let morningTime = settingsService.getMorningTime(for: today) else {
            return nil
        }

        // Build today's morning datetime
        let todayMorning = combineDateWithTime(date: now, time: morningTime)

        // If today's morning time hasn't passed, use it
        if todayMorning > now {
            return todayMorning
        }

        // Otherwise, find the next day with morning enabled
        var checkDay = today.next
        var daysChecked = 0

        while daysChecked < 7 {
            if let nextMorningTime = settingsService.getMorningTime(for: checkDay) {
                let nextDate = now.addingDays(daysChecked + 1)
                return combineDateWithTime(date: nextDate, time: nextMorningTime)
            }
            checkDay = checkDay.next
            daysChecked += 1
        }

        return nil
    }

    /// Calculate the next night lock time.
    private func calculateNextNightTime() -> Date? {
        let now = Date()
        let today = DayOfWeek.today

        // Get today's configured night lock time
        let nightLockTime = settingsService.getNightLockTime(for: today)
        let todayNight = combineDateWithTime(date: now, time: nightLockTime)

        // If today's night time hasn't passed, use it
        if todayNight > now {
            return todayNight
        }

        // Otherwise, use tomorrow's night time
        let tomorrow = today.next
        let tomorrowNightLockTime = settingsService.getNightLockTime(for: tomorrow)
        let tomorrowNight = combineDateWithTime(date: now.addingDays(1), time: tomorrowNightLockTime)

        return tomorrowNight
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

    // MARK: - Task Handlers

    /// Handle the morning lock background task (async version for SwiftUI)
    @MainActor
    func handleMorningTask() async {
        lockStateManager.enterMorningLock()
        await sendNotification(
            title: "Time to journal",
            body: "Set your intentions for the day"
        )
        scheduleMorningTask()
        scheduleScheduledNotifications()
    }

    /// Handle the night lock background task (async version for SwiftUI)
    @MainActor
    func handleNightTask() async {
        lockStateManager.enterNightLock()
        await sendNotification(
            title: "Time to reflect",
            body: "How did your day go?"
        )
        scheduleNightTask()
        scheduleScheduledNotifications()
    }

    /// Handle background task (BGTask version)
    func handleBackgroundTask(_ task: BGAppRefreshTask, type: SessionType) {
        // Set up expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Execute the task
        Task { @MainActor in
            switch type {
            case .morning:
                await handleMorningTask()
            case .night:
                await handleNightTask()
            case .anytime:
                break
            }
            task.setTaskCompleted(success: true)
        }
    }

    /// Handle grace expiry background task
    func handleGraceHardLockTask(_ task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        Task { @MainActor in
            lockStateManager.enterNightHardLock()
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Notifications

    /// Request notification authorization (call on app launch / onboarding complete)
    func requestNotificationAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    /// Schedule local notifications for the next morning/night lock times.
    func scheduleScheduledNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.morningNotificationId, Self.nightNotificationId]
        )

        let calendar = Calendar.current

        if settingsService.isMorningEnabled, let nextMorning = calculateNextMorningTime() {
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextMorning)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Time to journal"
            content.body = "Set your intentions for the day"
            content.sound = .default
            let request = UNNotificationRequest(identifier: Self.morningNotificationId, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error { print("Failed to schedule morning notification: \(error)") }
                else { print("Morning notification scheduled for \(nextMorning)") }
            }
        }

        if let nextNight = calculateNextNightTime() {
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextNight)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Time to reflect"
            content.body = "How did your day go?"
            content.sound = .default
            let request = UNNotificationRequest(identifier: Self.nightNotificationId, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error { print("Failed to schedule night notification: \(error)") }
                else { print("Night notification scheduled for \(nextNight)") }
            }
        }
    }

    /// Schedule one-time reminder for grace period ending and hard-lock return
    func scheduleGraceExpiryNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.graceEndingNotificationId])
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Grace period ending"
        content.body = "Sanctuary Mode is returning now."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: Self.graceEndingNotificationId,
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error {
                print("Failed to schedule grace-ending notification: \(error)")
            }
        }
        scheduleGraceHardLockTask(at: date)
    }

    private func scheduleGraceHardLockTask(at date: Date) {
        let request = BGAppRefreshTaskRequest(identifier: Self.graceHardLockTaskIdentifier)
        request.earliestBeginDate = date
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule grace hard-lock task: \(error)")
        }
    }

    /// Send a test notification (fires in ~1 second so it shows even when app is in foreground)
    func sendTestNotification() async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Meridian test"
        content.body = "If you see this, notifications are working."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "com.meridian.test", content: content, trigger: trigger)
        do {
            try await center.add(request)
            print("Test notification scheduled")
        } catch {
            print("Failed to send test notification: \(error)")
        }
    }

    /// Send a local notification (immediate)
    private func sendNotification(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        do {
            try await center.add(request)
            print("Notification sent: \(title)")
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}
