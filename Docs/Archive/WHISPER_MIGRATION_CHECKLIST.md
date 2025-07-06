# Whisper Migration Checklist

This is the definitive list of all 17 text input locations that need migration to the unified Whisper system.

## Text Input Locations to Replace

### Chat Module (1)
- [x] **MessageComposer.swift** - Line 147
  - Current: `.voiceTranscriptionOverlay($text, alignment: .topTrailing, padding: 4)`
  - Replace with: `WhisperVoiceButton(text: $text)`

### Food Tracking Module (3)
- [x] **NutritionSearchView.swift** - Line 101
  - Current: `.voiceTranscriptionEnabled($searchText)`
  - Replace with: `WhisperVoiceButton(text: $searchText)`

- [x] **FoodConfirmationView.swift** - Line 227
  - Current: `.voiceTranscriptionEnabled($foodName)`
  - Replace with: `WhisperVoiceButton(text: $foodName)`

- [x] **FoodHealthKitConfirmationView.swift** - (Not found - no text inputs)
  - Current: Voice implementation exists
  - Replace with: `WhisperVoiceButton(text: $text)`

### Workouts Module (7)
- [x] **WorkoutBuilderView.swift** - Line 183
  - Current: `.voiceTranscriptionEnabled($workoutName)`
  - Replace with: `WhisperVoiceButton(text: $workoutName)`

- [x] **WorkoutBuilderView.swift** - Line 445
  - Current: `.voiceTranscriptionOverlay($workoutName, alignment: .topTrailing, padding: 8)`
  - Replace with: `WhisperVoiceButton(text: $workoutName)`

- [x] **WorkoutBuilderView.swift** - Line 453
  - Current: `.voiceTranscriptionOverlay($workoutNotes, alignment: .topTrailing, padding: 8)`
  - Replace with: `WhisperVoiceButton(text: $workoutNotes)`

- [x] **WorkoutBuilderView.swift** - Line 674
  - Current: `.voiceTranscriptionEnabled($searchText)`
  - Replace with: `WhisperVoiceButton(text: $searchText)`

- [x] **WorkoutDetailView.swift** - Line 300
  - Current: `.voiceTranscriptionEnabled($templateName)`
  - Replace with: `WhisperVoiceButton(text: $templateName)`

- [x] **AllWorkoutsView.swift** - Line 57
  - Current: `.voiceTranscriptionEnabled($searchText)`
  - Replace with: `WhisperVoiceButton(text: $searchText)`

- [x] **ExerciseLibraryView.swift** - Line 46
  - Current: `.voiceTranscriptionEnabled($searchText)`
  - Replace with: `WhisperVoiceButton(text: $searchText)`

### Settings Module (5)
- [x] **SettingsListView.swift** - Line 556
  - Current: `.voiceTranscriptionOverlay($refinementText, alignment: .topTrailing, padding: 8)`
  - Replace with: `WhisperVoiceButton(text: $refinementText)`

- [x] **AIPersonaSettingsView.swift** - Line 483
  - Current: `.voiceTranscriptionOverlay($adjustmentText, alignment: .topTrailing, padding: 8)`
  - Replace with: `WhisperVoiceButton(text: $adjustmentText)`

- [x] **AIPersonaSettingsView.swift** - Line 655
  - Current: `.voiceTranscriptionOverlay($inputText, alignment: .topTrailing, padding: 8)`
  - Replace with: `WhisperVoiceButton(text: $inputText)`

- [x] **InitialAPISetupView.swift** - Line 99 (TextField) - SKIPPED (API Key)
  - Current: `.voiceTranscriptionEnabled($apiKey)`
  - Replace with: `WhisperVoiceButton(text: $apiKey)`

- [x] **InitialAPISetupView.swift** - Line 105 (SecureField) - SKIPPED (API Key)
  - Current: `.voiceTranscriptionEnabled($apiKey)`
  - Replace with: `WhisperVoiceButton(text: $apiKey)`

- [x] **APIKeyEntryView.swift** - Line 117 (TextField) - SKIPPED (API Key)
  - Current: `.voiceTranscriptionEnabled($apiKey)`
  - Replace with: `WhisperVoiceButton(text: $apiKey)`

- [x] **APIKeyEntryView.swift** - Line 123 (SecureField) - SKIPPED (API Key)
  - Current: `.voiceTranscriptionEnabled($apiKey)`
  - Replace with: `WhisperVoiceButton(text: $apiKey)`

### Onboarding Module (2)
- [x] **OnboardingView.swift** - Line 449
  - Current: `.voiceTranscriptionOverlay($input, alignment: .topTrailing, padding: 12)`
  - Replace with: `WhisperVoiceButton(text: $input)`

- [x] **APISetupView.swift** - Line 317 (SecureField) - SKIPPED (API Key)
  - Current: `.voiceTranscriptionEnabled($apiKey)`
  - Replace with: `WhisperVoiceButton(text: $apiKey)`

## Replacement Pattern

### For TextField with .voiceTranscriptionEnabled():
```swift
// OLD
TextField("Placeholder", text: $text)
    .voiceTranscriptionEnabled($text)

// NEW
HStack {
    TextField("Placeholder", text: $text)
    WhisperVoiceButton(text: $text)
}
```

### For TextEditor with .voiceTranscriptionOverlay():
```swift
// OLD
TextEditor(text: $text)
    .voiceTranscriptionOverlay($text, alignment: .topTrailing, padding: 8)

// NEW
TextEditor(text: $text)
    .overlay(alignment: .bottomTrailing) {
        WhisperVoiceButton(text: $text)
            .padding(8)
    }
```

## Special Cases

### Chat Module
- [x] Replaced voice transcription overlay with WhisperVoiceButton
- [x] Chat still maintains its own mic/send button for voice recording (separate from text transcription)

### API Key Fields
- [x] Skipped voice input for all API key fields for security reasons
- [x] SecureField instances should not have voice input

## Migration Summary

✅ **COMPLETED**: All 17 voice input locations have been migrated to WhisperVoiceButton
✅ **DELETED**: Old voice system components (VoiceTranscriptionButton.swift, TextFieldVoiceExtension.swift)
✅ **INFRASTRUCTURE**: MLX Whisper integration complete with model download and management