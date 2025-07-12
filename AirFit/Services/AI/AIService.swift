import Foundation

/// Streamlined AI Service - Direct provider management without unnecessary layers
actor AIService: AIServiceProtocol {
    
    // MARK: - Properties
    nonisolated let serviceIdentifier = "ai-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { 
        // TODO: Make this properly async once we update protocol
        true 
    }
    
    // Provider management
    private var providers: [LLMProviderIdentifier: any LLMProvider] = [:]
    private var _activeProvider: AIProvider = .gemini
    nonisolated var activeProvider: AIProvider { 
        // TODO: Make this properly async once we update protocol
        // For now, return the default provider
        .gemini 
    }
    private var currentModel: String = LLMModel.gemini25Flash.identifier
    
    // Dependencies
    private let apiKeyManager: APIKeyManagementProtocol
    
    // Simple cost tracking
    private(set) var totalCost: Double = 0
    
    // Available models - simplified from complex runtime discovery
    nonisolated var availableModels: [AIModel] {
        [
            AIModel(
                id: LLMModel.gemini25Flash.identifier,
                name: "Gemini 2.5 Flash",
                provider: .gemini,
                contextWindow: 1_000_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0.0001, output: 0.0003)
            ),
            AIModel(
                id: LLMModel.claude4Sonnet.identifier,
                name: "Claude 4 Sonnet",
                provider: .anthropic,
                contextWindow: 200_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0.003, output: 0.015)
            ),
            AIModel(
                id: LLMModel.gpt4o.identifier,
                name: "GPT-4o",
                provider: .openAI,
                contextWindow: 128_000,
                costPerThousandTokens: AIModel.TokenCost(input: 0.0025, output: 0.01)
            )
        ]
    }
    
    // MARK: - Initialization
    
    init(apiKeyManager: APIKeyManagementProtocol) {
        self.apiKeyManager = apiKeyManager
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        guard !_isConfigured else { return }
        
        // Setup providers based on available API keys
        await setupProviders()
        
        // Ensure we have at least one provider
        guard !providers.isEmpty else {
            throw AppError.from(ServiceError.notConfigured)
        }
        
        _isConfigured = true
        AppLogger.info("AI Service configured with \(providers.count) providers", category: .ai)
    }
    
    func reset() async {
        providers.removeAll()
        _isConfigured = false
        totalCost = 0
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: ["providers": providers.count.description]
        )
    }
    
    // MARK: - AIServiceProtocol
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        try await apiKeyManager.saveAPIKey(apiKey, for: provider)
        _activeProvider = provider
        if let model = model {
            currentModel = model
        }
        try await configure()
    }
    
    nonisolated func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let isConfigured = await self._isConfigured
                    guard isConfigured else {
                        throw AppError.from(ServiceError.notConfigured)
                    }
                    
                    // Convert AIRequest to LLMRequest
                    let llmRequest = await self.buildLLMRequest(from: request)
                    
                    // Get the appropriate provider
                    guard let provider = await self.providers[self._activeProvider.toLLMProviderIdentifier()] else {
                        throw AppError.llm("AI provider not available")
                    }
                    
                    if request.stream {
                        // Handle streaming
                        let stream = await provider.stream(llmRequest)
                        var fullResponse = ""
                        
                        for try await chunk in stream {
                            fullResponse += chunk.delta
                            continuation.yield(.textDelta(chunk.delta))
                            
                            if chunk.isFinished {
                                let usage = AITokenUsage(
                                    promptTokens: chunk.usage?.promptTokens ?? 0,
                                    completionTokens: chunk.usage?.completionTokens ?? 0,
                                    totalTokens: chunk.usage?.totalTokens ?? 0
                                )
                                
                                await self.trackCost(usage: usage, model: llmRequest.model)
                                continuation.yield(.done(usage: usage))
                            }
                        }
                    } else {
                        // Handle single response
                        let response = try await provider.complete(llmRequest)
                        
                        // Handle structured data if present
                        if let structuredData = response.structuredData {
                            continuation.yield(.structuredData(structuredData))
                        } else {
                            continuation.yield(.text(response.content))
                        }
                        
                        let usage = AITokenUsage(
                            promptTokens: response.usage.promptTokens,
                            completionTokens: response.usage.completionTokens,
                            totalTokens: response.usage.totalTokens
                        )
                        
                        await self.trackCost(usage: usage, model: llmRequest.model)
                        continuation.yield(.done(usage: usage))
                    }
                    
                    continuation.finish()
                } catch {
                    let userError = self.convertToUserFriendlyError(error)
                    continuation.finish(throwing: userError)
                }
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        guard _isConfigured else { return false }
        return await apiKeyManager.hasAPIKey(for: _activeProvider)
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    nonisolated func estimateTokenCount(for text: String) -> Int {
        // Simple estimation that's good enough
        text.count / 4
    }
    
    // MARK: - Legacy Support
    
    func analyzeGoal(_ goalText: String) async throws -> String {
        guard _isConfigured else {
            throw AppError.from(ServiceError.notConfigured)
        }
        
        let request = AIRequest(
            systemPrompt: "You are a fitness coach. Analyze this goal and provide brief, actionable advice in under 3 sentences.",
            messages: [AIChatMessage(role: .user, content: goalText)],
            temperature: 0.7,
            maxTokens: 150,
            stream: false,
            user: "goal-analysis"
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
    
    // MARK: - Private Methods
    
    private func setupProviders() async {
        // Check API keys and setup providers
        async let anthropicKey = try? apiKeyManager.getAPIKey(for: .anthropic)
        async let openAIKey = try? apiKeyManager.getAPIKey(for: .openAI)
        async let geminiKey = try? apiKeyManager.getAPIKey(for: .gemini)
        
        let (anthropicResult, openAIResult, geminiResult) = await (anthropicKey, openAIKey, geminiKey)
        
        // Setup providers - simple and direct
        if let key = geminiResult {
            let config = LLMProviderConfig(apiKey: key)
            providers[.google] = GeminiProvider(config: config)
            _activeProvider = .gemini
            currentModel = LLMModel.gemini25Flash.identifier
        }
        
        if let key = anthropicResult {
            let config = LLMProviderConfig(apiKey: key)
            providers[.anthropic] = AnthropicProvider(config: config)
            if _activeProvider != .gemini {
                _activeProvider = .anthropic
                currentModel = LLMModel.claude4Sonnet.identifier
            }
        }
        
        if let key = openAIResult {
            let config = LLMProviderConfig(apiKey: key)
            providers[.openai] = OpenAIProvider(config: config)
            if _activeProvider != .gemini && _activeProvider != .anthropic {
                _activeProvider = .openAI
                currentModel = LLMModel.gpt4o.identifier
            }
        }
    }
    
    private func buildLLMRequest(from aiRequest: AIRequest) -> LLMRequest {
        // Convert messages
        let llmMessages = aiRequest.messages.map { msg in
            LLMMessage(
                role: LLMMessage.Role(rawValue: msg.role.rawValue) ?? .user,
                content: msg.content,
                name: msg.name,
                attachments: nil
            )
        }
        
        return LLMRequest(
            messages: llmMessages,
            model: currentModel,
            temperature: aiRequest.temperature,
            maxTokens: aiRequest.maxTokens,
            systemPrompt: aiRequest.systemPrompt,
            responseFormat: aiRequest.responseFormat,
            stream: aiRequest.stream,
            metadata: ["user": aiRequest.user],
            thinkingBudgetTokens: nil
        )
    }
    
    private func trackCost(usage: AITokenUsage, model: String) {
        if let llmModel = LLMModel(rawValue: model) {
            let cost = Double(usage.promptTokens) / 1_000.0 * llmModel.cost.input +
                       Double(usage.completionTokens) / 1_000.0 * llmModel.cost.output
            totalCost += cost
        }
    }
    
    // MARK: - Error Handling
    
    nonisolated private func convertToUserFriendlyError(_ error: Error) -> AppError {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("unauthorized") || errorString.contains("401") {
            return AppError.authentication("Please check your AI service API keys in Settings")
        }
        
        if errorString.contains("rate limit") || errorString.contains("429") {
            return AppError.llm("AI service is busy. Please wait and try again.")
        }
        
        if errorString.contains("network") || errorString.contains("connection") {
            return AppError.networkError(underlying: error)
        }
        
        if errorString.contains("timeout") {
            return AppError.serviceUnavailable
        }
        
        return AppError.llm("I encountered an issue. Please try again.")
    }
}

// MARK: - Helper Extensions

extension AIProvider {
    func toLLMProviderIdentifier() -> LLMProviderIdentifier {
        switch self {
        case .openAI: return .openai
        case .anthropic: return .anthropic
        case .gemini: return .google
        }
    }
}