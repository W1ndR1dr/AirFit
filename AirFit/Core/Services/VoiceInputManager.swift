import Foundation
import AVFoundation
import WhisperKit

@MainActor
@Observable
final class VoiceInputManager: NSObject {
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

    // MARK: - Private Properties
    private var audioEngine = AVAudioEngine()
    private var audioRecorder: AVAudioRecorder?
    private var waveformTimer: Timer?
    private var audioBuffer: [Float] = []
    private var recordingURL: URL?
    private var whisper: WhisperKit?
    private let modelManager: WhisperModelManager

    private var inputNode: AVAudioInputNode { audioEngine.inputNode }

    // MARK: - Initialization
    init(modelManager: WhisperModelManager = .shared) {
        self.modelManager = modelManager
        super.init()

        Task { [weak self] in
            await self?.initializeWhisper()
        }
    }

    deinit {
        audioRecorder?.stop()
        audioEngine.stop()
        waveformTimer?.invalidate()
    }

    // MARK: - Permission
    func requestPermission() async throws -> Bool {
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
        if !granted { throw VoiceInputError.notAuthorized }
        return granted
    }

    // MARK: - Recording Control
    func startRecording() async throws {
        guard try await requestPermission() else { return }
        try await prepareRecorder()
        audioRecorder?.record()
        isRecording = true
        startWaveformTimer()
    }

    func stopRecording() async -> String? {
        guard let recorder = audioRecorder, recorder.isRecording else { return nil }
        recorder.stop()
        stopWaveformTimer()
        isRecording = false
        guard let url = recordingURL else { return nil }
        do {
            let text = try await transcribeAudio(at: url)
            try? FileManager.default.removeItem(at: url)
            currentTranscription = text
            onTranscription?(text)
            return text
        } catch {
            AppLogger.error("Transcription failed", error: error, category: .ai)
            onError?(error)
            return nil
        }
    }

    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        guard try await requestPermission() else { return }
        guard whisper != nil else { throw VoiceInputError.whisperNotReady }
        if audioEngine.isRunning { audioEngine.stop() }
        audioBuffer.removeAll()
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false)!
        inputNode.installTap(onBus: 0, bufferSize: 8_192, format: format) { [weak self] buffer, _ in
            self?.processStreamingBuffer(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true
        startWaveformTimer()
    }

    func stopStreamingTranscription() async {
        guard audioEngine.isRunning else { return }
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        stopWaveformTimer()
        audioBuffer.removeAll()
        isTranscribing = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Private Setup
    private func initializeWhisper() async {
        let modelID = modelManager.selectOptimalModel()
        do {
            whisper = try await WhisperKit(
                WhisperKitConfig(
                    model: modelID,
                    modelRepo: "mlx-community/whisper-\(modelID)-mlx",
                    modelFolder: modelID,
                    verbose: false,
                    logLevel: .error,
                    prewarm: true,
                    load: true,
                    download: true
                )
            )
        } catch {
            AppLogger.error("Failed to initialize Whisper", error: error, category: .ai)
            onError?(VoiceInputError.whisperInitializationFailed)
        }
    }

    private func prepareRecorder() async throws {
        guard whisper != nil else { throw VoiceInputError.whisperNotReady }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
        audioRecorder?.isMeteringEnabled = true
    }

    // MARK: - Transcription
    private func transcribeAudio(at url: URL) async throws -> String {
        guard let whisper else { throw VoiceInputError.whisperNotReady }
        let result = try await whisper.transcribe(
            audioPath: url.path,
            decodeOptions: DecodingOptions(
                verbose: false,
                task: .transcribe,
                language: "en",
                temperature: 0.0,
                temperatureIncrementOnFallback: 0.2,
                temperatureFallbackCount: 5,
                sampleLength: 224,
                topK: 5,
                usePrefillPrompt: true,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: true,
                wordTimestamps: false,
                clipTimestamps: "0",
                suppressBlank: true,
                supressTokens: nil,
                compressionRatioThreshold: 2.4,
                logprobThreshold: -1.0,
                noSpeechThreshold: 0.6
            )
        )
        guard let segments = result else { throw VoiceInputError.transcriptionFailed }
        let text = segments.map { $0.text }.joined(separator: " ")
        return postProcessTranscription(text)
    }

    private func processAudioChunk(_ audioData: [Float]) async {
        guard let whisper else { return }
        do {
            let result = try await whisper.transcribe(
                audioArray: audioData,
                decodeOptions: DecodingOptions(language: "en", temperature: 0.0, withoutTimestamps: true)
            )
            let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return }
            let processed = postProcessTranscription(text)
            currentTranscription = processed
            onPartialTranscription?(processed)
        } catch {
            AppLogger.debug("Streaming chunk error: \(error)", category: .ai)
        }
    }

    private func processStreamingBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)
        let data = Array(UnsafeBufferPointer(start: channelDataValue, count: frames))
        audioBuffer.append(contentsOf: data)
        if audioBuffer.count >= 16_000 {
            let chunk = Array(audioBuffer.prefix(16_000))
            audioBuffer.removeFirst(16_000)
            Task { await processAudioChunk(chunk) }
        }
        analyzeAudioBuffer(buffer)
    }

    // MARK: - Waveform
    private func startWaveformTimer() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onWaveformUpdate?(self.waveformBuffer)
        }
    }

    private func stopWaveformTimer() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        waveformBuffer.removeAll()
        onWaveformUpdate?([])
    }

    private func updateAudioLevels() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        let normalized = pow(10, level / 20)
        waveformBuffer.append(normalized)
        if waveformBuffer.count > 50 { waveformBuffer.removeFirst() }
    }

    private func analyzeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let data = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelData.pointee[$0] }
        let rms = sqrt(data.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let normalized = min(rms * 10, 1.0)
        waveformBuffer.append(normalized)
        if waveformBuffer.count > 50 { waveformBuffer.removeFirst() }
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

// MARK: - Errors
enum VoiceInputError: LocalizedError, Sendable {
    case notAuthorized
    case whisperInitializationFailed
    case whisperNotReady
    case recordingFailed
    case transcriptionFailed
    case audioEngineError

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Microphone access not authorized"
        case .whisperInitializationFailed:
            return "Failed to initialize Whisper model"
        case .whisperNotReady:
            return "Whisper is not ready for transcription"
        case .recordingFailed:
            return "Audio recording failed"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .audioEngineError:
            return "Audio engine error occurred"
        }
    }
}
