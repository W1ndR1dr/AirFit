@testable import AirFit
import Foundation

@MainActor
final class MockAIService: AIServiceProtocol, MockProtocol {
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // MARK: - ServiceProtocol
    var isConfigured: Bool = true
    var serviceIdentifier: String = "MockAIService"
    
    func configure() async throws {
        recordInvocation("configure")
    }
    
    func reset() async {
        recordInvocation("reset")
        isConfigured = false
    }
    
    func healthCheck() async -> ServiceHealth {
        recordInvocation("healthCheck")
        return ServiceHealth(
            status: isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: ["provider": activeProvider.rawValue]
        )
    }
    
    // MARK: - AIServiceProtocol
    var activeProvider: AIProvider = .openAI
    var availableModels: [AIModel] = [
        AIModel(
            id: "gpt-4",
            name: "GPT-4",
            provider: .openAI,
            contextWindow: 8192,
            costPerThousandTokens: AIModel.TokenCost(input: 0.03, output: 0.06)
        ),
        AIModel(
            id: "claude-3",
            name: "Claude 3",
            provider: .anthropic,
            contextWindow: 100000,
            costPerThousandTokens: AIModel.TokenCost(input: 0.015, output: 0.075)
        )
    ]
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        recordInvocation("configure", arguments: provider.rawValue, apiKey, model ?? "default")
        activeProvider = provider
        isConfigured = true
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        recordInvocation("sendRequest", arguments: request.messages.count)
        
        return AsyncThrowingStream { continuation in
            Task {
                // Simulate streaming response
                let mockResponse = "This is a mock response to your request."
                for word in mockResponse.split(separator: " ") {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms between words
                    continuation.yield(.textDelta(String(word) + " "))
                }
                
                // Final response with usage
                continuation.yield(.done(usage: AITokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30)))
                continuation.finish()
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        recordInvocation("validateConfiguration")
        return isConfigured
    }
    
    func checkHealth() async -> ServiceHealth {
        return await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        recordInvocation("estimateTokenCount", arguments: text.count)
        // Simple mock estimation
        return text.count / 4
    }

    enum MockError: Error {
        case notSet
    }
}

extension UserProfileJsonBlob {
    static var mock: UserProfileJsonBlob {
        UserProfileJsonBlob(
            lifeContext: LifeContext(),
            goal: Goal(),
            blend: Blend(),
            engagementPreferences: EngagementPreferences(),
            sleepWindow: SleepWindow(),
            motivationalStyle: MotivationalStyle()
        )
    }
}
