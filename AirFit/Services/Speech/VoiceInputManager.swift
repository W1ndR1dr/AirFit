import Foundation
import AVFoundation
@preconcurrency import WhisperKit

/// Voice input manager using WhisperKit for transcription
@MainActor
final class VoiceInputManager: VoiceInputProtocol {
    // MARK: - State Properties
    private(set) var state: VoiceInputState = .idle
    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var waveformBuffer: [Float] = []
    private(set) var currentTranscription = ""

    // MARK: - Audio Properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioSession: AVAudioSession?
    private var recordingBuffer: AVAudioPCMBuffer?
    private var audioFormat: AVAudioFormat?

    // MARK: - WhisperKit Integration
    private var whisperKit: WhisperKit?
    private var preferredModel: String {
        DeviceCapabilities.isHighEnd ? "large-v3-turbo" : "base"
    }

    // MARK: - Recording Configuration
    private let maxRecordingDuration: TimeInterval = 60.0 // Updated from 30s to 60s
    private let audioSampleRate: Double = 16_000 // WhisperKit expects 16kHz

    // MARK: - Waveform
    private let waveformUpdateInterval: TimeInterval = 0.05 // 20Hz update
    private var waveformTimer: Timer?
    private let maxWaveformSamples = 50

    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)?
    var onPartialTranscription: ((String) -> Void)?
    var onWaveformUpdate: (([Float]) -> Void)?
    var onError: ((Error) -> Void)?
    var onStateChange: ((VoiceInputState) -> Void)?

    // MARK: - Initialization
    init() {
        AppLogger.info("VoiceInputManager initialized with WhisperKit", category: .services)
    }

    deinit {
        // Audio engine cleanup handled in async context
    }

    func initialize() async {
        state = .preparingModel
        onStateChange?(.preparingModel)

        do {
            // Initialize WhisperKit with preferred model
            AppLogger.info("Initializing WhisperKit with model: \(preferredModel)", category: .services)

            // WhisperKit will automatically download the model if needed
            whisperKit = try await WhisperKit(
                model: preferredModel,
                modelFolder: nil,
                computeOptions: ModelComputeOptions(audioEncoderCompute: .cpuAndGPU),
                download: true
            )

            state = .ready
            onStateChange?(.ready)
            AppLogger.info("WhisperKit initialized successfully", category: .services)

        } catch {
            AppLogger.error("Failed to initialize WhisperKit", error: error, category: .services)
            state = .error(.whisperInitializationFailed)
            onStateChange?(state)
            onError?(error)
        }
    }

    // MARK: - Permission
    func requestPermission() async throws -> Bool {
        // WhisperKit doesn't need speech recognition permission, only microphone
        let audioStatus = await AVAudioApplication.requestRecordPermission()
        guard audioStatus else {
            throw VoiceInputError.notAuthorized
        }

        return true
    }

    // MARK: - Recording Control
    func startRecording() async throws {
        guard state == .ready else {
            throw VoiceInputError.whisperNotReady
        }

        guard whisperKit != nil else {
            throw VoiceInputError.whisperInitializationFailed
        }

        // Ensure permissions
        let hasPermission = try await requestPermission()
        guard hasPermission else {
            throw VoiceInputError.notAuthorized
        }

        // Reset state
        waveformBuffer.removeAll()
        currentTranscription = ""

        // Start audio engine
        try startAudioEngine()

        isRecording = true
        state = .recording
        onStateChange?(.recording)

        AppLogger.info("Started recording with WhisperKit", category: .services)
    }

    func stopRecording() async -> String? {
        guard isRecording else { return nil }

        isRecording = false
        state = .transcribing
        onStateChange?(.transcribing)

        // Get captured audio buffer before stopping
        let audioBuffer = recordingBuffer

        // Stop audio engine
        stopAudioEngine()

        // Transcribe with WhisperKit
        guard let whisperKit = whisperKit, let buffer = audioBuffer else {
            state = .ready
            onStateChange?(.ready)
            return nil
        }

        do {
            // Convert audio buffer to file for WhisperKit
            let audioData = try convertBufferToData(buffer)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).wav")

            try writeWAVFile(audioData: audioData, to: tempURL, sampleRate: audioSampleRate)

            // Transcribe with WhisperKit
            let results = try await whisperKit.transcribe(
                audioPath: tempURL.path,
                decodeOptions: DecodingOptions(
                    language: "en",
                    temperature: 0,
                    sampleLength: Int(maxRecordingDuration),
                    usePrefillPrompt: true,
                    skipSpecialTokens: true
                )
            )

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

            // Get the transcription text
            let transcription = results.map { $0.text }.joined(separator: " ")
            currentTranscription = transcription

            state = .ready
            onStateChange?(.ready)

            if !transcription.isEmpty {
                onTranscription?(transcription)
            }

            AppLogger.info("WhisperKit transcription complete: \(transcription)", category: .services)
            return transcription.isEmpty ? nil : transcription

        } catch {
            AppLogger.error("WhisperKit transcription failed", error: error, category: .services)
            state = .error(.transcriptionFailed)
            onStateChange?(state)
            onError?(error)
            return nil
        }
    }

    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws {
        // WhisperKit doesn't support real-time streaming yet
        // Just start recording normally
        try await startRecording()
    }

    func stopStreamingTranscription() async {
        _ = await stopRecording()
    }

    // MARK: - Audio Engine
    private func startAudioEngine() throws {
        // Configure audio session
        audioSession = AVAudioSession.sharedInstance()
        try audioSession?.setCategory(.record, mode: .spokenAudio, options: .duckOthers)
        try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)

        // Create audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw VoiceInputError.recordingFailed("Failed to create audio engine")
        }

        inputNode = audioEngine.inputNode

        // Get recording format (device native, usually 48kHz)
        guard let recordingFormat = inputNode?.outputFormat(forBus: 0) else {
            throw VoiceInputError.recordingFailed("Failed to get recording format")
        }

        audioFormat = recordingFormat

        // Create buffer for recording (60 seconds max at device sample rate)
        let bufferCapacity = AVAudioFrameCount(recordingFormat.sampleRate * maxRecordingDuration)
        recordingBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat, frameCapacity: bufferCapacity)
        recordingBuffer?.frameLength = 0

        // Configure audio tap
        inputNode?.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
            self?.appendToRecordingBuffer(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start waveform timer
        startWaveformTimer()
    }

    private func appendToRecordingBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let recordingBuffer = recordingBuffer,
              let bufferChannelData = buffer.floatChannelData,
              let recordingChannelData = recordingBuffer.floatChannelData else { return }

        let frameLength = buffer.frameLength
        let currentLength = recordingBuffer.frameLength
        let remainingCapacity = recordingBuffer.frameCapacity - currentLength

        // Don't exceed buffer capacity
        let framesToCopy = min(frameLength, remainingCapacity)

        if framesToCopy > 0 {
            // Copy audio data
            for channel in 0..<Int(buffer.format.channelCount) {
                let src = bufferChannelData[channel]
                let dst = recordingChannelData[channel].advanced(by: Int(currentLength))
                memcpy(dst, src, Int(framesToCopy) * MemoryLayout<Float>.size)
            }

            recordingBuffer.frameLength = currentLength + framesToCopy
        }
    }

    private func stopAudioEngine() {
        waveformTimer?.invalidate()
        waveformTimer = nil

        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)

        audioEngine = nil
        audioFormat = nil

        try? audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Audio Processing
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }

        // Calculate RMS for volume level
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let normalizedLevel = min(max(rms * 10, 0), 1) // Normalize to 0-1

        // Update waveform buffer
        Task { @MainActor in
            self.waveformBuffer.append(normalizedLevel)
            if self.waveformBuffer.count > self.maxWaveformSamples {
                self.waveformBuffer.removeFirst()
            }
        }
    }

    private func startWaveformTimer() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: waveformUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isRecording else { return }
                self.onWaveformUpdate?(self.waveformBuffer)
            }
        }
    }

    // MARK: - Audio Conversion
    private func convertBufferToData(_ buffer: AVAudioPCMBuffer) throws -> Data {
        guard let channelData = buffer.floatChannelData else {
            throw VoiceInputError.recordingFailed("Invalid audio format")
        }

        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        _ = MemoryLayout<Float>.size

        var data = Data()

        // Interleave channels if stereo
        for frame in 0..<frameLength {
            for channel in 0..<channelCount {
                let sample = channelData[channel][frame]
                withUnsafeBytes(of: sample) { bytes in
                    data.append(contentsOf: bytes)
                }
            }
        }

        return data
    }

    private func writeWAVFile(audioData: Data, to url: URL, sampleRate: Double) throws {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1 // WhisperKit expects mono
        )!

        let audioFile = try AVAudioFile(
            forWriting: url,
            settings: format.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        // Convert data to PCM buffer
        let frameCount = audioData.count / MemoryLayout<Float>.size
        let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(frameCount)
        )!

        pcmBuffer.frameLength = AVAudioFrameCount(frameCount)

        // Copy audio data
        audioData.withUnsafeBytes { bytes in
            let floatPointer = bytes.bindMemory(to: Float.self)
            if let channelData = pcmBuffer.floatChannelData,
               let baseAddress = floatPointer.baseAddress {
                channelData[0].update(from: baseAddress, count: frameCount)
            }
        }

        // Write to file
        try audioFile.write(from: pcmBuffer)
    }
}
