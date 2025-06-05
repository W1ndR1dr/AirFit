import Foundation
@testable import AirFit

// MARK: - MockAPIKeyManager
@MainActor
final class MockAPIKeyManager: APIKeyManagementProtocol, MockProtocol {
    // MARK: - MockProtocol (not Sendable, but that's OK for test mocks)
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // Stubbed responses
    var stubbedSaveAPIKeyError: Error?
    var stubbedGetAPIKeyResult: String = "test-api-key"
    var stubbedGetAPIKeyError: Error?
    var stubbedDeleteAPIKeyError: Error?
    var stubbedHasAPIKeyResult: Bool = true
    var stubbedGetAllConfiguredProvidersResult: [AIProvider] = []
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        recordInvocation("saveAPIKey", arguments: key, provider)
        if let error = stubbedSaveAPIKeyError {
            throw error
        }
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String {
        recordInvocation("getAPIKey", arguments: provider)
        if let error = stubbedGetAPIKeyError {
            throw error
        }
        return stubbedGetAPIKeyResult
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        recordInvocation("deleteAPIKey", arguments: provider)
        if let error = stubbedDeleteAPIKeyError {
            throw error
        }
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        recordInvocation("hasAPIKey", arguments: provider)
        return stubbedHasAPIKeyResult
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        recordInvocation("getAllConfiguredProviders")
        return stubbedGetAllConfiguredProvidersResult
    }
}