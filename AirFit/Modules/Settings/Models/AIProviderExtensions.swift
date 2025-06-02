import Foundation
import SwiftUI

// MARK: - AIProvider Extensions for Settings
extension AIProvider: Identifiable {
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Google Gemini"
        case .openRouter: return "OpenRouter"
        }
    }
    
    var icon: String {
        switch self {
        case .openAI: return "cpu"
        case .anthropic: return "brain"
        case .gemini: return "sparkles"
        case .openRouter: return "arrow.triangle.branch"
        }
    }
    
    var availableModels: [String] {
        switch self {
        case .openAI:
            return ["gpt-4-turbo-preview", "gpt-4", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
        case .gemini:
            return ["gemini-1.5-pro", "gemini-1.5-flash", "gemini-1.0-pro"]
        case .openRouter:
            return ["anthropic/claude-3-opus", "openai/gpt-4-turbo", "google/gemini-pro"]
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4-turbo-preview"
        case .anthropic: return "claude-3-sonnet-20240229"
        case .gemini: return "gemini-1.5-flash"
        case .openRouter: return "anthropic/claude-3-opus"
        }
    }
    
    var keyInstructions: [String] {
        switch self {
        case .openAI:
            return [
                "Log in to your OpenAI account",
                "Navigate to API keys section",
                "Create a new secret key",
                "Copy the key (starts with 'sk-')",
                "Keep your key secure and never share it"
            ]
        case .anthropic:
            return [
                "Log in to your Anthropic account",
                "Go to Account Settings > API Keys",
                "Generate a new API key",
                "Copy the key (starts with 'sk-ant-')",
                "Store your key securely"
            ]
        case .gemini:
            return [
                "Visit Google AI Studio",
                "Click 'Get API key'",
                "Create or select a project",
                "Generate and copy your API key",
                "Enable the Gemini API for your project"
            ]
        case .openRouter:
            return [
                "Create an OpenRouter account",
                "Navigate to Keys section",
                "Generate a new API key",
                "Copy your key",
                "Add credits to your account"
            ]
        }
    }
    
    var apiKeyURL: URL? {
        switch self {
        case .openAI:
            return URL(string: "https://platform.openai.com/api-keys")
        case .anthropic:
            return URL(string: "https://console.anthropic.com/account/keys")
        case .gemini:
            return URL(string: "https://aistudio.google.com/app/apikey")
        case .openRouter:
            return URL(string: "https://openrouter.ai/keys")
        }
    }
}
