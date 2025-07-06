import Foundation

actor GeminiProvider: LLMProvider, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "gemini-provider"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready

    let identifier = LLMProviderIdentifier.google
    let capabilities = LLMCapabilities(
        maxContextTokens: 2_097_152,  // 2M tokens for Gemini 1.5 Pro, 1M for 2.5 Flash
        supportsJSON: true,
        supportsStreaming: true,
        supportsSystemPrompt: true,
        supportsFunctionCalling: true,  // Supports function declarations
        supportsVision: true  // Multimodal support
    )
    let costPerKToken: (input: Double, output: Double) = (0.0005, 0.0015)

    private let config: LLMProviderConfig
    private let session: URLSession
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    init(config: LLMProviderConfig) {
        self.config = config

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        self.session = URLSession(configuration: sessionConfig)
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        let url = URL(string: "\(baseURL)/models?key=\(key)")!
        let (_, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        return (200...299).contains(httpResponse.statusCode)
    }

    func complete(_ request: LLMRequest) async throws -> LLMResponse {
        try await LLMRetryHandler.withRetry { [self] in
            let geminiRequest = try buildGeminiRequest(request)
            let requestData = try JSONEncoder().encode(geminiRequest)

            let endpoint = "generateContent"
            let url = URL(string: "\(baseURL)/models/\(request.model):\(endpoint)?key=\(config.apiKey)")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = requestData

            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.from(LLMError.invalidResponse("Invalid HTTP response"))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                try handleGeminiError(data, statusCode: httpResponse.statusCode)
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return try convertToLLMResponse(geminiResponse, for: request)
        }
    }

    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let geminiRequest = try buildGeminiStreamRequest(request)
                    let requestData = try JSONEncoder().encode(geminiRequest)

                    let url = URL(string: "\(baseURL)/models/\(request.model):streamGenerateContent?key=\(config.apiKey)&alt=sse")!
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = requestData

                    let (asyncBytes, response) = try await session.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw AppError.from(LLMError.invalidResponse("Invalid streaming response"))
                    }

                    var buffer = ""
                    for try await byte in asyncBytes {
                        let char = Character(UnicodeScalar(byte))
                        buffer.append(char)

                        if buffer.hasSuffix("\n\n") {
                            let lines = buffer.components(separatedBy: "\n").filter { !$0.isEmpty }
                            for line in lines where line.hasPrefix("data: ") {
                                let jsonString = String(line.dropFirst(6))
                                if jsonString != "[DONE]" {
                                    do {
                                        guard let data = jsonString.data(using: .utf8) else {
                                            // Skip if unable to convert to data
                                            continue
                                        }
                                        let streamResponse = try JSONDecoder().decode(GeminiProviderStreamResponse.self, from: data)
                                        let chunk = try convertToStreamChunk(streamResponse)
                                        continuation.yield(chunk)
                                    } catch {
                                        // Skip malformed chunks
                                        continue
                                    }
                                }
                            }
                            buffer = ""
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Methods

    private nonisolated func buildGeminiRequest(_ request: LLMRequest) throws -> GeminiRequest {
        let contents = try convertMessagesToContents(request.messages)

        // Handle structured output configuration
        var responseMimeType: String?
        var responseSchema: [String: Any]?
        var tools: [GeminiTool]?

        switch request.responseFormat {
        case .json:
            // Simple JSON mode - use tools approach for backward compatibility
            tools = [GeminiTool.structuredOutput(schema: """
            {
                "type": "object",
                "properties": {},
                "additionalProperties": true
            }
            """)]
        case .structuredJson(let schema):
            // Native structured output with response schema
            responseMimeType = "application/json"
            if let schemaDict = try? JSONSerialization.jsonObject(with: schema.jsonSchema) as? [String: Any] {
                responseSchema = schemaDict
            }
        case .text, .none:
            break
        }

        return GeminiRequest(
            contents: contents,
            generationConfig: GeminiGenerationConfig(
                temperature: request.temperature,
                maxOutputTokens: request.maxTokens ?? 2_048,
                topP: 1.0, // Default top-P since it's not in LLMRequest
                candidateCount: 1,
                thinkingBudgetTokens: request.thinkingBudgetTokens,
                responseMimeType: responseMimeType,
                responseSchema: responseSchema
            ),
            safetySettings: [
                GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
            ],
            tools: tools
        )
    }

    private nonisolated func buildGeminiStreamRequest(_ request: LLMRequest) throws -> GeminiRequest {
        let streamRequest = try buildGeminiRequest(request)
        // Gemini doesn't have a separate stream flag - streaming is controlled by endpoint
        return streamRequest
    }

    private nonisolated func convertMessagesToContents(_ messages: [LLMMessage]) throws -> [GeminiContent] {
        return messages.map { message in
            let role = message.role == .assistant ? "model" : "user"
            var parts: [GeminiPart] = []

            // Add text content
            if !message.content.isEmpty {
                parts.append(GeminiPart(text: message.content))
            }

            // Add attachments if present
            if let attachments = message.attachments {
                for attachment in attachments {
                    let base64Data = attachment.data.base64EncodedString()
                    let inlineData = GeminiInlineData(
                        mimeType: attachment.mimeType,
                        data: base64Data
                    )
                    parts.append(GeminiPart(inlineData: inlineData))
                }
            }

            return GeminiContent(
                role: role,
                parts: parts
            )
        }
    }

    private nonisolated func convertToLLMResponse(_ response: GeminiResponse, for request: LLMRequest) throws -> LLMResponse {
        guard let candidate = response.candidates.first,
              let content = candidate.content.parts.first?.text else {
            throw AppError.from(LLMError.invalidResponse("Empty response from Gemini"))
        }

        let usage = LLMResponse.TokenUsage(
            promptTokens: response.usageMetadata?.promptTokenCount ?? 0,
            completionTokens: response.usageMetadata?.candidatesTokenCount ?? 0
        )

        // Check if response is structured JSON
        var structuredData: Data?
        if case .structuredJson = request.responseFormat {
            if let jsonData = content.data(using: .utf8),
               let _ = try? JSONSerialization.jsonObject(with: jsonData) {
                structuredData = jsonData
            }
        }

        return LLMResponse(
            content: content,
            model: request.model,
            usage: usage,
            finishReason: mapFinishReason(candidate.finishReason),
            metadata: [:],
            structuredData: structuredData
        )
    }

    private nonisolated func convertToStreamChunk(_ response: GeminiProviderStreamResponse) throws -> LLMStreamChunk {
        guard let candidate = response.candidates?.first,
              let content = candidate.content.parts.first?.text else {
            return LLMStreamChunk(
                delta: "",
                isFinished: false,
                usage: nil
            )
        }

        let isFinished = candidate.finishReason != nil

        return LLMStreamChunk(
            delta: content,
            isFinished: isFinished,
            usage: nil
        )
    }

    private nonisolated func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
        switch reason {
        case "STOP":
            return .stop
        case "MAX_TOKENS":
            return .length
        case "SAFETY":
            return .contentFilter
        case "RECITATION":
            return .contentFilter
        default:
            return .stop
        }
    }
}

