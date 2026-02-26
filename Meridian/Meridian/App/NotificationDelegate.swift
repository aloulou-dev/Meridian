//
//  NotificationDelegate.swift
//  Meridian
//
//  Handles notification presentation in foreground and tap-to-open morning/night prompt.
//

import UIKit
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is in foreground (e.g. test notification)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        DispatchQueue.main.async {
            if id == SchedulingService.morningNotificationId {
                LockStateManager.shared.openToPromptFromNotification(sessionType: .morning)
            } else if id == SchedulingService.nightNotificationId {
                LockStateManager.shared.openToPromptFromNotification(sessionType: .night)
            }
        }
        completionHandler()
    }
}
