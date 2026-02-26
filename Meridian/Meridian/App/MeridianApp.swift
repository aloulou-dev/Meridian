//
//  MeridianApp.swift
//  Meridian
//
//  Main entry point for the Meridian iOS app.
//  A habit-building app combining app blocking with journaling.
//

import SwiftUI
import BackgroundTasks

@main
struct MeridianApp: App {
    @StateObject private var lockStateManager = LockStateManager.shared
    @StateObject private var settingsService = SettingsService.shared

    init() {
        // Register background tasks for morning and night lock triggers
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(lockStateManager)
                .environmentObject(settingsService)
                .preferredColorScheme(.dark)
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
    }
}

// MARK: - Root View

/// Root view that handles navigation based on app state
struct RootView: View {
    @EnvironmentObject var lockStateManager: LockStateManager
    @EnvironmentObject var settingsService: SettingsService

    var body: some View {
        Group {
            if !settingsService.isOnboardingComplete {
                OnboardingContainerView()
            } else if lockStateManager.currentState != .unlocked {
                JournalEntryView(sessionType: lockStateManager.currentSessionType)
            } else {
                NightSkyView()
            }
        }
        .onAppear {
            lockStateManager.checkForExpiredLocks()
        }
    }
}
