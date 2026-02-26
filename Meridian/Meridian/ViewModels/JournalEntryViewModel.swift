//
//  JournalEntryViewModel.swift
//  Meridian
//
//  ViewModel for the journal entry screen.
//

import SwiftUI
import Combine

/// ViewModel for journal entry creation
final class JournalEntryViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var entryText: String = ""
    @Published var morningEntry: JournalEntry?
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    // MARK: - Properties

    let sessionType: SessionType
    private let coreDataService = CoreDataService.shared
    private let lockStateManager = LockStateManager.shared
    private let settingsService = SettingsService.shared

    // MARK: - Computed Properties

    /// Current word count
    var wordCount: Int {
        let words = entryText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .filter { !$0.isEmpty }
        return words.count
    }

    /// Whether the current state is locked
    var isLocked: Bool {
        lockStateManager.currentState.isLocked
    }

    /// Minimum words required (5 if locked, 0 if anytime)
    var minimumWords: Int {
        sessionType.requiresMinimumWords ? Theme.Validation.minimumWordCount : 0
    }

    /// Whether the submit button should be enabled
    var canSubmit: Bool {
        if sessionType.requiresMinimumWords {
            return wordCount >= minimumWords && !isSubmitting
        }
        return !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    /// The prompt text for this session type
    var prompt: String {
        sessionType.prompt
    }

    /// Header title with date
    var headerTitle: String {
        Date().formattedWithSession(sessionType)
    }

    /// Whether to show the morning entry reference (for night sessions)
    var showMorningReference: Bool {
        sessionType == .night && morningEntry != nil
    }

    // MARK: - Initialization

    init(sessionType: SessionType) {
        self.sessionType = sessionType
        loadMorningEntry()
    }

    // MARK: - Morning Entry

    /// Load today's morning entry for night sessions
    func loadMorningEntry() {
        guard sessionType == .night else { return }
        morningEntry = coreDataService.fetchTodaysMorningEntry()
    }

    // MARK: - Validation

    /// Validate the entry content
    func validateEntry() -> String? {
        let trimmedText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check empty
        if trimmedText.isEmpty {
            return "Please write something before submitting"
        }

        // Check minimum words for locked sessions
        if sessionType.requiresMinimumWords && wordCount < minimumWords {
            return "Please write at least \(minimumWords) words"
        }

        // Check maximum length
        if trimmedText.count > Theme.Validation.maximumContentLength {
            return "Entry is too long (maximum \(Theme.Validation.maximumContentLength) characters)"
        }

        // Check for suspiciously long words
        let words = trimmedText.split(separator: " ")
        for word in words {
            if word.count > Theme.Validation.maximumWordLength {
                return "Some words are too long. Please check your entry."
            }
        }

        // Check rate limiting
        if !settingsService.canCreateEntry() {
            return "Please wait a moment before creating another entry"
        }

        return nil
    }

    // MARK: - Submission

    /// Submit the journal entry
    func submitEntry() async -> Bool {
        // Validate
        if let error = validateEntry() {
            errorMessage = error
            return false
        }

        isSubmitting = true
        errorMessage = nil

        // Create entry
        let entry = coreDataService.createEntry(
            content: entryText.trimmingCharacters(in: .whitespacesAndNewlines),
            sessionType: sessionType,
            morningReferenceID: morningEntry?.id
        )

        guard entry != nil else {
            errorMessage = "Failed to save entry. Please try again."
            isSubmitting = false
            return false
        }

        // Unlock apps if this was a locked session
        if isLocked {
            lockStateManager.unlockApps()
        }

        isSubmitting = false
        return true
    }

    // MARK: - Draft Management

    /// Save a draft (for when app is backgrounded)
    func saveDraft() {
        // Could implement draft saving to UserDefaults here
        // For now, we rely on iOS state restoration
    }

    /// Clear the current entry
    func clearEntry() {
        entryText = ""
        errorMessage = nil
    }
}
