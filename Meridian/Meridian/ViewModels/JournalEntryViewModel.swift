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
    @Published var photoLocalPath: String?
    @Published var generatedPrompt: String = ""
    @Published var isLoadingPrompt = false
    @Published var isUsingAIPrompt = false
    @Published var promptLoadError: String?
    @Published var selectedEntryInputMode: MorningEntryMode = .digital
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var requiresTotemScan = false
    @Published var isProcessingOCR = false
    @Published var ocrError: String?

    // MARK: - Properties

    let sessionType: SessionType
    private let coreDataService = CoreDataService.shared
    private let lockStateManager = LockStateManager.shared
    private let settingsService = SettingsService.shared
    private let questionGenerationService = QuestionGenerationService.shared
    private let aiService = AIQuestionService()
    private var lastPromptRefreshAt: Date?

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
        if sessionType != .anytime && selectedEntryInputMode == .physical {
            return 0
        }
        return sessionType.requiresMinimumWords ? Theme.Validation.minimumWordCount : 0
    }

    /// Whether the submit button should be enabled
    var canSubmit: Bool {
        if sessionType != .anytime && selectedEntryInputMode == .physical {
            let hasText = !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasPhoto = photoLocalPath != nil
            return (hasText || hasPhoto) && !isSubmitting
        }
        if sessionType.requiresMinimumWords {
            return wordCount >= minimumWords && !isSubmitting
        }
        return !entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }

    /// The prompt text for this session type
    var prompt: String {
        generatedPrompt.isEmpty ? sessionType.prompt : generatedPrompt
    }

    var canRefreshPrompt: Bool {
        guard !isLoadingPrompt else { return false }
        guard let lastPromptRefreshAt else { return true }
        return Date().timeIntervalSince(lastPromptRefreshAt) > 15
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
        Task { [weak self] in
            await self?.loadPrompt()
        }
    }

    // MARK: - Morning Entry

    /// Load today's morning entry for night sessions
    func loadMorningEntry() {
        guard sessionType == .night else { return }
        morningEntry = coreDataService.fetchTodaysMorningEntry()
    }

    @MainActor
    func loadPrompt(forceRefresh: Bool = false) async {
        isLoadingPrompt = true
        promptLoadError = nil

        let result = await questionGenerationService.prompt(for: sessionType, forceRefresh: forceRefresh)
        generatedPrompt = result.text
        isUsingAIPrompt = result.source == .ai
        if result.source == .fallback && SettingsService.shared.isAIPromptsEnabled {
            promptLoadError = "Using local fallback prompt"
        }

        lastPromptRefreshAt = Date()
        isLoadingPrompt = false
    }

    // MARK: - Photo OCR

    @MainActor
    func processPhotoOCR(imageData: Data) async {
        isProcessingOCR = true
        ocrError = nil

        do {
            let extractedText = try await aiService.extractTextFromImage(imageData)
            entryText = extractedText
        } catch {
            ocrError = "Could not read handwriting. You can type your reflection instead."
            print("OCR failed: \(error)")
        }

        isProcessingOCR = false
    }

    // MARK: - Validation

    /// Validate the entry content
    func validateEntry() -> String? {
        let trimmedText = entryText.trimmingCharacters(in: .whitespacesAndNewlines)

        if sessionType != .anytime && selectedEntryInputMode == .physical {
            if trimmedText.isEmpty && photoLocalPath == nil {
                return "Add a photo or write a short reflection to continue"
            }
            if !trimmedText.isEmpty && trimmedText.count > Theme.Validation.maximumContentLength {
                return "Entry is too long (maximum \(Theme.Validation.maximumContentLength) characters)"
            }
            if !settingsService.canCreateEntry() {
                return "Please wait a moment before creating another entry"
            }
            return nil
        }

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
            morningReferenceID: morningEntry?.id,
            entryMode: sessionType != .anytime ? selectedEntryInputMode.rawValue : "digital",
            photoLocalPath: photoLocalPath
        )

        guard entry != nil else {
            errorMessage = "Failed to save entry. Please try again."
            isSubmitting = false
            return false
        }

        if isLocked {
            if settingsService.hasTotemConfigured && QRScannerService.isCameraAvailable {
                requiresTotemScan = true
                isSubmitting = false
                return true
            } else {
                lockStateManager.unlockApps()
            }
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
        photoLocalPath = nil
        errorMessage = nil
    }
}
