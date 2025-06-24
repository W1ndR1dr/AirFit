import Foundation

actor AnthropicProvider: LLMProvider, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "anthropic-provider"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready
    
    private let config: LLMProviderConfig
    private let session: URLSession
    
    let identifier = LLMProviderIdentifier.anthropic
    
    let capabilities = LLMCapabilities(
        maxContextTokens: 200_000,
        supportsJSON: true,
        supportsStreaming: true,
        supportsSystemPrompt: true,
        supportsFunctionCalling: true,  // Now supported in beta
        supportsVision: true
    )
    
    let costPerKToken: (input: Double, output: Double) = (0.003, 0.015) // Default Sonnet pricing
    
    init(config: LLMProviderConfig) {
        self.config = config
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        // Don't set API key here for security - set per-request instead
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        let anthropicRequest = try buildAnthropicRequest(from: request)
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.httpBody = try JSONEncoder().encode(anthropicRequest)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.from(LLMError.networkError(URLError(.badServerResponse)))
        }
        
        if httpResponse.statusCode == 401 {
            throw AppError.from(LLMError.invalidAPIKey)
        } else if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap { Double($0) }
            throw AppError.from(LLMError.rateLimitExceeded(retryAfter: retryAfter))
        } else if httpResponse.statusCode >= 400 {
            let errorMessage = try? JSONDecoder().decode(AnthropicError.self, from: data)
            throw AppError.from(LLMError.serverError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?.error.message
            ))
        }
        
        let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return try mapToLLMResponse(anthropicResponse, model: request.model)
    }
    
    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let streamRequest = LLMRequest(
                        messages: request.messages,
                        model: request.model,
                        temperature: request.temperature,
                        maxTokens: request.maxTokens,
                        systemPrompt: request.systemPrompt,
                        responseFormat: request.responseFormat,
                        stream: true,
                        metadata: request.metadata,
                        thinkingBudgetTokens: request.thinkingBudgetTokens
                    )
                    
                    let anthropicRequest = try buildAnthropicRequest(from: streamRequest)
                    let url = URL(string: "https://api.anthropic.com/v1/messages")!
                    
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
                    urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
                    urlRequest.httpBody = try JSONEncoder().encode(anthropicRequest)
                    
                    let (bytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw AppError.from(LLMError.networkError(URLError(.badServerResponse)))
                    }
                    
                    var buffer = ""
                    
                    for try await byte in bytes {
                        buffer.append(Character(UnicodeScalar(byte)))
                        
                        if buffer.hasSuffix("\n\n") {
                            let lines = buffer.split(separator: "\n")
                            buffer = ""
                            
                            for line in lines {
                                if line.hasPrefix("data: ") {
                                    let jsonData = line.dropFirst(6)
                                    if jsonData == "[DONE]" {
                                        continuation.finish()
                                        return
                                    }
                                    
                                    if let data = jsonData.data(using: .utf8),
                                       let event = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: data) {
                                        if let chunk = mapToStreamChunk(event) {
                                            continuation.yield(chunk)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func validateAPIKey(_ key: String) async throws -> Bool {
        let testRequest = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Hi", name: nil, attachments: nil)],
            model: LLMModel.claude4Sonnet.identifier,
            temperature: 0,
            maxTokens: 1,
            systemPrompt: nil,
            responseFormat: nil,
            stream: false,
            metadata: [:],
            thinkingBudgetTokens: nil
        )
        
        do {
            _ = try await complete(testRequest)
            return true
        } catch LLMError.invalidAPIKey {
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    private func buildAnthropicRequest(from request: LLMRequest) throws -> AnthropicRequest {
        var messages = request.messages.map { msg in
            AnthropicMessage(role: msg.role.rawValue, content: msg.content)
        }
        
        // Handle system prompt
        if let systemPrompt = request.systemPrompt {
            messages.insert(
                AnthropicMessage(role: "system", content: systemPrompt),
                at: 0
            )
        }
        
        return AnthropicRequest(
            model: request.model,
            messages: messages,
            max_tokens: request.maxTokens ?? 4_096,
            temperature: request.temperature,
            stream: request.stream
        )
    }
    
    private func mapToLLMResponse(_ response: AnthropicResponse, model: String) throws -> LLMResponse {
        guard let content = response.content.first?.text else {
            throw AppError.from(LLMError.invalidResponse("No content in response"))
        }
        
        return LLMResponse(
            content: content,
            model: model,
            usage: LLMResponse.TokenUsage(
                promptTokens: response.usage.input_tokens,
                completionTokens: response.usage.output_tokens
            ),
            finishReason: mapFinishReason(response.stop_reason),
            metadata: ["id": response.id]
        )
    }
    
    private func mapToStreamChunk(_ event: AnthropicStreamEvent) -> LLMStreamChunk? {
        switch event.type {
        case "content_block_delta":
            return LLMStreamChunk(
                delta: event.delta?.text ?? "",
                isFinished: false,
                usage: nil
            )
        case "message_stop":
            return LLMStreamChunk(
                delta: "",
                isFinished: true,
                usage: event.usage.map { usage in
                    LLMResponse.TokenUsage(
                        promptTokens: usage.input_tokens,
                        completionTokens: usage.output_tokens
                    )
                }
            )
        default:
            return nil
        }
    }
    
    private func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
        switch reason {
        case "end_turn", "stop_sequence":
            return .stop
        case "max_tokens":
            return .length
        default:
            return .stop
        }
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [
                "provider": identifier.name,
                "maxTokens": "\(capabilities.maxContextTokens)",
                "supportsFunctions": capabilities.supportsFunctionCalling ? "true" : "false"
            ]
        )
    }
}

// MARK: - Anthropic API Models

private struct AnthropicRequest: Encodable {
    let model: String
    let messages: [AnthropicMessage]
    let max_tokens: Int
    let temperature: Double
    let stream: Bool
}

private struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

private struct AnthropicResponse: Decodable {
    let id: String
    let content: [Content]
    let stop_reason: String?
    let usage: Usage
    
    struct Content: Decodable {
        let text: String
    }
    
    struct Usage: Decodable {
        let input_tokens: Int
        let output_tokens: Int
    }
}

private struct AnthropicStreamEvent: Decodable {
    let type: String
    let delta: Delta?
    let usage: AnthropicResponse.Usage?
    
    struct Delta: Decodable {
        let text: String?
    }
}

private struct AnthropicError: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let message: String
        let type: String
    }
}
