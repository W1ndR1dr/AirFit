import Foundation
import Combine

/// The unified AI service that combines the best of both implementations
/// Uses comprehensive AIRequest/AIResponse models with LLMOrchestrator's provider management
@MainActor
final class UnifiedAIService: AIAPIServiceProtocol {
    private let providers: [LLMProviderIdentifier: any LLMProvider]
    private let cache: AIResponseCache
    private let apiKeyManager: APIKeyManagerProtocol
    
    @Published private(set) var availableProviders: Set<LLMProviderIdentifier> = []
    @Published private(set) var totalCost: Double = 0
    
    private var currentProvider: AIProvider = .anthropic
    private var fallbackProviders: [AIProvider] = [.openAI, .gemini]
    
    init(apiKeyManager: APIKeyManagerProtocol) async {
        self.apiKeyManager = apiKeyManager
        self.cache = AIResponseCache()
        
        // Initialize providers
        var providers: [LLMProviderIdentifier: any LLMProvider] = [:]
        
        // Setup Anthropic
        if let anthropicKey = await apiKeyManager.getAPIKey(for: "anthropic") {
            let config = LLMProviderConfig(
                apiKey: anthropicKey,
                baseURL: nil,
                timeout: 30,
                maxRetries: 3
            )
            providers[.anthropic] = AnthropicProvider(config: config)
            availableProviders.insert(.anthropic)
        }
        
        // Setup OpenAI
        if let openAIKey = await apiKeyManager.getAPIKey(for: "openai") {
            let config = LLMProviderConfig(
                apiKey: openAIKey,
                baseURL: nil,
                timeout: 30,
                maxRetries: 3
            )
            providers[.openai] = OpenAIProvider(config: config)
            availableProviders.insert(.openai)
        }
        
        // Setup Google Gemini
        if let geminiKey = await apiKeyManager.getAPIKey(for: "gemini") {
            providers[.google] = GeminiProvider(apiKey: geminiKey)
            availableProviders.insert(.google)
        }
        
        self.providers = providers
    }
    
    // MARK: - AIAPIServiceProtocol Implementation
    
    nonisolated func configure(provider: AIProvider, apiKey: String, modelIdentifier: String?) {
        Task { @MainActor in
            self.currentProvider = provider
        }
        // API keys are managed by APIKeyManager, this is for protocol compliance
    }
    
