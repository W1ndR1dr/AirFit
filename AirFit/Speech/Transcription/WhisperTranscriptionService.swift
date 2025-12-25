import AVFoundation
import Foundation
import SwiftUI

/// Simple single-model WhisperKit transcription service
/// Records audio with waveform visualization, transcribes when stopped
@Observable
@MainActor
final class WhisperTranscriptionService {

    // MARK: - Published State

    /// Current transcribed text
    private(set) var transcript: String = ""

    /// Whether we're currently recording
    private(set) var isRecording: Bool = false

    /// Audio level for waveform visualization (0.0 - 1.0)
    private(set) var audioLevel: Float = 0.0

    /// Array of recent audio levels for multi-bar waveform
    private(set) var audioLevels: [Float] = Array(repeating: 0, count: 50)

    /// Error message if something goes wrong
    private(set) var errorMessage: String?

    /// Whether speech is currently being detected
    private(set) var isSpeechDetected: Bool = false

    /// Whether model is loaded and ready
    private(set) var isReady: Bool = false

    /// Whether currently transcribing
    private(set) var isPolishing: Bool = false

    // MARK: - Callbacks

    /// Callback when transcription is finalized
    var onTranscriptionComplete: ((String) -> Void)?

    // MARK: - Configuration

    /// Auto-stop after this duration of silence (seconds)
    var silenceTimeout: TimeInterval = 3.0

    // MARK: - Private Properties

    private let audioCapture = AudioCaptureManager()
    private let whisperAdapter = WhisperKitAdapter()
    private let modelManager = ModelManager.shared

    private var audioLevelTask: Task<Void, Never>?
    private var silenceTimer: Timer?
    private var lastSpeechTime: Date?

    // Energy threshold for speech detection
    private let speechThreshold: Float = 0.05

    // Audio level update interval (for smooth waveform)
    private let audioLevelUpdateInterval: TimeInterval = 0.05  // 20 FPS

    // MARK: - Shared Instance

    static let shared = WhisperTranscriptionService()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Load model and prepare for transcription
    /// Uses WhisperKit's built-in model management - downloads automatically if needed
    func prepare() async throws {
        guard !isReady else { return }

        print("[WhisperTranscription] Preparing model...")

        // Get the recommended model variant for this device
        await modelManager.load()
        let selectedModel = modelManager.selectedModelDescriptor()
        let variant = selectedModel?.whisperKitModel ?? ModelCatalog.finalLargeV3Turbo.whisperKitModel

        print("[WhisperTranscription] Loading model variant: \(variant)")

        do {
            // Let WhisperKit handle everything - download + load in one step
            try await whisperAdapter.loadModel(variant: variant)
            print("[WhisperTranscription] Model ready!")
            isReady = true
        } catch {
            print("[WhisperTranscription] Failed to load model: \(error)")
            throw TranscriptionError.transcriptionFailed("Failed to load model: \(error.localizedDescription)")
        }
    }

    /// Start listening - captures audio and shows waveform
    func startListening() async throws {
        guard !isRecording else { return }

        // Request microphone authorization
        let authorized = await requestMicrophoneAuthorization()
        guard authorized else {
            errorMessage = "Microphone access required"
            throw TranscriptionError.notAuthorized
        }

        // Ensure model is loaded
        if !isReady {
            try await prepare()
        }

        // Reset state
        transcript = ""
        errorMessage = nil
        isSpeechDetected = false
        isPolishing = false
        lastSpeechTime = Date()

        // Start audio capture
        try await audioCapture.startCapture()
        isRecording = true

        print("[WhisperTranscription] Recording started")

        // Start continuous audio level updates for waveform
        startAudioLevelUpdates()

        // Start silence detection
        startSilenceDetection()
    }

    /// Stop listening and transcribe
    func stopListening() async {
        guard isRecording else { return }

        print("[WhisperTranscription] Stopping recording...")
        isRecording = false

        // Stop timers and tasks
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioLevelTask?.cancel()
        audioLevelTask = nil

        // Get final audio
        let audioSamples = audioCapture.stopCapture()
        print("[WhisperTranscription] Got \(audioSamples.count) audio samples")

        // Reset audio levels
        audioLevel = 0
        audioLevels = Array(repeating: 0, count: 50)

        // Transcribe if we have audio
        if !audioSamples.isEmpty {
            isPolishing = true

            do {
                print("[WhisperTranscription] Transcribing...")
                let result = try await whisperAdapter.transcribe(audioArray: audioSamples)
                transcript = result.text
                print("[WhisperTranscription] Transcription: \(transcript.prefix(100))...")
            } catch {
                print("[WhisperTranscription] Transcription error: \(error)")
                errorMessage = "Transcription failed: \(error.localizedDescription)"
            }

            isPolishing = false
        }

        isSpeechDetected = false

        // Call completion handler
        let finalTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalTranscript.isEmpty {
            onTranscriptionComplete?(finalTranscript)
        }
    }

    /// Cancel without completing (discard transcript)
    func cancel() async {
        transcript = ""

        // Stop everything
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioLevelTask?.cancel()
        audioLevelTask = nil

        _ = audioCapture.stopCapture()
        isRecording = false
        isSpeechDetected = false
        isPolishing = false
        audioLevel = 0
        audioLevels = Array(repeating: 0, count: 50)
    }

    /// Unload model to free memory
    func unloadModels() async {
        await whisperAdapter.unloadModel()
        isReady = false
    }

    // MARK: - Private Methods

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startAudioLevelUpdates() {
        audioLevelTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled && self.isRecording {
                try? await Task.sleep(for: .seconds(self.audioLevelUpdateInterval))

                guard self.isRecording else { break }

                // Copy current audio levels from capture manager
                let level = self.audioCapture.audioLevel
                let levels = self.audioCapture.audioLevels

                self.audioLevel = level
                self.audioLevels = levels

                // Update speech detection
                self.isSpeechDetected = level > self.speechThreshold
                if self.isSpeechDetected {
                    self.lastSpeechTime = Date()
                }
            }
        }
    }

    private func startSilenceDetection() {
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                guard self.isRecording else {
                    self.silenceTimer?.invalidate()
                    return
                }

                // Check if we've had silence for too long
                if let lastSpeech = self.lastSpeechTime,
                   Date().timeIntervalSince(lastSpeech) > self.silenceTimeout {
                    print("[WhisperTranscription] Silence timeout, stopping...")
                    await self.stopListening()
                }
            }
        }
    }
}

// MARK: - Errors

extension WhisperTranscriptionService {
    enum TranscriptionError: LocalizedError {
        case notAuthorized
        case modelsNotInstalled
        case transcriptionFailed(String)

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Microphone access not authorized"
            case .modelsNotInstalled:
                return "Speech model not installed. Download it in Settings."
            case .transcriptionFailed(let reason):
                return "Transcription failed: \(reason)"
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let thermalWarning = Notification.Name("WhisperTranscriptionThermalWarning")
}
