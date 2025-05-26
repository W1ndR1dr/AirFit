@testable import AirFit
import Combine
import Foundation

struct ConfigureCallData {
    let provider: AIProvider
    let apiKey: String
    let modelIdentifier: String?
}

final class MockAIAPIService: AIAPIServiceProtocol {
    var configureCalledWith: ConfigureCallData?
    var getStreamingResponseCalledWithRequest: AIRequest?
    var mockStreamingResponsePublisher: AnyPublisher<AIResponseType, Error> = Empty().eraseToAnyPublisher()

    func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
        configureCalledWith = ConfigureCallData(provider: provider, apiKey: apiKey, modelIdentifier: modelIdentifier)
    }

    func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponseType, Error> {
        getStreamingResponseCalledWithRequest = request
        return mockStreamingResponsePublisher
    }
}
