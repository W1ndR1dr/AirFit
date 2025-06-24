import Foundation
@testable import AirFit

/// Mock LLMOrchestrator for testing
@MainActor
final class MockLLMOrchestrator {
    
    // MARK: - Mock Properties
    var mockResponse: LLMResponse?
    var mockStreamChunks: [LLMStreamChunk] = []
    var shouldThrowError = false
    var mockError: Error = LLMError.invalidResponse("Mock error")
    
    // MARK: - Tracking Properties
    var completeCallCount = 0
    var streamCallCount = 0
    var lastPrompt = ""
    var lastRequest: LLMRequest?
    var estimateCostCallCount = 0
    
    // MARK: - Mock Available Providers
    var mockAvailableProviders: Set<LLMProviderIdentifier> = [.anthropic, .openai, .google]
    
    let apiKeyManager: APIKeyManagementProtocol
    
    init(apiKeyManager: APIKeyManagementProtocol = MockAPIKeyManager()) {
        self.apiKeyManager = apiKeyManager
    }
    
    // MARK: - Test Helper Methods
    
    func setShouldThrowError(_ value: Bool) {
        self.shouldThrowError = value
    }
    
    // MARK: - LLMOrchestrator-like Methods
    
    func complete(
        prompt: String,
        task: AITask,
        model: LLMModel? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> LLMResponse {
        completeCallCount += 1
        lastPrompt = prompt
        
        if shouldThrowError {
            throw mockError
        }
        
        // Track the request
        lastRequest = LLMRequest(
            messages: [LLMMessage(role: .user, content: prompt, name: nil, attachments: nil)],
            model: model?.identifier ?? task.recommendedModels.first!.identifier,
            temperature: temperature,
            maxTokens: maxTokens,
            systemPrompt: nil,
            responseFormat: nil,
            stream: false,
            metadata: ["task": String(describing: task)],
            thinkingBudgetTokens: nil
        )
        
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
            model: model?.identifier ?? "claude-3-sonnet",
            usage: LLMResponse.TokenUsage(promptTokens: 100, completionTokens: 200),
            finishReason: .stop,
            metadata: [:]
        )
    }
    
    func stream(
        prompt: String,
        task: AITask,
        model: LLMModel? = nil,
        temperature: Double = 0.7
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        streamCallCount += 1
        lastPrompt = prompt
        
        return AsyncThrowingStream { continuation in
            Task {
                if self.shouldThrowError {
                    continuation.finish(throwing: self.mockError)
                    return
                }
                
                // Use mockStreamChunks if provided
                if !self.mockStreamChunks.isEmpty {
                    for chunk in self.mockStreamChunks {
                        continuation.yield(chunk)
                    }
                } else {
                    // Default streaming response
                    let chunks = ["Test", " response", " streaming"]
                    for (index, chunk) in chunks.enumerated() {
                        let isLast = index == chunks.count - 1
                        continuation.yield(LLMStreamChunk(
                            delta: chunk,
                            isFinished: isLast,
                            usage: isLast ? LLMResponse.TokenUsage(promptTokens: 50, completionTokens: 10) : nil
                        ))
                    }
                }
                
                continuation.finish()
            }
        }
    }
    
    func estimateCost(for prompt: String, model: LLMModel, responseTokens: Int = 1_000) -> Double {
        estimateCostCallCount += 1
        // Simple mock cost calculation
        return Double(prompt.count + responseTokens) * 0.00001
    }
    
    // MARK: - Test Helpers
    
    func reset() {
        completeCallCount = 0
        streamCallCount = 0
        lastPrompt = ""
        lastRequest = nil
        estimateCostCallCount = 0
        mockResponse = nil
        mockStreamChunks = []
        shouldThrowError = false
    }
}
