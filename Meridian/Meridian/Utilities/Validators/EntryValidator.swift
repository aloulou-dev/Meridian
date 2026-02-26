//
//  EntryValidator.swift
//  Meridian
//
//  Validation utilities for journal entries.
//

import Foundation

/// Validates journal entry content
struct EntryValidator {
    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let error: String?

        static let valid = ValidationResult(isValid: true, error: nil)

        static func invalid(_ error: String) -> ValidationResult {
            ValidationResult(isValid: false, error: error)
        }
    }

    // MARK: - Validation

    /// Validate entry content
    /// - Parameters:
    ///   - content: The entry text content
    ///   - requiresMinimumWords: Whether minimum word count is required
    /// - Returns: Validation result
    static func validate(
        content: String,
        requiresMinimumWords: Bool
    ) -> ValidationResult {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check empty
        if trimmed.isEmpty {
            return .invalid("Please write something before submitting")
        }

        // Check maximum length
        if trimmed.count > Theme.Validation.maximumContentLength {
            return .invalid("Entry is too long (maximum \(Theme.Validation.maximumContentLength) characters)")
        }

        // Count words
        let words = trimmed.split(separator: " ").filter { !$0.isEmpty }
        let wordCount = words.count

        // Check minimum words
        if requiresMinimumWords && wordCount < Theme.Validation.minimumWordCount {
            return .invalid("Please write at least \(Theme.Validation.minimumWordCount) words")
        }

        // Check for suspiciously long words (potential abuse/attack)
        for word in words {
            if word.count > Theme.Validation.maximumWordLength {
                return .invalid("Some words are too long. Please check your entry.")
            }
        }

        return .valid
    }

    /// Count words in text
    static func wordCount(_ text: String) -> Int {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .filter { !$0.isEmpty }
            .count
    }

    /// Check if text meets minimum word count
    static func meetsMinimumWords(_ text: String) -> Bool {
        wordCount(text) >= Theme.Validation.minimumWordCount
    }

    /// Sanitize content (remove potentially harmful characters)
    static func sanitize(_ content: String) -> String {
        // Remove null bytes and other control characters (except newlines/tabs)
        var sanitized = content.unicodeScalars.filter { scalar in
            scalar == "\n" || scalar == "\t" || !CharacterSet.controlCharacters.contains(scalar)
        }
        .map { Character($0) }
        .reduce("") { $0 + String($1) }

        // Trim to maximum length
        if sanitized.count > Theme.Validation.maximumContentLength {
            sanitized = String(sanitized.prefix(Theme.Validation.maximumContentLength))
        }

        return sanitized
    }
}
