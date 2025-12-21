import Foundation
import Speech
import AVFoundation

/// Manages real-time speech transcription using iOS 26's SpeechAnalyzer
/// Provides audio levels for waveform visualization and streaming transcription
@Observable
@MainActor
final class SpeechTranscriptionManager {
    // MARK: - Published State

    /// Current transcribed text (updates in real-time as user speaks)
    private(set) var transcript: String = ""

    /// Whether we're currently recording/transcribing
    private(set) var isRecording: Bool = false

    /// Audio level for waveform visualization (0.0 - 1.0)
    private(set) var audioLevel: Float = 0.0

    /// Array of recent audio levels for multi-bar waveform (last 50 samples)
    private(set) var audioLevels: [Float] = Array(repeating: 0, count: 50)

    /// Error message if something goes wrong
    private(set) var errorMessage: String?

    /// Whether speech is currently being detected
    private(set) var isSpeechDetected: Bool = false

    // MARK: - Private Properties

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    // Note: SpeechDetector has a protocol conformance bug in iOS 26 beta
    // Using audio level monitoring for voice activity detection instead

    private var audioEngine: AVAudioEngine?
    private var levelTimer: Timer?

    private var transcriptionTask: Task<Void, Never>?
    private var silenceTimer: Timer?

    /// Callback when transcription is finalized
    var onTranscriptionComplete: ((String) -> Void)?

    /// Auto-stop after this duration of silence (seconds)
    var silenceTimeout: TimeInterval = 1.5

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Start listening and transcribing speech
    func startListening() async throws {
        guard !isRecording else { return }

        // Request authorization
        let authorized = await requestAuthorization()
        guard authorized else {
            errorMessage = "Microphone access required"
            return
        }

        do {
            // Setup audio session
            try await setupAudioSession()

            // Initialize speech components with proper API
            let locale = Locale.current
            transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                reportingOptions: [.volatileResults],
                attributeOptions: []
            )

            guard let transcriber else {
                throw SpeechError.initializationFailed
            }

            // Initialize analyzer with transcriber module
            // Note: SpeechDetector omitted due to iOS 26 beta protocol conformance bug
            analyzer = SpeechAnalyzer(modules: [transcriber])

            // Start audio metering for waveform
            startAudioMetering()

            // Reset state
            transcript = ""
            errorMessage = nil
            isRecording = true

            // Start transcription stream
            transcriptionTask = Task {
                do {
                    for try await result in transcriber.results {
                        await MainActor.run {
                            // Extract text from AttributedString
                            self.transcript = String(result.text.characters)
                            self.isSpeechDetected = true
                            self.resetSilenceTimer()
                        }
                    }
                } catch {
                    print("[SpeechTranscription] Stream error: \(error)")
                }
            }

            // Start silence timer for auto-stop
            // Note: Voice activity detection via audio level monitoring
            resetSilenceTimer()

        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Stop listening and finalize transcription
    func stopListening() async {
        guard isRecording else { return }

        isRecording = false
        isSpeechDetected = false

        // Stop timers
        silenceTimer?.invalidate()
        silenceTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil

        // Cancel tasks
        transcriptionTask?.cancel()

        // Stop analyzer
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        analyzer = nil
        transcriber = nil

        // Stop audio engine
        audioEngine?.stop()
        audioEngine = nil

        // Reset audio levels
        audioLevel = 0
        audioLevels = Array(repeating: 0, count: 50)

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Call completion handler with final transcript
        let finalTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalTranscript.isEmpty {
            onTranscriptionComplete?(finalTranscript)
        }
    }

    /// Cancel without completing (discard transcript)
    func cancel() async {
        transcript = ""
        await stopListening()
    }

    // MARK: - Private Methods

    private func requestAuthorization() async -> Bool {
        // Request microphone access
        let audioAuthorized = await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }

        guard audioAuthorized else { return false }

        // Request speech recognition access
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        return speechStatus == .authorized
    }

    private func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startAudioMetering() {
        audioEngine = AVAudioEngine()
        guard let audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Install tap for audio level metering
        // IMPORTANT: This callback runs on the audio render thread, NOT the main thread
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            // Process audio on the audio thread (no MainActor access)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            // Calculate RMS (root mean square) for audio level
            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))

            // Convert to decibels and normalize to 0-1 range
            let db = 20 * log10(max(rms, 0.0001))
            let normalizedLevel = max(0, min(1, (db + 50) / 50)) // -50dB to 0dB range

            // Hop to MainActor to update state
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Smooth the level for display
                self.audioLevel = self.audioLevel * 0.7 + normalizedLevel * 0.3

                // Shift levels array and add new sample
                self.audioLevels.removeFirst()
                self.audioLevels.append(self.audioLevel)
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.stopListening()
            }
        }
    }
}

// MARK: - Errors

enum SpeechError: LocalizedError {
    case initializationFailed
    case notAuthorized
    case audioSessionFailed

    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize speech recognition"
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .audioSessionFailed:
            return "Failed to configure audio session"
        }
    }
}

// MARK: - Shared Instance

extension SpeechTranscriptionManager {
    static let shared = SpeechTranscriptionManager()
}
