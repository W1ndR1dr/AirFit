import Foundation

/// Protocol for voice input adapter specifically for food tracking
@MainActor
protocol FoodVoiceAdapterProtocol: AnyObject, Sendable {
    /// Callbacks for voice events
    var onFoodTranscription: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    var onStateChange: ((VoiceInputState) -> Void)? { get set }
    var onWaveformUpdate: (([Float]) -> Void)? { get set }

    /// Recording state
    var isRecording: Bool { get }
    var transcribedText: String { get }
    var voiceWaveform: [Float] { get }

    /// Initialize voice input system
    func initialize() async

    /// Request microphone permission
    func requestPermission() async throws -> Bool

    /// Start recording voice input
    func startRecording() async throws

    /// Stop recording and return transcribed text
    func stopRecording() async -> String?
}
