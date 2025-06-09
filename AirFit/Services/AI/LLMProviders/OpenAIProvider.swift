import Foundation

actor OpenAIProvider: LLMProvider, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "openai-provider"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready
    
    private let config: LLMProviderConfig
    private let session: URLSession
    
    let identifier = LLMProviderIdentifier.openai
    
    let capabilities = LLMCapabilities(
        maxContextTokens: 128_000,
        supportsJSON: true,
        supportsStreaming: true,
        supportsSystemPrompt: true,
        supportsFunctionCalling: true,
        supportsVision: true
    )
    
    let costPerKToken: (input: Double, output: Double) = (0.01, 0.03) // Default GPT-4 Turbo pricing
    
    init(config: LLMProviderConfig) {
        self.config = config
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        // Don't set authorization header here for security - set per-request instead
        
        self.session = URLSession(configuration: sessionConfig)
    }
    
    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        let openAIRequest = try buildOpenAIRequest(from: request)
        let baseURL = config.baseURL ?? URL(string: "https://api.openai.com")!
        let url = baseURL.appendingPathComponent("/v1/chat/completions")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(openAIRequest)
        
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
            let errorMessage = try? JSONDecoder().decode(OpenAIError.self, from: data)
            throw AppError.from(LLMError.serverError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?.error.message
            ))
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return try mapToLLMResponse(openAIResponse)
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
                    
                    let openAIRequest = try buildOpenAIRequest(from: streamRequest)
                    let baseURL = config.baseURL ?? URL(string: "https://api.openai.com")!
                    let url = baseURL.appendingPathComponent("/v1/chat/completions")
                    
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = try JSONEncoder().encode(openAIRequest)
                    
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
                                       let event = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: data) {
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
            model: LLMModel.gpt35Turbo.identifier,
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
    
    private func buildOpenAIRequest(from request: LLMRequest) throws -> OpenAIRequest {
        var messages = request.messages.map { msg in
            OpenAIMessage(role: msg.role.rawValue, content: msg.content)
        }
        
        // Handle system prompt
        if let systemPrompt = request.systemPrompt {
            messages.insert(
                OpenAIMessage(role: "system", content: systemPrompt),
                at: 0
            )
        }
        
        var openAIRequest = OpenAIRequest(
            model: request.model,
            messages: messages,
            temperature: request.temperature,
            max_tokens: request.maxTokens,
            stream: request.stream
        )
        
        // Handle JSON response format
        if case .json = request.responseFormat {
            openAIRequest.response_format = ResponseFormat(type: "json_object")
        }
        
        return openAIRequest
    }
    
    private func mapToLLMResponse(_ response: OpenAIResponse) throws -> LLMResponse {
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw AppError.from(LLMError.invalidResponse("No content in response"))
        }
        
        return LLMResponse(
            content: content,
            model: response.model,
            usage: LLMResponse.TokenUsage(
                promptTokens: response.usage?.prompt_tokens ?? 0,
                completionTokens: response.usage?.completion_tokens ?? 0
            ),
            finishReason: mapFinishReason(choice.finish_reason),
            metadata: ["id": response.id]
        )
    }
    
    private func mapToStreamChunk(_ event: OpenAIStreamResponse) -> LLMStreamChunk? {
        guard let choice = event.choices.first else { return nil }
        
        if let content = choice.delta?.content {
            return LLMStreamChunk(
                delta: content,
                isFinished: false,
                usage: nil
            )
        } else if choice.finish_reason != nil {
            return LLMStreamChunk(
                delta: "",
                isFinished: true,
                usage: nil // OpenAI doesn't provide usage in stream
            )
        }
        
        return nil
    }
    
    private func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
        switch reason {
        case "stop":
            return .stop
        case "length":
            return .length
        case "content_filter":
            return .contentFilter
        case "tool_calls", "function_call":
            return .toolCalls
        default:
            return .stop
        }
    }
}

// MARK: - OpenAI API Models

private struct OpenAIRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let max_tokens: Int?
    let stream: Bool
    var response_format: ResponseFormat?
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct ResponseFormat: Codable {
    let type: String
}

private struct OpenAIResponse: Decodable {
    let id: String
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Decodable {
        let message: Message
        let finish_reason: String?
        
        struct Message: Decodable {
            let content: String?
        }
    }
    
    struct Usage: Decodable {
        let prompt_tokens: Int
        let completion_tokens: Int
    }
}

private struct OpenAIStreamResponse: Decodable {
    let id: String
    let choices: [StreamChoice]
    
    struct StreamChoice: Decodable {
        let delta: Delta?
        let finish_reason: String?
        
        struct Delta: Decodable {
            let content: String?
        }
    }
}

private struct OpenAIError: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let message: String
        let type: String
        let code: String?
    }
}

// MARK: - ServiceProtocol Extension

extension OpenAIProvider {
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