import AVFoundation
import Foundation

/// Captures audio from the microphone and provides PCM samples for WhisperKit
@Observable
@MainActor
final class AudioCaptureManager {

    // MARK: - Published State

    /// Current audio level (0.0 - 1.0) for waveform visualization
    private(set) var audioLevel: Float = 0.0

    /// Recent audio levels for multi-bar waveform (50 samples)
    private(set) var audioLevels: [Float] = Array(repeating: 0, count: 50)

    /// Whether currently capturing audio
    private(set) var isCapturing: Bool = false

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?

    /// Audio buffer and lock are accessed from audio thread - must be nonisolated(unsafe)
    nonisolated(unsafe) private var audioBuffer: [Float] = []
    nonisolated(unsafe) private let bufferLock = NSLock()

    /// WhisperKit expects 16kHz mono audio
    private static let targetSampleRate: Double = 16000
    private var converter: AVAudioConverter?

    // MARK: - Public API

    /// Start capturing audio from microphone
    func startCapture() async throws {
        guard !isCapturing else { return }

        // Setup audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        // Small delay to ensure session is active
        try await Task.sleep(for: .milliseconds(50))

        // Create audio engine
        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Validate format
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw CaptureError.invalidFormat
        }

        // Create target format (16kHz mono Float32)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw CaptureError.invalidFormat
        }

        // Create converter if needed
        if inputFormat.sampleRate != Self.targetSampleRate || inputFormat.channelCount != 1 {
            converter = AVAudioConverter(from: inputFormat, to: targetFormat)
            converter?.primeMethod = .none
        }

        // Clear previous buffer
        bufferLock.withLock {
            audioBuffer.removeAll()
        }

        // Capture converter for use in audio thread callback
        let capturedConverter = converter

        // Install tap - callback runs on audio thread, NOT main actor
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, converter: capturedConverter)
        }

        // Start engine
        engine.prepare()
        try engine.start()

        isCapturing = true
    }

    /// Stop capturing and return all accumulated audio samples
    func stopCapture() -> [Float] {
        guard isCapturing else { return [] }

        // Stop engine
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        audioEngine = nil
        converter = nil

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        isCapturing = false

        // Reset audio levels
        audioLevel = 0
        audioLevels = Array(repeating: 0, count: 50)

        // Return accumulated buffer
        bufferLock.lock()
        let result = audioBuffer
        audioBuffer.removeAll()
        bufferLock.unlock()

        return result
    }

    /// Get the latest N seconds of audio (for streaming transcription)
    func getLatestChunk(seconds: Double) -> [Float] {
        let samplesNeeded = Int(Self.targetSampleRate * seconds)

        bufferLock.lock()
        defer { bufferLock.unlock() }

        if audioBuffer.count <= samplesNeeded {
            return audioBuffer
        }

        return Array(audioBuffer.suffix(samplesNeeded))
    }

    /// Get current audio buffer length in seconds
    func currentDuration() -> Double {
        bufferLock.lock()
        let count = audioBuffer.count
        bufferLock.unlock()

        return Double(count) / Self.targetSampleRate
    }

    /// Clear the audio buffer (for starting a new segment)
    func clearBuffer() {
        bufferLock.lock()
        audioBuffer.removeAll()
        bufferLock.unlock()
    }

    // MARK: - Private Methods (Audio Thread)

    /// Process audio buffer - called from audio thread, NOT main actor
    nonisolated private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter?) {
        // Convert to target format if needed
        let processedBuffer: AVAudioPCMBuffer
        if let converter = converter {
            guard let converted = convertBuffer(buffer, using: converter) else { return }
            processedBuffer = converted
        } else {
            processedBuffer = buffer
        }

        // Extract Float32 samples
        guard let channelData = processedBuffer.floatChannelData?[0] else { return }
        let frameLength = Int(processedBuffer.frameLength)

        // Append to buffer (thread-safe via lock)
        bufferLock.lock()
        for i in 0..<frameLength {
            audioBuffer.append(channelData[i])
        }
        bufferLock.unlock()

        // Calculate audio level (RMS) and update UI
        calculateAudioLevel(from: buffer)
    }

    nonisolated private func convertBuffer(_ buffer: AVAudioPCMBuffer, using converter: AVAudioConverter) -> AVAudioPCMBuffer? {
        let sampleRateRatio = Self.targetSampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * sampleRateRatio)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.targetSampleRate,
            channels: 1,
            interleaved: false
        ) else { return nil }

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            return nil
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

        if status == .error {
            return nil
        }

        return outputBuffer
    }

    nonisolated private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) {
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

        // Update on main actor
        Task { @MainActor in
            // Smooth the level with exponential moving average
            self.audioLevel = self.audioLevel * 0.7 + normalizedLevel * 0.3

            // Update levels array
            self.audioLevels.removeFirst()
            self.audioLevels.append(self.audioLevel)
        }
    }
}

// MARK: - Errors

extension AudioCaptureManager {
    enum CaptureError: LocalizedError {
        case notAuthorized
        case invalidFormat
        case engineFailed

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Microphone access not authorized"
            case .invalidFormat:
                return "Invalid audio format"
            case .engineFailed:
                return "Audio engine failed to start"
            }
        }
    }
}
