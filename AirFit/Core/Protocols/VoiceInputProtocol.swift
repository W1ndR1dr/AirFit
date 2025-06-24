import Foundation

/// Protocol defining voice input functionality for speech-to-text transcription
@MainActor
protocol VoiceInputProtocol: AnyObject {
    // MARK: - State Properties
    var state: VoiceInputState { get }
    var isRecording: Bool { get }
    var isTranscribing: Bool { get }
    var waveformBuffer: [Float] { get }
    var currentTranscription: String { get }
    
    // MARK: - Callbacks
    var onTranscription: ((String) -> Void)? { get set }
    var onPartialTranscription: ((String) -> Void)? { get set }
    var onWaveformUpdate: (([Float]) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    var onStateChange: ((VoiceInputState) -> Void)? { get set }
    
    // MARK: - Initialization
    func initialize() async
    
    // MARK: - Permission
    func requestPermission() async throws -> Bool
    
    // MARK: - Recording Control
    func startRecording() async throws
    func stopRecording() async -> String?
    
    // MARK: - Streaming Transcription
    func startStreamingTranscription() async throws
    func stopStreamingTranscription() async
}
