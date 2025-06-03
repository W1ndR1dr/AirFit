import Combine
import Foundation

enum TranscriptionError: Error {
    case unavailable
    case permissionDenied
    case failedToStart
    case processingError(Error?)
}

/// Interface for speech-to-text transcription services.
protocol WhisperServiceWrapperProtocol {
    var isAvailable: CurrentValueSubject<Bool, Never> { get }
    var isTranscribing: CurrentValueSubject<Bool, Never> { get }

    func requestPermission(completion: @escaping (Bool) -> Void)
    func startTranscription(resultHandler: @escaping (Result<String, TranscriptionError>) -> Void)
    func stopTranscription()
}
