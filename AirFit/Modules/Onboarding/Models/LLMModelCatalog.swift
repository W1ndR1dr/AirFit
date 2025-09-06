import Foundation

/// Centralized access to supported LLM models for onboarding UI
enum LLMModelCatalog {
    /// Return models (id + display) for a given provider using canonical identifiers
    static func models(for provider: AIProvider) -> [(id: String, display: String)] {
        // Only expose models that are whitelisted in provider.availableModels for world-class reliability
        let allowed = Set(provider.availableModels)
        return LLMModel.allCases
            .filter { $0.provider.matches(provider) && allowed.contains($0.identifier) }
            .map { ($0.identifier, $0.displayName) }
    }

    /// Return triplets for UI chips across multiple providers
    static func triplets(for providers: [AIProvider]) -> [(provider: AIProvider, displayName: String, modelId: String)] {
        providers.flatMap { provider in
            models(for: provider).map { (provider, $0.display, $0.id) }
        }
    }
}

private extension LLMProviderIdentifier {
    func toAIProvider() -> AIProvider {
        switch self {
        case .openai: return .openAI
        case .anthropic: return .anthropic
        case .google: return .gemini
        default: return .gemini
        }
    }
}

private extension LLMModel {
    func aiProvider() -> AIProvider { provider.toAIProvider() }
}

private extension LLMProviderIdentifier {
    func matches(_ provider: AIProvider) -> Bool {
        switch (self, provider) {
        case (.openai, .openAI), (.anthropic, .anthropic), (.google, .gemini):
            return true
        default:
            return false
        }
    }
}
