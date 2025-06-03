import Foundation

@MainActor
final class LLMOrchestrator: ObservableObject {
    private var providers: [LLMProviderIdentifier: any LLMProvider] = [:]
    private let apiKeyManager: APIKeyManagementProtocol
    private let cache = AIResponseCache()
    
    @Published private(set) var availableProviders: Set<LLMProviderIdentifier> = []
    @Published private(set) var totalCost: Double = 0
    
    private var usageHistory: [UsageRecord] = []
    private var cacheEnabled = true
    
    init(apiKeyManager: APIKeyManagementProtocol) {
        self.apiKeyManager = apiKeyManager
        Task {
            await setupProviders()
        }
    }
    
    // MARK: - Public API
    
    func complete(
        prompt: String,
        task: AITask,
        model: LLMModel? = nil,
        temperature: Double = 0.7,
        maxTokens: Int? = nil
    ) async throws -> LLMResponse {
        let request = buildRequest(
            prompt: prompt,
            model: model ?? task.recommendedModels.first!,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: false,
            task: task
        )
        
        return try await executeWithFallback(request: request, task: task)
    }
    
    func stream(
        prompt: String,
        task: AITask,
        model: LLMModel? = nil,
        temperature: Double = 0.7
    ) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        let request = buildRequest(
            prompt: prompt,
            model: model ?? task.recommendedModels.first!,
            temperature: temperature,
            maxTokens: nil,
            stream: true,
            task: task
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let provider = try await selectProvider(for: request.model, task: task)
                    let stream = await provider.stream(request)
                    
                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func estimateCost(for prompt: String, model: LLMModel, responseTokens: Int = 1000) -> Double {
        let promptTokens = estimateTokenCount(prompt)
        let rates = model.cost
        
        let inputCost = Double(promptTokens) / 1000.0 * rates.input
        let outputCost = Double(responseTokens) / 1000.0 * rates.output
        
        return inputCost + outputCost
    }
    
    // MARK: - Private Implementation
    
    private func setupProviders() async {
        // Setup Anthropic
        if let anthropicKey = try? await apiKeyManager.getAPIKey(for: .anthropic) {
            let config = LLMProviderConfig(apiKey: anthropicKey)
            let provider = AnthropicProvider(config: config)
            
            if let validated = try? await provider.validateAPIKey(anthropicKey), validated {
                providers[.anthropic] = provider
                availableProviders.insert(.anthropic)
            }
        }
        
        // Setup OpenAI
        if let openAIKey = try? await apiKeyManager.getAPIKey(for: .openAI) {
            let config = LLMProviderConfig(apiKey: openAIKey)
            let provider = OpenAIProvider(config: config)
            
            if let validated = try? await provider.validateAPIKey(openAIKey), validated {
                providers[.openai] = provider
                availableProviders.insert(.openai)
            }
        }
        
        // Setup Google Gemini
        if let geminiKey = try? await apiKeyManager.getAPIKey(for: .gemini) {
            let provider = GeminiProvider(apiKey: geminiKey)
            providers[.google] = provider
            availableProviders.insert(.google)
        }
    }
    
    private func executeWithFallback(
        request: LLMRequest,
        task: AITask,
        attemptedProviders: Set<LLMProviderIdentifier> = []
    ) async throws -> LLMResponse {
        // Check cache first if enabled
        if cacheEnabled {
            if let cachedResponse = await cache.get(request: request) {
                AppLogger.debug("Cache hit for LLM request", category: .ai)
                return cachedResponse
            }
        }
        
        do {
            let provider = try await selectProvider(
                for: request.model,
                task: task,
                excluding: attemptedProviders
            )
            
            let startTime = Date()
            let response = try await provider.complete(request)
            let duration = Date().timeIntervalSince(startTime)
            
            // Track usage
            await recordUsage(
                provider: provider.identifier,
                model: request.model,
                usage: response.usage,
                duration: duration,
                success: true
            )
            
            // Cache the response if caching is enabled
            if cacheEnabled {
                // Determine TTL based on task type
                let ttl = determineCacheTTL(for: task, request: request)
                await cache.set(request: request, response: response, ttl: ttl)
            }
            
            return response
        } catch {
            // Log the error
            print("LLM Provider error: \(error)")
            
            // Try fallback if available
            if let fallbackModel = findFallbackModel(
                for: request.model,
                task: task,
                excluding: attemptedProviders
            ) {
                let fallbackRequest = LLMRequest(
                    messages: request.messages,
                    model: fallbackModel.identifier,
                    temperature: request.temperature,
                    maxTokens: request.maxTokens,
                    systemPrompt: request.systemPrompt,
                    responseFormat: request.responseFormat,
                    stream: request.stream,
                    metadata: request.metadata
                )
                
                var newAttempted = attemptedProviders
                newAttempted.insert(LLMModel(rawValue: request.model)?.provider ?? .anthropic)
                
                return try await executeWithFallback(
                    request: fallbackRequest,
                    task: task,
                    attemptedProviders: newAttempted
                )
            }
            
            throw error
        }
    }
    
    private func selectProvider(
        for modelId: String,
        task: AITask,
        excluding: Set<LLMProviderIdentifier> = []
    ) async throws -> any LLMProvider {
        // Find provider for model
        guard let model = LLMModel.allCases.first(where: { $0.identifier == modelId }) else {
            throw LLMError.unsupportedFeature("Unknown model: \(modelId)")
        }
        
        let providerId = model.provider
        
        guard !excluding.contains(providerId),
              let provider = providers[providerId] else {
            throw LLMError.unsupportedFeature("Provider not available: \(providerId.name)")
        }
        
        return provider
    }
    
    private func findFallbackModel(
        for modelId: String,
        task: AITask,
        excluding: Set<LLMProviderIdentifier>
    ) -> LLMModel? {
        let recommendedModels = task.recommendedModels
        
        // Find next available model
        for model in recommendedModels {
            if !excluding.contains(model.provider) && providers[model.provider] != nil {
                return model
            }
        }
        
        return nil
    }
    
    private func buildRequest(
        prompt: String,
        model: LLMModel,
        temperature: Double,
        maxTokens: Int?,
        stream: Bool,
        task: AITask
    ) -> LLMRequest {
        LLMRequest(
            messages: [LLMMessage(role: .user, content: prompt, name: nil)],
            model: model.identifier,
            temperature: temperature,
            maxTokens: maxTokens,
            systemPrompt: nil,
            responseFormat: nil,
            stream: stream,
            metadata: ["task": String(describing: task)]
        )
    }
    
    private func recordUsage(
        provider: LLMProviderIdentifier,
        model: String,
        usage: LLMResponse.TokenUsage,
        duration: TimeInterval,
        success: Bool
    ) async {
        let record = UsageRecord(
            provider: provider,
            model: model,
            usage: usage,
            duration: duration,
            success: success,
            timestamp: Date()
        )
        
        usageHistory.append(record)
        
        // Update total cost
        if let modelEnum = LLMModel.allCases.first(where: { $0.identifier == model }) {
            totalCost += usage.cost(at: modelEnum.cost)
        }
        
        // Keep only last 1000 records
        if usageHistory.count > 1000 {
            usageHistory.removeFirst(usageHistory.count - 1000)
        }
    }
    
    private func estimateTokenCount(_ text: String) -> Int {
        // Rough estimation: ~4 characters per token
        return text.count / 4
    }
    
    private func determineCacheTTL(for task: AITask, request: LLMRequest) -> TimeInterval {
        // Determine cache TTL based on task type and other factors
        switch task {
        case .personalityExtraction:
            // Personality extraction results should be cached for consistency
            return 3600 * 6 // 6 hours
        case .personaSynthesis:
            // Persona synthesis is expensive and results are stable
            return 3600 * 24 // 24 hours
        case .conversationAnalysis:
            // Conversation analysis can be cached moderately
            return 3600 * 4 // 4 hours
        case .coaching:
            // Coach responses should be fresh and personalized
            return 3600 // 1 hour
        case .quickResponse:
            // Quick responses should be somewhat fresh
            return 1800 // 30 minutes
        }
    }
    
    // MARK: - Cache Control Methods
    
    func setCacheEnabled(_ enabled: Bool) {
        cacheEnabled = enabled
        if !enabled {
            Task {
                await cache.clear()
            }
        }
    }
    
    func clearCache() async {
        await cache.clear()
    }
    
    func invalidateCache(tag: String) async {
        await cache.invalidate(tag: tag)
    }
    
    func getCacheStatistics() async -> CacheStatistics {
        await cache.getStatistics()
    }
}

// MARK: - Supporting Types

private struct UsageRecord {
    let provider: LLMProviderIdentifier
    let model: String
    let usage: LLMResponse.TokenUsage
    let duration: TimeInterval
    let success: Bool
    let timestamp: Date
}

// MARK: - LLMModel Extension

extension LLMModel: CaseIterable {
    static var allCases: [LLMModel] {
        [
            .claude3Opus, .claude3Sonnet, .claude3Haiku, .claude2,
            .gpt4Turbo, .gpt4, .gpt35Turbo,
            .gemini15Pro, .gemini15Flash, .geminiPro
        ]
    }
}

extension LLMModel: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        if let model = LLMModel.allCases.first(where: { $0.identifier == rawValue }) {
            self = model
        } else {
            return nil
        }
    }
    
    var rawValue: String {
        identifier
    }
}