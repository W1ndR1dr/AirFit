import Foundation

/// Stub implementation of Whisper model manager
/// TODO: Replace with actual implementation when Whisper integration is enabled
@MainActor
final class WhisperModelManager {
    enum ModelError: Error {
        case modelNotFound
        case insufficientStorage
        case downloadFailed(reason: String)
    }

    init() {
        AppLogger.info("WhisperModelManager initialized (stub)", category: .services)
    }
}
