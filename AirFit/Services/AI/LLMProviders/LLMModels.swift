import Foundation

// MARK: - Model Selection
enum LLMModel: CaseIterable {
    // Anthropic - Claude 4 Series (2025)
    case claude4Opus
    case claude4Sonnet

    // OpenAI - Latest Models (2025)
    case gpt4o
    case o3
    case o3Mini
    case o4Mini

    // Google Gemini - 2.5 Series (2025)
    case gemini25Pro
    case gemini25Flash
    case gemini25FlashThinking

    var identifier: String {
        switch self {
        // Anthropic - Claude 4 Series
        case .claude4Opus: return "claude-4-opus-20250514"
        case .claude4Sonnet: return "claude-4-sonnet-20250514"
        // OpenAI - Latest
        case .gpt4o: return "gpt-4o"
        case .o3: return "o3"
        case .o3Mini: return "o3-mini"
        case .o4Mini: return "o4-mini"
        // Google Gemini - 2.5 Series
        case .gemini25Pro: return "gemini-2.5-pro"
        case .gemini25Flash: return "gemini-2.5-flash"
        case .gemini25FlashThinking: return "gemini-2.5-flash-thinking-preview-05-20"
        }
    }

    init?(rawValue: String) {
        if let model = LLMModel.allCases.first(where: { $0.identifier == rawValue }) {
            self = model
        } else {
            return nil
        }
    }

    var provider: LLMProviderIdentifier {
        switch self {
        case .claude4Opus, .claude4Sonnet:
            return .anthropic
        case .gpt4o, .o3, .o3Mini, .o4Mini:
            return .openai
        case .gemini25Pro, .gemini25Flash, .gemini25FlashThinking:
            return .google
        }
    }

    var contextWindow: Int {
        switch self {
        // Anthropic - Claude 4 has 200K context
        case .claude4Opus, .claude4Sonnet:
            return 200_000
        // OpenAI - New models have varying context windows
        case .gpt4o:
            return 128_000
        case .o3, .o3Mini:
            return 128_000  // Reasoning models
        case .o4Mini:
            return 64_000   // Smaller context for mini
        // Google Gemini - 2.5 series has large context
        case .gemini25Pro:
            return 2_097_152  // 2M tokens
        case .gemini25Flash, .gemini25FlashThinking:
            return 1_048_576  // 1M tokens
        }
    }

    // Cost per 1K tokens (input, output) in USD - Updated Jan 2025
    var cost: (input: Double, output: Double) {
        switch self {
        // Anthropic Claude 4 Series
        case .claude4Opus:
            return (0.015, 0.075)  // Same as Claude 3 Opus pricing
        case .claude4Sonnet:
            return (0.003, 0.015)  // Same as Claude 3.5 Sonnet pricing
        // OpenAI Latest
        case .gpt4o:
            return (0.005, 0.015)
        case .o3:
            return (0.015, 0.060)  // Reasoning model - higher cost
        case .o3Mini:
            return (0.003, 0.012)  // Mini reasoning model
        case .o4Mini:
            return (0.00015, 0.0006)  // Same as GPT-4o Mini
        // Google Gemini 2.5 Series
        case .gemini25Pro:
            return (0.00125, 0.005)  // Premium pricing
        case .gemini25Flash:
            return (0.00015, 0.0003)  // $0.15/$0.30 per 1M tokens
        case .gemini25FlashThinking:
            return (0.00015, 0.0003)  // Same pricing, thinking counts as input
        }
    }

    var displayName: String {
        switch self {
        // Anthropic Claude 4
        case .claude4Opus: return "Claude 4 Opus"
        case .claude4Sonnet: return "Claude 4 Sonnet"
        // OpenAI Latest
        case .gpt4o: return "GPT-4o"
        case .o3: return "o3"
        case .o3Mini: return "o3-mini"
        case .o4Mini: return "o4-mini"
        // Google Gemini 2.5
        case .gemini25Pro: return "Gemini 2.5 Pro"
        case .gemini25Flash: return "Gemini 2.5 Flash"
        case .gemini25FlashThinking: return "Gemini 2.5 Flash Thinking"
        }
    }

    var description: String {
        switch self {
        // Anthropic Claude 4
        case .claude4Opus: return "Most powerful, best for complex reasoning"
        case .claude4Sonnet: return "Best balance of intelligence and speed"
        // OpenAI Latest
        case .gpt4o: return "Latest multimodal flagship model"
        case .o3: return "Advanced reasoning with chain-of-thought"
        case .o3Mini: return "Efficient reasoning model"
        case .o4Mini: return "Ultra-fast, cost-effective"
        // Google Gemini 2.5
        case .gemini25Pro: return "Largest context window (2M tokens)"
        case .gemini25Flash: return "Fast with 1M context window"
        case .gemini25FlashThinking: return "Step-by-step reasoning with thinking budget"
        }
    }

    var specialFeatures: [String] {
        switch self {
        case .claude4Opus, .claude4Sonnet:
            return ["Function calling", "Context caching", "Computer use", "200K context"]
        case .gpt4o:
            return ["Function calling", "Vision", "Audio input/output", "Real-time API"]
        case .o3, .o3Mini:
            return ["Chain-of-thought reasoning", "Function calling", "Extended thinking"]
        case .o4Mini:
            return ["Function calling", "Ultra-fast responses"]
        case .gemini25Pro:
            return ["2M context window", "Multimodal", "Function calling", "Grounding"]
        case .gemini25Flash:
            return ["1M context window", "Multimodal", "JSON/structured output", "Code execution"]
        case .gemini25FlashThinking:
            return ["Thinking budget (≤24,576 tokens)", "Step-by-step reasoning", "Multimodal"]
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
            return [.claude4Sonnet, .gpt4o, .gemini25Flash]
        case .personaSynthesis:
            return [.claude4Opus, .o3, .gemini25FlashThinking]
        case .conversationAnalysis:
            return [.gemini25Flash, .o4Mini, .claude4Sonnet]
        case .coaching:
            return [.claude4Sonnet, .gpt4o, .gemini25Pro]
        case .quickResponse:
            return [.o4Mini, .gemini25Flash]
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
