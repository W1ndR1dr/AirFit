import Foundation

/// Production AI service that adapts between the simple interface and full AI capabilities
@MainActor
final class ProductionAIService: AIServiceProtocol {
    
    // MARK: - Properties
    let serviceIdentifier = "production-ai-service"
    private(set) var isConfigured: Bool = false
    private(set) var activeProvider: AIProvider = .anthropic
    private(set) var availableModels: [AIModel] = []
    
    private let unifiedService: UnifiedAIService
    private let apiKeyManager: APIKeyManagerProtocol
    
    // MARK: - Initialization
    init(apiKeyManager: APIKeyManagerProtocol) async {
        self.apiKeyManager = apiKeyManager
        self.unifiedService = await UnifiedAIService(apiKeyManager: apiKeyManager)
        
        // Initialize available models
        self.availableModels = [
            AIModel(
                id: "claude-3-sonnet-20240229",
                name: "Claude 3 Sonnet",
                provider: .anthropic,
                contextWindow: 200_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0.003, output: 0.015)
            ),
            AIModel(
                id: "gpt-4-turbo-preview",
                name: "GPT-4 Turbo",
                provider: .openAI,
                contextWindow: 128_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0.01, output: 0.03)
            ),
            AIModel(
                id: "gemini-1.5-pro",
                name: "Gemini 1.5 Pro",
                provider: .gemini,
                contextWindow: 2_097_152,
                costPerThousandTokens: AIModel.TokenCost(input: 0.00125, output: 0.00375)
            )
        ]
    }
    
    // MARK: - ServiceProtocol
    func configure() async throws {
        // Check which providers have API keys
        let hasAnthropicKey = await apiKeyManager.hasAPIKey(for: .anthropic)
        let hasOpenAIKey = await apiKeyManager.hasAPIKey(for: .openAI)
        let hasGeminiKey = await apiKeyManager.hasAPIKey(for: .gemini)
        
        guard hasAnthropicKey || hasOpenAIKey || hasGeminiKey else {
            throw ServiceError.notConfigured
        }
        
        // Set active provider based on available keys
        if hasAnthropicKey {
            activeProvider = .anthropic
        } else if hasOpenAIKey {
            activeProvider = .openAI
        } else if hasGeminiKey {
            activeProvider = .gemini
        }
        
        isConfigured = true
        AppLogger.info("Production AI Service configured with provider: \(activeProvider.rawValue)", category: .ai)
    }
    
    func reset() async {
        isConfigured = false
        activeProvider = .anthropic
    }
    
    func healthCheck() async -> ServiceHealth {
        guard isConfigured else {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: "Service not configured",
                metadata: [:]
            )
        }
        
        return ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: ["provider": activeProvider.rawValue]
        )
    }
    
    // MARK: - AIServiceProtocol
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        // Save the API key
        try await apiKeyManager.setAPIKey(apiKey, for: provider)
        
        // Update active provider
        activeProvider = provider
        
        // Configure the service
        try await configure()
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Convert AIRequest to format expected by UnifiedAIService
                    let messages = request.messages.map { msg in
                        AIChatMessage(
                            role: msg.role,
                            content: msg.content,
                            name: msg.name
                        )
                    }
                    
                    let aiRequest = AIRequest(
                        systemPrompt: request.systemPrompt,
                        messages: messages,
                        functions: request.functions,
                        temperature: request.temperature,
                        maxTokens: request.maxTokens,
                        stream: request.stream,
                        user: "user"
                    )
                    
                    // Send through unified service using Combine publisher
                    let publisher = unifiedService.getStreamingResponse(for: aiRequest)
                    
                    for try await response in publisher.values {
                        continuation.yield(response)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        guard isConfigured else {
            return false
        }
        
        // Check if the current provider has a valid API key
        return await apiKeyManager.hasAPIKey(for: activeProvider)
    }
    
    func checkHealth() async -> ServiceHealth {
        return await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Simple estimation: ~4 characters per token
        return text.count / 4
    }
    
    // MARK: - Legacy Support
    
    /// Analyze a goal using AI (legacy method for backward compatibility)
    func analyzeGoal(_ goalText: String) async throws -> String {
        guard isConfigured else {
            throw ServiceError.notConfigured
        }
        
        let systemPrompt = """
        You are a fitness and nutrition coach. Analyze the user's goal and provide brief, 
        actionable advice. Keep your response under 3 sentences and focus on practical steps.
        """
        
        let request = AIRequest(
            systemPrompt: systemPrompt,
            messages: [AIChatMessage(role: .user, content: goalText, name: nil)],
            functions: nil,
            temperature: 0.7,
            maxTokens: 150,
            stream: false,
            user: "user"
        )
        
        var responseText = ""
        for try await response in sendRequest(request) {
            switch response {
            case .text(let content):
                responseText = content
            case .textDelta(let delta):
                responseText += delta
            default:
                break
            }
        }
        
        return responseText.isEmpty ? "I'll help you achieve your fitness goals! Let's create a personalized plan together." : responseText
    }
}