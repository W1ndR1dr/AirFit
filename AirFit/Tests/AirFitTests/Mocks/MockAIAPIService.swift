import Foundation
import Combine

final class MockAIAPIService: AIAPIServiceProtocol {
    var configureCalledWith: (provider: AIProvider, apiKey: String, modelIdentifier: String?)?
    var getStreamingResponseCalledWithRequest: AIRequest?
    var mockStreamingResponsePublisher: AnyPublisher<AIResponseType, Error> = Empty().eraseToAnyPublisher()

    func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
        configureCalledWith = (provider, apiKey, modelIdentifier)
    }

    func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponseType, Error> {
        getStreamingResponseCalledWithRequest = request
        return mockStreamingResponsePublisher
    }
}
