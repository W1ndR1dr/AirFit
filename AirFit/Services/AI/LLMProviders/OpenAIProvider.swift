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

    let costPerKToken: (input: Double, output: Double) = (0.01, 0.03) // Placeholder pricing

    init(config: LLMProviderConfig) {
        self.config = config

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        // Don't set authorization header here for security - set per-request instead

        self.session = URLSession(configuration: sessionConfig)
    }

    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        try await LLMRetryHandler.withRetry { [self] in
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
                    var accumulatedContent = ""

                    // Estimate prompt tokens from the request
                    let promptTokens = estimateTokenCount(for: request)

                    for try await byte in bytes {
                        buffer.append(Character(UnicodeScalar(byte)))

                        if buffer.hasSuffix("\n\n") {
                            let lines = buffer.split(separator: "\n")
                            buffer = ""

                            for line in lines {
                                if line.hasPrefix("data: ") {
                                    let jsonData = line.dropFirst(6)
                                    if jsonData == "[DONE]" {
                                        // Send final chunk with estimated usage
                                        let completionTokens = estimateTokens(accumulatedContent)
                                        let usage = LLMResponse.TokenUsage(
                                            promptTokens: promptTokens,
                                            completionTokens: completionTokens
                                        )
                                        continuation.yield(LLMStreamChunk(
                                            delta: "",
                                            isFinished: true,
                                            usage: usage
                                        ))
                                        continuation.finish()
                                        return
                                    }

                                    if let data = jsonData.data(using: .utf8),
                                       let event = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: data) {
                                        if let chunk = mapToStreamChunk(event) {
                                            if !chunk.delta.isEmpty {
                                                accumulatedContent += chunk.delta
                                            }
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
            model: LLMModel.gpt5Mini.identifier,
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

    private nonisolated func buildOpenAIRequest(from request: LLMRequest) throws -> OpenAIRequest {
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
            stream: request.stream,
            response_format: nil,
            tools: nil,
            tool_choice: nil
        )

        // Handle response format
        switch request.responseFormat {
        case .json:
            openAIRequest.response_format = ResponseFormat(type: "json_object", json_schema: nil)
        case .structuredJson(let schema):
            openAIRequest.response_format = ResponseFormat(
                type: "json_schema",
                json_schema: ResponseFormat.JSONSchema(
                    name: schema.name,
                    schema: convertToOpenAISchema(schema),
                    strict: schema.strict
                )
            )
        case .text, .none:
            break
        }

        // TODO: Add tools when LLMRequest supports functions
        // For now, check metadata for function definitions
        // This would need to be properly implemented when LLMRequest is extended

        return openAIRequest
    }

    private nonisolated func convertToOpenAISchema(_ schema: StructuredOutputSchema) -> ResponseFormat.JSONSchema.Schema {
        // Parse the pre-encoded JSON schema
        guard let schemaDict = try? JSONSerialization.jsonObject(with: schema.jsonSchema) as? [String: Any] else {
            // Fallback to empty schema
            return ResponseFormat.JSONSchema.Schema(
                properties: [:],
                required: []
            )
        }

        // Convert to OpenAI's format
        let properties = (schemaDict["properties"] as? [String: Any]) ?? [:]
        let required = (schemaDict["required"] as? [String]) ?? []

        var convertedProperties: [String: ResponseFormat.JSONSchema.Schema.Property] = [:]
        for (key, value) in properties {
            if let propDict = value as? [String: Any] {
                convertedProperties[key] = convertPropertyFromDict(propDict)
            }
        }

        return ResponseFormat.JSONSchema.Schema(
            properties: convertedProperties,
            required: required
        )
    }

    private nonisolated func convertPropertyFromDict(_ dict: [String: Any]) -> ResponseFormat.JSONSchema.Schema.Property {
        let type = dict["type"] as? String ?? "string"
        let description = dict["description"] as? String
        let enumValues = dict["enum"] as? [String]

        var items: ResponseFormat.JSONSchema.Schema.Property.Items?
        if type == "array", let itemsDict = dict["items"] as? [String: Any] {
            let itemType = itemsDict["type"] as? String ?? "string"
            var itemProperties: [String: ResponseFormat.JSONSchema.Schema.Property]?

            if itemType == "object", let props = itemsDict["properties"] as? [String: Any] {
                itemProperties = props.compactMapValues { propValue in
                    guard let propDict = propValue as? [String: Any] else { return nil }
                    return convertPropertyFromDict(propDict)
                }
            }

            items = ResponseFormat.JSONSchema.Schema.Property.Items(
                type: itemType,
                properties: itemProperties
            )
        }

        var properties: [String: ResponseFormat.JSONSchema.Schema.Property]?
        if type == "object", let props = dict["properties"] as? [String: Any] {
            properties = props.compactMapValues { propValue in
                guard let propDict = propValue as? [String: Any] else { return nil }
                return convertPropertyFromDict(propDict)
            }
        }

        return ResponseFormat.JSONSchema.Schema.Property(
            type: type,
            description: description,
            items: items,
            properties: properties,
            enum: enumValues
        )
    }

    private nonisolated func mapToLLMResponse(_ response: OpenAIResponse) throws -> LLMResponse {
        guard let choice = response.choices.first else {
            throw AppError.from(LLMError.invalidResponse("No choices in response"))
        }

        // Check for refusal (structured outputs safety feature)
        if choice.message.refusal != nil {
            throw AppError.from(LLMError.contentFilter)
        }

        var content = choice.message.content ?? ""
        var hasToolCalls = false

        // Handle tool calls
        if let toolCalls = choice.message.tool_calls, !toolCalls.isEmpty {
            hasToolCalls = true
            // TODO: Properly handle tool calls when LLMResponse supports it
            // For now, append tool information to content
            for toolCall in toolCalls {
                content += "\n[Tool Call: \(toolCall.function.name) with args: \(toolCall.function.arguments)]"
            }
        }

        guard !content.isEmpty else {
            throw AppError.from(LLMError.invalidResponse("No content in response"))
        }

        // Check for structured data
        var structuredData: Data?
        if let jsonContent = content.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: jsonContent) {
            // Valid JSON, store as structured data
            structuredData = jsonContent
        }

        return LLMResponse(
            content: content,
            model: response.model,
            usage: LLMResponse.TokenUsage(
                promptTokens: response.usage?.prompt_tokens ?? 0,
                completionTokens: response.usage?.completion_tokens ?? 0
            ),
            finishReason: hasToolCalls ? .toolCalls : mapFinishReason(choice.finish_reason),
            metadata: ["id": response.id],
            structuredData: structuredData,
            cacheMetrics: nil  // TODO: Extract from response.usage.prompt_tokens_details.cached_tokens when available
        )
    }

    private nonisolated func mapToStreamChunk(_ event: OpenAIStreamResponse) -> LLMStreamChunk? {
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

    private nonisolated func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
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

    // MARK: - Token Estimation

    private nonisolated func estimateTokenCount(for request: LLMRequest) -> Int {
        var totalChars = 0

        // Count system prompt
        if let systemPrompt = request.systemPrompt {
            totalChars += systemPrompt.count
        }

        // Count messages
        for message in request.messages {
            totalChars += message.content.count
            totalChars += 10 // Overhead for role and formatting
        }

        // Rough estimation: ~4 characters per token for English
        return max(totalChars / 4, 1)
    }

    private nonisolated func estimateTokens(_ text: String) -> Int {
        // More accurate estimation considering punctuation and structure
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let punctuationCount = text.filter { ".,;:!?()[]{}\"'".contains($0) }.count

        // OpenAI tokenization is roughly:
        // - 1 token per word
        // - Additional tokens for punctuation
        // - ~0.75 tokens per word on average for English
        let baseTokens = words.count
        let punctuationTokens = punctuationCount / 3 // Some punctuation is attached to words

        return max(baseTokens + punctuationTokens, 1)
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
    var tools: [OpenAITool]?
    var tool_choice: String?
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: OpenAIContent?
    let tool_calls: [ToolCall]?
    let tool_call_id: String?

    // Simple text message constructor
    init(role: String, content: String) {
        self.role = role
        self.content = .text(content)
        self.tool_calls = nil
        self.tool_call_id = nil
    }

    // Tool response constructor
    init(role: String, content: String, toolCallId: String) {
        self.role = role
        self.content = .text(content)
        self.tool_calls = nil
        self.tool_call_id = toolCallId
    }
}

private enum OpenAIContent: Codable {
    case text(String)
    case toolResponse(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        self = .text(text)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text), .toolResponse(let text):
            try container.encode(text)
        }
    }
}

private struct OpenAITool: Codable {
    let type: String
    let function: OpenAIFunction
}

private struct OpenAIFunction: Codable {
    let name: String
    let description: String
    let parameters: OpenAIParameters
}

private struct OpenAIParameters: Codable {
    let type: String
    let properties: [String: OpenAIProperty]
    let required: [String]
}

private struct OpenAIProperty: Codable {
    let type: String
    let description: String
    let `enum`: [String]?
    let items: Box<OpenAIProperty>?
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

private struct ToolCall: Codable {
    let id: String
    let type: String
    let function: FunctionCall

    struct FunctionCall: Codable {
        let name: String
        let arguments: String
    }
}

private struct ResponseFormat: Codable {
    let type: String
    let json_schema: JSONSchema?

    struct JSONSchema: Codable {
        let name: String
        let schema: Schema
        let strict: Bool

        struct Schema: Codable {
            var type: String = "object"
            let properties: [String: Property]
            let required: [String]
            var additionalProperties: Bool = false

            struct Property: Codable {
                let type: String
                let description: String?
                let items: Items?
                let properties: [String: Property]?
                let `enum`: [String]?

                struct Items: Codable {
                    let type: String
                    let properties: [String: Property]?
                }
            }
        }
    }
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
            let tool_calls: [ToolCall]?
            let refusal: String? // For structured outputs
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
