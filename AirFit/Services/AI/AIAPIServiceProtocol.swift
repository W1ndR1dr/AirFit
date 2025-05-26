import Combine
import Foundation

/// Defines interaction with an AI provider's API.
protocol AIAPIServiceProtocol {
    /// Configure the service with provider, API key, and optional model identifier.
    func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?)

    /// Returns a publisher streaming AI responses for the given request.
    func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponseType, Error>
}
