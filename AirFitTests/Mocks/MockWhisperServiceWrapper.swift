import Foundation
import Combine

final class MockWhisperServiceWrapper: WhisperServiceWrapperProtocol {
    var isAvailable = CurrentValueSubject<Bool, Never>(true)
    var isTranscribing = CurrentValueSubject<Bool, Never>(false)
    var mockTranscript = ""
    var permissionGranted = true
    private var resultHandler: ((Result<String, TranscriptionError>) -> Void)?

    func requestPermission(completion: @escaping (Bool) -> Void) {
        completion(permissionGranted)
    }

    func startTranscription(resultHandler: @escaping (Result<String, TranscriptionError>) -> Void) {
        guard permissionGranted else {
            resultHandler(.failure(.permissionDenied))
            return
        }
        isTranscribing.send(true)
        self.resultHandler = resultHandler
    }

    func stopTranscription() {
        isTranscribing.send(false)
        if let handler = resultHandler {
            handler(.success(mockTranscript))
        }
        resultHandler = nil
    }
}
