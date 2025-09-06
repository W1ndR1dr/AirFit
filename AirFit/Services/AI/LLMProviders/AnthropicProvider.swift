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
        try await LLMRetryHandler.withRetry { [self] in
            let anthropicRequest = try buildAnthropicRequest(from: request)
            let url = URL(string: "https://api.anthropic.com/v1/messages")!

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
            urlRequest.httpBody = try JSONEncoder().encode(anthropicRequest)
            
            // Use request-specific timeout if provided, otherwise use default
            if let timeout = request.timeout {
                urlRequest.timeoutInterval = timeout
            }

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
                        thinkingBudgetTokens: request.thinkingBudgetTokens,
                        timeout: request.timeout
                    )

                    let anthropicRequest = try buildAnthropicRequest(from: streamRequest)
                    let url = URL(string: "https://api.anthropic.com/v1/messages")!

                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
                    urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
                    urlRequest.httpBody = try JSONEncoder().encode(anthropicRequest)
                    
                    // Use request-specific timeout if provided
                    if let timeout = request.timeout {
                        urlRequest.timeoutInterval = timeout
                    }

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
            thinkingBudgetTokens: nil,
            timeout: 10.0  // 10 second timeout for validation
        )

        do {
            _ = try await complete(testRequest)
            return true
        } catch LLMError.invalidAPIKey {
            return false
        }
    }

    // MARK: - Private Helpers

    private nonisolated func buildAnthropicRequest(from request: LLMRequest) throws -> AnthropicRequest {
        var messages = request.messages.map { msg in
            AnthropicMessage(role: msg.role.rawValue, content: .text(msg.content))
        }

        // Handle system prompt with potential caching
        if let systemPrompt = request.systemPrompt {
            // Estimate token count (rough approximation: ~4 chars per token)
            let estimatedTokens = systemPrompt.count / 4
            
            // Use cache_control for prompts >= 1024 tokens
            if estimatedTokens >= 1024 {
                // Create content array with cache_control
                let systemMessage = AnthropicMessage(
                    role: "system",
                    content: .array([
                        AnthropicContentBlock(
                            type: "text",
                            text: systemPrompt,
                            cache_control: ["type": "ephemeral"]
                        )
                    ])
                )
                messages.insert(systemMessage, at: 0)
            } else {
                // Small prompt, no caching benefit
                messages.insert(
                    AnthropicMessage(role: "system", content: .text(systemPrompt)),
                    at: 0
                )
            }
        }

        // Handle structured output via tool forcing
        var tools: [AnthropicTool]?
        var toolChoice: AnthropicRequest.ToolChoice?

        if case .structuredJson(let schema) = request.responseFormat {
            // Create a tool that outputs the structured data
            let tool = AnthropicTool(
                name: schema.name,
                description: schema.description,
                input_schema: try convertToAnthropicSchema(schema)
            )
            tools = [tool]
            // Force the model to use this specific tool
            toolChoice = AnthropicRequest.ToolChoice(type: "tool", name: schema.name)
        }

        return AnthropicRequest(
            model: request.model,
            messages: messages,
            max_tokens: request.maxTokens ?? 4_096,
            temperature: request.temperature,
            stream: request.stream,
            tools: tools,
            tool_choice: toolChoice
        )
    }

    private nonisolated func convertToAnthropicSchema(_ schema: StructuredOutputSchema) throws -> AnthropicInputSchema {
        // Parse the pre-encoded JSON schema
        guard let schemaDict = try? JSONSerialization.jsonObject(with: schema.jsonSchema) as? [String: Any] else {
            throw AppError.from(LLMError.invalidResponse("Invalid schema format"))
        }

        let properties = (schemaDict["properties"] as? [String: Any]) ?? [:]
        let required = (schemaDict["required"] as? [String]) ?? []

        var convertedProperties: [String: AnthropicProperty] = [:]
        for (key, value) in properties {
            if let propDict = value as? [String: Any] {
                convertedProperties[key] = convertPropertyToAnthropic(propDict)
            }
        }

        return AnthropicInputSchema(
            type: "object",
            properties: convertedProperties,
            required: required
        )
    }

    private nonisolated func convertPropertyToAnthropic(_ dict: [String: Any]) -> AnthropicProperty {
        let type = dict["type"] as? String ?? "string"
        let description = dict["description"] as? String ?? ""
        let enumValues = dict["enum"] as? [String]

        var items: Box<AnthropicProperty>?
        if type == "array", let itemsDict = dict["items"] as? [String: Any] {
            items = Box(convertPropertyToAnthropic(itemsDict))
        }

        return AnthropicProperty(
            type: type,
            description: description,
            items: items,
            enum: enumValues,
            minimum: nil,
            maximum: nil
        )
    }

    private nonisolated func mapToLLMResponse(_ response: AnthropicResponse, model: String) throws -> LLMResponse {
        // Combine all text content
        var textContent = ""
        var hasToolUse = false
        var structuredData: Data?

        for content in response.content {
            if let text = content.text {
                textContent += text
            } else if content.type == "tool_use" {
                hasToolUse = true
                // Check if this is structured output via forced tool use
                if let input = content.input {
                    // Convert the tool input to JSON data for structured output
                    let jsonObject = input.mapValues { $0.value }
                    if let data = try? JSONSerialization.data(withJSONObject: jsonObject) {
                        structuredData = data
                        // Also include as text for backward compatibility
                        if let jsonString = String(data: data, encoding: .utf8) {
                            textContent = jsonString
                        }
                    }
                }
            }
        }

        guard !textContent.isEmpty else {
            throw AppError.from(LLMError.invalidResponse("No content in response"))
        }

        // Extract cache metrics if available
        var cacheMetrics: LLMResponse.CacheMetrics?
        if let cacheReadTokens = response.usage.cache_read_input_tokens,
           cacheReadTokens > 0 {
            cacheMetrics = LLMResponse.CacheMetrics(
                cachedTokens: cacheReadTokens,
                totalPromptTokens: response.usage.input_tokens
            )
        }
        
        return LLMResponse(
            content: textContent,
            model: model,
            usage: LLMResponse.TokenUsage(
                promptTokens: response.usage.input_tokens,
                completionTokens: response.usage.output_tokens
            ),
            finishReason: hasToolUse ? .toolCalls : mapFinishReason(response.stop_reason),
            metadata: ["id": response.id],
            structuredData: structuredData,
            cacheMetrics: cacheMetrics
        )
    }

    private nonisolated func mapToStreamChunk(_ event: AnthropicStreamEvent) -> LLMStreamChunk? {
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

    private nonisolated func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
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
    let tools: [AnthropicTool]?
    let tool_choice: ToolChoice?

    struct ToolChoice: Encodable {
        let type: String // "auto", "any", or "tool"
        let name: String? // Only for type "tool"
    }
}

