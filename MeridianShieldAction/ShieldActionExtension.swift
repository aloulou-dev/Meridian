//
//  ShieldActionExtension.swift
//  MeridianShieldAction
//
//  Handles button taps on the shield and sends notifications.
//

import ManagedSettingsUI
import UserNotifications

/// Extension that handles user interactions with the shield
class ShieldActionExtension: ShieldActionDelegate {

    // MARK: - Shield Action Handling

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldAction(action: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldAction(action: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldAction(action: action, completionHandler: completionHandler)
    }

    // MARK: - Shared Action Handler

    private func handleShieldAction(action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Send notification to prompt user to open Meridian
            sendJournalNotification()
            // Defer to let notification appear, then close shield
            completionHandler(.defer)

        case .secondaryButtonPressed:
            // No secondary button configured, but handle gracefully
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    // MARK: - Notification

    private func sendJournalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = "Tap to open Meridian and complete your reflection"
        content.sound = .default

        // Add category for potential actions
        content.categoryIdentifier = "SHIELD_PROMPT"

        let request = UNNotificationRequest(
            identifier: "shield-prompt-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate delivery
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send shield notification: \(error.localizedDescription)")
            }
        }
    }
}
