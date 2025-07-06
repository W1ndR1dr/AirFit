# Whisper Migration Guide

## Overview
This guide details the complete replacement of all voice systems with a single, unified MLX Whisper implementation featuring premium UX.

## Current State (TO BE DELETED)
- Two separate voice systems: Chat module's recording + standard VoiceTranscriptionButton
- Multiple VoiceInputManager instances (inefficient)
- SFSpeechRecognizer (poor quality)

## Target Architecture

```
┌─────────────────────┐
│   Unified Voice     │
│  Transcription      │ (ONE button style everywhere)
│     Button          │
└──────────┬──────────┘
           │ uses
           ▼
┌─────────────────────┐
│  SharedWhisperMgr   │ (SINGLE shared instance)
└──────────┬──────────┘
           │ uses
           ▼
┌─────────────────────┐
│   MLX Whisper       │ (High-quality local transcription)
└─────────────────────┘
```

## Premium UX Flow

### 1. Idle State
- Waveform icon in bottom-right of text field
- Subtle gradient matching app theme

### 2. Recording State (on tap)
- Text field animates to show live waveform visualization
- Waveform takes up entire text field space
- Real-time audio level visualization
- Haptic feedback on start

### 3. Stop Recording
- Waveform animates into red stop button
- User can tap to stop anytime
- Or auto-stop on silence detection

### 4. Processing State
- "Processing..." animation
- Subtle loading indicator
- Text field temporarily disabled

### 5. Transcription Complete
- Text streams into field character by character
- Smooth animation
- Haptic success feedback

## Onboarding Integration

### Add Whisper Setup Screen
- After HealthKit permissions
- Before any text input screens
- Options:
  - Enable voice transcription
  - Choose model size (small/medium/large)
  - Download model in background
  - Show download progress

## Settings Integration

### Voice Settings Screen (`/Settings/Voice`)
- Model selection (tiny/base/small/medium/large)
- Download/delete models
- Storage usage display
- Test transcription
- Language selection
- Auto-punctuation toggle

## Implementation Plan

### Phase 1: Extract Good UX Patterns
From Chat's voice system, keep:
- Waveform visualization arrays
- Recording state management
- Haptic feedback patterns
- Error handling flows

### Phase 2: Delete Current Systems
1. Remove `VoiceTranscriptionButton.swift`
2. Remove `TextFieldVoiceExtension.swift` modifiers
3. Remove Chat's separate voice recording
4. Delete `VoiceInputManager.swift`

### Phase 3: Build Unified System

#### 3.1 Core Components
```swift
// SharedWhisperManager.swift - Singleton
@MainActor
final class SharedWhisperManager: ObservableObject {
    static let shared = SharedWhisperManager()
    private var whisperModel: WhisperModel?
    @Published var isModelLoaded = false
    @Published var downloadProgress: Double = 0
    
    func loadModel(_ size: ModelSize) async throws
    func transcribe(_ audioBuffer: AVAudioPCMBuffer) async throws -> String
    func deleteModel() async
}

// WhisperVoiceButton.swift - Unified button
struct WhisperVoiceButton: View {
    @Binding var text: String
    @EnvironmentObject private var whisperManager: SharedWhisperManager
    @State private var recordingState: RecordingState = .idle
    @State private var waveformLevels: [Float] = []
    
    enum RecordingState {
        case idle
        case recording
        case processing
        case streaming(progress: Double)
    }
}
```

#### 3.2 Button Placement
- Always bottom-right of text field
- Overlay positioning for TextEditor
- Trailing position for TextField
- Consistent 8pt padding

### Phase 4: Animate Everything

1. **Tap to Record**: 
   - Button scales down slightly
   - Waveform icon fades out
   - Recording view expands to fill text field

2. **During Recording**:
   - Live waveform visualization
   - Pulse animation on levels
   - Red recording indicator

3. **Stop Recording**:
   - Waveform morphs into stop button
   - Smooth color transition

4. **Processing**:
   - Shimmer effect
   - "Thinking" dots animation

5. **Text Streaming**:
   - Character-by-character appearance
   - Cursor animation

## Files to Delete
1. `/AirFit/Services/Speech/VoiceInputManager.swift`
2. `/AirFit/Core/Views/VoiceTranscriptionButton.swift`
3. `/AirFit/Core/Views/TextFieldVoiceExtension.swift`
4. All `.voiceTranscriptionEnabled()` and `.voiceTranscriptionOverlay()` modifiers

## New Files to Create
1. `/AirFit/Services/Speech/SharedWhisperManager.swift` - Singleton manager
2. `/AirFit/Core/Views/WhisperVoiceButton.swift` - Unified button component
3. `/AirFit/Core/Views/WhisperVoiceOverlay.swift` - Recording overlay view
4. `/AirFit/Modules/Settings/Views/VoiceSettingsView.swift` - Model management
5. `/AirFit/Modules/Onboarding/Views/WhisperSetupView.swift` - Onboarding screen

## Simple Integration Pattern
```swift
// For any TextField:
TextField("Placeholder", text: $text)
    .overlay(alignment: .bottomTrailing) {
        WhisperVoiceButton(text: $text)
            .padding(8)
    }

// For any TextEditor:
TextEditor(text: $text)
    .overlay(alignment: .bottomTrailing) {
        WhisperVoiceButton(text: $text)
            .padding(8)
    }
```

## All 17 Text Input Locations

See `/Docs/WHISPER_MIGRATION_CHECKLIST.md` for the complete list with line numbers.

## Performance Benchmarks

Track these metrics during migration:
- Transcription latency (target: <500ms after speech ends)
- Memory usage (target: <100MB for model)
- Battery impact (target: <5% per hour of use)
- Accuracy (target: >95% for common English)

## Rollback Plan

If issues arise:
1. Disable feature flag
2. Falls back to SFSpeechRecognizer automatically
3. No UI changes required

## Key Technical Decisions

### Audio Processing
- 16kHz mono audio for Whisper (downsample from 48kHz)
- 30-second max recording duration
- VAD (Voice Activity Detection) for auto-stop
- Ring buffer for continuous recording

### Model Management
- Download models on-demand (not bundled)
- Store in app's Documents directory
- Model sizes:
  - Tiny: ~39MB (fast, lower quality)
  - Base: ~74MB (balanced)
  - Small: ~244MB (recommended)
  - Medium: ~769MB (best quality)
  - Large: ~1550MB (overkill for mobile)

### Performance Optimization
- Metal acceleration via MLX
- Batch processing for efficiency
- Background queue for transcription
- Streaming output for better UX

## Success Criteria

- [ ] ONE unified voice system across entire app
- [ ] Whisper quality >> SFSpeechRecognizer
- [ ] Premium animations and UX
- [ ] Model management in Settings
- [ ] Onboarding integration
- [ ] <2 second processing time for 10 second audio
- [ ] Smooth text streaming output
- [ ] Works offline after model download