# Korean Vocabulary SRS App

An iOS app for learning Korean vocabulary using spaced repetition (SM-2 algorithm).

## Features

- **Add Words Tab**: Add Korean words by typing or voice input, get free translation suggestions (no API keys needed!)
- **Study Tab**: Review flashcards with spaced repetition scheduling

## Setup Instructions

**No API keys needed!** The app uses the free MyMemory Translation API which requires no setup or registration.

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose **iOS** → **App**
   - Product Name: `korean-srs-app`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Use SwiftData: **Yes**
   - Minimum iOS: **17.0**
3. Save the project in `/Users/justinhaddad/Documents/korean-srs-app/`

### 2. Add Files to Xcode Project

Add all the Swift files from this directory to your Xcode project:
- Models/Word.swift
- Models/SRSManager.swift
- Services/SpeechRecognizer.swift
- Services/TranslationService.swift
- Views/AddWordView.swift
- Views/StudyView.swift
- Views/FlashcardView.swift
- Config.swift
- ContentView.swift
- korean_srs_appApp.swift

### 3. Add Info.plist Entries

In Xcode:
1. Right-click on your project → **New File** → **Property List**
2. Name it `Info.plist`
3. Add the following keys:
   - `NSMicrophoneUsageDescription`: "We need microphone access to add words by voice"
   - `NSSpeechRecognitionUsageDescription`: "We need speech recognition to convert spoken words to text"

Or copy the provided `Info.plist` file.

### 4. Build and Run

1. Build the project (⌘B)
2. Run on simulator or device (⌘R)
3. Grant microphone and speech recognition permissions when prompted

## Usage

1. **Add Words**: Use the microphone to speak Korean words, or type them. Select a translation suggestion or enter your own.
2. **Study**: Review flashcards. Flip the card to see the answer, then rate your recall (Again/Hard/Good/Easy).

## SRS Algorithm (SM-2)

- **Again**: Reset to 1 day, decrease ease factor
- **Hard**: Multiply interval by 1.2, decrease ease
- **Good**: 1 day → 6 days → interval × ease factor
- **Easy**: 4 days → interval × ease × 1.3, increase ease

## Notes

- **No API keys needed!** Uses free MyMemory Translation API
- The app requires iOS 17+ for SwiftData support
- Internet connection required for translation suggestions
- MyMemory API: Free, unlimited use (community-translated)

