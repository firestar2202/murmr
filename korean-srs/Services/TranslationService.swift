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
    
    func fetchTranslations(for text: String, from languageCode: String = "ko") async throws -> [TranslationOption] {
        guard !text.isEmpty else {
            return []
        }
        
        // Create language pair (source|target, where target is always English)
        let langPair = "\(languageCode)|en"
        
        // URL encode the text
        guard let url = URL(string: "\(baseURL)?q=\(text)&langpair=\(langPair)") else {
            throw TranslationError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TranslationError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        print(String(data: data, encoding: .utf8))
        let result = try decoder.decode(MyMemoryResponse.self, from: data)
        
        guard result.responseStatus == 200,
              let responseData = result.responseData
              else {
            throw TranslationError.noTranslations
        }
        let translatedText = responseData.translatedText
        
        var deduplicationSet = Set<String>()
        var options: [TranslationOption] = []
        
        func appendOption(text: String, confidence: Double) {
            let decoded = decodeTranslation(text)
            guard !decoded.isEmpty else { return }
            let key = decoded.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard deduplicationSet.insert(key).inserted else { return }
            options.append(TranslationOption(text: decoded, confidence: confidence))
        }
        
        // Use match value from responseData if available, otherwise default to 0.9
        let mainTranslationConfidence = responseData.match ?? 0.9
        appendOption(text: translatedText, confidence: mainTranslationConfidence)
        
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

private struct MyMemoryResponse: Decodable {
    let responseData: ResponseData?
    let quotaFinished: Bool?
    let mtLangSupported: String?
    let responseDetails: String?
    let responseStatus: Int
    let responderId: String?
    let exception_code: String?
    let matches: [Match]?
    
    struct ResponseData: Decodable {
        let translatedText: String
        let match: Double?
    }
    
    struct Match: Decodable {
        let id: String?
        let segment: String?
        let translation: String
        let source: String?
        let target: String?
        let quality: String?
        let reference: String?
        let usageCount: Int?
        let subject: String?
        let createdBy: String?
        let lastUpdatedBy: String?
        let createDate: String?
        let lastUpdateDate: String?
        let match: Double?
        let penalty: Double?
        let model: String? // Additional field that may exist
        
        enum CodingKeys: String, CodingKey {
            case id
            case segment
            case translation
            case source
            case target
            case quality
            case reference
            case usageCount = "usage-count"
            case subject
            case createdBy = "created-by"
            case lastUpdatedBy = "last-updated-by"
            case createDate = "create-date"
            case lastUpdateDate = "last-update-date"
            case match
            case penalty
            case model
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Handle id as String or Int
            if let idString = try? container.decode(String.self, forKey: .id) {
                id = idString
            } else if let idInt = try? container.decode(Int.self, forKey: .id) {
                id = String(idInt)
            } else {
                id = nil
            }
            
            segment = try? container.decode(String.self, forKey: .segment)
            translation = try container.decode(String.self, forKey: .translation)
            source = try? container.decode(String.self, forKey: .source)
            target = try? container.decode(String.self, forKey: .target)
            
            // Handle quality as String or Number
            if let qualityString = try? container.decode(String.self, forKey: .quality) {
                quality = qualityString
            } else if let qualityDouble = try? container.decode(Double.self, forKey: .quality) {
                quality = String(format: "%.0f", qualityDouble)
            } else if let qualityInt = try? container.decode(Int.self, forKey: .quality) {
                quality = String(qualityInt)
            } else {
                quality = nil
            }
            
            reference = try? container.decode(String.self, forKey: .reference)
            usageCount = try? container.decode(Int.self, forKey: .usageCount)
            
            // Handle subject as String or Boolean
            if let subjectString = try? container.decode(String.self, forKey: .subject) {
                subject = subjectString
            } else if let subjectBool = try? container.decode(Bool.self, forKey: .subject) {
                subject = subjectBool ? "true" : "false"
            } else {
                subject = nil
            }
            
            createdBy = try? container.decode(String.self, forKey: .createdBy)
            lastUpdatedBy = try? container.decode(String.self, forKey: .lastUpdatedBy)
            createDate = try? container.decode(String.self, forKey: .createDate)
            lastUpdateDate = try? container.decode(String.self, forKey: .lastUpdateDate)
            match = try? container.decode(Double.self, forKey: .match)
            
            // Handle penalty as Number or null
            penalty = try? container.decode(Double.self, forKey: .penalty)
            
            model = try? container.decode(String.self, forKey: .model)
        }
        
        var confidenceScore: Double {
            // Prefer match value if available
            if let match = match {
                return max(0.0, min(1.0, match))
            }
            // Try to parse quality as number (it can be a string or number)
            if let qualityString = quality, let qualityValue = Double(qualityString) {
                return max(0.0, min(1.0, qualityValue / 100.0))
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

