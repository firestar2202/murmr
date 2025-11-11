//
//  SRSManager.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import Foundation

enum SRSEase: String, CaseIterable {
    case again = "Again"
    case hard = "Hard"
    case good = "Good"
    case easy = "Easy"
}

struct SRSManager {
    // SM-2 Algorithm implementation
    
    static func updateWord(_ word: Word, with ease: SRSEase) {
        switch ease {
        case .again:
            // Reset to 1 day, decrease ease factor by 0.2
            word.interval = 1
            word.easeFactor = max(1.3, word.easeFactor - 0.2)
            word.repetitions = 0
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            
        case .hard:
            // Multiply interval by 1.2, decrease ease by 0.15
            word.interval = Int(Double(word.interval) * 1.2)
            word.easeFactor = max(1.3, word.easeFactor - 0.15)
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: word.interval, to: Date()) ?? Date()
            
        case .good:
            // First = 1 day, second = 6 days, then interval × ease factor
            if word.repetitions == 0 {
                word.interval = 1
            } else if word.repetitions == 1 {
                word.interval = 6
            } else {
                word.interval = Int(Double(word.interval) * word.easeFactor)
            }
            word.repetitions += 1
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: word.interval, to: Date()) ?? Date()
            
        case .easy:
            // First = 4 days, then interval × ease factor × 1.3, increase ease by 0.15
            if word.repetitions == 0 {
                word.interval = 4
            } else {
                word.interval = Int(Double(word.interval) * word.easeFactor * 1.3)
            }
            word.easeFactor += 0.15
            word.repetitions += 1
            word.nextReviewDate = Calendar.current.date(byAdding: .day, value: word.interval, to: Date()) ?? Date()
        }
    }
    
    static func getNextInterval(for word: Word, with ease: SRSEase) -> Int {
        let tempWord = Word(
            frontText: word.frontText,
            backText: word.backText,
            language: word.language,
            dateCreated: word.dateCreated,
            nextReviewDate: word.nextReviewDate,
            easeFactor: word.easeFactor,
            interval: word.interval,
            repetitions: word.repetitions
        )
        
        updateWord(tempWord, with: ease)
        return tempWord.interval
    }
}

