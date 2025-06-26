import Foundation

extension AIProvider {

    /// Base URL for each AI provider's API
    var baseURL: URL {
        switch self {
        case .openAI:
            return URL(string: "https://api.openai.com/v1")!
        case .anthropic:
            return URL(string: "https://api.anthropic.com/v1")!
        case .gemini:
            return URL(string: "https://generativelanguage.googleapis.com")!
        }
    }

    /// Display name for UI
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .gemini:
            return "Google Gemini"
        }
    }

    /// Icon name for UI
    var iconName: String {
        switch self {
        case .openAI:
            return "cpu"
        case .anthropic:
            return "brain"
        case .gemini:
            return "sparkle"
        }
    }

    /// Default model for each provider
    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-5-sonnet-20241022"
        case .gemini:
            return "gemini-1.5-flash-002"
        }
    }

    /// Available models for each provider
    var availableModels: [String] {
        switch self {
        case .openAI:
            return [
                "gpt-4o",
                "gpt-4o-mini",
                "gpt-4-turbo-2024-04-09",
                "gpt-4",
                "gpt-3.5-turbo"
            ]
        case .anthropic:
            return [
                "claude-3-5-sonnet-20241022",
                "claude-3-opus-20240229",
                "claude-3-sonnet-20240229",
                "claude-3-5-haiku-20241022",
                "claude-3-haiku-20240307"
            ]
        case .gemini:
            return [
                "gemini-2.0-flash-thinking-exp",
                "gemini-2.0-flash-exp",
                "gemini-1.5-pro-002",
                "gemini-1.5-flash-002",
                "gemini-1.0-pro"
            ]
        }
    }

    /// Maximum context window for default model
    var defaultContextWindow: Int {
        switch self {
        case .openAI:
            return 128_000 // GPT-4o-mini
        case .anthropic:
            return 200_000 // Claude 3 Sonnet
        case .gemini:
            return 30_720 // Gemini Pro
        }
    }

    /// Whether the provider supports function calling
    var supportsFunctionCalling: Bool {
        switch self {
        case .openAI, .anthropic, .gemini:
            return true
        }
    }

    /// Whether the provider supports vision/image inputs
    var supportsVision: Bool {
        switch self {
        case .openAI, .anthropic, .gemini:
            return true
        }
    }

    /// Rate limit (requests per minute) for free tier
    var freeRateLimit: Int? {
        switch self {
        case .openAI:
            return 3 // GPT-4 free tier
        case .anthropic:
            return 5 // Claude free tier
        case .gemini:
            return 60 // Gemini free tier
        }
    }

    /// Required headers for authentication
    func authHeaders(apiKey: String) -> [String: String] {
        switch self {
        case .openAI:
            return ["Authorization": "Bearer \(apiKey)"]
        case .anthropic:
            return [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01"
            ]
        case .gemini:
            return ["x-goog-api-key": apiKey]
        }
    }

    /// Streaming endpoint path
    func streamingEndpoint(for model: String) -> String {
        switch self {
        case .openAI:
            return "chat/completions"
        case .anthropic:
            return "messages"
        case .gemini:
            return "v1beta/models/\(model):streamGenerateContent"
        }
    }

    /// Parse model pricing ($ per 1M tokens)
    func pricing(for model: String) -> (input: Double, output: Double)? {
        switch self {
        case .openAI:
            switch model {
            case "gpt-4o":
                return (input: 5.0, output: 15.0)
            case "gpt-4o-mini":
                return (input: 0.15, output: 0.6)
            case "gpt-4-turbo-2024-04-09":
                return (input: 10.0, output: 30.0)
            case "gpt-4":
                return (input: 30.0, output: 60.0)
            case "gpt-3.5-turbo":
                return (input: 0.5, output: 1.5)
            default:
                return nil
            }
        case .anthropic:
            switch model {
            case "claude-3-5-sonnet-20241022":
                return (input: 3.0, output: 15.0)
            case "claude-3-opus-20240229":
                return (input: 15.0, output: 75.0)
            case "claude-3-sonnet-20240229":
                return (input: 3.0, output: 15.0)
            case "claude-3-5-haiku-20241022":
                return (input: 1.0, output: 5.0)
            case "claude-3-haiku-20240307":
                return (input: 0.25, output: 1.25)
            default:
                return nil
            }
        case .gemini:
            switch model {
            case "gemini-2.0-flash-thinking-exp", "gemini-2.0-flash-exp":
                return (input: 0.0, output: 0.0) // Free during experimental phase
            case "gemini-1.5-pro-002":
                return (input: 1.25, output: 5.0)
            case "gemini-1.5-flash-002":
                return (input: 0.075, output: 0.3)
            case "gemini-1.0-pro":
                return (input: 0.5, output: 1.5)
            default:
                return nil
            }
        }
    }

    /// Validate if a model string is valid for this provider
    func isValidModel(_ model: String) -> Bool {
        availableModels.contains(model)
    }

    /// Get a descriptive error message for common provider errors
    func errorMessage(for code: String) -> String? {
        switch self {
        case .openAI:
            switch code {
            case "invalid_api_key":
                return "Invalid OpenAI API key. Please check your key in Settings."
            case "insufficient_quota":
                return "OpenAI API quota exceeded. Please check your usage limits."
            case "model_not_found":
                return "The requested model is not available with your OpenAI account."
            default:
                return nil
            }
        case .anthropic:
            switch code {
            case "invalid_x_api_key":
                return "Invalid Anthropic API key. Please check your key in Settings."
            case "rate_limit_error":
                return "Anthropic rate limit exceeded. Please wait before trying again."
            default:
                return nil
            }
        case .gemini:
            switch code {
            case "API_KEY_INVALID":
                return "Invalid Google Gemini API key. Please check your key in Settings."
            case "RESOURCE_EXHAUSTED":
                return "Google Gemini quota exceeded. Please check your usage limits."
            default:
                return nil
            }
        }
    }
}
