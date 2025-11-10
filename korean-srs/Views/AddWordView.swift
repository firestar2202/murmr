//
//  AddWordView.swift
//  korean-srs-app
//
//  Created by Auto on 1/1/25.
//

import SwiftUI
import SwiftData

struct AddWordView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var koreanText = ""
    @State private var englishText = ""
    @State private var translationOptions: [TranslationOption] = []
    @State private var isLoadingTranslations = false
    @State private var errorMessage: String?
    
    private let translationService = TranslationService()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Korean Word") {
                    HStack {
                        TextField("Enter Korean word", text: $koreanText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        Button(action: {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                            } else {
                                speechRecognizer.startRecording()
                            }
                        }) {
                            Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .foregroundColor(speechRecognizer.isRecording ? .red : .blue)
                                .font(.title2)
                        }
                    }
                }
                
                if !translationOptions.isEmpty {
                    Section("Translation Suggestions") {
                        ForEach(translationOptions) { option in
                            Button(action: {
                                englishText = option.text
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(option.text)
                                            .foregroundColor(.primary)
                                            .font(.body)
                                        Text("Confidence: \(Int(option.confidence * 100))%")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    if englishText == option.text {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("English Translation") {
                    TextField("Enter English translation", text: $englishText)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    Button(action: addWord) {
                        HStack {
                            Spacer()
                            Text("Add Word")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(koreanText.isEmpty || englishText.isEmpty)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Words")
            .onChange(of: speechRecognizer.transcribedText) { _, newValue in
                koreanText = newValue
            }
            .onChange(of: koreanText) { _, newValue in
                if !newValue.isEmpty {
                    fetchTranslations(for: newValue)
                } else {
                    translationOptions = []
                }
            }
            .task {
                await speechRecognizer.requestAuthorization()
            }
        }
    }
    
    private func fetchTranslations(for text: String) {
        guard !text.isEmpty else { return }
        
        isLoadingTranslations = true
        errorMessage = nil
        
        Task {
            do {
                let options = try await translationService.fetchTranslations(for: text)
                await MainActor.run {
                    translationOptions = options
                    isLoadingTranslations = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingTranslations = false
                }
            }
        }
    }
    
    private func addWord() {
        guard !koreanText.isEmpty && !englishText.isEmpty else { return }
        
        let word = Word(
            frontText: koreanText.trimmingCharacters(in: .whitespacesAndNewlines),
            backText: englishText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(word)
        
        // Reset fields
        koreanText = ""
        englishText = ""
        translationOptions = []
        errorMessage = nil
    }
}

#Preview {
    AddWordView()
        .modelContainer(for: Word.self, inMemory: true)
}

