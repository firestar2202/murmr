//
//  LanguageDetector.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import Foundation
import NaturalLanguage

struct LanguageInfo {
    let code: String
    let name: String
    let nativeName: String
}

enum SupportedLanguage: String, CaseIterable {
    case korean = "ko"
    case japanese = "ja"
    case chinese = "zh"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"
    case thai = "th"
    case vietnamese = "vi"
    
    var info: LanguageInfo {
        switch self {
        case .korean:
            return LanguageInfo(code: "ko", name: "Korean", nativeName: "한국어")
        case .japanese:
            return LanguageInfo(code: "ja", name: "Japanese", nativeName: "日本語")
        case .chinese:
            return LanguageInfo(code: "zh", name: "Chinese", nativeName: "中文")
        case .spanish:
            return LanguageInfo(code: "es", name: "Spanish", nativeName: "Español")
        case .french:
            return LanguageInfo(code: "fr", name: "French", nativeName: "Français")
        case .german:
            return LanguageInfo(code: "de", name: "German", nativeName: "Deutsch")
        case .italian:
            return LanguageInfo(code: "it", name: "Italian", nativeName: "Italiano")
        case .portuguese:
            return LanguageInfo(code: "pt", name: "Portuguese", nativeName: "Português")
        case .russian:
            return LanguageInfo(code: "ru", name: "Russian", nativeName: "Русский")
        case .arabic:
            return LanguageInfo(code: "ar", name: "Arabic", nativeName: "العربية")
        case .hindi:
            return LanguageInfo(code: "hi", name: "Hindi", nativeName: "हिन्दी")
        case .thai:
            return LanguageInfo(code: "th", name: "Thai", nativeName: "ไทย")
        case .vietnamese:
            return LanguageInfo(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt")
        }
    }
    
    static func from(code: String) -> SupportedLanguage? {
        return SupportedLanguage.allCases.first { $0.rawValue == code }
    }
}

class LanguageDetector {
    static func detectLanguage(from text: String) -> String? {
        guard !text.isEmpty else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let dominantLanguage = recognizer.dominantLanguage else {
            return nil
        }
        
        let languageCode = dominantLanguage.rawValue
        
        // Map to supported language codes
        // NLLanguage returns codes like "ko", "ja", "zh-Hans", "zh-Hant", etc.
        if languageCode.hasPrefix("zh") {
            return "zh" // Normalize Chinese variants
        }
        
        // Check if it's a supported language
        if SupportedLanguage.from(code: languageCode) != nil {
            return languageCode
        }
        
        // Default to Korean if detection fails (for backward compatibility)
        return "ko"
    }
    
    static func getLanguageName(for code: String) -> String {
        if let language = SupportedLanguage.from(code: code) {
            return language.info.name
        }
        return code.uppercased()
    }
    
    static func getLanguageNativeName(for code: String) -> String {
        if let language = SupportedLanguage.from(code: code) {
            return language.info.nativeName
        }
        return code.uppercased()
    }
}

