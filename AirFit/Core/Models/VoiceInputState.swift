import Foundation

/// Represents the current state of the voice input system
enum VoiceInputState: Equatable, Sendable {
    case idle
    case downloadingModel(progress: Double, modelName: String)
    case preparingModel
    case ready
    case recording
    case transcribing
    case error(VoiceInputError)
    
    var isInteractable: Bool {
        switch self {
        case .ready, .recording, .transcribing:
            return true
        case .idle, .downloadingModel, .preparingModel, .error:
            return false
        }
    }
    
    var statusMessage: String {
        switch self {
        case .idle:
            return "Initializing voice input..."
        case .downloadingModel(let progress, let modelName):
            return "Downloading \(modelName) model: \(Int(progress * 100))%"
        case .preparingModel:
            return "Preparing voice model..."
        case .ready:
            return "Ready to record"
        case .recording:
            return "Recording..."
        case .transcribing:
            return "Transcribing..."
        case .error(let error):
            return error.localizedDescription
        }
    }
}

/// Errors specific to voice input functionality
enum VoiceInputError: LocalizedError, Equatable {
    case notAuthorized
    case whisperNotReady
    case whisperInitializationFailed
    case modelDownloadFailed(String)
    case transcriptionFailed
    case recordingFailed(String)
    case noAudioDetected
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Microphone access not authorized"
        case .whisperNotReady:
            return "Voice model not ready"
        case .whisperInitializationFailed:
            return "Failed to initialize voice model"
        case .modelDownloadFailed(let reason):
            return "Model download failed: \(reason)"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .noAudioDetected:
            return "No audio detected"
        }
    }
}