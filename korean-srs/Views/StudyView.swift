//
//  StudyView.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import SwiftUI
import SwiftData

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Word.nextReviewDate, order: .forward) private var allWords: [Word]
    
    @State private var currentWordIndex = 0
    @State private var isFlipped = false
    
    private var dueWords: [Word] {
        let today = Calendar.current.startOfDay(for: Date())
        return allWords.filter { word in
            Calendar.current.startOfDay(for: word.nextReviewDate) <= today
        }
    }
    
    private var currentWord: Word? {
        guard currentWordIndex < dueWords.count else { return nil }
        return dueWords[currentWordIndex]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Card counter
                VStack(spacing: 8) {
                    Text("\(dueWords.count) cards due")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if !dueWords.isEmpty {
                        Text("Card \(currentWordIndex + 1) of \(dueWords.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                if let word = currentWord {
                    FlashcardView(
                        frontText: word.frontText,
                        backText: word.backText,
                        onFlip: {
                            isFlipped = true
                        }
                    )
                    .id(currentWordIndex) // Force recreation on word change
                    
                    Spacer()
                    
                    // Rating buttons (only show after flip)
                    if isFlipped {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                RatingButton(
                                    ease: .again,
                                    word: word,
                                    action: { rateWord(word, ease: .again) }
                                )
                                
                                RatingButton(
                                    ease: .hard,
                                    word: word,
                                    action: { rateWord(word, ease: .hard) }
                                )
                            }
                            
                            HStack(spacing: 16) {
                                RatingButton(
                                    ease: .good,
                                    word: word,
                                    action: { rateWord(word, ease: .good) }
                                )
                                
                                RatingButton(
                                    ease: .easy,
                                    word: word,
                                    action: { rateWord(word, ease: .easy) }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No cards due! 🎉")
                            .font(.title2.bold())
                        
                        Text("Great job! All your cards are scheduled for future review.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Study")
        }
    }
    
    private func rateWord(_ word: Word, ease: SRSEase) {
        SRSManager.updateWord(word, with: ease)
        
        // Save context
        try? modelContext.save()
        
        // Move to next card or reset
        withAnimation {
            if currentWordIndex < dueWords.count - 1 {
                currentWordIndex += 1
            }
            isFlipped = false
        }
    }
}

struct RatingButton: View {
    let ease: SRSEase
    let word: Word
    let action: () -> Void
    
    private var color: Color {
        switch ease {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return Color(red: 0.2, green: 0.8, blue: 0.2)
        }
    }
    
    private var nextInterval: Int {
        SRSManager.getNextInterval(for: word, with: ease)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(ease.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(nextInterval)d")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StudyView()
        .modelContainer(for: Word.self, inMemory: true)
}

