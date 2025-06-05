import Foundation
@testable import AirFit

/// Mock LLMOrchestrator for testing
@MainActor
final class MockLLMOrchestrator {
    
    var mockResponse: LLMResponse?
    var shouldThrowError = false
    var mockError: Error = LLMError.invalidResponse("Mock error")
    
    init() {
        // No super init needed for mock
    }
    
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
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
    
    func stream(prompt request: LLMRequest) async throws -> AsyncThrowingStream<LLMStreamChunk, Error> {
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
                        isFinished: false,
                        usage: nil
                    ))
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                }
                continuation.finish()
            }
        }
    }
}