import Foundation
import Combine

/// # LLMOrchestrator
///
/// ## Purpose
/// Orchestrates multiple LLM providers (Anthropic, OpenAI, Gemini), handles intelligent
/// fallback logic, manages response caching, and tracks usage/costs across providers.
///
/// ## Dependencies
/// - `APIKeyManagementProtocol`: Secure API key storage and retrieval
/// - `LLMProvider` implementations: Anthropic, OpenAI, and Gemini providers
/// - `AIResponseCache`: Intelligent response caching with TTL management
///
/// ## Key Responsibilities
/// - Manage multiple LLM provider instances
/// - Select optimal model based on task requirements
/// - Implement intelligent fallback when providers fail
/// - Cache responses with task-specific TTL
/// - Track token usage and costs across all providers
/// - Provide streaming and completion APIs
/// - Optimize model selection for cost/performance
///
/// ## Usage
/// ```swift
/// let orchestrator = await container.resolve(LLMOrchestrator.self)
///
/// // Complete request with automatic provider selection
/// let response = try await orchestrator.complete(
///     prompt: "Analyze this workout",
///     task: .coaching,
///     temperature: 0.7
/// )
///
/// // Stream response
/// let stream = orchestrator.stream(prompt: prompt, task: .quickResponse)
/// for try await chunk in stream {
///     // Handle streaming chunk
/// }
/// ```
///
/// ## Important Notes
/// - Automatically validates API keys on startup
/// - Implements smart caching based on task type
/// - Tracks costs in real-time for budget management
/// - Supports Gemini 2.5 Flash thinking model with budget control
///
/// ## Performance Update (Phase 3.2)
/// - Optimized to run all AI operations off the main thread
/// - Class remains @MainActor for ObservableObject compatibility
/// - All heavy operations are nonisolated and use internal actor
/// - Thread safety handled by OrchestratorState actor for concurrent access
@MainActor
final class LLMOrchestrator: ObservableObject, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "llm-orchestrator"

    // Thread-safe state management using internal actor
    private nonisolated let state = OrchestratorState()

    // Synchronous access required by ServiceProtocol
    // This is a best-effort check - for guaranteed accuracy use async version
    private nonisolated let _isConfiguredCache = AtomicBool()
    nonisolated var isConfigured: Bool {
        _isConfiguredCache.value
    }

    nonisolated let apiKeyManager: APIKeyManagementProtocol
    private nonisolated let cache = AIResponseCache()

    // UI-related properties that need MainActor
    @Published private(set) var availableProviders: Set<LLMProviderIdentifier> = []
    @Published private(set) var totalCost: Double = 0

    init(apiKeyManager: APIKeyManagementProtocol) {
        self.apiKeyManager = apiKeyManager
        // setupProviders() is called in configure() method
    }

    // MARK: - ServiceProtocol Methods

    nonisolated func configure() async throws {
        guard await !state.isConfigured else { return }

        await setupProviders()
        await state.setConfigured(true)
        _isConfiguredCache.value = true

        let providerCount = await MainActor.run { availableProviders.count }
        AppLogger.info("\(serviceIdentifier) configured with \(providerCount) providers", category: .services)
    }

    nonisolated func reset() async {
        await state.reset()
        _isConfiguredCache.value = false

        await MainActor.run {
            availableProviders.removeAll()
            totalCost = 0
        }

        await cache.clear()

        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    nonisolated func healthCheck() async -> ServiceHealth {
        let (providerSet, cost) = await MainActor.run {
            (availableProviders, totalCost)
        }
        let healthyProviders = providerSet.count
        let status: ServiceHealth.Status = healthyProviders > 0 ? .healthy : .unhealthy

        return ServiceHealth(
            status: status,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: healthyProviders == 0 ? "No LLM providers available" : nil,
            metadata: [
                "availableProviders": providerSet.map { $0.name }.joined(separator: ", "),
                "totalCost": "\(cost)",
                "cacheEnabled": "\(await state.cacheEnabled)"
            ]
        )
    }

    // MARK: - Public API

    nonisolated func complete(
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

    nonisolated func completeWithRequest(
        _ request: LLMRequest,
        task: AITask
    ) async throws -> LLMResponse {
        return try await executeWithFallback(request: request, task: task)
    }

    nonisolated func stream(
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

    nonisolated func estimateCost(for prompt: String, model: LLMModel, responseTokens: Int = 1_000) -> Double {
        let promptTokens = estimateTokenCount(prompt)
        let rates = model.cost

        let inputCost = Double(promptTokens) / 1_000.0 * rates.input
        let outputCost = Double(responseTokens) / 1_000.0 * rates.output

        return inputCost + outputCost
    }

    // MARK: - Private Implementation

    nonisolated private func setupProviders() async {
        var newProviders = Set<LLMProviderIdentifier>()
        var localProviders: [LLMProviderIdentifier: any LLMProvider] = [:]

        // Fetch all API keys in parallel
        async let anthropicKey = try? apiKeyManager.getAPIKey(for: .anthropic)
        async let openAIKey = try? apiKeyManager.getAPIKey(for: .openAI)
        async let geminiKey = try? apiKeyManager.getAPIKey(for: .gemini)

        // Await all keys first
        let (anthropicKeyResult, openAIKeyResult, geminiKeyResult) = await (anthropicKey, openAIKey, geminiKey)

        // Setup providers in parallel using TaskGroup
        await withTaskGroup(of: (LLMProviderIdentifier, (any LLMProvider)?)?.self) { group in
            // Anthropic setup
            if let key = anthropicKeyResult {
                group.addTask {
                    let config = LLMProviderConfig(apiKey: key)
                    let provider = AnthropicProvider(config: config)

                    if let validated = try? await provider.validateAPIKey(key), validated {
                        return (.anthropic, provider)
                    }
                    return nil
                }
            }

            // OpenAI setup
            if let key = openAIKeyResult {
                group.addTask {
                    let config = LLMProviderConfig(apiKey: key)
                    let provider = OpenAIProvider(config: config)

                    if let validated = try? await provider.validateAPIKey(key), validated {
                        return (.openai, provider)
                    }
                    return nil
                }
            }

            // Google Gemini setup (no validation needed)
            if let key = geminiKeyResult {
                group.addTask {
                    let config = LLMProviderConfig(apiKey: key)
                    let provider = GeminiProvider(config: config)
                    return (.google, provider)
                }
            }

            // Collect results
            for await result in group {
                if let (identifier, provider) = result {
                    localProviders[identifier] = provider
                    newProviders.insert(identifier)
                }
            }
        }

        // Update state
        await state.setProviders(localProviders)

        // Update UI property on MainActor
        await MainActor.run {
            availableProviders = newProviders
        }
    }

    nonisolated private func executeWithFallback(
        request: LLMRequest,
        task: AITask,
        attemptedProviders: Set<LLMProviderIdentifier> = []
    ) async throws -> LLMResponse {
        // Check cache first if enabled
        if await state.cacheEnabled {
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
            if await state.cacheEnabled {
                // Determine TTL based on task type
                let ttl = determineCacheTTL(for: task, request: request)
                await cache.set(request: request, response: response, ttl: ttl)
            }

            return response
        } catch {
            // Log the error
            AppLogger.error("LLM Provider error: \(error)", category: .ai)

            // Try fallback if available
            if let fallbackModel = await findFallbackModel(
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
                    metadata: request.metadata,
                    thinkingBudgetTokens: request.thinkingBudgetTokens
                )

                var newAttempted = attemptedProviders
                newAttempted.insert(LLMModel(rawValue: request.model)?.provider ?? .anthropic)

                return try await executeWithFallback(
                    request: fallbackRequest,
                    task: task,
                    attemptedProviders: newAttempted
                )
            }

            throw error.asAppError
        }
    }

    nonisolated private func selectProvider(
        for modelId: String,
        task: AITask,
        excluding: Set<LLMProviderIdentifier> = []
    ) async throws -> any LLMProvider {
        // Find provider for model
        guard let model = LLMModel.allCases.first(where: { $0.identifier == modelId }) else {
            throw AppError.from(LLMError.unsupportedFeature("Unknown model: \(modelId)"))
        }

        let providerId = model.provider

        guard !excluding.contains(providerId) else {
            throw AppError.from(LLMError.unsupportedFeature("Provider excluded: \(providerId.name)"))
        }

        guard let provider = await state.getProvider(providerId) else {
            throw AppError.from(LLMError.unsupportedFeature("Provider not available: \(providerId.name)"))
        }

        return provider
    }

    nonisolated private func findFallbackModel(
        for modelId: String,
        task: AITask,
        excluding: Set<LLMProviderIdentifier>
    ) async -> LLMModel? {
        let recommendedModels = task.recommendedModels

        // Find next available model
        for model in recommendedModels {
            if !excluding.contains(model.provider) {
                if await state.hasProvider(model.provider) {
                    return model
                }
            }
        }

        return nil
    }

    nonisolated private func buildRequest(
        prompt: String,
        model: LLMModel,
        temperature: Double,
        maxTokens: Int?,
        stream: Bool,
        task: AITask
    ) -> LLMRequest {
        // Determine thinking budget for Gemini 2.5 Flash thinking model
        let thinkingBudget: Int? = {
            if model == .gemini25FlashThinking {
                // Start with low budget and tune based on task
                switch task {
                case .personaSynthesis:
                    return 8_192 // Higher budget for complex creative tasks
                case .personalityExtraction, .conversationAnalysis:
                    return 4_096 // Medium budget for analysis
                case .coaching, .quickResponse:
                    return 1_024 // Lower budget for quick responses
                }
            }
            return nil
        }()

        return LLMRequest(
            messages: [LLMMessage(role: .user, content: prompt, name: nil, attachments: nil)],
            model: model.identifier,
            temperature: temperature,
            maxTokens: maxTokens,
            systemPrompt: nil,
            responseFormat: nil,
            stream: stream,
            metadata: ["task": String(describing: task)],
            thinkingBudgetTokens: thinkingBudget
        )
    }

    nonisolated private func recordUsage(
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

        await state.addUsageRecord(record)

        // Update total cost
        if let modelEnum = LLMModel.allCases.first(where: { $0.identifier == model }) {
            let additionalCost = usage.cost(at: modelEnum.cost)
            await MainActor.run {
                totalCost += additionalCost
            }
        }
    }

    nonisolated private func estimateTokenCount(_ text: String) -> Int {
        // Rough estimation: ~4 characters per token
        return text.count / 4
    }

    nonisolated private func determineCacheTTL(for task: AITask, request: LLMRequest) -> TimeInterval {
        // Determine cache TTL based on task type and other factors
        switch task {
        case .personalityExtraction:
            // Personality extraction results should be cached for consistency
            return 3_600 * 6 // 6 hours
        case .personaSynthesis:
            // Persona synthesis is expensive and results are stable
            return 3_600 * 24 // 24 hours
        case .conversationAnalysis:
            // Conversation analysis can be cached moderately
            return 3_600 * 4 // 4 hours
        case .coaching:
            // Coach responses should be fresh and personalized
            return 3_600 // 1 hour
        case .quickResponse:
            // Quick responses should be somewhat fresh
            return 1_800 // 30 minutes
        }
    }

    // MARK: - Cache Control Methods

    nonisolated func setCacheEnabled(_ enabled: Bool) async {
        await state.setCacheEnabled(enabled)
        if !enabled {
            await cache.clear()
        }
    }

    nonisolated func clearCache() async {
        await cache.clear()
    }

    nonisolated func invalidateCache(tag: String) async {
        await cache.invalidate(tag: tag)
    }

    nonisolated func getCacheStatistics() async -> CacheStatistics {
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

// MARK: - Thread-Safe State Management

private actor OrchestratorState {
    private var providers: [LLMProviderIdentifier: any LLMProvider] = [:]
    private var usageHistory: [UsageRecord] = []
    private(set) var cacheEnabled = true
    private(set) var isConfigured = false

    func setConfigured(_ value: Bool) {
        isConfigured = value
    }

    func setProviders(_ newProviders: [LLMProviderIdentifier: any LLMProvider]) {
        providers = newProviders
    }

    func getProvider(_ identifier: LLMProviderIdentifier) -> (any LLMProvider)? {
        providers[identifier]
    }

    func hasProvider(_ identifier: LLMProviderIdentifier) -> Bool {
        providers[identifier] != nil
    }

    func addUsageRecord(_ record: UsageRecord) {
        usageHistory.append(record)

        // Keep only last 1000 records
        if usageHistory.count > 1_000 {
            usageHistory.removeFirst(usageHistory.count - 1_000)
        }
    }

    func setCacheEnabled(_ enabled: Bool) {
        cacheEnabled = enabled
    }

    func reset() {
        providers.removeAll()
        usageHistory.removeAll()
        cacheEnabled = true
        isConfigured = false
    }
}

// MARK: - Atomic Bool for Thread-Safe Synchronous Access

private final class AtomicBool: @unchecked Sendable {
    private var _value: Bool
    private let lock = NSLock()

    init(initialValue: Bool = false) {
        self._value = initialValue
    }

    var value: Bool {
        get {
            lock.withLock { _value }
        }
        set {
            lock.withLock { _value = newValue }
        }
    }
}

// NSLock extension for withLock pattern
extension NSLock {
    @inlinable
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        return try body()
    }
}
