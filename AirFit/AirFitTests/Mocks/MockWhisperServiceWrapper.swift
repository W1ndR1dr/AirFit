import Foundation
import Combine
@testable import AirFit

final class MockWhisperServiceWrapper: WhisperServiceWrapperProtocol {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            currentResultHandler?(.success(mockTranscript))
            currentResultHandler = nil
        }
    }
}
