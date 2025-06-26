import Foundation

@MainActor
final class ChatSuggestionsEngine: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "chat-suggestions-engine"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    private let user: User
    private let contextAssembler: ContextAssembler

    init(user: User, contextAssembler: ContextAssembler) {
        self.user = user
        self.contextAssembler = contextAssembler
    }

    /// Generates context-aware suggestions based on recent chat messages and user context.
    /// - Parameters:
    ///   - messages: Recent chat messages for analysis.
    ///   - userContext: The current user profile.
    /// - Returns: A set of quick suggestions and contextual actions.
    func generateSuggestions(
        messages: [ChatMessage],
        userContext: User
    ) async -> SuggestionSet {
        var quick = getFitnessPrompts()
        var contextual: [ContextualAction] = []

        // Analyze the last user message for topical hints
        if let lastUserMessage = messages.reversed().first(where: { $0.isUserMessage }) {
            let text = lastUserMessage.content.lowercased()
            if text.contains("workout") {
                quick.append(QuickSuggestion(text: "Show my workout stats", autoSend: true))
                contextual.append(ContextualAction(title: "Log Workout", icon: "figure.run"))
            }
            if text.contains("nutrition") || text.contains("meal") {
                quick.append(QuickSuggestion(text: "Log a meal", autoSend: false))
                contextual.append(ContextualAction(title: "View Meal Plan", icon: "fork.knife"))
            }
            if text.contains("goal") {
                quick.append(QuickSuggestion(text: "Review my goals", autoSend: true))
                contextual.append(ContextualAction(title: "Update Goals", icon: "target"))
            }
        } else {
            // If no conversation yet, offer starters
            quick.append(contentsOf: [
                QuickSuggestion(text: "What can you do?", autoSend: true),
                QuickSuggestion(text: "Share a fitness tip", autoSend: true)
            ])
        }

        // Incorporate simple history signals
        if !userContext.getRecentWorkouts().isEmpty {
            contextual.append(ContextualAction(title: "Last Workout Summary", icon: "chart.bar"))
        }
        if !userContext.getRecentMeals().isEmpty {
            contextual.append(ContextualAction(title: "Recent Meals", icon: "fork.knife"))
        }

        // Remove duplicate quick suggestions by text for performance
        var unique = Set<String>()
        quick = quick.filter { unique.insert($0.text).inserted }

        return SuggestionSet(quick: quick, contextual: contextual)
    }

    private func getFitnessPrompts() -> [QuickSuggestion] {
        [
            QuickSuggestion(text: "How was my workout today?", autoSend: true),
            QuickSuggestion(text: "Plan my next workout", autoSend: false),
            QuickSuggestion(text: "Analyze my nutrition", autoSend: true),
            QuickSuggestion(text: "Set a new fitness goal", autoSend: false)
        ]
    }

    // MARK: - ServiceProtocol Methods

    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }

    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: [
                "hasUser": "true",
                "hasContextAssembler": "true"
            ]
        )
    }
}

struct SuggestionSet {
    let quick: [QuickSuggestion]
    let contextual: [ContextualAction]
}
