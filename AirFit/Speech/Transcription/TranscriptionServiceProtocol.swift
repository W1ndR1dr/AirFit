import Foundation

/// Protocol defining the transcription service interface
/// Both WhisperTranscriptionService and SpeechTranscriptionManager conform to this
@MainActor
protocol TranscriptionServiceProtocol: AnyObject, Observable {
    /// Current transcribed text (updates in real-time)
    var transcript: String { get }

    /// Whether currently recording/transcribing
    var isRecording: Bool { get }

    /// Audio level for waveform visualization (0.0 - 1.0)
    var audioLevel: Float { get }

    /// Array of recent audio levels for multi-bar waveform
    var audioLevels: [Float] { get }

    /// Error message if something goes wrong
    var errorMessage: String? { get }

    /// Whether speech is currently being detected
    var isSpeechDetected: Bool { get }

    /// Callback when transcription is finalized
    var onTranscriptionComplete: ((String) -> Void)? { get set }

    /// Auto-stop after this duration of silence (seconds)
    var silenceTimeout: TimeInterval { get set }

    /// Start listening and transcribing speech
    func startListening() async throws

    /// Stop listening and finalize transcription
    func stopListening() async

    /// Cancel without completing (discard transcript)
    func cancel() async
}

// MARK: - Conformance

extension SpeechTranscriptionManager: TranscriptionServiceProtocol {}
extension WhisperTranscriptionService: TranscriptionServiceProtocol {}
