import Foundation
@testable import AirFit

// MARK: - MockLLMProvider
actor MockLLMProvider: LLMProvider, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // LLMProvider conformance
    let identifier: LLMProviderIdentifier = LLMProviderIdentifier(name: "MockProvider", version: "1.0")
    let capabilities: LLMCapabilities = LLMCapabilities(
        maxContextTokens: 100_000,
        supportsJSON: true,
        supportsStreaming: true,
        supportsSystemPrompt: true,
        supportsFunctionCalling: true,
        supportsVision: true
    )
    let costPerKToken: (input: Double, output: Double) = (input: 0.01, output: 0.03)
    
    // Stubbed responses
    var stubbedCompleteResult: LLMResponse = LLMResponse(
        content: "Mock response",
        model: "mock-model",
        usage: LLMResponse.TokenUsage(promptTokens: 100, completionTokens: 50),
        finishReason: .stop,
        metadata: [:]
    )
    var stubbedCompleteError: Error?
    var stubbedStreamChunks: [LLMStreamChunk] = []
    var stubbedStreamError: Error?
    var stubbedValidateAPIKeyResult: Bool = true
    var stubbedValidateAPIKeyError: Error?
    
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        await recordInvocation("complete", arguments: request)
        
        if let error = stubbedCompleteError {
            throw error
        }
        
        return stubbedCompleteResult
    }
    
    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        Task {
            await recordInvocation("stream", arguments: request)
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                if let error = stubbedStreamError {
                    continuation.finish(throwing: error)
                    return
                }
                
                for chunk in stubbedStreamChunks {
                    continuation.yield(chunk)
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                }
                
                continuation.finish()
            }
        }
    }
    
    func validateAPIKey(_ key: String) async throws -> Bool {
        await recordInvocation("validateAPIKey", arguments: key)
        
        if let error = stubbedValidateAPIKeyError {
            throw error
        }
        
        return stubbedValidateAPIKeyResult
    }
    
    // Actor-isolated record invocation
    private func recordInvocation(_ method: String, arguments: Any...) {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        if invocations[method] == nil {
            invocations[method] = []
        }
        invocations[method]?.append(Array(arguments))
    }
    
    // Helper methods for testing (must be called from async context)
    func stubComplete(with response: LLMResponse) {
        stubbedCompleteResult = response
    }
    
    func stubCompleteError(with error: Error) {
        stubbedCompleteError = error
    }
    
    func stubStream(with chunks: [LLMStreamChunk]) {
        stubbedStreamChunks = chunks
    }
    
    func stubStreamError(with error: Error) {
        stubbedStreamError = error
    }
    
    func stubValidateAPIKey(with result: Bool) {
        stubbedValidateAPIKeyResult = result
    }
    
    func stubValidateAPIKeyError(with error: Error) {
        stubbedValidateAPIKeyError = error
    }
    
    // Verify helpers (must be called from async context)
    func verifyComplete(called times: Int = 1) {
        mockLock.lock()
        let actual = invocations["complete"]?.count ?? 0
        mockLock.unlock()
        
        assert(actual == times, "complete was called \(actual) times, expected \(times)")
    }
    
    func verifyStream(called times: Int = 1) {
        mockLock.lock()
        let actual = invocations["stream"]?.count ?? 0
        mockLock.unlock()
        
        assert(actual == times, "stream was called \(actual) times, expected \(times)")
    }
    
    func verifyValidateAPIKey(called times: Int = 1) {
        mockLock.lock()
        let actual = invocations["validateAPIKey"]?.count ?? 0
        mockLock.unlock()
        
        assert(actual == times, "validateAPIKey was called \(actual) times, expected \(times)")
    }
    
    func reset() {
        mockLock.lock()
        defer { mockLock.unlock() }
        
        invocations.removeAll()
        stubbedResults.removeAll()
    }
}