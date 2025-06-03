import Foundation
import Combine

/// Enhanced AI API Service with full streaming support and multi-provider handling
@MainActor
final class EnhancedAIAPIService: AIServiceProtocol {
    
    // MARK: - Properties
    let serviceIdentifier = "ai-api-service"
    private(set) var isConfigured: Bool = false
    private(set) var activeProvider: AIProvider = .openAI
    private(set) var availableModels: [AIModel] = []
    
    private let networkManager: NetworkManagementProtocol
    private let apiKeyManager: APIKeyManagementProtocol
    private let configuration: ServiceConfiguration
    private let llmOrchestrator: LLMOrchestrator
    
    private var currentModel: String?
    private var streamingTasks: Set<Task<Void, Never>> = []
    
    // MARK: - Initialization
    init(
        networkManager: NetworkManagementProtocol = NetworkManager.shared,
        apiKeyManager: APIKeyManagementProtocol,
        configuration: ServiceConfiguration = .shared,
        llmOrchestrator: LLMOrchestrator
    ) {
        self.networkManager = networkManager
        self.apiKeyManager = apiKeyManager
        self.configuration = configuration
        self.llmOrchestrator = llmOrchestrator
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        // Check for configured providers
        let configuredProviders = await apiKeyManager.getAllConfiguredProviders()
        guard !configuredProviders.isEmpty else {
            throw ServiceError.notConfigured
        }
        
        // Use first configured provider as default
        activeProvider = configuredProviders.first ?? configuration.ai.defaultProvider
        currentModel = configuration.ai.defaultModel
        
        // Load available models for provider
        availableModels = getModelsForProvider(activeProvider)
        
        isConfigured = true
        AppLogger.info("AI Service configured with provider: \(activeProvider.rawValue)", category: .services)
    }
    