    nonisolated func getStreamingResponse(for request: AIRequest) -> AnyPublisher<AIResponse, Error> {
        let subject = PassthroughSubject<AIResponse, Error>()
        
        Task {
            do {
                // Try cache first if not streaming functions
                if request.functions == nil, let cached = await checkCache(for: request) {
                    subject.send(.text(cached))
                    subject.send(.done(usage: nil))
                    subject.send(completion: .finished)
                    return
                }
                
                // Get appropriate provider
                guard let provider = await selectProvider(for: request) else {
                    throw AIError.networkError("No available AI provider")
                }
                
                // Convert to provider request
                let llmRequest = convertToLLMRequest(request, provider: provider)
                
                // Stream response
                let stream = await provider.stream(llmRequest)
                var fullResponse = ""
                
                for try await chunk in stream {
                    if !chunk.delta.isEmpty {
                        fullResponse += chunk.delta
                        subject.send(.textDelta(chunk.delta))
                    }
                    
                    if chunk.isFinished {
                        // Cache successful response
                        if request.functions == nil {
                            await cacheResponse(fullResponse, for: request)
                        }
                        
                        // Track usage
                        var aiUsage: AITokenUsage? = nil
                        if let usage = chunk.usage {
                            let cost = usage.cost(at: await provider.costPerKToken)
                            Task { @MainActor in
                                totalCost += cost
                            }
                            // Include usage in done message
                            aiUsage = AITokenUsage(
                                promptTokens: usage.promptTokens,
                                completionTokens: usage.completionTokens,
                                totalTokens: usage.promptTokens + usage.completionTokens
                            )
                        }
                        
                        subject.send(.done(usage: aiUsage))
                    }
                }
                
                subject.send(completion: .finished)
            } catch {
                subject.send(.error(error as? AIError ?? AIError.networkError(error.localizedDescription)))
                subject.send(completion: .failure(error))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Direct Methods (Better API)
    
    /// Complete a request with automatic provider selection and fallback
    func complete(_ request: AIRequest) async throws -> String {
        // Check cache
        if request.functions == nil, let cached = await checkCache(for: request) {
            return cached
        }
        
        var lastError: Error?
        let providersToTry = [currentProvider] + fallbackProviders
        
        for providerType in providersToTry {
            guard let provider = selectProvider(for: request, preferredProvider: providerType) else {
                continue
            }
            
            do {
                let llmRequest = convertToLLMRequest(request, provider: provider)
                let response = try await provider.complete(llmRequest)
                
                // Track cost
                let cost = response.usage.cost(at: provider.costPerKToken)
                totalCost += cost
                
                // Cache response
                if request.functions == nil {
                    await cacheResponse(response.content, for: request)
                }
                
                return response.content
            } catch {
                lastError = error
                AppLogger.warning("Provider \(providerType) failed: \(error)", category: .ai)
                continue
            }
        }
        
        throw lastError ?? AIError.networkError("No available AI provider")
    }
    
    /// Stream a response with function calling support
    func streamWithFunctions(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let provider = await selectProvider(for: request) else {
                        throw AIError.networkError("No available AI provider")
                    }
                    
                    let llmRequest = convertToLLMRequest(request, provider: provider)
                    let stream = await provider.stream(llmRequest)
                    
                    for try await chunk in stream {
                        if !chunk.delta.isEmpty {
                            continuation.yield(.textDelta(chunk.delta))
                        }
                        
                        if chunk.isFinished {
                            var aiUsage: AITokenUsage? = nil
                            if let usage = chunk.usage {
                                let cost = usage.cost(at: await provider.costPerKToken)
                                Task { @MainActor in
                                totalCost += cost
                            }
                                aiUsage = AITokenUsage(
                                    promptTokens: usage.promptTokens,
                                    completionTokens: usage.completionTokens,
                                    totalTokens: usage.promptTokens + usage.completionTokens
                                )
                            }
                            continuation.yield(.done(usage: aiUsage))
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.yield(.error(error))
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func selectProvider(
        for request: AIRequest,
        preferredProvider: AIProvider? = nil
    ) -> (any LLMProvider)? {
        let provider = preferredProvider ?? currentProvider
        
        switch provider {
        case .anthropic:
            return providers[.anthropic]
        case .openAI:
            return providers[.openai]
        case .googleGemini:
            return providers[.google]
        case .openRouter:
            // OpenRouter not implemented yet
            return providers[.openai] // Fallback to OpenAI
        }
    }
    
    private func convertToLLMRequest(_ request: AIRequest, provider: any LLMProvider) -> LLMRequest {
        var messages: [LLMMessage] = []
        
        // Add conversation history
        for message in request.messages {
            messages.append(LLMMessage(
                role: mapRole(message.role),
                content: message.content,
                name: nil
            ))
        }
        
        // Add current message
        messages.append(LLMMessage(
            role: .user,
            content: request.userMessage.content,
            name: nil
        ))
        
        // Determine model based on task
        let model = selectModel(for: request, provider: provider)
        
        return LLMRequest(
            messages: messages,
            model: model,
            temperature: 0.7,
            maxTokens: nil,
            systemPrompt: request.systemPrompt,
            responseFormat: nil,
            stream: true,
            metadata: [
                "hasFunctions": request.functions != nil,
                "messageCount": request.messages.count
            ]
        )
    }
    
    private func mapRole(_ role: AIMessageRole) -> LLMMessage.Role {
        switch role {
        case .system: return .system
        case .user: return .user
        case .assistant: return .assistant
        case .function, .tool:
            // LLM providers don't have function/tool roles yet
            // This is where we'd need to extend LLMMessage.Role
            return .assistant
        }
    }
    
    private func selectModel(for request: AIRequest, provider: any LLMProvider) -> String {
        // Smart model selection based on task complexity
        let hasLongContext = request.messages.count > 10
        let hasFunctions = request.functions != nil
        let needsHighCapability = hasFunctions || hasLongContext
        
        switch provider.identifier {
        case .anthropic:
            return needsHighCapability ? LLMModel.claude3Opus.identifier : LLMModel.claude3Haiku.identifier
        case .openai:
            return needsHighCapability ? LLMModel.gpt4Turbo.identifier : LLMModel.gpt35Turbo.identifier
        case .google:
            return LLMModel.gemini15Pro.identifier
        default:
            return LLMModel.claude3Haiku.identifier
        }
    }
    
    private func checkCache(for request: AIRequest) async -> String? {
        // Create cache key from request
        let cacheRequest = LLMRequest(
            messages: request.messages.map { msg in
                LLMMessage(role: mapRole(msg.role), content: msg.content, name: nil)
            } + [LLMMessage(role: .user, content: request.userMessage.content, name: nil)],
            model: "", // Model doesn't matter for cache key
            temperature: 0,
            maxTokens: nil,
            systemPrompt: request.systemPrompt,
            responseFormat: nil,
            stream: false,
            metadata: [:]
        )
        
        if let cached = await cache.get(request: cacheRequest) {
            return cached.content
        }
        
        return nil
    }
    
    private func cacheResponse(_ response: String, for request: AIRequest) async {
        let cacheRequest = LLMRequest(
            messages: request.messages.map { msg in
                LLMMessage(role: mapRole(msg.role), content: msg.content, name: nil)
            } + [LLMMessage(role: .user, content: request.userMessage.content, name: nil)],
            model: "", // Model doesn't matter for cache
            temperature: 0,
            maxTokens: nil,
            systemPrompt: request.systemPrompt,
            responseFormat: nil,
            stream: false,
            metadata: [:]
        )
        
        let cacheResponse = LLMResponse(
            content: response,
            model: currentProvider.defaultModel,
            usage: LLMResponse.TokenUsage(promptTokens: 0, completionTokens: 0),
            finishReason: .stop,
            metadata: [:]
        )
        
        await cache.set(request: cacheRequest, response: cacheResponse, ttl: 3600)
    }
}

// MARK: - Extensions for Missing LLM Features

extension LLMMessage.Role {
    // TODO: Add function and tool roles to LLMMessage.Role
    // For now, we map them to assistant
}

// MARK: - Configuration

extension UnifiedAIService {
    /// Configure caching behavior
    func setCachingEnabled(_ enabled: Bool) async {
        if !enabled {
            await cache.clear()
        }
    }
    
    /// Get cache statistics
    func getCacheStats() async -> CacheStatistics {
        return await cache.getStatistics()
    }
    
    /// Set fallback providers for reliability
    func setFallbackProviders(_ providers: [AIProvider]) {
        self.fallbackProviders = providers
    }
}