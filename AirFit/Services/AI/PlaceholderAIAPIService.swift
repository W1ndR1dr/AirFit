import Foundation
import Combine

/// Stub implementation of `AIAPIServiceProtocol` used until the real
/// service is available.
actor PlaceholderAIAPIService: AIAPIServiceProtocol {
    func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {}

    func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponse, Error> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}
