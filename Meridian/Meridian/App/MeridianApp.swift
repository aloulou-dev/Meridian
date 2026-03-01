//
//  MeridianApp.swift
//  Meridian
//
//  Main entry point for the Meridian iOS app.
//  A habit-building app combining app blocking with journaling.
//

import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct MeridianApp: App {
    @StateObject private var lockStateManager = LockStateManager.shared
    @StateObject private var settingsService = SettingsService.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        registerBackgroundTasks()
#if DEBUG
        CoreDataService.shared.seedSampleEntries()
        Task {
            await AIQuestionServiceSelfTest.runIfNeeded()
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(lockStateManager)
                .environmentObject(settingsService)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        lockStateManager.checkForExpiredLocks()
                        if !lockStateManager.isLocked {
                            lockStateManager.startForegroundTimer()
                        }
                    }
                }
        }
        .backgroundTask(.appRefresh(SchedulingService.morningLockTaskIdentifier)) {
            await SchedulingService.shared.handleMorningTask()
        }
        .backgroundTask(.appRefresh(SchedulingService.nightLockTaskIdentifier)) {
            await SchedulingService.shared.handleNightTask()
        }
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SchedulingService.morningLockTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            SchedulingService.shared.handleBackgroundTask(refreshTask, type: .morning)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SchedulingService.nightLockTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            SchedulingService.shared.handleBackgroundTask(refreshTask, type: .night)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: SchedulingService.graceHardLockTaskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            SchedulingService.shared.handleGraceHardLockTask(refreshTask)
        }
    }
}

// MARK: - Root View

/// Root view that handles navigation based on app state
struct RootView: View {
    @EnvironmentObject var lockStateManager: LockStateManager
    @EnvironmentObject var settingsService: SettingsService
    @State private var hasRequestedNotificationPermission = false

    var body: some View {
        Group {
            if !settingsService.isOnboardingComplete {
                OnboardingContainerView()
            } else if !settingsService.hasSeenTryJournalPrompt {
                TryJournalPromptView()
            } else if lockStateManager.currentState.isLocked {
                JournalEntryView(sessionType: lockStateManager.currentSessionType)
            } else {
                NightSkyView()
            }
        }
        .onAppear {
            lockStateManager.checkForExpiredLocks()
            requestNotificationPermissionIfNeeded()
        }
    }

    /// Request notification permission once when main app is shown (e.g. existing users who never got the prompt)
    private func requestNotificationPermissionIfNeeded() {
        guard settingsService.isOnboardingComplete, !hasRequestedNotificationPermission else { return }
        hasRequestedNotificationPermission = true
        Task {
            _ = await SchedulingService.shared.requestNotificationAuthorization()
        }
    }
}
