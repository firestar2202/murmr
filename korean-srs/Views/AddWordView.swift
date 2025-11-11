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
    @State private var frontText = ""
    @State private var englishText = ""
    @State private var selectedLanguage: SupportedLanguage = .korean
    @State private var translationOptions: [TranslationOption] = []
    @State private var isLoadingTranslations = false
    @State private var errorMessage: String?
    
    private let translationService = TranslationService()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Language") {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(SupportedLanguage.allCases, id: \.self) { language in
                            HStack {
                                Text(language.info.name)
                                Text("(\(language.info.nativeName))")
                                    .foregroundColor(.secondary)
                            }
                            .tag(language)
                        }
                    }
                }
                
                Section("Word") {
                    HStack {
                        TextField("Enter word", text: $frontText)
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
                    .disabled(frontText.isEmpty || englishText.isEmpty)
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
                frontText = newValue
            }
            .onChange(of: frontText) { _, newValue in
                // Auto-detect language when text changes
                if !newValue.isEmpty {
                    if let detectedCode = LanguageDetector.detectLanguage(from: newValue),
                       let detectedLanguage = SupportedLanguage.from(code: detectedCode) {
                        selectedLanguage = detectedLanguage
                    }
                    fetchTranslations(for: newValue, language: selectedLanguage.rawValue)
                } else {
                    translationOptions = []
                }
            }
            .onChange(of: selectedLanguage) { _, _ in
                // Re-fetch translations when language changes
                if !frontText.isEmpty {
                    fetchTranslations(for: frontText, language: selectedLanguage.rawValue)
                }
            }
            .task {
                await speechRecognizer.requestAuthorization()
            }
        }
    }
    
    private func fetchTranslations(for text: String, language: String) {
        guard !text.isEmpty else { return }
        
        isLoadingTranslations = true
        errorMessage = nil
        
        Task {
            do {
                let options = try await translationService.fetchTranslations(for: text, from: language)
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
        guard !frontText.isEmpty && !englishText.isEmpty else { return }
        
        let word = Word(
            frontText: frontText.trimmingCharacters(in: .whitespacesAndNewlines),
            backText: englishText.trimmingCharacters(in: .whitespacesAndNewlines),
            language: selectedLanguage.rawValue
        )
        
        modelContext.insert(word)
        
        // Reset fields
        frontText = ""
        englishText = ""
        translationOptions = []
        errorMessage = nil
    }
}

#Preview {
    AddWordView()
        .modelContainer(for: Word.self, inMemory: true)
}

