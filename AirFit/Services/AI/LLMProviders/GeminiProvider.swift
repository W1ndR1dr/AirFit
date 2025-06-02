import Foundation

actor GeminiProvider: LLMProvider {
    let identifier = LLMProviderIdentifier.google
    let capabilities = LLMCapabilities(
        maxContextTokens: 32768,
        supportsJSON: true,
        supportsStreaming: true,
        supportsSystemPrompt: true,
        supportsFunctionCalling: false,
        supportsVision: false
    )
    let costPerKToken: (input: Double, output: Double) = (0.0005, 0.0015)
    
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let session = URLSession.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
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
        let geminiRequest = try buildGeminiRequest(request)
        let requestData = try JSONEncoder().encode(geminiRequest)
        
        let url = URL(string: "\(baseURL)/models/\(request.model):generateContent?key=\(apiKey)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestData
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse("Invalid HTTP response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            try handleGeminiError(data, statusCode: httpResponse.statusCode)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return try convertToLLMResponse(geminiResponse, for: request)
    }
    
    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let geminiRequest = try buildGeminiStreamRequest(request)
                    let requestData = try JSONEncoder().encode(geminiRequest)
                    
                    let url = URL(string: "\(baseURL)/models/\(request.model):streamGenerateContent?alt=sse&key=\(apiKey)")!
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = requestData
                    
                    let (asyncBytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw LLMError.invalidResponse("Invalid streaming response")
                    }
                    
                    var buffer = ""
                    for try await byte in asyncBytes {
                        let char = Character(UnicodeScalar(byte)!)
                        buffer.append(char)
                        
                        if buffer.hasSuffix("\n\n") {
                            let lines = buffer.components(separatedBy: "\n").filter { !$0.isEmpty }
                            for line in lines {
                                if line.hasPrefix("data: ") {
                                    let jsonString = String(line.dropFirst(6))
                                    if jsonString != "[DONE]" {
                                        do {
                                            let data = jsonString.data(using: .utf8)!
                                            let streamResponse = try JSONDecoder().decode(GeminiStreamResponse.self, from: data)
                                            let chunk = try convertToStreamChunk(streamResponse)
                                            continuation.yield(chunk)
                                        } catch {
                                            // Skip malformed chunks
                                            continue
                                        }
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
    
    private func buildGeminiRequest(_ request: LLMRequest) throws -> GeminiRequest {
        let contents = try convertMessagesToContents(request.messages)
        
        return GeminiRequest(
            contents: contents,
            generationConfig: GeminiGenerationConfig(
                temperature: request.temperature,
                maxOutputTokens: request.maxTokens ?? 2048,
                topP: 1.0, // Default top-P since it's not in LLMRequest
                candidateCount: 1
            ),
            safetySettings: [
                GeminiSafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_MEDIUM_AND_ABOVE"),
                GeminiSafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_MEDIUM_AND_ABOVE")
            ]
        )
    }
    
    private func buildGeminiStreamRequest(_ request: LLMRequest) throws -> GeminiRequest {
        let streamRequest = try buildGeminiRequest(request)
        // Gemini doesn't have a separate stream flag - streaming is controlled by endpoint
        return streamRequest
    }
    
    private func convertMessagesToContents(_ messages: [LLMMessage]) throws -> [GeminiContent] {
        return messages.map { message in
            let role = message.role == .assistant ? "model" : "user"
            return GeminiContent(
                role: role,
                parts: [GeminiPart(text: message.content)]
            )
        }
    }
    
    private func convertToLLMResponse(_ response: GeminiResponse, for request: LLMRequest) throws -> LLMResponse {
        guard let candidate = response.candidates.first,
              let content = candidate.content.parts.first?.text else {
            throw LLMError.invalidResponse("Empty response from Gemini")
        }
        
        let usage = LLMResponse.TokenUsage(
            promptTokens: response.usageMetadata?.promptTokenCount ?? 0,
            completionTokens: response.usageMetadata?.candidatesTokenCount ?? 0
        )
        
        return LLMResponse(
            content: content,
            model: request.model,
            usage: usage,
            finishReason: mapFinishReason(candidate.finishReason),
            metadata: [:]
        )
    }
    
    private func convertToStreamChunk(_ response: GeminiStreamResponse) throws -> LLMStreamChunk {
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
    
    private func mapFinishReason(_ reason: String?) -> LLMResponse.FinishReason {
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
}

struct GeminiContent: Codable {
    let role: String
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerationConfig: Codable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    let candidateCount: Int
}

struct GeminiSafetySetting: Codable {
    let category: String
    let threshold: String
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
}

struct GeminiStreamResponse: Codable {
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

// MARK: - Gemini Model Configurations

extension GeminiProvider {
    static var supportedModels: [String] {
        [
            "gemini-1.5-pro",
            "gemini-1.5-flash",
            "gemini-1.0-pro"
        ]
    }
}

// MARK: - Enhanced Error Handling

extension GeminiProvider {
    private func handleGeminiError(_ data: Data, statusCode: Int) throws -> Never {
        if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
            let message = errorResponse.error.message
            
            switch statusCode {
            case 400:
                if message.contains("API key") {
                    throw LLMError.invalidAPIKey
                } else {
                    throw LLMError.invalidResponse(message)
                }
            case 401:
                throw LLMError.invalidAPIKey
            case 429:
                throw LLMError.rateLimitExceeded(retryAfter: nil)
            case 500...599:
                throw LLMError.serverError(statusCode: statusCode, message: message)
            default:
                throw LLMError.invalidResponse("HTTP \(statusCode): \(message)")
            }
        } else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.invalidResponse("HTTP \(statusCode): \(errorText)")
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