private struct AnthropicMessage: Codable {
    let role: String
    let content: AnthropicContent
}

private enum AnthropicContent: Codable {
    case text(String)
    case array([AnthropicContentBlock])
    case toolUse(id: String, name: String, input: [String: AnthropicValue])
    case toolResult(toolUseId: String, content: String)

    private enum CodingKeys: String, CodingKey {
        case type, text, id, name, input, toolUseId = "tool_use_id", content
    }

    init(from decoder: Decoder) throws {
        // Try to decode as array first
        if let array = try? [AnthropicContentBlock](from: decoder) {
            self = .array(array)
            return
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(String.self, forKey: .type)

        switch type {
        case "tool_use":
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decode(String.self, forKey: .name)
            let input = try container.decode([String: AnthropicValue].self, forKey: .input)
            self = .toolUse(id: id, name: name, input: input)
        case "tool_result":
            let toolUseId = try container.decode(String.self, forKey: .toolUseId)
            let content = try container.decode(String.self, forKey: .content)
            self = .toolResult(toolUseId: toolUseId, content: content)
        default:
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let text):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .array(let blocks):
            var container = encoder.singleValueContainer()
            try container.encode(blocks)
        case .toolUse(let id, let name, let input):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("tool_use", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(input, forKey: .input)
        case .toolResult(let toolUseId, let content):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("tool_result", forKey: .type)
            try container.encode(toolUseId, forKey: .toolUseId)
            try container.encode(content, forKey: .content)
        }
    }
}

private struct AnthropicContentBlock: Codable {
    let type: String
    let text: String?
    let cache_control: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case type, text, cache_control
    }
    
    init(type: String, text: String, cache_control: [String: String]? = nil) {
        self.type = type
        self.text = text
        self.cache_control = cache_control
    }
}

private struct AnthropicTool: Codable {
    let name: String
    let description: String
    let input_schema: AnthropicInputSchema
}

private struct AnthropicInputSchema: Codable {
    let type: String
    let properties: [String: AnthropicProperty]
    let required: [String]
}

private struct AnthropicProperty: Codable {
    let type: String
    let description: String
    let items: Box<AnthropicProperty>?
    let `enum`: [String]?
    let minimum: Double?
    let maximum: Double?
}

// Box type to handle recursive property
private final class Box<T: Codable>: Codable {
    let value: T

    init(_ value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(T.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

private struct AnthropicValue: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnthropicValue].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnthropicValue].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnthropicValue($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnthropicValue($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}

private struct AnthropicResponse: Decodable {
    let id: String
    let content: [Content]
    let stop_reason: String?
    let usage: Usage

    struct Content: Decodable {
        let type: String
        let text: String?
        let id: String?
        let name: String?
        let input: [String: AnthropicValue]?

        enum CodingKeys: String, CodingKey {
            case type, text, id, name, input
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)

            switch type {
            case "text":
                text = try container.decode(String.self, forKey: .text)
                id = nil
                name = nil
                input = nil
            case "tool_use":
                text = nil
                id = try container.decode(String.self, forKey: .id)
                name = try container.decode(String.self, forKey: .name)
                input = try container.decode([String: AnthropicValue].self, forKey: .input)
            default:
                text = try? container.decode(String.self, forKey: .text)
                id = nil
                name = nil
                input = nil
            }
        }
    }

    struct Usage: Decodable {
        let input_tokens: Int
        let output_tokens: Int
        let cache_creation_input_tokens: Int?
        let cache_read_input_tokens: Int?
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
