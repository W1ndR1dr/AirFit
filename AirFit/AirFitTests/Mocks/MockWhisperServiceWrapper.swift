@testable import AirFit
import Combine
import Foundation

final class MockWhisperServiceWrapper: WhisperServiceWrapperProtocol, @unchecked Sendable {
    var isAvailable = CurrentValueSubject<Bool, Never>(true)
    var isTranscribing = CurrentValueSubject<Bool, Never>(false)

    var mockTranscript: String = ""
    var permissionGranted: Bool = true
    private var currentResultHandler: ((Result<String, TranscriptionError>) -> Void)?

    func requestPermission(completion: @escaping (Bool) -> Void) {
        completion(permissionGranted)
    }

    func startTranscription(resultHandler: @escaping (Result<String, TranscriptionError>) -> Void) {
        guard permissionGranted else {
            resultHandler(.failure(.permissionDenied))
            return
        }
        isTranscribing.send(true)
        currentResultHandler = resultHandler
    }

    func stopTranscription() {
        isTranscribing.send(false)
        let transcript = mockTranscript
        if let handler = currentResultHandler {
            currentResultHandler = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                handler(.success(transcript))
            }
        }
    }

    func reset() {
        isAvailable.send(true)
        isTranscribing.send(false)
        mockTranscript = ""
        permissionGranted = true
        currentResultHandler = nil
    }
}
