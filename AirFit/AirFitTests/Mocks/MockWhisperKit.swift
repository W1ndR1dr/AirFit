import Foundation
@testable import AirFit

// MARK: - Mock WhisperKit

final class MockWhisperKit: @unchecked Sendable {
    private let queue = DispatchQueue(label: "MockWhisperKit", attributes: .concurrent)

    private var _transcriptionResult: [TranscriptionResult] = []
    private var _transcriptionError: Error?
    private var _isReady = true

    var transcriptionResult: [TranscriptionResult] {
        get { queue.sync { _transcriptionResult } }
        set { queue.async(flags: .barrier) { self._transcriptionResult = newValue } }
    }

    var transcriptionError: Error? {
        get { queue.sync { _transcriptionError } }
        set { queue.async(flags: .barrier) { self._transcriptionError = newValue } }
    }

    var isReady: Bool {
        get { queue.sync { _isReady } }
        set { queue.async(flags: .barrier) { self._isReady = newValue } }
    }

    struct TranscriptionResult: Sendable {
        let text: String
        let segments: [TranscriptionSegment]

        init(text: String) {
            self.text = text
            self.segments = [TranscriptionSegment(text: text)]
        }
    }

    struct TranscriptionSegment: Sendable {
        let text: String
        let start: Double
        let end: Double

        init(text: String, start: Double = 0.0, end: Double = 1.0) {
            self.text = text
            self.start = start
            self.end = end
        }
    }

    func transcribe(audioPath: String, decodeOptions: MockDecodeOptions? = nil) async throws -> [TranscriptionResult] {
        if let error = transcriptionError {
            throw error
        }

        // Simulate processing time
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        return transcriptionResult
    }

    func transcribe(audioArray: [Float], decodeOptions: MockDecodeOptions? = nil) async throws -> [TranscriptionResult] {
        if let error = transcriptionError {
            throw error
        }

        // Simulate real-time processing
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        return transcriptionResult
    }

    // MARK: - Test Stubbing
    func stubTranscriptionResult(_ result: [TranscriptionResult]) {
        transcriptionResult = result
    }

    func stubTranscriptionError(_ error: Error) {
        transcriptionError = error
    }

    func stubReady(_ ready: Bool) {
        isReady = ready
    }

    // MARK: - Reset
    func reset() {
        transcriptionResult = []
        transcriptionError = nil
        isReady = true
    }
}

// MARK: - Mock Decode Options

struct MockDecodeOptions: Sendable {
    let verbose: Bool
    let task: TranscriptionTask
    let language: String?
    let temperature: Float
    let temperatureIncrementOnFallback: Float
    let temperatureFallbackCount: Int
    let sampleLength: Int
    let topK: Int
    let usePrefillPrompt: Bool
    let usePrefillCache: Bool
    let skipSpecialTokens: Bool
    let withoutTimestamps: Bool
    let wordTimestamps: Bool
    let clipTimestamps: [Double]
    let suppressBlank: Bool
    let supressTokens: [Int]?
    let compressionRatioThreshold: Float
    let logProbThreshold: Float
    let noSpeechThreshold: Float

    init(
        verbose: Bool = false,
        task: TranscriptionTask = .transcribe,
        language: String? = "en",
        temperature: Float = 0.0,
        temperatureIncrementOnFallback: Float = 0.2,
        temperatureFallbackCount: Int = 5,
        sampleLength: Int = 224,
        topK: Int = 5,
        usePrefillPrompt: Bool = true,
        usePrefillCache: Bool = true,
        skipSpecialTokens: Bool = true,
        withoutTimestamps: Bool = true,
        wordTimestamps: Bool = false,
        clipTimestamps: [Double] = [0],
        suppressBlank: Bool = true,
        supressTokens: [Int]? = nil,
        compressionRatioThreshold: Float = 2.4,
        logProbThreshold: Float = -1.0,
        noSpeechThreshold: Float = 0.6
    ) {
        self.verbose = verbose
        self.task = task
        self.language = language
        self.temperature = temperature
        self.temperatureIncrementOnFallback = temperatureIncrementOnFallback
        self.temperatureFallbackCount = temperatureFallbackCount
        self.sampleLength = sampleLength
        self.topK = topK
        self.usePrefillPrompt = usePrefillPrompt
        self.usePrefillCache = usePrefillCache
        self.skipSpecialTokens = skipSpecialTokens
        self.withoutTimestamps = withoutTimestamps
        self.wordTimestamps = wordTimestamps
        self.clipTimestamps = clipTimestamps
        self.suppressBlank = suppressBlank
        self.supressTokens = supressTokens
        self.compressionRatioThreshold = compressionRatioThreshold
        self.logProbThreshold = logProbThreshold
        self.noSpeechThreshold = noSpeechThreshold
    }
}

enum TranscriptionTask: Sendable {
    case transcribe
    case translate
}