    func reset() async {
        // Cancel all streaming tasks
        for task in streamingTasks {
            task.cancel()
        }
        streamingTasks.removeAll()
        
        isConfigured = false
        activeProvider = .openAI
        availableModels = []
        currentModel = nil
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
        
        let startTime = Date()
        
        do {
            // Simple health check
            let testRequest = AIRequest(
                messages: [AIMessage(role: .user, content: "Hi", name: nil)],
                model: currentModel ?? configuration.ai.defaultModel,
                systemPrompt: "Reply with 'Hello' only.",
                maxTokens: 10,
                temperature: 0.1,
                stream: false,
                functions: nil
            )
            
            var responseReceived = false
            for try await response in sendRequest(testRequest) {
                if case .textDelta = response {
                    responseReceived = true
                    break
                }
            }
            
            let responseTime = Date().timeIntervalSince(startTime)
            
            return ServiceHealth(
                status: responseReceived ? .healthy : .degraded,
                lastCheckTime: Date(),
                responseTime: responseTime,
                errorMessage: nil,
                metadata: [
                    "provider": activeProvider.rawValue,
                    "model": currentModel ?? "default"
                ]
            )
        } catch {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: error.localizedDescription,
                metadata: ["provider": activeProvider.rawValue]
            )
        }
    }
    
    // MARK: - AIServiceProtocol
    
    func configure(provider: AIProvider, apiKey: String, model: String?) async throws {
        // Save API key
        try await apiKeyManager.saveAPIKey(apiKey, for: provider)
        
        // Update configuration
        activeProvider = provider
        currentModel = model ?? getDefaultModel(for: provider)
        availableModels = getModelsForProvider(provider)
        
        isConfigured = true
        AppLogger.info("AI Service configured with \(provider.rawValue), model: \(currentModel ?? "default")", category: .services)
    }
    
    func sendRequest(_ request: AIRequest) -> AsyncThrowingStream<AIResponse, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                await handleStreamingRequest(request, continuation: continuation)
            }
            
            streamingTasks.insert(task)
            
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.streamingTasks.remove(task)
                }
            }
        }
    }
    
    func validateConfiguration() async throws -> Bool {
        guard isConfigured else {
            return false
        }
        
        // Check if API key exists
        return await apiKeyManager.hasAPIKey(for: activeProvider)
    }
    
    func checkHealth() async -> ServiceHealth {
        await healthCheck()
    }
    
    func estimateTokenCount(for text: String) -> Int {
        // Simple estimation: ~4 characters per token
        return max(1, text.count / 4)
    }
    
    // MARK: - Private Methods
    
    private func handleStreamingRequest(
        _ request: AIRequest,
        continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
    ) async {
        do {
            guard isConfigured else {
                throw ServiceError.notConfigured
            }
            
            // Get API key
            let apiKey = try await apiKeyManager.getAPIKey(for: activeProvider)
            
            // Build URL request
            let urlRequest = try buildURLRequest(for: request, apiKey: apiKey)
            
            // Handle based on provider
            switch activeProvider {
            case .openAI:
                await streamOpenAIResponse(urlRequest: urlRequest, continuation: continuation)
            case .anthropic:
                await streamAnthropicResponse(urlRequest: urlRequest, continuation: continuation)
            case .googleGemini:
                await streamGeminiResponse(urlRequest: urlRequest, continuation: continuation)
            case .openRouter:
                await streamOpenRouterResponse(urlRequest: urlRequest, continuation: continuation)
            }
            
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    private func buildURLRequest(for request: AIRequest, apiKey: String) throws -> URLRequest {
        let url: URL
        var headers: [String: String] = [:]
        
        switch activeProvider {
        case .openAI:
            url = URL(string: "https://api.openai.com/v1/chat/completions")!
            headers["Authorization"] = "Bearer \(apiKey)"
            
        case .anthropic:
            url = URL(string: "https://api.anthropic.com/v1/messages")!
            headers["x-api-key"] = apiKey
            headers["anthropic-version"] = "2023-06-01"
            
        case .googleGemini:
            url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(request.model ?? "gemini-pro"):streamGenerateContent")!
            headers["x-goog-api-key"] = apiKey
            
        case .openRouter:
            url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
            headers["Authorization"] = "Bearer \(apiKey)"
            headers["HTTP-Referer"] = "https://airfit.app"
        }
        
        headers["Content-Type"] = "application/json"
        
        // Build request body
        let body = try buildRequestBody(for: request)
        
        var urlRequest = networkManager.buildRequest(
            url: url,
            method: "POST",
            headers: headers,
            body: body,
            timeout: configuration.ai.timeout
        )
        
        urlRequest.httpBody = body
        
        return urlRequest
    }
    
    private func buildRequestBody(for request: AIRequest) throws -> Data {
        var body: [String: Any] = [:]
        
        switch activeProvider {
        case .openAI, .openRouter:
            body["model"] = request.model ?? currentModel ?? configuration.ai.defaultModel
            body["messages"] = request.messages.map { message in
                ["role": message.role.rawValue, "content": message.content]
            }
            body["stream"] = request.stream
            body["temperature"] = request.temperature ?? 0.7
            if let maxTokens = request.maxTokens {
                body["max_tokens"] = maxTokens
            }
            if let functions = request.functions {
                body["functions"] = functions
                body["function_call"] = "auto"
            }
            
        case .anthropic:
            var messages: [[String: Any]] = []
            var systemMessage: String? = nil
            
            for message in request.messages {
                if message.role == .system {
                    systemMessage = message.content
                } else {
                    messages.append([
                        "role": message.role == .assistant ? "assistant" : "user",
                        "content": message.content
                    ])
                }
            }
            
            body["model"] = request.model ?? "claude-3-sonnet-20240229"
            body["messages"] = messages
            if let system = systemMessage ?? request.systemPrompt {
                body["system"] = system
            }
            body["stream"] = request.stream
            body["temperature"] = request.temperature ?? 0.7
            if let maxTokens = request.maxTokens {
                body["max_tokens"] = maxTokens
            }
            
        case .googleGemini:
            var contents: [[String: Any]] = []
            for message in request.messages {
                contents.append([
                    "role": message.role == .assistant ? "model" : "user",
                    "parts": [["text": message.content]]
                ])
            }
            body["contents"] = contents
            body["generationConfig"] = [
                "temperature": request.temperature ?? 0.7,
                "maxOutputTokens": request.maxTokens ?? 2048
            ]
        }
        
        return try JSONSerialization.data(withJSONObject: body)
    }
    
    // MARK: - Provider-Specific Streaming
    
    private func streamOpenAIResponse(
        urlRequest: URLRequest,
        continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
    ) async {
        let stream = networkManager.performStreamingRequest(urlRequest)
        
        do {
            for try await data in stream {
                guard let line = String(data: data, encoding: .utf8) else { continue }
                
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    
                    if jsonString == "[DONE]" {
                        continuation.yield(.done(usage: nil))
                        continuation.finish()
                        return
                    }
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: jsonData) {
                        
                        if let delta = chunk.choices.first?.delta {
                            if let content = delta.content {
                                continuation.yield(.textDelta(content))
                            }
                            if let functionCall = delta.functionCall {
                                continuation.yield(.functionCall(
                                    name: functionCall.name ?? "",
                                    arguments: functionCall.arguments ?? ""
                                ))
                            }
                        }
                    }
                }
            }
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    private func streamAnthropicResponse(
        urlRequest: URLRequest,
        continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
    ) async {
        let stream = networkManager.performStreamingRequest(urlRequest)
        
        do {
            for try await data in stream {
                guard let line = String(data: data, encoding: .utf8) else { continue }
                
                if line.hasPrefix("data: ") {
                    let jsonString = String(line.dropFirst(6))
                    
                    if let jsonData = jsonString.data(using: .utf8),
                       let event = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: jsonData) {
                        
                        switch event.type {
                        case "content_block_delta":
                            if let text = event.delta?.text {
                                continuation.yield(.textDelta(text))
                            }
                        case "message_stop":
                            continuation.yield(.done(usage: nil))
                            continuation.finish()
                            return
                        default:
                            break
                        }
                    }
                }
            }
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    private func streamGeminiResponse(
        urlRequest: URLRequest,
        continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
    ) async {
        // Gemini uses a different streaming format
        // For now, we'll use non-streaming and simulate streaming
        do {
            let response: GeminiResponse = try await networkManager.performRequest(urlRequest, expecting: GeminiResponse.self)
            
            if let text = response.candidates?.first?.content?.parts?.first?.text {
                // Simulate streaming by yielding chunks
                let chunkSize = 50
                var index = text.startIndex
                
                while index < text.endIndex {
                    let endIndex = text.index(index, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
                    let chunk = String(text[index..<endIndex])
                    continuation.yield(.textDelta(chunk))
                    index = endIndex
                    
                    // Small delay to simulate streaming
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
            }
            
            continuation.yield(.done(usage: nil))
            continuation.finish()
        } catch {
            continuation.finish(throwing: error)
        }
    }
    
    private func streamOpenRouterResponse(
        urlRequest: URLRequest,
        continuation: AsyncThrowingStream<AIResponse, Error>.Continuation
    ) async {
        // OpenRouter uses OpenAI-compatible format
        await streamOpenAIResponse(urlRequest: urlRequest, continuation: continuation)
    }
    
    // MARK: - Helper Methods
    
    private func getModelsForProvider(_ provider: AIProvider) -> [AIModel] {
        switch provider {
        case .openAI:
            return [
                AIModel(id: "gpt-4o", name: "GPT-4 Optimized", contextWindow: 128000),
                AIModel(id: "gpt-4o-mini", name: "GPT-4 Mini", contextWindow: 128000),
                AIModel(id: "gpt-4-turbo", name: "GPT-4 Turbo", contextWindow: 128000),
                AIModel(id: "gpt-3.5-turbo", name: "GPT-3.5 Turbo", contextWindow: 16385)
            ]
        case .anthropic:
            return [
                AIModel(id: "claude-3-opus-20240229", name: "Claude 3 Opus", contextWindow: 200000),
                AIModel(id: "claude-3-sonnet-20240229", name: "Claude 3 Sonnet", contextWindow: 200000),
                AIModel(id: "claude-3-haiku-20240307", name: "Claude 3 Haiku", contextWindow: 200000)
            ]
        case .googleGemini:
            return [
                AIModel(id: "gemini-pro", name: "Gemini Pro", contextWindow: 30720),
                AIModel(id: "gemini-pro-vision", name: "Gemini Pro Vision", contextWindow: 30720)
            ]
        case .openRouter:
            return [
                AIModel(id: "meta-llama/llama-3-70b-instruct", name: "Llama 3 70B", contextWindow: 8192),
                AIModel(id: "mistralai/mixtral-8x7b-instruct", name: "Mixtral 8x7B", contextWindow: 32768)
            ]
        }
    }
    
    private func getDefaultModel(for provider: AIProvider) -> String {
        switch provider {
        case .openAI:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-sonnet-20240229"
        case .googleGemini:
            return "gemini-pro"
        case .openRouter:
            return "meta-llama/llama-3-70b-instruct"
        }
    }
}

// MARK: - Response Models

private struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
            let functionCall: FunctionCall?
            
            private enum CodingKeys: String, CodingKey {
                case content
                case functionCall = "function_call"
            }
        }
        
        let delta: Delta
    }
    
    struct FunctionCall: Decodable {
        let name: String?
        let arguments: String?
    }
    
    let choices: [Choice]
}

private struct AnthropicStreamEvent: Decodable {
    let type: String
    struct Delta: Decodable {
        let text: String?
    }
    let delta: Delta?
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}

// Note: AIModel is now defined in Core/Models/AI/AIModels.swift