// MARK: - Gemini API Models

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
    let safetySettings: [GeminiSafetySetting]
    let tools: [GeminiTool]? // For structured output and function calling
}

struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?

    init(text: String) {
        self.text = text
        self.inlineData = nil
    }

    init(inlineData: GeminiInlineData) {
        self.text = nil
        self.inlineData = inlineData
    }
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String // Base64 encoded
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    let candidateCount: Int
    let thinkingBudgetTokens: Int? // For Gemini 2.5 Flash thinking mode
    let responseMimeType: String? // For structured output
    let responseSchema: [String: Any]? // JSON schema for structured output

    enum CodingKeys: String, CodingKey {
        case temperature
        case maxOutputTokens
        case topP
        case candidateCount
        case thinkingBudgetTokens
        case responseMimeType
        case responseSchema
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(maxOutputTokens, forKey: .maxOutputTokens)
        try container.encode(topP, forKey: .topP)
        try container.encode(candidateCount, forKey: .candidateCount)
        try container.encodeIfPresent(thinkingBudgetTokens, forKey: .thinkingBudgetTokens)
        try container.encodeIfPresent(responseMimeType, forKey: .responseMimeType)

        // Custom encoding for responseSchema dictionary
        if let schema = responseSchema {
            // Encode as AnyCodable wrapper
            let wrapper = AnyCodable(schema)
            try container.encode(wrapper, forKey: .responseSchema)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = try container.decode(Double.self, forKey: .temperature)
        maxOutputTokens = try container.decode(Int.self, forKey: .maxOutputTokens)
        topP = try container.decode(Double.self, forKey: .topP)
        candidateCount = try container.decode(Int.self, forKey: .candidateCount)
        thinkingBudgetTokens = try container.decodeIfPresent(Int.self, forKey: .thinkingBudgetTokens)
        responseMimeType = try container.decodeIfPresent(String.self, forKey: .responseMimeType)
        responseSchema = nil // We don't decode this from responses
    }

    init(temperature: Double, maxOutputTokens: Int, topP: Double, candidateCount: Int, thinkingBudgetTokens: Int?, responseMimeType: String?, responseSchema: [String: Any]?) {
        self.temperature = temperature
        self.maxOutputTokens = maxOutputTokens
        self.topP = topP
        self.candidateCount = candidateCount
        self.thinkingBudgetTokens = thinkingBudgetTokens
        self.responseMimeType = responseMimeType
        self.responseSchema = responseSchema
    }
}

