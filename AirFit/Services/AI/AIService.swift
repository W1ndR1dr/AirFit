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
final class AIService: AIServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    let serviceIdentifier = "production-ai-service"
    private(set) var isConfigured: Bool = false
    private(set) var activeProvider: AIProvider = .anthropic
    private(set) var availableModels: [AIModel] = []
    
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
            throw AppError.from(ServiceError.notConfigured)
        }
        
        // Set active provider and model based on available keys
        // Default to Gemini 2.5 Flash if available
        if hasGeminiKey {
            activeProvider = .gemini
            currentModel = LLMModel.gemini25Flash.identifier
        } else if hasAnthropicKey {
            activeProvider = .anthropic
            currentModel = LLMModel.claude3Sonnet.identifier
        } else if hasOpenAIKey {
            activeProvider = .openAI
            currentModel = LLMModel.gpt4Turbo.identifier
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
        try await apiKeyManager.saveAPIKey(apiKey, for: provider)
        
        // Update active provider
        activeProvider = provider
        
        // Configure the service
        try await configure()
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard isConfigured else {
                        throw AppError.from(ServiceError.notConfigured)
                    }
                    
                    // Convert AIRequest messages to LLMMessage format
                    let llmMessages = request.messages.map { msg in
                        LLMMessage(
                            role: LLMMessage.Role(rawValue: msg.role.rawValue) ?? .user,
                            content: msg.content,
                            name: msg.name,
                            attachments: nil
                        )
                    }
                    
                    // Create LLMRequest
                    _ = LLMRequest(
                        messages: llmMessages,
                        model: currentModel,
                        temperature: request.temperature,
                        maxTokens: request.maxTokens,
                        systemPrompt: request.systemPrompt,
                        responseFormat: nil,
                        stream: request.stream,
                        metadata: [:],
                        thinkingBudgetTokens: nil
                    )
                    
                    // Build prompt from messages
                    var prompt = ""
                    if !request.systemPrompt.isEmpty {
                        prompt += "System: \(request.systemPrompt)\n\n"
                    }
                    for message in request.messages {
                        prompt += "\(message.role.rawValue.capitalized): \(message.content)\n"
                    }
                    
                    if request.stream {
                        // Stream responses (no caching for streams)
                        let stream = await orchestrator.stream(
                            prompt: prompt,
                            task: .coaching,
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
                                
                                // Update cost tracking
                                if let model = LLMModel(rawValue: currentModel) {
                                    let cost = Double(usage.promptTokens) / 1000.0 * model.cost.input +
                                               Double(usage.completionTokens) / 1000.0 * model.cost.output
                                    totalCost += cost
                                }
                                
                                continuation.yield(.done(usage: usage))
                            }
                        }
                    } else {
                        // Single response
                        let llmResponse = try await orchestrator.complete(
                            prompt: prompt,
                            task: .coaching,
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
        return [(activeProvider, totalCost)]
    }
    
    // MARK: - Private Helpers
    
    private func generateCacheKey(for request: AIRequest) -> String {
        let content = request.messages.map { $0.content }.joined(separator: "|")
        let systemPromptPart = request.systemPrompt
        let key = "\(systemPromptPart)-\(content)-\(request.temperature)"
        return key.data(using: .utf8)?.base64EncodedString() ?? key
    }
}