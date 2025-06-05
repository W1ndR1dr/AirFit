import Foundation
@testable import AirFit

// MARK: - MockAPIKeyManagementProtocol
final class MockAPIKeyManagement: APIKeyManagementProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
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
        recordInvocation("getAllConfiguredProviders", arguments: nil)
        return stubbedGetAllConfiguredProvidersResult
    }
}

// MARK: - MockAPIKeyManager
final class MockAPIKeyManager: APIKeyManagementProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // Stubbed responses
    var stubbedSetAPIKeyError: Error?
    var stubbedGetAPIKeyResult: String? = "test-api-key"
    var stubbedGetAPIKeyError: Error?
    var stubbedRemoveAPIKeyError: Error?
    var stubbedHasAPIKeyResult: Bool = true
    var stubbedGetAllConfiguredProvidersResult: [AIProvider] = []
    
    // Legacy sync methods
    var stubbedSaveAPIKeyError: Error?
    var stubbedDeleteAPIKeyError: Error?
    
    func setAPIKey(_ key: String, for provider: AIProvider) async throws {
        recordInvocation("setAPIKey", arguments: key, provider)
        if let error = stubbedSetAPIKeyError {
            throw error
        }
    }
    
    func getAPIKey(for provider: AIProvider) async throws -> String? {
        recordInvocation("getAPIKey", arguments: provider)
        if let error = stubbedGetAPIKeyError {
            throw error
        }
        return stubbedGetAPIKeyResult
    }
    
    func removeAPIKey(for provider: AIProvider) async throws {
        recordInvocation("removeAPIKey", arguments: provider)
        if let error = stubbedRemoveAPIKeyError {
            throw error
        }
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        recordInvocation("hasAPIKey", arguments: provider)
        return stubbedHasAPIKeyResult
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        recordInvocation("getAllConfiguredProviders", arguments: nil)
        return stubbedGetAllConfiguredProvidersResult
    }
}