struct GeminiSafetySetting: Codable {
    let category: String
    let threshold: String
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
}

struct GeminiProviderStreamResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int
    let candidatesTokenCount: Int
    let totalTokenCount: Int
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

// MARK: - Tool Support for Structured Output

struct GeminiTool: Codable {
    let type: String // "codeExecution" or "structuredOutput"
    let codeExecution: GeminiCodeExecution?
    let structuredOutput: GeminiStructuredOutput?

    static func codeExecution() -> GeminiTool {
        GeminiTool(
            type: "codeExecution",
            codeExecution: GeminiCodeExecution(),
            structuredOutput: nil
        )
    }

    static func structuredOutput(schema: String) -> GeminiTool {
        GeminiTool(
            type: "structuredOutput",
            codeExecution: nil,
            structuredOutput: GeminiStructuredOutput(schema: schema)
        )
    }
}

struct GeminiCodeExecution: Codable {
    // Empty for now, as per the guide
}

struct GeminiStructuredOutput: Codable {
    let schema: String // JSON schema as string
}

// MARK: - Gemini Model Configurations

extension GeminiProvider {
    static var supportedModels: [String] {
        [
            "gemini-2.5-flash-preview-05-20",
            "gemini-2.5-flash-thinking-preview-05-20",
            "gemini-2.0-flash-thinking-exp",
            "gemini-2.0-flash-exp",
            "gemini-1.5-pro-002",
            "gemini-1.5-flash-002",
            "gemini-1.0-pro"
        ]
    }
}

// MARK: - Enhanced Error Handling

extension GeminiProvider {
    private nonisolated func handleGeminiError(_ data: Data, statusCode: Int) throws -> Never {
        if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
            let message = errorResponse.error.message

            switch statusCode {
            case 400:
                if message.contains("API key") || message.contains("Invalid API key") {
                    throw AppError.from(LLMError.invalidAPIKey)
                } else if message.contains("safety") {
                    throw AppError.from(LLMError.contentFilter)
                } else {
                    throw AppError.from(LLMError.invalidResponse(message))
                }
            case 401, 403:
                throw AppError.from(LLMError.invalidAPIKey)
            case 429:
                // Extract retry-after if available from headers
                throw AppError.from(LLMError.rateLimitExceeded(retryAfter: nil))
            case 500...599:
                throw AppError.from(LLMError.serverError(statusCode: statusCode, message: message))
            default:
                throw AppError.from(LLMError.invalidResponse("HTTP \(statusCode): \(message)"))
            }
        } else {
            // Try to parse as plain text error
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"

            switch statusCode {
            case 429:
                throw AppError.from(LLMError.rateLimitExceeded(retryAfter: nil))
            case 500...599:
                throw AppError.from(LLMError.serverError(statusCode: statusCode, message: errorText))
            default:
                throw AppError.from(LLMError.invalidResponse("HTTP \(statusCode): \(errorText)"))
            }
        }
    }
}

struct GeminiErrorResponse: Codable {
    let error: GeminiError
}

struct GeminiError: Codable {
    let code: Int
    let message: String
    let status: String
}

// MARK: - ServiceProtocol Extension

extension GeminiProvider {
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
