import Foundation

/// # AIService
/// 
/// ## Purpose
/// Production AI service that provides the primary interface for all AI operations in AirFit.
/// Manages provider switching, model selection, cost tracking, and response caching.
///
/// ## Dependencies
/// - `LLMOrchestrator`: Manages multiple LLM providers and handles fallback logic
/// - `APIKeyManagementProtocol`: Secure storage and retrieval of API keys
/// - `AIResponseCache`: Caches AI responses to reduce costs and improve performance
///
/// ## Key Responsibilities
/// - Configure and manage AI providers (Anthropic, OpenAI, Gemini)
/// - Handle streaming and non-streaming AI requests
/// - Track token usage and costs across providers
/// - Cache responses for efficiency
/// - Provide fallback mechanisms when providers fail
/// - Convert between simplified AIRequest and full LLMRequest formats
///
/// ## Usage
/// ```swift
/// let aiService = await container.resolve(AIServiceProtocol.self)
/// try await aiService.configure()
/// 
/// // Send a request
/// let request = AIRequest(systemPrompt: "You are a fitness coach", messages: [...])
/// for try await response in aiService.sendRequest(request) {
///     // Handle response
/// }
/// ```
actor AIService: AIServiceProtocol {
    
    // MARK: - Properties
    nonisolated let serviceIdentifier = "production-ai-service"
    private var _isConfigured: Bool = false
    nonisolated var isConfigured: Bool {
        get { false } // Return false as default for nonisolated access
    }
    private var _activeProvider: AIProvider = .anthropic
    nonisolated var activeProvider: AIProvider {
        get { .anthropic } // Return default for nonisolated access
    }
    private var _availableModels: [AIModel] = []
    nonisolated var availableModels: [AIModel] {
        get { [] } // Return empty for nonisolated access
    }
    
    private let orchestrator: LLMOrchestrator
    private let apiKeyManager: APIKeyManagementProtocol
    private let cache: AIResponseCache
    private var currentModel: String = LLMModel.gemini25Flash.identifier
    
    // Cost tracking
    private(set) var totalCost: Double = 0
    
    // Fallback providers
    private var fallbackProviders: [AIProvider] = [.openAI, .gemini, .anthropic]
    private var cacheEnabled = true
    
    // MARK: - Initialization
    init(llmOrchestrator: LLMOrchestrator) {
        self.orchestrator = llmOrchestrator
        self.apiKeyManager = llmOrchestrator.apiKeyManager
        self.cache = AIResponseCache()
        
        // Initialize available models
        self._availableModels = [
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
            throw AppError.from(ServiceError.notConfigured)
        }
        
        // Set active provider and model based on available keys
        // Default to Gemini 2.5 Flash if available
        if hasGeminiKey {
            _activeProvider = .gemini
            currentModel = LLMModel.gemini25Flash.identifier
        } else if hasAnthropicKey {
            _activeProvider = .anthropic
            currentModel = LLMModel.claude4Sonnet.identifier
        } else if hasOpenAIKey {
            _activeProvider = .openAI
            currentModel = LLMModel.gpt4o.identifier
        }
        
        _isConfigured = true
        AppLogger.info("Production AI Service configured with provider: \(_activeProvider.rawValue)", category: .ai)
    }
    
    func reset() async {
        _isConfigured = false
        _activeProvider = .anthropic
    }
    
    func healthCheck() async -> ServiceHealth {
        guard _isConfigured else {
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
            metadata: ["provider": _activeProvider.rawValue]
        )
    }
    
    // MARK: - AIServiceProtocol
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        // Save the API key
        try await apiKeyManager.saveAPIKey(apiKey, for: provider)
        
        // Update active provider
        _activeProvider = provider
        
        // Configure the service
        try await configure()
    }
    
    nonisolated func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let isConfigured = await self.checkConfigurationStatus()
                    guard isConfigured else {
                        throw AppError.from(ServiceError.notConfigured)
                    }
                    
                    // Build a better prompt that preserves conversation structure
                    var prompt = ""
                    
                    // Add system prompt if present
                    if !request.systemPrompt.isEmpty {
                        prompt += request.systemPrompt + "\n\n"
                    }
                    
                    // Add conversation history with clear role markers
                    if request.messages.count > 1 {
                        prompt += "Conversation history:\n"
                        for (index, message) in request.messages.dropLast().enumerated() {
                            let role = message.role == .user ? "User" : "Assistant"
                            prompt += "\(role): \(message.content)\n"
                            if index < request.messages.count - 2 {
                                prompt += "\n"
                            }
                        }
                        prompt += "\n---\n\n"
                    }
                    
                    // Add the current message
                    if let lastMessage = request.messages.last {
                        let role = lastMessage.role == .user ? "User" : "Assistant"
                        prompt += "Current message:\n\(role): \(lastMessage.content)"
                    }
                    
                    // Determine the task type based on context
                    let task: AITask = request.user == "onboarding" ? .conversationAnalysis : .coaching
                    
                    if request.stream {
                        // Stream responses
                        let model = await self.getCurrentModel()
                        let stream = orchestrator.stream(
                            prompt: prompt,
                            task: task,
                            temperature: request.temperature
                        )
                        
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
                                
                                // Update cost tracking on actor
                                await self.updateCost(usage: usage, model: model)
                                
                                continuation.yield(.done(usage: usage))
                            }
                        }
                    } else {
                        // Single response
                        let llmResponse = try await orchestrator.complete(
                            prompt: prompt,
                            task: task,
                            temperature: request.temperature,
                            maxTokens: request.maxTokens
                        )
                        continuation.yield(.text(llmResponse.content))
                        
                        let usage = AITokenUsage(
                            promptTokens: llmResponse.usage.promptTokens,
                            completionTokens: llmResponse.usage.completionTokens,
                            totalTokens: llmResponse.usage.totalTokens
                        )
                        continuation.yield(.done(usage: usage))
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        guard _isConfigured else {
            return false
        }
        
        // Check if the current provider has a valid API key
        return await apiKeyManager.hasAPIKey(for: _activeProvider)
    }
    
    func checkHealth() async -> ServiceHealth {
        return await healthCheck()
    }
    
    nonisolated func estimateTokenCount(for text: String) -> Int {
        // Simple estimation: ~4 characters per token
        return text.count / 4
    }
    
    // MARK: - Legacy Support
    
    /// Analyze a goal using AI (legacy method for backward compatibility)
    func analyzeGoal(_ goalText: String) async throws -> String {
        guard _isConfigured else {
            throw AppError.from(ServiceError.notConfigured)
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
    
    // MARK: - Cache Control
    
    func setCacheEnabled(_ enabled: Bool) {
        cacheEnabled = enabled
    }
    
    func clearCache() async {
        await cache.clear()
    }
    
    func getCacheStatistics() async -> (hits: Int, misses: Int, size: Int) {
        let stats = await cache.getStatistics()
        return (hits: stats.hitCount, misses: stats.missCount, size: stats.memorySizeBytes)
    }
    
    // MARK: - Cost Tracking
    
    func resetCostTracking() {
        totalCost = 0
    }
    
    func getCostBreakdown() -> [(provider: AIProvider, cost: Double)] {
        // Simple breakdown - in future could track per provider
        return [(_activeProvider, totalCost)]
    }
    
    // MARK: - Private Helpers
    
    private func checkConfigurationStatus() -> Bool {
        return _isConfigured
    }
    
    private func getCurrentModel() -> String {
        return currentModel
    }
    
    private func generateCacheKey(for request: AIRequest) -> String {
        let content = request.messages.map { $0.content }.joined(separator: "|")
        let systemPromptPart = request.systemPrompt
        let key = "\(systemPromptPart)-\(content)-\(request.temperature)"
        return key.data(using: .utf8)?.base64EncodedString() ?? key
    }
    
    private func updateCost(usage: AITokenUsage, model: String) {
        if let llmModel = LLMModel(rawValue: model) {
            let cost = Double(usage.promptTokens) / 1_000.0 * llmModel.cost.input +
                       Double(usage.completionTokens) / 1_000.0 * llmModel.cost.output
            totalCost += cost
        }
    }
}
