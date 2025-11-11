//
//  Word.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import Foundation
import SwiftData

@Model
final class Word {
    var id: UUID
    var frontText: String
    var backText: String // English translation
    var language: String = "ko" // Language code for frontText (e.g., "ko", "ja", "zh") - defaults to Korean for backward compatibility
    var dateCreated: Date
    var nextReviewDate: Date
    var easeFactor: Double // SM-2 ease factor (starts at 2.5)
    var interval: Int // Days until next review
    var repetitions: Int // Number of successful reviews
    
    init(
        id: UUID = UUID(),
        frontText: String,
        backText: String,
        language: String = "ko", // Default to Korean for backward compatibility
        dateCreated: Date = Date(),
        nextReviewDate: Date = Date(),
        easeFactor: Double = 2.5,
        interval: Int = 1,
        repetitions: Int = 0
    ) {
        self.id = id
        self.frontText = frontText
        self.backText = backText
        self.language = language
        self.dateCreated = dateCreated
        self.nextReviewDate = nextReviewDate
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
    }
}

