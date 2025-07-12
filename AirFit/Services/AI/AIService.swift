import Foundation

/// AI Service Mode - Determines behavior when no API keys are configured
enum AIServiceMode {
    case production     // Normal operation with real AI providers
    case demo          // Context-aware demo responses
    case test          // Generic test responses
    case offline       // Throws errors
}

/// Streamlined AI Service - Direct provider management without unnecessary layers
actor AIService: AIServiceProtocol {
    
    // MARK: - Properties
    nonisolated let serviceIdentifier = "ai-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { 
        true // Always return true for compatibility
    }
    
    // Service mode
    private let mode: AIServiceMode
    
    // Provider management
    private var providers: [LLMProviderIdentifier: any LLMProvider] = [:]
    private var _activeProvider: AIProvider = .gemini
    nonisolated var activeProvider: AIProvider { 
        .gemini // Default for nonisolated access
    }
    private var currentModel: String = LLMModel.gemini25Flash.identifier
    
    // Dependencies
    private let apiKeyManager: APIKeyManagementProtocol?
    
    // Simple cost tracking
    private(set) var totalCost: Double = 0
    
    // Available models
    nonisolated var availableModels: [AIModel] {
        switch mode {
        case .production:
            return [
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
        case .demo, .test:
            return [
                AIModel(
                    id: "demo-model",
                    name: mode == .demo ? "Demo AI" : "Test AI",
                    provider: .gemini,
                    contextWindow: 100_000,
                    costPerThousandTokens: AIModel.TokenCost(input: 0, output: 0)
                )
            ]
        case .offline:
            return []
        }
    }
    
    // MARK: - Initialization
    
    init(apiKeyManager: APIKeyManagementProtocol? = nil, mode: AIServiceMode = .production) {
        self.apiKeyManager = apiKeyManager
        self.mode = mode
    }
    
    // MARK: - ServiceProtocol (keeping for compatibility, will remove in next phase)
    
    func configure() async throws {
        switch mode {
        case .production:
            guard let apiKeyManager = apiKeyManager else {
                throw AppError.from(ServiceError.notConfigured)
            }
            await setupProviders(apiKeyManager: apiKeyManager)
            guard !providers.isEmpty else {
                throw AppError.from(ServiceError.notConfigured)
            }
        case .demo, .test:
            // Always configured in demo/test mode
            break
        case .offline:
            throw AIError.unauthorized
        }
        
        _isConfigured = true
        AppLogger.info("AI Service configured in \(mode) mode", category: .ai)
    }
    
    func reset() async {
        providers.removeAll()
        _isConfigured = false
        totalCost = 0
    }
    
    func healthCheck() async -> ServiceHealth {
        switch mode {
        case .production:
            return ServiceHealth(
                status: _isConfigured ? .healthy : .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: _isConfigured ? nil : "Service not configured",
                metadata: ["providers": providers.count.description]
            )
        case .demo, .test:
            return ServiceHealth(
                status: .healthy,
                lastCheckTime: Date(),
                responseTime: 0.1,
                errorMessage: nil,
                metadata: ["mode": String(describing: mode)]
            )
        case .offline:
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: "No AI provider configured",
                metadata: [:]
            )
        }
    }
    
    // MARK: - AIServiceProtocol
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        guard mode == .production else {
            // Ignore in non-production modes
            return
        }
        
        guard let apiKeyManager = apiKeyManager else {
            throw AppError.from(ServiceError.notConfigured)
        }
        
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
                    switch await self.mode {
                    case .production:
                        try await self.handleProductionRequest(request, continuation: continuation)
                    case .demo:
                        try await self.handleDemoRequest(request, continuation: continuation)
                    case .test:
                        try await self.handleTestRequest(request, continuation: continuation)
                    case .offline:
                        continuation.yield(.error(AIError.unauthorized))
                        continuation.finish()
                    }
                } catch {
                    let userError = self.convertToUserFriendlyError(error)
                    continuation.finish(throwing: userError)
                }
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        switch mode {
        case .production:
            guard _isConfigured, let apiKeyManager = apiKeyManager else { return false }
            return await apiKeyManager.hasAPIKey(for: _activeProvider)
        case .demo, .test:
            return true
        case .offline:
            return false
        }
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    nonisolated func estimateTokenCount(for text: String) -> Int {
        text.count / 4
    }
    
    // MARK: - Legacy Support
    
    func analyzeGoal(_ goalText: String) async throws -> String {
        guard mode != .offline else {
            throw AIError.unauthorized
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
    
    // MARK: - Production Request Handling
    
    private func handleProductionRequest(_ request: AIRequest, continuation: AsyncThrowingStream<AIResponse, Error>.Continuation) async throws {
        guard _isConfigured else {
            throw AppError.from(ServiceError.notConfigured)
        }
        
        let llmRequest = buildLLMRequest(from: request)
        
        guard let provider = providers[_activeProvider.toLLMProviderIdentifier()] else {
            throw AppError.llm("AI provider not available")
        }
        
        if request.stream {
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
                    
                    await trackCost(usage: usage, model: llmRequest.model)
                    continuation.yield(.done(usage: usage))
                }
            }
        } else {
            let response = try await provider.complete(llmRequest)
            
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
            
            await trackCost(usage: usage, model: llmRequest.model)
            continuation.yield(.done(usage: usage))
        }
        
        continuation.finish()
    }
    
    // MARK: - Demo Mode Handling
    
    private func handleDemoRequest(_ request: AIRequest, continuation: AsyncThrowingStream<AIResponse, Error>.Continuation) async throws {
        let response = getDemoResponse(for: request)
        
        if request.stream {
            // Simulate streaming
            let words = response.split(separator: " ")
            for word in words {
                try await Task.sleep(nanoseconds: 50_000_000)
                continuation.yield(.textDelta(String(word) + " "))
            }
        } else {
            try await Task.sleep(nanoseconds: 500_000_000)
            continuation.yield(.text(response))
        }
        
        let usage = AITokenUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
        continuation.yield(.done(usage: usage))
        continuation.finish()
    }
    
    private func getDemoResponse(for request: AIRequest) -> String {
        guard let lastMessage = request.messages.last else {
            return "I'm here to help you with your fitness journey!"
        }
        
        let content = lastMessage.content.lowercased()
        
        // Context-aware demo responses
        if content.contains("workout") {
            return "Let's create a workout plan that fits your goals! I'd recommend starting with 3-4 sessions per week focusing on compound movements."
        } else if content.contains("nutrition") || content.contains("food") || content.contains("ate") {
            return "Nutrition is key to your fitness goals. Based on what you've told me, I'd suggest aiming for balanced macros with adequate protein."
        } else if content.contains("goal") {
            return "That's a great goal! Let's break it down into actionable steps. We'll track your progress weekly and adjust as needed."
        } else if content.contains("tired") || content.contains("motivation") {
            return "I understand how you feel. Remember, progress isn't always linear. Even small steps forward count. What's one thing you can do today?"
        } else {
            return "I'm here to support you every step of the way. Tell me more about what you'd like to work on."
        }
    }
    
    // MARK: - Test Mode Handling
    
    private func handleTestRequest(_ request: AIRequest, continuation: AsyncThrowingStream<AIResponse, Error>.Continuation) async throws {
        let response = "Test response for: \(request.messages.last?.content ?? "empty")"
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        if request.stream {
            continuation.yield(.textDelta(response))
        } else {
            continuation.yield(.text(response))
        }
        
        let usage = AITokenUsage(promptTokens: 10, completionTokens: 10, totalTokens: 20)
        continuation.yield(.done(usage: usage))
        continuation.finish()
    }
    
    // MARK: - Private Methods
    
    private func setupProviders(apiKeyManager: APIKeyManagementProtocol) async {
        async let anthropicKey = try? apiKeyManager.getAPIKey(for: .anthropic)
        async let openAIKey = try? apiKeyManager.getAPIKey(for: .openAI)
        async let geminiKey = try? apiKeyManager.getAPIKey(for: .gemini)
        
        let (anthropicResult, openAIResult, geminiResult) = await (anthropicKey, openAIKey, geminiKey)
        
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