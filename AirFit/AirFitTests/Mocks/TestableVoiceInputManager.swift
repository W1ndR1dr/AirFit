import Foundation
import AVFoundation
@testable import AirFit

// MARK: - Testable VoiceInputManager

@MainActor
@Observable
final class TestableVoiceInputManager: NSObject {
    // MARK: - Published State
    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var waveformBuffer: [Float] = []
    private(set) var currentTranscription = ""

    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Dependencies (Injectable for testing)
    private let modelManager: MockWhisperModelManager
    private let audioSession: MockAVAudioSession
    private var mockWhisper: MockWhisperKit?
    private var waveformTimer: Timer?
    private var recordingURL: URL?

    // MARK: - Initialization
    init(modelManager: MockWhisperModelManager, audioSession: MockAVAudioSession) {
        self.modelManager = modelManager
        self.audioSession = audioSession
        super.init()

        Task { [weak self] in
            await self?.initializeWhisper()
        }
    }

    // MARK: - Permission
    func requestPermission() async throws -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    // MARK: - Recording Control
    func startRecording() async throws {
        guard try await requestPermission() else { return }
        try await prepareRecorder()
        isRecording = true
        startWaveformTimer()
    }

    func stopRecording() async -> String? {
        guard isRecording else { return nil }
        stopWaveformTimer()
        isRecording = false
        
        do {
            let text = try await transcribeAudio()
            currentTranscription = text
            onTranscription?(text)
            return text
        } catch {
            onError?(error)
            return nil
        }
    }

    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        guard try await requestPermission() else { return }
        guard mockWhisper != nil else { throw VoiceInputError.whisperNotReady }
        isTranscribing = true
        startWaveformTimer()
        
        // Simulate streaming transcription
        Task {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if let result = modelManager.getTranscriptionResult() {
                await MainActor.run {
                    currentTranscription = postProcessTranscription(result)
                    onPartialTranscription?(currentTranscription)
                }
            }
        }
    }

    func stopStreamingTranscription() async {
        guard isTranscribing else { return }
        stopWaveformTimer()
        isTranscribing = false
    }

    // MARK: - Private Setup
    private func initializeWhisper() async {
        if modelManager.getTranscriptionError() != nil {
            await MainActor.run {
                onError?(VoiceInputError.whisperInitializationFailed)
            }
            return
        }
        
        mockWhisper = MockWhisperKit()
        if let result = modelManager.getTranscriptionResult() {
            mockWhisper?.stubTranscriptionResult([MockWhisperKit.TranscriptionResult(text: result)])
        }
    }

    private func prepareRecorder() async throws {
        guard mockWhisper != nil else { throw VoiceInputError.whisperNotReady }
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_recording.wav")
    }

    // MARK: - Transcription
    private func transcribeAudio() async throws -> String {
        guard let whisper = mockWhisper else { throw VoiceInputError.whisperNotReady }
        
        if let error = modelManager.getTranscriptionError() {
            throw error
        }
        
        let result = try await whisper.transcribe(audioPath: "test_path")
        guard !result.isEmpty else { throw VoiceInputError.transcriptionFailed }
        let text = result.map { $0.text }.joined(separator: " ")
        return postProcessTranscription(text)
    }

    // MARK: - Waveform
    private func startWaveformTimer() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Simulate waveform data
                let level = Float.random(in: 0...1)
                self.waveformBuffer.append(level)
                if self.waveformBuffer.count > 50 {
                    self.waveformBuffer.removeFirst()
                }
                self.onWaveformUpdate?(self.waveformBuffer)
            }
        }
    }

    private func stopWaveformTimer() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        waveformBuffer.removeAll()
        onWaveformUpdate?([])
    }

    // MARK: - Fitness-Specific Post-Processing
    private func postProcessTranscription(_ text: String) -> String {
        var processed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Fitness-specific corrections
        let corrections: [String: String] = [
            "sets": "sets", "reps": "reps", "cardio": "cardio",
            "hiit": "HIIT", "amrap": "AMRAP", "emom": "EMOM",
            "pr": "PR", "one rm": "1RM", "tabata": "Tabata"
        ]

        for (pattern, replacement) in corrections {
            processed = processed.replacingOccurrences(
                of: pattern, with: replacement, options: [.caseInsensitive]
            )
        }

        return processed
    }
}
