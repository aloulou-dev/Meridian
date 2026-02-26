//
//  AppSecrets.swift
//  Meridian
//
//  DEV-ONLY secret loading for local builds.
//  Do not rely on client-side API keys for production.
//

import Foundation

enum AppSecrets {
    /// DEV ONLY: Any API key loaded client-side can be extracted.
    /// Production should move OpenAI calls behind a server-side proxy.
    static var openAIAPIKey: String? {
        if let fromEnv = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]?.trimmedNonEmpty {
            return fromEnv
        }

        if let fromInfo = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           let trimmed = fromInfo.trimmedNonEmpty {
            return trimmed
        }

        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = object as? [String: Any],
              let key = dict["OPENAI_API_KEY"] as? String else {
            return nil
        }

        return key.trimmedNonEmpty
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
