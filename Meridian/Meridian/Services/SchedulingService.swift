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

    // MARK: - Properties

    private let settingsService = SettingsService.shared
    private let lockStateManager = LockStateManager.shared

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

    /// Calculate the next night lock time (2 hours before bedtime)
    private func calculateNextNightTime() -> Date? {
        let now = Date()
        let today = DayOfWeek.today

        // Get today's night lock time (bedtime - 2 hours)
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
        scheduleMorningTask() // Reschedule for next occurrence
    }

    /// Handle the night lock background task (async version for SwiftUI)
    @MainActor
    func handleNightTask() async {
        lockStateManager.enterNightLock()
        await sendNotification(
            title: "Time to reflect",
            body: "How did your day go?"
        )
        scheduleNightTask() // Reschedule for next occurrence
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

    // MARK: - Notifications

    /// Request notification authorization
    func requestNotificationAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    /// Send a local notification
    private func sendNotification(title: String, body: String) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await center.add(request)
            print("Notification sent: \(title)")
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}
