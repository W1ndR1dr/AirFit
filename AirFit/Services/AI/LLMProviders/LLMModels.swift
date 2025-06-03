import Foundation

// MARK: - Model Selection
enum LLMModel: CaseIterable {
    // Anthropic
    case claude35Sonnet
    case claude3Opus
    case claude3Sonnet
    case claude35Haiku
    case claude3Haiku
    
    // OpenAI
    case gpt4o
    case gpt4oMini
    case gpt4Turbo
    case gpt4
    case gpt35Turbo
    
    // Google Gemini
    case gemini25Flash
    case gemini25FlashThinking
    case gemini20FlashThinking
    case gemini20Flash
    case gemini15Pro
    case gemini15Flash
    case gemini10Pro
    
    var identifier: String {
        switch self {
        case .claude35Sonnet: return "claude-3-5-sonnet-20241022"
        case .claude3Opus: return "claude-3-opus-20240229"
        case .claude3Sonnet: return "claude-3-sonnet-20240229"
        case .claude35Haiku: return "claude-3-5-haiku-20241022"
        case .claude3Haiku: return "claude-3-haiku-20240307"
        case .gpt4o: return "gpt-4o"
        case .gpt4oMini: return "gpt-4o-mini"
        case .gpt4Turbo: return "gpt-4-turbo-2024-04-09"
        case .gpt4: return "gpt-4"
        case .gpt35Turbo: return "gpt-3.5-turbo"
        case .gemini25Flash: return "gemini-2.5-flash-preview-05-20"
        case .gemini25FlashThinking: return "gemini-2.5-flash-thinking-preview-05-20"
        case .gemini20FlashThinking: return "gemini-2.0-flash-thinking-exp"
        case .gemini20Flash: return "gemini-2.0-flash-exp"
        case .gemini15Pro: return "gemini-1.5-pro-002"
        case .gemini15Flash: return "gemini-1.5-flash-002"
        case .gemini10Pro: return "gemini-1.0-pro"
        }
    }
    
    var provider: LLMProviderIdentifier {
        switch self {
        case .claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude35Haiku, .claude3Haiku:
            return .anthropic
        case .gpt4o, .gpt4oMini, .gpt4Turbo, .gpt4, .gpt35Turbo:
            return .openai
        case .gemini25Flash, .gemini25FlashThinking, .gemini20FlashThinking, .gemini20Flash, .gemini15Pro, .gemini15Flash, .gemini10Pro:
            return .google
        }
    }
    
    var contextWindow: Int {
        switch self {
        case .claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude35Haiku, .claude3Haiku:
            return 200_000
        case .gpt4o, .gpt4oMini:
            return 128_000
        case .gpt4Turbo:
            return 128_000
        case .gpt4:
            return 8_192
        case .gpt35Turbo:
            return 16_384
        case .gemini25Flash, .gemini25FlashThinking:
            return 1_048_576  // 1M tokens
        case .gemini20FlashThinking, .gemini20Flash:
            return 1_048_576  // 1M tokens
        case .gemini15Pro:
            return 2_097_152  // 2M tokens
        case .gemini15Flash:
            return 1_048_576  // 1M tokens
        case .gemini10Pro:
            return 32_768
        }
    }
    
    // Cost per 1K tokens (input, output) in USD - Updated Jan 2025
    var cost: (input: Double, output: Double) {
        switch self {
        case .claude35Sonnet:
            return (0.003, 0.015)
        case .claude3Opus:
            return (0.015, 0.075)
        case .claude3Sonnet:
            return (0.003, 0.015)
        case .claude35Haiku:
            return (0.001, 0.005)
        case .claude3Haiku:
            return (0.00025, 0.00125)
        case .gpt4o:
            return (0.005, 0.015)
        case .gpt4oMini:
            return (0.00015, 0.0006)
        case .gpt4Turbo:
            return (0.01, 0.03)
        case .gpt4:
            return (0.03, 0.06)
        case .gpt35Turbo:
            return (0.0005, 0.0015)
        case .gemini25Flash:
            return (0.00015, 0.0003)  // $0.15/$0.30 per 1M as per guide
        case .gemini25FlashThinking:
            return (0.00015, 0.0003)  // Same pricing, thinking counts as input
        case .gemini20FlashThinking:
            return (0.0, 0.0)  // Free during experimental phase
        case .gemini20Flash:
            return (0.0, 0.0)  // Free during experimental phase
        case .gemini15Pro:
            return (0.00125, 0.005)
        case .gemini15Flash:
            return (0.000075, 0.0003)
        case .gemini10Pro:
            return (0.0005, 0.0015)
        }
    }
    
