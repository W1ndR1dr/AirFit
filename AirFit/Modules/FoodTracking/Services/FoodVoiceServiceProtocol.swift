import Foundation

/// Abstraction for food-specific voice operations.
@MainActor
protocol FoodVoiceServiceProtocol: Sendable {
    /// Indicates whether recording is currently active.
    var isRecording: Bool { get }
    /// Indicates whether streaming transcription is active.
    var isTranscribing: Bool { get }
    /// Last fully transcribed text.
    var transcribedText: String { get }
    /// Waveform samples for UI visualization.
    var voiceWaveform: [Float] { get }

    /// Request microphone permission.
    func requestPermission() async throws -> Bool
    /// Start voice recording.
    func startRecording() async throws
    /// Stop voice recording and return processed transcription.
    func stopRecording() async -> String?

    /// Callback when a food transcription is available.
    var onFoodTranscription: ((String) -> Void)? { get set }
    /// Error callback.
    var onError: ((Error) -> Void)? { get set }
}

/// Errors that can occur in `FoodVoiceAdapter` operations.
enum FoodVoiceError: LocalizedError {
    case voiceInputManagerUnavailable
    case transcriptionFailed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .voiceInputManagerUnavailable:
            return "Voice input manager from Module 13 is not available"
        case .transcriptionFailed:
            return "Failed to transcribe voice input"
        case .permissionDenied:
            return "Microphone permission was denied"
        }
    }
} 