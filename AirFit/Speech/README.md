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
│   ├── WhisperTranscriptionService.swift   # Single-pass pipeline
│   └── TranscriptionServiceProtocol.swift  # Common interface
│
└── UI/
    ├── SpeechSettingsView.swift    # Settings screen
    └── ModelRequiredSheet.swift    # First-use download prompt
```

## Single-Pass Pipeline

AirFit records your voice and transcribes the full clip in one pass for consistent accuracy and punctuation.
Model selection is tuned to device RAM, with optional quality modes in Settings.

## Models

| ID | Name | Subtitle | Size | WER | Languages |
|----|------|----------|------|-----|-----------|
| `large-v3-turbo` | Pro | Whisper Large v3 Turbo | ~632 MB | ~2.4% | Multilingual |
| `distil-large-v3` | Standard | Distil-Whisper Large v3 | ~600 MB | ~2.5% | Multilingual |
| `small-en` | Lite | Whisper Small | ~218 MB | ~3.0% | English only |

### Model Details

- **Pro**: OpenAI's Whisper Large v3 with intelligent OD-MBP compression. Highest accuracy available.
- **Standard**: HuggingFace Distil-Whisper, 6x faster than Pro with 99% of the accuracy. Runs cooler.
- **Lite**: Lightweight English-only model. Fast processing, smallest download.

## Device Recommendations

| Device | RAM | Default Mode | Model Used |
|--------|-----|--------------|------------|
| iPhone 16 Pro | 8 GB | Pro | large-v3-turbo |
| iPhone 15 Pro | 8 GB | Pro | large-v3-turbo |
| iPhone 15 Plus | 6 GB | Standard | distil-large-v3 |
| Older devices | 4 GB | Lite | small-en |

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
    displayName: "Name",           // Short name: "Pro", "Standard", "Lite"
    subtitle: "Whisper Model Name", // Technical name for subtitle
    description: "Detailed description for tooltips...",
    folderName: "huggingface_folder_name",
    whisperKitModel: "model-folder-name",
    sizeBytes: 500_000_000,
    sha256: nil,
    purpose: .final,
    minRAMGB: 6,
    languages: nil  // nil = multilingual, ["en"] = English only
)
```

2. Add to `allModels` array (ordered by quality, highest first)
3. Update `ModelRecommendation` logic if needed
4. If changing model IDs, add migration in `ModelStore.migrateModelIds()`

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
