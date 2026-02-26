//
//  PromptCoachService.swift
//  Meridian
//
//  Local/mock "AI coach" for hackathon builds.
//

import Foundation

final class PromptCoachService {
    static let shared = PromptCoachService()

    private let coreDataService = CoreDataService.shared

    private init() {}

    func prompt(for sessionType: SessionType) -> String {
        let recentEntries = coreDataService.fetchAllEntries(limit: 20)
        let themes = extractTopThemes(from: recentEntries)

        switch sessionType {
        case .morning:
            let focus = themes.first ?? "what matters most"
            return """
            1. What gift are you most grateful for this morning?
            2. What intention do you want to carry into today around "\(focus)"?
            3. Where might you drift off-course, and what would bring you back?
            4. What one concrete action will you take, and what strength do you ask for?
            """
        case .night:
            let focus = themes.first ?? "your deepest values"
            return """
            1. Take a breath. How are you arriving at this moment?
            2. What are two moments of gratitude from today?
            3. Which moments stand out when you review the day?
            4. Where did you feel aligned with "\(focus)", and where did you feel pulled away?
            5. What do you want to release and ask healing for?
            6. What intention do you entrust to tomorrow before rest?
            """
        case .anytime:
            if let theme = themes.first {
                return "What are you noticing right now about \"\(theme)\" in your life?"
            }
            return "What is most present in your mind and heart right now?"
        }
    }

    private func extractTopThemes(from entries: [JournalEntry]) -> [String] {
        let stopWords: Set<String> = [
            "the", "and", "for", "that", "this", "with", "have", "from", "your", "you",
            "are", "was", "were", "but", "not", "about", "just", "into", "then", "they",
            "them", "will", "would", "could", "should", "what", "when", "where", "how"
        ]

        var counts: [String: Int] = [:]
        for entry in entries {
            let text = (entry.content ?? "").lowercased()
            let words = text
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 4 && !stopWords.contains($0) }
            for word in words {
                counts[word, default: 0] += 1
            }
        }

        return counts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map(\.key)
    }
}
