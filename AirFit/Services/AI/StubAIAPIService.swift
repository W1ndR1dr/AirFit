import Combine
import Foundation

/// Simple stub implementation of ``AIAPIServiceProtocol`` used during
development and in previews.
final class StubAIAPIService: AIAPIServiceProtocol {
    func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
        // No-op
    }

    func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponse, Error> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}
