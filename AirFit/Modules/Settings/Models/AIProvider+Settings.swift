import Foundation
import SwiftUI

// MARK: - AIProvider Extensions for Settings
extension AIProvider: Identifiable {
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .openAI: return "cpu"
        case .anthropic: return "brain"
        case .gemini: return "sparkles"
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
        }
    }
}
