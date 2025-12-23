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
    private var audioEngine: AVAudioEngine?
    private var audioConverter: AVAudioConverter?
    private var analyzerFormat: AVAudioFormat?

    // AsyncStream for feeding audio to SpeechAnalyzer
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?

    private var transcriptionTask: Task<Void, Never>?
    private var analyzerTask: Task<Void, Never>?
    private var silenceTimer: Timer?

    /// Callback when transcription is finalized
    var onTranscriptionComplete: ((String) -> Void)?

    /// Auto-stop after this duration of silence (seconds)
    var silenceTimeout: TimeInterval = 2.0

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
            throw SpeechError.notAuthorized
        }

        do {
            // Setup audio session first
            try await setupAudioSession()

            // Initialize speech transcriber
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

            // Create analyzer with transcriber module
            analyzer = SpeechAnalyzer(modules: [transcriber])

            guard let analyzer else {
                throw SpeechError.initializationFailed
            }

            // Get the optimal audio format for the analyzer
            // This is CRITICAL - microphone format may differ from what analyzer expects
            analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

            guard let analyzerFormat else {
                print("[SpeechTranscription] Could not get analyzer format")
                throw SpeechError.audioSessionFailed
            }

            print("[SpeechTranscription] Analyzer format: \(analyzerFormat)")

            // Create async stream for audio input
            let (inputStream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
            self.inputContinuation = continuation

            // Reset state
            transcript = ""
            errorMessage = nil
            isRecording = true

            // Start analyzer with input stream (runs in background)
            analyzerTask = Task {
                do {
                    try await analyzer.start(inputSequence: inputStream)
                } catch {
                    print("[SpeechTranscription] Analyzer error: \(error)")
                    self.errorMessage = error.localizedDescription
                }
            }

            // Start listening for transcription results
            transcriptionTask = Task { [weak self] in
                do {
                    for try await result in transcriber.results {
                        await MainActor.run {
                            guard let self else { return }
                            self.transcript = String(result.text.characters)
                            self.isSpeechDetected = true
                            self.resetSilenceTimer()
                        }
                    }
                } catch {
                    print("[SpeechTranscription] Stream error: \(error)")
                }
            }

            // Start audio engine - must happen after analyzer is set up
            try startAudioEngine()

            // Start silence timer for auto-stop
            resetSilenceTimer()

        } catch {
            // Clean up on failure
            await cleanup()
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Stop listening and finalize transcription
    func stopListening() async {
        guard isRecording else { return }
        isRecording = false
        isSpeechDetected = false

        // Stop silence timer
        silenceTimer?.invalidate()
        silenceTimer = nil

        // Finish the input stream - signals end of audio
        inputContinuation?.finish()
        inputContinuation = nil

        // Wait briefly for final results
        try? await Task.sleep(for: .milliseconds(100))

        // Cancel tasks
        transcriptionTask?.cancel()
        analyzerTask?.cancel()

        // Finalize analyzer
        try? await analyzer?.finalizeAndFinishThroughEndOfInput()

        await cleanup()

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

    private func cleanup() async {
        // Stop audio engine
        if let audioEngine {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        audioEngine = nil
        audioConverter = nil

        // Clear speech components
        analyzer = nil
        transcriber = nil
        analyzerFormat = nil

        // Reset audio levels
        audioLevel = 0
        audioLevels = Array(repeating: 0, count: 50)

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

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

        // Small delay to ensure session is fully active
        try await Task.sleep(for: .milliseconds(50))
    }

    private func startAudioEngine() throws {
        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let microphoneFormat = inputNode.outputFormat(forBus: 0)

        // Validate microphone format
        guard microphoneFormat.sampleRate > 0, microphoneFormat.channelCount > 0 else {
            print("[SpeechTranscription] Invalid microphone format: \(microphoneFormat)")
            throw SpeechError.audioSessionFailed
        }

        print("[SpeechTranscription] Microphone format: \(microphoneFormat)")

        // Create converter if formats differ
        if let analyzerFormat, microphoneFormat != analyzerFormat {
            audioConverter = AVAudioConverter(from: microphoneFormat, to: analyzerFormat)
            audioConverter?.primeMethod = .none
            print("[SpeechTranscription] Created converter: \(microphoneFormat.sampleRate)Hz -> \(analyzerFormat.sampleRate)Hz")
        }

        // Capture references for the audio tap closure
        let continuation = self.inputContinuation
        let converter = self.audioConverter
        let targetFormat = self.analyzerFormat

        // Install tap for audio capture
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: microphoneFormat) { [weak self] buffer, _ in
            // Convert buffer if needed, then yield to analyzer
            do {
                let bufferToYield: AVAudioPCMBuffer
                if let converter, let targetFormat {
                    bufferToYield = try Self.convertBuffer(buffer, using: converter, to: targetFormat)
                } else {
                    bufferToYield = buffer
                }
                continuation?.yield(AnalyzerInput(buffer: bufferToYield))
            } catch {
                print("[SpeechTranscription] Buffer conversion error: \(error)")
            }

            // Calculate audio level for waveform (runs on audio thread)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)

            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            let db = 20 * log10(max(rms, 0.0001))
            let normalizedLevel = max(0, min(1, (db + 50) / 50))

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioLevel = self.audioLevel * 0.7 + normalizedLevel * 0.3
                self.audioLevels.removeFirst()
                self.audioLevels.append(self.audioLevel)
            }
        }

        engine.prepare()
        try engine.start()
    }

    /// Convert audio buffer to target format
    private static func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        to targetFormat: AVAudioFormat
    ) throws -> AVAudioPCMBuffer {
        let sampleRateRatio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * sampleRateRatio)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            throw SpeechError.audioSessionFailed
        }

        var error: NSError?
        var inputBufferConsumed = false

        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputBufferConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputBufferConsumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        if status == .error, let error {
            throw error
        }

        return outputBuffer
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
