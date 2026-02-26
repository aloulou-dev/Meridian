//
//  QuestionGenerationService.swift
//  Meridian
//
//  Orchestrates AI prompts with deterministic fallback behavior.
//

import Foundation

enum PromptSource {
    case ai
    case fallback
}

struct PromptGenerationResult {
    let text: String
    let source: PromptSource
}

protocol QuestionGenerating {
    func prompt(for sessionType: SessionType, forceRefresh: Bool) async -> PromptGenerationResult
}

protocol FallbackPromptProviding {
    func prompt(for sessionType: SessionType) -> String
}

protocol AIPromptSettingsProviding {
    var isAIPromptsEnabled: Bool { get }
}

protocol JournalEntriesProviding {
    func recentEntryContents(limit: Int) -> [String]
}

final class QuestionGenerationService: QuestionGenerating {
    static let shared = QuestionGenerationService()

    private let aiService: AIQuestionProviding
    private let fallbackService: FallbackPromptProviding
    private let settingsService: AIPromptSettingsProviding
    private let entryProvider: JournalEntriesProviding

    private var cache: [String: PromptGenerationResult] = [:]

    init(
        aiService: AIQuestionProviding = AIQuestionService(),
        fallbackService: FallbackPromptProviding = PromptCoachService.shared,
        settingsService: AIPromptSettingsProviding = SettingsService.shared,
        entryProvider: JournalEntriesProviding = CoreDataService.shared
    ) {
        self.aiService = aiService
        self.fallbackService = fallbackService
        self.settingsService = settingsService
        self.entryProvider = entryProvider
    }

    func prompt(for sessionType: SessionType, forceRefresh: Bool = false) async -> PromptGenerationResult {
        let cacheKey = dailyCacheKey(for: sessionType)
        if !forceRefresh, let cached = cache[cacheKey] {
            return cached
        }

        guard settingsService.isAIPromptsEnabled else {
            let fallback = PromptGenerationResult(text: fallbackService.prompt(for: sessionType), source: .fallback)
            cache[cacheKey] = fallback
            return fallback
        }

        do {
            let recentEntries = entryProvider.recentEntryContents(limit: 16)
            let questions = try await aiService.generateQuestions(for: sessionType, recentEntries: recentEntries)
            let result = PromptGenerationResult(text: render(questions: questions), source: .ai)
            cache[cacheKey] = result
            return result
        } catch {
            let fallback = PromptGenerationResult(text: fallbackService.prompt(for: sessionType), source: .fallback)
            cache[cacheKey] = fallback
            return fallback
        }
    }
}

extension PromptCoachService: FallbackPromptProviding {}
extension SettingsService: AIPromptSettingsProviding {}
extension CoreDataService: JournalEntriesProviding {
    func recentEntryContents(limit: Int) -> [String] {
        fetchAllEntries(limit: limit)
            .compactMap { $0.content?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private extension QuestionGenerationService {
    func dailyCacheKey(for sessionType: SessionType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(sessionType.rawValue)-\(formatter.string(from: Date()))"
    }

    func render(questions: [String]) -> String {
        questions
            .enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
    }
}
