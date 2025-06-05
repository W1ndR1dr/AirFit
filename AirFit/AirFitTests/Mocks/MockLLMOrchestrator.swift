import Foundation
@testable import AirFit

/// Mock LLMOrchestrator for testing
class MockLLMOrchestrator: LLMOrchestrator {
    
    var mockResponse: LLMResponse?
    var shouldThrowError = false
    var mockError: Error = LLMError.invalidResponse("Mock error")
    
    init() {
        super.init(apiKeyManager: MockAPIKeyManager())
    }
    
    override func complete(_ request: LLMRequest) async throws -> LLMResponse {
        if shouldThrowError {
            throw mockError
        }
        
        return mockResponse ?? LLMResponse(
            content: """
            {
                "name": "Test Coach",
                "archetype": "The Balanced Coach",
                "energy": "balanced",
                "warmth": "friendly",
                "formality": "casual"
            }
            """,
            model: request.model ?? "mock",
            usage: LLMResponse.TokenUsage(promptTokens: 100, completionTokens: 200),
            finishReason: .stop,
            metadata: [:]
        )
    }
    
    override func stream(prompt request: LLMRequest) async throws -> AsyncThrowingStream<LLMStreamChunk, Error> {
        if shouldThrowError {
            throw mockError
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate streaming response
                let chunks = ["Test", " response", " streaming"]
                for chunk in chunks {
                    continuation.yield(LLMStreamChunk(
                        delta: chunk,
                        model: request.model ?? "mock",
                        finishReason: nil
                    ))
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                }
                continuation.finish()
            }
        }
    }
}