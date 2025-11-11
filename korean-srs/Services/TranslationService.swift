//
//  TranslationService.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import Foundation

struct TranslationOption: Identifiable {
    let id = UUID()
    let text: String
    let confidence: Double
}

class TranslationService {
    // Uses MyMemory Translation API - free, no API key needed!
    // https://mymemory.translated.net/
    
    private let baseURL = "https://api.mymemory.translated.net/get"
    
    func fetchTranslations(for koreanText: String) async throws -> [TranslationOption] {
        guard !koreanText.isEmpty else {
            return []
        }
        
        // URL encode the text
        guard let url = URL(string: "\(baseURL)?q=\(koreanText)&langpair=ko|en") else {
            throw TranslationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TranslationError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MyMemoryResponse.self, from: data)
        
        guard result.responseStatus == 200,
              let translatedText = result.responseData?.translatedText else {
            throw TranslationError.noTranslations
        }
        
        var deduplicationSet = Set<String>()
        var options: [TranslationOption] = []
        
        func appendOption(text: String, confidence: Double) {
            let decoded = decodeTranslation(text)
            guard !decoded.isEmpty else { return }
            let key = decoded.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard deduplicationSet.insert(key).inserted else { return }
            options.append(TranslationOption(text: decoded, confidence: confidence))
        }
        
        appendOption(text: translatedText, confidence: 0.9)
        
        if let matches = result.matches {
            for match in matches {
                appendOption(text: match.translation, confidence: match.confidenceScore)
            }
        }
        
        // Add simple variations for UX
        let base = options.first?.text ?? ""
        let variations = generateVariations(from: base)
        for option in variations {
            appendOption(text: option.text, confidence: option.confidence)
        }
        
        return Array(options.prefix(5))
    }
    
    // Generate simple variations of the translation
    private func generateVariations(from translation: String) -> [TranslationOption] {
        var variations: [TranslationOption] = []
        
        // Add capitalized version if different
        let capitalized = translation.capitalized
        if capitalized != translation {
            variations.append(TranslationOption(text: capitalized, confidence: 0.75))
        }
        
        // Add lowercase version if different
        let lowercased = translation.lowercased()
        if lowercased != translation && lowercased != capitalized.lowercased() {
            variations.append(TranslationOption(text: lowercased, confidence: 0.70))
        }
        
        return variations
    }
    
    private func decodeTranslation(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        
        var normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "+", with: " ")
        
        let pattern = "%\\s*([0-9A-Fa-f]{2})"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: normalized.utf16.count)
            normalized = regex.stringByReplacingMatches(in: normalized, options: [], range: range, withTemplate: "%$1")
        }
        
        return normalized.removingPercentEncoding ?? normalized
    }
}

// MARK: - Response Models

private struct MyMemoryResponse: Codable {
    let responseData: ResponseData?
    let responseStatus: Int
    let matches: [Match]?
    
    struct ResponseData: Codable {
        let translatedText: String
    }
    
    struct Match: Codable {
        let translation: String
        let quality: Double?
        let match: Double?
        
        var confidenceScore: Double {
            if let quality = quality {
                return max(0.0, min(1.0, quality / 100.0))
            }
            if let match = match {
                return max(0.0, min(1.0, match))
            }
            return 0.6
        }
    }
}

// MARK: - Errors

enum TranslationError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noTranslations
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid translation request"
        case .invalidResponse:
            return "Translation service unavailable"
        case .noTranslations:
            return "No translations found"
        }
    }
}

