import Foundation

// MARK: - Core Protocol
protocol LLMProvider: Actor {
    var identifier: LLMProviderIdentifier { get }
    var capabilities: LLMCapabilities { get }
    var costPerKToken: (input: Double, output: Double) { get }
    
    func complete(_ request: LLMRequest) async throws -> LLMResponse
    func stream(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamChunk, Error>
    func validateAPIKey(_ key: String) async throws -> Bool
}

// MARK: - Provider Identifier
struct LLMProviderIdentifier: Hashable, Sendable {
    let name: String
    let version: String
    
    static let anthropic = LLMProviderIdentifier(name: "Anthropic", version: "2024-01")
    static let openai = LLMProviderIdentifier(name: "OpenAI", version: "v1")
    static let google = LLMProviderIdentifier(name: "Google", version: "v1beta")
}

// MARK: - Capabilities
struct LLMCapabilities: Sendable {
    let maxContextTokens: Int
    let supportsJSON: Bool
    let supportsStreaming: Bool
    let supportsSystemPrompt: Bool
    let supportsFunctionCalling: Bool
    let supportsVision: Bool
}

// MARK: - Request/Response Models
struct LLMRequest: Sendable {
    let messages: [LLMMessage]
    let model: String
    let temperature: Double
    let maxTokens: Int?
    let systemPrompt: String?
    let responseFormat: ResponseFormat?
    let stream: Bool
    let metadata: [String: String]
    let thinkingBudgetTokens: Int? // For Gemini 2.5 Flash thinking mode
    
    enum ResponseFormat: Sendable {
        case text
        case json(schema: String? = nil)
    }
}

struct LLMMessage: Sendable {
    let role: Role
    let content: String
    let name: String?
    let attachments: [MessageAttachment]? // For multimodal content
    
    enum Role: String, Sendable {
        case system
        case user
        case assistant
    }
    
    struct MessageAttachment: Sendable {
        let type: AttachmentType
        let data: Data
        let mimeType: String
        
        enum AttachmentType: String, Sendable {
            case image
            case audio
            case video
            case document
        }
    }
}

struct LLMResponse: Sendable {
    let content: String
    let model: String
    let usage: TokenUsage
    let finishReason: FinishReason
    let metadata: [String: String]
    
    struct TokenUsage: Codable, Sendable {
        let promptTokens: Int
        let completionTokens: Int
        var totalTokens: Int { promptTokens + completionTokens }
        
        func cost(at rates: (input: Double, output: Double)) -> Double {
            let inputCost = Double(promptTokens) / 1_000.0 * rates.input
            let outputCost = Double(completionTokens) / 1_000.0 * rates.output
            return inputCost + outputCost
        }
    }
    
    enum FinishReason: String, Codable, Sendable {
        case stop
        case length
        case contentFilter = "content_filter"
        case toolCalls = "tool_calls"
    }
}

struct LLMStreamChunk: Sendable {
    let delta: String
    let isFinished: Bool
    let usage: LLMResponse.TokenUsage?
}

// MARK: - Errors
enum LLMError: LocalizedError, Sendable {
    case invalidAPIKey
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case contextLengthExceeded(max: Int, requested: Int)
    case invalidResponse(String)
    case networkError(Error)
    case serverError(statusCode: Int, message: String?)
    case timeout
    case cancelled
    case unsupportedFeature(String)
    case contentFilter
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .rateLimitExceeded(let retryAfter):
            if let retry = retryAfter {
                return "Rate limit exceeded. Retry after \(Int(retry)) seconds"
            }
            return "Rate limit exceeded"
        case .contextLengthExceeded(let max, let requested):
            return "Context length exceeded: \(requested) tokens (max: \(max))"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown")"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request cancelled"
        case .unsupportedFeature(let feature):
            return "\(feature) is not supported by this provider"
        case .contentFilter:
            return "Content was filtered due to safety settings"
        }
    }
}
