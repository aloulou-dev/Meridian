//
//  AIQuestionServiceSelfTest.swift
//  Meridian
//
//  Lightweight debug-time checks for parser and fallback behavior.
//

import Foundation

#if DEBUG
enum AIQuestionServiceSelfTest {
    private static var didRun = false

    static func runIfNeeded() async {
        guard !didRun else { return }
        didRun = true

        testParsesValidJSON()
        testParsesCodeFenceJSON()
        await testFallbackWhenAIThrows()
    }

    private static func testParsesValidJSON() {
        let payload = #"{"questions":["Q1","Q2","Q3","Q4"]}"#
        let parsed = AIQuestionService.parseQuestions(from: payload, expectedCount: 4)
        assert(parsed?.count == 4, "AIQuestionService parser should parse plain JSON")
    }

    private static func testParsesCodeFenceJSON() {
        let payload = """
        ```json
        {"questions":["Q1","Q2","Q3","Q4","Q5","Q6"]}
        ```
        """
        let parsed = AIQuestionService.parseQuestions(from: payload, expectedCount: 6)
        assert(parsed?.count == 6, "AIQuestionService parser should parse fenced JSON")
    }

    private static func testFallbackWhenAIThrows() async {
        let service = QuestionGenerationService(
            aiService: ThrowingAIService(),
            fallbackService: FixedFallback(),
            settingsService: EnabledSettings(),
            entryProvider: EmptyEntries()
        )

        let result = await service.prompt(for: .morning, forceRefresh: true)
        assert(result.source == .fallback, "Prompt generation should fallback when AI throws")
        assert(result.text == "fallback prompt", "Fallback prompt text should be used on AI failure")
    }
}

private struct ThrowingAIService: AIQuestionProviding {
    func generateQuestions(for sessionType: SessionType, recentEntries: [String]) async throws -> [String] {
        throw AIQuestionError.badResponse
    }
}

private struct FixedFallback: FallbackPromptProviding {
    func prompt(for sessionType: SessionType) -> String { "fallback prompt" }
}

private struct EnabledSettings: AIPromptSettingsProviding {
    let isAIPromptsEnabled: Bool = true
}

private struct EmptyEntries: JournalEntriesProviding {
    func recentEntryContents(limit: Int) -> [String] { [] }
}
#endif
