import Foundation
@testable import AirFit

final class MockAPIKeyManager: APIKeyManagerProtocol {
    var savedKeys: [AIProvider: String] = [:]
    var saveAPIKeyCalledWith: (key: String, provider: AIProvider)?
    var getAPIKeyCalledWithProvider: AIProvider?
    var deleteAPIKeyCalledWithProvider: AIProvider?

    func saveAPIKey(_ apiKey: String, forProvider provider: AIProvider) throws {
        savedKeys[provider] = apiKey
        saveAPIKeyCalledWith = (apiKey, provider)
    }

    func getAPIKey(forProvider provider: AIProvider) -> String? {
        getAPIKeyCalledWithProvider = provider
        return savedKeys[provider]
    }

    func deleteAPIKey(forProvider provider: AIProvider) throws {
        deleteAPIKeyCalledWithProvider = provider
        savedKeys[provider] = nil
    }
}
