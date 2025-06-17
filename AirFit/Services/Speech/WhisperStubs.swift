import Foundation
import AVFoundation

// MARK: - WhisperKit Stubs
// Stub implementations to replace WhisperKit functionality without breaking interfaces

/// Stub ModelError enum
enum ModelError: Error, LocalizedError, Sendable {
    case modelNotFound
    case insufficientStorage
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Model not found"
        case .insufficientStorage:
            return "Not enough storage space for model"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        }
    }
}

/// Stub WhisperKit class - provides the same interface but returns mock data
@MainActor
final class WhisperKit: @unchecked Sendable {
    static func detectAvailableLanguages() async -> [String] {
        return ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ko"]
    }
    
    static func recommendedModels() -> [String] {
        return ["tiny", "base", "small", "medium", "large"]
    }
    
    static func download(variant: String) async throws {
        // Simulate download
        try await Task.sleep(for: .seconds(1))
    }
    
    func transcribe(audioPath: String) async throws -> TranscriptionResult {
        // Return mock transcription
        return TranscriptionResult(
            text: "This is a mock transcription result.",
            segments: [],
            language: "en"
        )
    }
    
    func transcribe(audioArray: [Float]) async throws -> TranscriptionResult {
        // Return mock transcription
        return TranscriptionResult(
            text: "Mock transcription from audio array.",
            segments: [],
            language: "en"
        )
    }
}

/// Stub TranscriptionResult
struct TranscriptionResult: Sendable {
    let text: String
    let segments: [TranscriptionSegment]
    let language: String
}

/// Stub TranscriptionSegment
struct TranscriptionSegment: Sendable {
    let text: String
    let start: TimeInterval
    let end: TimeInterval
}

/// Stub VoiceActivityDetector
@MainActor
final class VoiceActivityDetector {
    func voiceActivity(in audioBuffer: AVAudioPCMBuffer) -> Float {
        // Return mock voice activity level
        return Float.random(in: 0.0...1.0)
    }
}

/// Stub AudioProcessor
@MainActor
final class AudioProcessor {
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        // Return mock processed audio
        return Array(repeating: 0.0, count: 1024)
    }
}

/// Stub Progress tracking
struct Progress {
    let fractionCompleted: Double
    let localizedDescription: String
    
    static var discreteProgress: Progress {
        Progress(fractionCompleted: 0.0, localizedDescription: "Starting...")
    }
}

/// Stub WhisperKitConfig
struct WhisperKitConfig {
    let modelPath: String?
    let verbose: Bool
    let logLevel: LogLevel
    let enablePromptPrefill: Bool
    let enableCachePrefill: Bool
    let enableSpecialCharacters: Bool
    let timingLevel: TimingLevel
    let enableBackgroundDownloads: Bool
    let enableOnDeviceEval: Bool
    
    init(
        modelPath: String? = nil,
        verbose: Bool = false,
        logLevel: LogLevel = .error,
        enablePromptPrefill: Bool = false,
        enableCachePrefill: Bool = false,
        enableSpecialCharacters: Bool = false,
        timingLevel: TimingLevel = .disabled,
        enableBackgroundDownloads: Bool = false,
        enableOnDeviceEval: Bool = false
    ) {
        self.modelPath = modelPath
        self.verbose = verbose
        self.logLevel = logLevel
        self.enablePromptPrefill = enablePromptPrefill
        self.enableCachePrefill = enableCachePrefill
        self.enableSpecialCharacters = enableSpecialCharacters
        self.timingLevel = timingLevel
        self.enableBackgroundDownloads = enableBackgroundDownloads
        self.enableOnDeviceEval = enableOnDeviceEval
    }
}

/// Stub LogLevel
enum LogLevel {
    case error
    case warning
    case info
    case debug
}

/// Stub TimingLevel
enum TimingLevel {
    case disabled
    case pipeline
    case audioEngine
}

/// Stub DecodingOptions
struct DecodingOptions {
    let language: String?
    let temperature: Float
    let withoutTimestamps: Bool
    let task: DecodingTask
    let supressTokens: [Int]?
    
    init(
        language: String? = nil,
        temperature: Float = 0.0,
        withoutTimestamps: Bool = false,
        task: DecodingTask = .transcribe,
        supressTokens: [Int]? = nil
    ) {
        self.language = language
        self.temperature = temperature
        self.withoutTimestamps = withoutTimestamps
        self.task = task
        self.supressTokens = supressTokens
    }
}

/// Stub DecodingTask
enum DecodingTask {
    case transcribe
    case translate
}