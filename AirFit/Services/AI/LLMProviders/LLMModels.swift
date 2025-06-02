import Foundation

// MARK: - Model Selection
enum LLMModel {
    // Anthropic
    case claude3Opus
    case claude3Sonnet
    case claude3Haiku
    case claude2
    
    // OpenAI
    case gpt4Turbo
    case gpt4
    case gpt35Turbo
    
    // Google Gemini
    case gemini15Pro
    case gemini15Flash
    case geminiPro
    
    var identifier: String {
        switch self {
        case .claude3Opus: return "claude-3-opus-20240229"
        case .claude3Sonnet: return "claude-3-sonnet-20240229"
        case .claude3Haiku: return "claude-3-haiku-20240307"
        case .claude2: return "claude-2.1"
        case .gpt4Turbo: return "gpt-4-turbo-preview"
        case .gpt4: return "gpt-4"
        case .gpt35Turbo: return "gpt-3.5-turbo"
        case .gemini15Pro: return "gemini-1.5-pro"
        case .gemini15Flash: return "gemini-1.5-flash"
        case .geminiPro: return "gemini-1.0-pro"
        }
    }
    
    var provider: LLMProviderIdentifier {
        switch self {
        case .claude3Opus, .claude3Sonnet, .claude3Haiku, .claude2:
            return .anthropic
        case .gpt4Turbo, .gpt4, .gpt35Turbo:
            return .openai
        case .gemini15Pro, .gemini15Flash, .geminiPro:
            return .google
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .claude3Opus, .claude3Sonnet, .claude3Haiku:
            return 200_000
        case .claude2:
            return 100_000
        case .gpt4Turbo:
            return 128_000
        case .gpt4:
            return 8_192
        case .gpt35Turbo:
            return 16_384
        case .gemini15Pro:
            return 2_097_152  // 2M tokens
        case .gemini15Flash:
            return 1_048_576  // 1M tokens
        case .geminiPro:
            return 32_768
        }
    }
    
    // Cost per 1K tokens (input, output) in USD
    var cost: (input: Double, output: Double) {
        switch self {
        case .claude3Opus:
            return (0.015, 0.075)
        case .claude3Sonnet:
            return (0.003, 0.015)
        case .claude3Haiku:
            return (0.00025, 0.00125)
        case .claude2:
            return (0.008, 0.024)
        case .gpt4Turbo:
            return (0.01, 0.03)
        case .gpt4:
            return (0.03, 0.06)
        case .gpt35Turbo:
            return (0.0005, 0.0015)
        case .gemini15Pro:
            return (0.00125, 0.00375)
        case .gemini15Flash:
            return (0.00015, 0.0006)
        case .geminiPro:
            return (0.0005, 0.0015)
        }
    }
}

// MARK: - Task-Based Model Selection
enum AITask {
    case personalityExtraction
    case personaSynthesis
    case conversationAnalysis
    case coaching
    case quickResponse
    
    var recommendedModels: [LLMModel] {
        switch self {
        case .personalityExtraction:
            // Balance of quality and speed
            return [.claude3Sonnet, .gpt4Turbo, .gemini15Flash]
        case .personaSynthesis:
            // Highest quality for creative generation
            return [.claude3Opus, .gemini15Pro, .gpt4Turbo]
        case .conversationAnalysis:
            // Fast and accurate
            return [.gemini15Flash, .claude3Haiku, .gpt35Turbo]
        case .coaching:
            // High quality conversational
            return [.claude3Sonnet, .gemini15Pro, .gpt4]
        case .quickResponse:
            // Speed matters most
            return [.gemini15Flash, .claude3Haiku, .gpt35Turbo]
        }
    }
}

// MARK: - Provider Configuration
struct LLMProviderConfig {
    let apiKey: String
    let baseURL: URL?
    let timeout: TimeInterval
    let maxRetries: Int
    
    init(
        apiKey: String,
        baseURL: URL? = nil,
        timeout: TimeInterval = 30,
        maxRetries: Int = 3
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
}