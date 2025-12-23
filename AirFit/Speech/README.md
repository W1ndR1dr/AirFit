# Speech Module

On-device speech-to-text transcription using WhisperKit.

## Architecture

```
Speech/
├── DeviceInfo/
│   ├── DeviceCapabilities.swift    # hw.machine + RAM detection
│   └── ModelRecommendation.swift   # Device → model mapping
│
├── Models/
│   ├── ModelDescriptor.swift       # Model metadata type
│   ├── ModelCatalog.swift          # Baked-in model catalog
│   ├── ModelStore.swift            # Install state, disk usage
│   ├── ModelDownloader.swift       # HuggingFace downloads
│   └── ModelManager.swift          # Coordinator (main entry point)
│
├── Transcription/
│   ├── AudioCaptureManager.swift           # AVAudioEngine capture
│   ├── WhisperKitAdapter.swift             # WhisperKit API wrapper
│   ├── WhisperTranscriptionService.swift   # Two-stage pipeline
│   └── TranscriptionServiceProtocol.swift  # Common interface
│
└── UI/
    ├── SpeechSettingsView.swift    # Settings screen
    └── ModelRequiredSheet.swift    # First-use download prompt
```

## Two-Stage Pipeline

1. **Stage A (Realtime)**: `whisper-small.en` - Fast partial results while speaking
2. **Stage B (Final)**: `whisper-large-v3-turbo` - High-quality final pass after silence

This provides ChatGPT-like UX: instant feedback with polished final text.

## Models

| ID | Model | Size | Purpose |
|----|-------|------|---------|
| `small-en-realtime` | openai_whisper-small.en_217MB | ~217 MB | Fast realtime partials |
| `large-v3-turbo` | openai_whisper-large-v3-v20240930_turbo_632MB | ~632 MB | Max accuracy (8GB+ RAM) |
| `distil-large-v3` | distil-whisper_distil-large-v3_turbo_600MB | ~600 MB | Battery saver mode |

## Device Recommendations

| Device | RAM | Default Final Model |
|--------|-----|---------------------|
| iPhone 16 Pro | 8 GB | large-v3-turbo |
| iPhone 15 Pro | 8 GB | large-v3-turbo |
| iPhone 15 Plus | 6 GB | distil-large-v3 |

## Storage Locations

- **Models**: `Application Support/WhisperModels/{folderName}/`
- **Temp downloads**: `Caches/WhisperDownloads/`
- **State**: `Application Support/WhisperModels/manifest.json`

## Usage

### Basic Transcription

```swift
let service = WhisperTranscriptionService.shared

// Check for models first
if await ModelManager.shared.hasRequiredModels() {
    try await service.startListening()
    // transcript updates in real-time via @Observable
    // Auto-stops after silence timeout
} else {
    // Show ModelRequiredSheet
}
```

### Settings Integration

Add to SettingsView:
```swift
NavigationLink {
    SpeechSettingsView()
} label: {
    SettingsRow(icon: "waveform", title: "Speech Recognition")
}
```

## Adding New Models

1. Add descriptor to `ModelCatalog.swift`:
```swift
static let newModel = ModelDescriptor(
    id: "new-model-id",
    displayName: "Display Name",
    folderName: "huggingface_folder_name",
    whisperKitModel: "model-name",
    sizeBytes: 500_000_000,
    sha256: nil,
    purpose: .final,
    minRAMGB: 6
)
```

2. Add to `allModels` array
3. Update `ModelRecommendation` logic if needed

## HuggingFace Integration

Models are downloaded from `argmaxinc/whisperkit-coreml`:
- File list API: `https://huggingface.co/api/models/argmaxinc/whisperkit-coreml/tree/main/{folder}`
- File download: `https://huggingface.co/argmaxinc/whisperkit-coreml/resolve/main/{folder}/{path}`

## Future Improvements

- [ ] CDN hosting for faster downloads (single ZIP vs file enumeration)
- [ ] Background URLSession for download-while-backgrounded
- [ ] Punctuation tuning via WhisperKit options
- [ ] Speaker diarization support
- [ ] iOS 26 SpeechAnalyzer hybrid mode (instant draft + WhisperKit polish)
