import Foundation

/// Mock implementation of AIServiceProtocol for testing
@MainActor
final class MockAIAPIService: AIServiceProtocol {
    
    // MARK: - Properties
    let serviceIdentifier = "mock-ai-service"
    private(set) var isConfigured: Bool = false
    private(set) var activeProvider: AIProvider = .openAI
    private(set) var availableModels: [AIModel] = []
    
    // Test control properties
    var shouldFail = false
    var failureError: Error = ServiceError.notConfigured
    var responseDelay: TimeInterval = 0
    var mockResponses: [String] = []
    var requestHistory: [AIRequest] = []
    var configureCallCount = 0
    var healthCheckCallCount = 0
    
    // MARK: - Initialization
    init() {
        availableModels = [
            AIModel(id: "mock-model-1", name: "Mock Model 1", contextWindow: 4096),
            AIModel(id: "mock-model-2", name: "Mock Model 2", contextWindow: 8192)
        ]
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        configureCallCount += 1
        
        if shouldFail {
            throw failureError
        }
        
        isConfigured = true
    }
    
    func reset() async {
        isConfigured = false
        activeProvider = .openAI
        mockResponses.removeAll()
        requestHistory.removeAll()
        configureCallCount = 0
        healthCheckCallCount = 0
    }
    
    func healthCheck() async -> ServiceHealth {
        healthCheckCallCount += 1
        
        if !isConfigured {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: "Not configured",
                metadata: [:]
            )
        }
        
        if shouldFail {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: failureError.localizedDescription,
                metadata: [:]
            )
        }
        
        return ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: [
                "provider": activeProvider.rawValue,
                "model": "mock-model"
            ]
        )
    }
    
    // MARK: - AIServiceProtocol
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        configureCallCount += 1
        
        if shouldFail {
            throw failureError
        }
        
        activeProvider = provider
        isConfigured = true
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        requestHistory.append(request)
        
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate network delay
                if self.responseDelay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(self.responseDelay * 1_000_000_000))
                }
                
                // Check for failure
                if self.shouldFail {
                    continuation.finish(throwing: self.failureError)
                    return
                }
                
                // Stream mock responses
                if self.mockResponses.isEmpty {
                    // Default responses
                    continuation.yield(.textDelta("Mock"))
                    continuation.yield(.textDelta(" response"))
                    continuation.yield(.textDelta(" from"))
                    continuation.yield(.textDelta(" AI"))
                    
                    // Check for function call
                    if request.functions != nil {
                        continuation.yield(.functionCall(
                            name: "mockFunction",
                            arguments: "{\"key\": \"value\"}"
                        ))
                    }
                    
                    continuation.yield(.done(usage: AIUsage(
                        promptTokens: 10,
                        completionTokens: 20,
                        totalTokens: 30
                    )))
                } else {
                    // Use provided mock responses
                    for response in self.mockResponses {
                        continuation.yield(.textDelta(response))
                        
                        // Small delay between chunks
                        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    }
                    
                    continuation.yield(.done(usage: AIUsage(
                        promptTokens: 15,
                        completionTokens: 25,
                        totalTokens: 40
                    )))
                }
                
                continuation.finish()
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        if shouldFail {
            throw failureError
        }
        return isConfigured
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Simple mock estimation
        return max(1, text.count / 4)
    }
    
    // MARK: - Test Helpers
    
    func setMockResponses(_ responses: [String]) {
        mockResponses = responses
    }
    
    func addMockResponse(_ response: String) {
        mockResponses.append(response)
    }
    
    func clearHistory() {
        requestHistory.removeAll()
    }
    
    func getLastRequest() -> AIRequest? {
        requestHistory.last
    }
    
    func getAllRequests() -> [AIRequest] {
        requestHistory
    }
}