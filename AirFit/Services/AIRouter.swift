import Foundation
import SwiftData

/// Routes messages to appropriate AI provider based on mode and privacy settings.
///
/// Supports three modes:
/// - **Claude**: All messages route to Claude via server
/// - **Gemini**: All messages route to Gemini direct
/// - **Hybrid**: Routes by data category for privacy-conscious users
///
/// In hybrid mode, users can configure which provider handles which data category:
/// - Nutrition → Gemini (fast, free)
/// - Workouts → Gemini (fast, free)
/// - Health metrics → Claude (more private)
/// - Profile/personal → Claude (more private)
actor AIRouter {
    static let shared = AIRouter()

    private let geminiService = GeminiService()
    private let apiClient = APIClient()
    private let contextManager = ContextManager.shared

    // MARK: - Types

    enum AIProvider: String, CaseIterable, Codable {
        case claude
        case gemini

        var displayName: String {
            switch self {
            case .claude: return "Claude"
            case .gemini: return "Gemini"
            }
        }
    }

    enum AIMode: String, CaseIterable {
        case claude   // All to Claude via server
        case gemini   // All to Gemini direct
        case hybrid   // Route by category

        var displayName: String {
            switch self {
            case .claude: return "Claude (Server)"
            case .gemini: return "Gemini (Direct)"
            case .hybrid: return "Hybrid (Privacy)"
            }
        }

        var description: String {
            switch self {
            case .claude: return "All conversations through your server"
            case .gemini: return "Fast, direct AI with on-device processing"
            case .hybrid: return "Route different data types to different providers"
            }
        }
    }

    // MARK: - Hybrid Routing Configuration

    /// Per-category provider routing for hybrid mode.
    struct HybridRouting: Codable {
        var nutritionProvider: AIProvider
        var workoutProvider: AIProvider
        var healthProvider: AIProvider
        var profileProvider: AIProvider

        static var `default`: HybridRouting {
            HybridRouting(
                nutritionProvider: .gemini,   // Nutrition → Gemini (fast, lower sensitivity)
                workoutProvider: .gemini,     // Workouts → Gemini (fast, lower sensitivity)
                healthProvider: .claude,      // Health → Claude (more private)
                profileProvider: .claude      // Profile → Claude (more private)
            )
        }

        static var current: HybridRouting {
            let defaults = UserDefaults.standard
            if let data = defaults.data(forKey: "hybridRouting"),
               let routing = try? JSONDecoder().decode(HybridRouting.self, from: data) {
                return routing
            }
            return .default
        }

        func save() {
            if let data = try? JSONEncoder().encode(self) {
                UserDefaults.standard.set(data, forKey: "hybridRouting")
            }
        }

        /// Get provider for a detected intent
        func provider(for intent: MessageIntent) -> AIProvider {
            switch intent {
            case .nutritionDiscussion: return nutritionProvider
            case .workoutDiscussion: return workoutProvider
            case .dataQuestion: return healthProvider
            case .generalChat: return profileProvider
            }
        }
    }

    // MARK: - Routing Result

    struct RoutingResult {
        let response: String
        let provider: AIProvider
        let intent: MessageIntent
    }

    // MARK: - Public API

    /// Route a message to the appropriate provider based on mode.
    ///
    /// - Parameters:
    ///   - message: User's message
    ///   - mode: Current AI mode
    ///   - context: Chat context for prompt injection
    ///   - history: Conversation history (for Gemini)
    ///   - modelContext: SwiftData context
    /// - Returns: AI response and routing metadata
    @MainActor
    func routeMessage(
        _ message: String,
        mode: AIMode,
        context: ChatContext,
        history: [ConversationMessage] = [],
        modelContext: ModelContext
    ) async throws -> RoutingResult {
        let intent = ContextManager.detectIntent(from: message)

        let provider: AIProvider
        switch mode {
        case .claude:
            provider = .claude
        case .gemini:
            provider = .gemini
        case .hybrid:
            provider = HybridRouting.current.provider(for: intent)
        }

        // Build context respecting privacy settings for Gemini
        let effectiveContext: ChatContext
        if provider == .gemini {
            effectiveContext = await buildPrivacyFilteredContext(context: context, modelContext: modelContext)
        } else {
            effectiveContext = context
        }

        // Route to appropriate provider
        let response: String
        switch provider {
        case .gemini:
            response = try await sendToGemini(
                message,
                context: effectiveContext,
                history: history
            )
        case .claude:
            response = try await sendToClaude(message, context: effectiveContext)
        }

        return RoutingResult(response: response, provider: provider, intent: intent)
    }

    /// Check which provider would handle a message (for UI indication).
    func predictProvider(for message: String, mode: AIMode) -> AIProvider {
        switch mode {
        case .claude: return .claude
        case .gemini: return .gemini
        case .hybrid:
            let intent = ContextManager.detectIntent(from: message)
            return HybridRouting.current.provider(for: intent)
        }
    }

    // MARK: - Provider Communication

    private func sendToGemini(
        _ message: String,
        context: ChatContext,
        history: [ConversationMessage]
    ) async throws -> String {
        // Build full system prompt
        var systemPrompt = context.systemPrompt
        if !context.memoryContext.isEmpty {
            systemPrompt += "\n\n" + context.memoryContext
        }

        // Include data context in message for Gemini
        var enrichedMessage = message
        if !context.dataContext.isEmpty {
            enrichedMessage = """
            [Context]
            \(context.dataContext)

            [User Message]
            \(message)
            """
        }

        return try await geminiService.chat(
            message: enrichedMessage,
            history: history,
            systemPrompt: systemPrompt
        )
    }

    private func sendToClaude(_ message: String, context: ChatContext) async throws -> String {
        // Claude via server - context is handled server-side
        try await apiClient.sendMessage(message)
    }

    // MARK: - Privacy Filtering

    /// Build context with privacy settings applied for Gemini.
    @MainActor
    private func buildPrivacyFilteredContext(context: ChatContext, modelContext: ModelContext) async -> ChatContext {
        let (filteredContext, excluded) = await contextManager.buildPrivacyAwareContext(modelContext: modelContext)

        if !excluded.isEmpty {
            print("[AIRouter] Excluded from Gemini context: \(excluded.joined(separator: ", "))")
        }

        return filteredContext
    }

    // MARK: - Mode Helpers

    /// Get current AI mode from settings
    static var currentMode: AIMode {
        let raw = UserDefaults.standard.string(forKey: "aiProvider") ?? "claude"
        return AIMode(rawValue: raw) ?? .claude
    }

    /// Set AI mode
    static func setMode(_ mode: AIMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: "aiProvider")
    }
}

// MARK: - Convenience Extensions

extension AIRouter.HybridRouting {
    /// Human-readable summary of routing configuration
    var summary: String {
        var parts: [String] = []
        if nutritionProvider == .gemini { parts.append("Nutrition → Gemini") }
        else { parts.append("Nutrition → Claude") }
        if workoutProvider == .gemini { parts.append("Workouts → Gemini") }
        else { parts.append("Workouts → Claude") }
        if healthProvider == .gemini { parts.append("Health → Gemini") }
        else { parts.append("Health → Claude") }
        if profileProvider == .gemini { parts.append("Profile → Gemini") }
        else { parts.append("Profile → Claude") }
        return parts.joined(separator: "\n")
    }

    /// Quick check if any category routes to Gemini
    var usesGemini: Bool {
        nutritionProvider == .gemini ||
        workoutProvider == .gemini ||
        healthProvider == .gemini ||
        profileProvider == .gemini
    }

    /// Quick check if any category routes to Claude
    var usesClaude: Bool {
        nutritionProvider == .claude ||
        workoutProvider == .claude ||
        healthProvider == .claude ||
        profileProvider == .claude
    }
}
