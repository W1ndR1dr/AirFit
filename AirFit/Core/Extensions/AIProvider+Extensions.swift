import Foundation

extension AIProvider {
    
    /// Base URL for each AI provider's API
    var baseURL: URL {
        switch self {
        case .openAI:
            return URL(string: "https://api.openai.com/v1")!
        case .anthropic:
            return URL(string: "https://api.anthropic.com/v1")!
        case .googleGemini:
            return URL(string: "https://generativelanguage.googleapis.com")!
        case .openRouter:
            return URL(string: "https://openrouter.ai/api/v1")!
        }
    }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .googleGemini:
            return "Google Gemini"
        case .openRouter:
            return "OpenRouter"
        }
    }
    
    /// Default model for each provider
    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-sonnet-20240229"
        case .googleGemini:
            return "gemini-pro"
        case .openRouter:
            return "openai/gpt-4o-mini"
        }
    }
    
    /// Available models for each provider
    var availableModels: [String] {
        switch self {
        case .openAI:
            return [
                "gpt-4o",
                "gpt-4o-mini",
                "gpt-4-turbo",
                "gpt-3.5-turbo",
                "gpt-3.5-turbo-16k"
            ]
        case .anthropic:
            return [
                "claude-3-opus-20240229",
                "claude-3-sonnet-20240229",
                "claude-3-haiku-20240307",
                "claude-2.1",
                "claude-instant-1.2"
            ]
        case .googleGemini:
            return [
                "gemini-pro",
                "gemini-pro-vision",
                "gemini-ultra"
            ]
        case .openRouter:
            return [
                "openai/gpt-4o",
                "openai/gpt-4o-mini",
                "anthropic/claude-3-opus",
                "anthropic/claude-3-sonnet",
                "google/gemini-pro",
                "meta-llama/llama-3-70b-instruct",
                "mistralai/mixtral-8x7b-instruct"
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
        case .googleGemini:
            return 30_720 // Gemini Pro
        case .openRouter:
            return 128_000 // GPT-4o-mini via OpenRouter
        }
    }
    
    /// Whether the provider supports function calling
    var supportsFunctionCalling: Bool {
        switch self {
        case .openAI, .anthropic, .googleGemini:
            return true
        case .openRouter:
            return true // Depends on underlying model
        }
    }
    
    /// Whether the provider supports vision/image inputs
    var supportsVision: Bool {
        switch self {
        case .openAI, .anthropic, .googleGemini:
            return true
        case .openRouter:
            return true // Depends on underlying model
        }
    }
    
    /// Rate limit (requests per minute) for free tier
    var freeRateLimit: Int? {
        switch self {
        case .openAI:
            return 3 // GPT-4 free tier
        case .anthropic:
            return 5 // Claude free tier
        case .googleGemini:
            return 60 // Gemini free tier
        case .openRouter:
            return nil // Varies by model
        }
    }
    
    /// Required headers for authentication
    func authHeaders(apiKey: String) -> [String: String] {
        switch self {
        case .openAI, .openRouter:
            return ["Authorization": "Bearer \(apiKey)"]
        case .anthropic:
            return [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01"
            ]
        case .googleGemini:
            return ["x-goog-api-key": apiKey]
        }
    }
    
    /// Streaming endpoint path
    func streamingEndpoint(for model: String) -> String {
        switch self {
        case .openAI, .openRouter:
            return "chat/completions"
        case .anthropic:
            return "messages"
        case .googleGemini:
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
            case "gpt-3.5-turbo":
                return (input: 0.5, output: 1.5)
            default:
                return nil
            }
        case .anthropic:
            switch model {
            case "claude-3-opus-20240229":
                return (input: 15.0, output: 75.0)
            case "claude-3-sonnet-20240229":
                return (input: 3.0, output: 15.0)
            case "claude-3-haiku-20240307":
                return (input: 0.25, output: 1.25)
            default:
                return nil
            }
        case .googleGemini:
            switch model {
            case "gemini-pro":
                return (input: 0.5, output: 1.5)
            default:
                return nil
            }
        case .openRouter:
            // OpenRouter has variable pricing
            return nil
        }
    }
    
    /// Validate if a model string is valid for this provider
    func isValidModel(_ model: String) -> Bool {
        availableModels.contains(model) ||
        (self == .openRouter && model.contains("/")) // OpenRouter uses provider/model format
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
        case .googleGemini:
            switch code {
            case "API_KEY_INVALID":
                return "Invalid Google Gemini API key. Please check your key in Settings."
            case "RESOURCE_EXHAUSTED":
                return "Google Gemini quota exceeded. Please check your usage limits."
            default:
                return nil
            }
        case .openRouter:
            return nil // OpenRouter uses standard HTTP error codes
        }
    }
}