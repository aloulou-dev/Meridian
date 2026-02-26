//
//  AIQuestionService.swift
//  Meridian
//
//  Dev-only OpenAI integration for structured journal prompts.
//

import Foundation

enum AIQuestionError: Error {
    case missingAPIKey
    case badResponse
    case malformedOutput
}

protocol AIQuestionProviding {
    func generateQuestions(for sessionType: SessionType, recentEntries: [String]) async throws -> [String]
}

final class AIQuestionService: AIQuestionProviding {
    private let session: URLSession
    private let model: String
    private let visionModel = "gpt-4o"

    init(session: URLSession = .shared, model: String = "gpt-4.1-mini") {
        self.session = session
        self.model = model
    }

    // MARK: - Vision OCR

    func extractTextFromImage(_ imageData: Data) async throws -> String {
        guard let apiKey = AppSecrets.openAIAPIKey else {
            throw AIQuestionError.missingAPIKey
        }

        let base64 = imageData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64)"

        let payload = VisionCompletionsRequest(
            model: visionModel,
            messages: [
                .init(role: "user", content: [
                    .text("Extract the handwritten text from this journal entry photo. "
                          + "Return ONLY the transcribed text, preserving paragraph breaks. "
                          + "Do not add commentary, labels, or formatting."),
                    .imageURL(dataURI)
                ])
            ],
            maxTokens: 1024
        )

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIQuestionError.badResponse
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIQuestionError.badResponse
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AIQuestionError.malformedOutput
        }
        return trimmed
    }

    // MARK: - Question Generation

    func generateQuestions(for sessionType: SessionType, recentEntries: [String]) async throws -> [String] {
        guard let apiKey = AppSecrets.openAIAPIKey else {
            throw AIQuestionError.missingAPIKey
        }

        let developerPrompt = Self.developerPrompt(for: sessionType)
        let userPrompt = Self.userPrompt(for: sessionType, recentEntries: recentEntries)

        let payload = ChatCompletionsRequest(
            model: model,
            temperature: 0.7,
            messages: [
                .init(role: "developer", content: developerPrompt),
                .init(role: "user", content: userPrompt)
            ],
            responseFormat: .jsonObject
        )

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AIQuestionError.badResponse
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIQuestionError.badResponse
        }

        guard let questions = Self.parseQuestions(from: content, expectedCount: Self.expectedQuestionCount(for: sessionType)) else {
            throw AIQuestionError.malformedOutput
        }

        return questions
    }
}

extension AIQuestionService {
    static func expectedQuestionCount(for sessionType: SessionType) -> Int {
        switch sessionType {
        case .morning:
            return 4
        case .night:
            return 6
        case .anytime:
            return 3
        }
    }

    static func developerPrompt(for sessionType: SessionType) -> String {
        switch sessionType {
        case .morning:
            return """
            You are a compassionate Jesuit-style reflection coach.
            Create exactly 4 short journaling questions for morning examen-light reflection.
            Questions must follow this order:
            1) gratitude anchor,
            2) intention for today,
            3) likely challenge/distraction awareness,
            4) concrete action and request for strength.
            Keep each question under 120 characters.
            Return ONLY valid JSON: {"questions":["...","...","...","..."]}.
            """
        case .night:
            return """
            You are a compassionate Jesuit-style reflection coach.
            Create exactly 6 short journaling questions for a night examen.
            Questions must follow this order:
            1) settling/presence,
            2) gratitude review,
            3) replay key moments of the day,
            4) notice alignment/misalignment (consolation/desolation language optional),
            5) forgiveness/healing,
            6) resolution and restful entrustment for tomorrow.
            Keep each question under 140 characters.
            Return ONLY valid JSON: {"questions":["...","...","...","...","...","..."]}.
            """
        case .anytime:
            return """
            Create exactly 3 gentle reflection questions for a neutral journaling session.
            Keep each question under 120 characters.
            Return ONLY valid JSON: {"questions":["...","...","..."]}.
            """
        }
    }

    static func userPrompt(for sessionType: SessionType, recentEntries: [String]) -> String {
        let entryContext: String
        if recentEntries.isEmpty {
            entryContext = "No recent entries available."
        } else {
            entryContext = recentEntries
                .prefix(8)
                .enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
        }

        return """
        Session type: \(sessionType.rawValue)
        Generate reflective questions that are warm, practical, and spiritually grounded without being preachy.
        Recent reflections (optional context):
        \(entryContext)
        """
    }

    static func parseQuestions(from content: String, expectedCount: Int) -> [String]? {
        guard let data = extractJSONData(from: content) else { return nil }
        guard let decoded = try? JSONDecoder().decode(QuestionEnvelope.self, from: data) else { return nil }

        let cleaned = decoded.questions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard cleaned.count == expectedCount else { return nil }
        return cleaned
    }

    static func extractJSONData(from content: String) -> Data? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }

        let withoutCodeFence = trimmed
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = withoutCodeFence.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
            return data
        }
        return nil
    }
}

private struct QuestionEnvelope: Codable {
    let questions: [String]
}

private struct ChatCompletionsRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
        static let jsonObject = ResponseFormat(type: "json_object")
    }

    let model: String
    let temperature: Double
    let messages: [Message]
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case temperature
        case messages
        case responseFormat = "response_format"
    }
}

private struct ChatCompletionsResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Vision API Types

private struct VisionCompletionsRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: [ContentPart]
    }

    enum ContentPart: Encodable {
        case text(String)
        case imageURL(String)

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .imageURL(let url):
                try container.encode("image_url", forKey: .type)
                try container.encode(ImageURL(url: url, detail: "high"), forKey: .imageURL)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageURL = "image_url"
        }

        struct ImageURL: Encodable {
            let url: String
            let detail: String
        }
    }

    let model: String
    let messages: [Message]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
    }
}