    var displayName: String {
        switch self {
        case .claude35Sonnet: return "Claude 3.5 Sonnet"
        case .claude3Opus: return "Claude 3 Opus"
        case .claude3Sonnet: return "Claude 3 Sonnet"
        case .claude35Haiku: return "Claude 3.5 Haiku"
        case .claude3Haiku: return "Claude 3 Haiku"
        case .gpt4o: return "GPT-4o"
        case .gpt4oMini: return "GPT-4o Mini"
        case .gpt4Turbo: return "GPT-4 Turbo"
        case .gpt4: return "GPT-4"
        case .gpt35Turbo: return "GPT-3.5 Turbo"
        case .gemini25Flash: return "Gemini 2.5 Flash"
        case .gemini25FlashThinking: return "Gemini 2.5 Flash Thinking"
        case .gemini20FlashThinking: return "Gemini 2.0 Flash Thinking (Exp)"
        case .gemini20Flash: return "Gemini 2.0 Flash (Exp)"
        case .gemini15Pro: return "Gemini 1.5 Pro"
        case .gemini15Flash: return "Gemini 1.5 Flash"
        case .gemini10Pro: return "Gemini 1.0 Pro"
        }
    }
    
    var description: String {
        switch self {
        case .claude35Sonnet: return "Best balance of intelligence and speed"
        case .claude3Opus: return "Most capable, best for complex tasks"
        case .claude3Sonnet: return "Balanced performance"
        case .claude35Haiku: return "Fast and intelligent"
        case .claude3Haiku: return "Fastest, most cost-effective"
        case .gpt4o: return "Latest multimodal model"
        case .gpt4oMini: return "Affordable multimodal model"
        case .gpt4Turbo: return "High capability with vision"
        case .gpt4: return "Classic high-performance"
        case .gpt35Turbo: return "Fast and affordable"
        case .gemini25Flash: return "Latest production model with 1M context"
        case .gemini25FlashThinking: return "Step-by-step reasoning with thinking budget"
        case .gemini20FlashThinking: return "Advanced reasoning (experimental)"
        case .gemini20Flash: return "Latest fast model (experimental)"
        case .gemini15Pro: return "Largest context window (2M tokens)"
        case .gemini15Flash: return "Fast with large context (1M tokens)"
        case .gemini10Pro: return "Balanced performance"
        }
    }
    
    var specialFeatures: [String] {
        switch self {
        case .claude35Sonnet, .claude3Opus, .claude3Sonnet, .claude35Haiku, .claude3Haiku:
            return ["Function calling", "Context caching", "Computer use (beta)"]
        case .gpt4o, .gpt4oMini:
            return ["Function calling", "Vision", "Audio input/output", "Real-time API"]
        case .gpt4Turbo:
            return ["Function calling", "Vision", "JSON mode"]
        case .gpt4, .gpt35Turbo:
            return ["Function calling"]
        case .gemini25Flash:
            return ["Multimodal input", "JSON/structured output", "1M context", "Code execution"]
        case .gemini25FlashThinking:
            return ["Thinking budget (≤24,576 tokens)", "Step-by-step reasoning", "Multimodal"]
        case .gemini20FlashThinking:
            return ["Advanced reasoning", "Extended thinking time"]
        case .gemini20Flash:
            return ["Native audio/video", "Real-time streaming"]
        case .gemini15Pro, .gemini15Flash:
            return ["Function calling", "Grounding (Google Search)", "Code execution", "Massive context"]
        case .gemini10Pro:
            return ["Function calling"]
        }
    }
    
    static var allCases: [LLMModel] {
        return [
            // Anthropic
            .claude35Sonnet,
            .claude3Opus,
            .claude3Sonnet,
            .claude35Haiku,
            .claude3Haiku,
            // OpenAI
            .gpt4o,
            .gpt4oMini,
            .gpt4Turbo,
            .gpt4,
            .gpt35Turbo,
            // Google Gemini
            .gemini25Flash,
            .gemini25FlashThinking,
            .gemini20FlashThinking,
            .gemini20Flash,
            .gemini15Pro,
            .gemini15Flash,
            .gemini10Pro
        ]
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
            return [.claude35Sonnet, .gpt4o, .gemini15Flash]
        case .personaSynthesis:
            // Highest quality for creative generation
            return [.claude3Opus, .gemini25FlashThinking, .gemini15Pro, .gpt4o]
        case .conversationAnalysis:
            // Fast and accurate
            return [.gemini25Flash, .gemini15Flash, .claude35Haiku, .gpt4oMini]
        case .coaching:
            // High quality conversational
            return [.claude35Sonnet, .gemini25Flash, .gemini15Pro, .gpt4o]
        case .quickResponse:
            // Speed matters most
            return [.gemini25Flash, .gemini15Flash, .claude35Haiku, .gpt4oMini]
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