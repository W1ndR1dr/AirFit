import Foundation

@MainActor
struct CoachRouter {
    private let routingConfiguration: RoutingConfiguration

    init(routingConfiguration: RoutingConfiguration) {
        self.routingConfiguration = routingConfiguration
    }

    /// Wraps RoutingConfiguration + ContextAnalyzer into a single decision point.
    func route(
        userInput: String,
        history: [AIChatMessage],
        userContext: UserContextSnapshot,
        userId: UUID
    ) -> RoutingStrategy {
        // If RoutingConfiguration has a forced route, honor it first.
        if let forced = routingConfiguration.forcedRoute {
            return RoutingStrategy(
                route: forced,
                reason: "Forced route via configuration",
                fallbackEnabled: routingConfiguration.enableIntelligentFallback,
                timestamp: Date()
            )
        }

        // Use ContextAnalyzer’s heuristics for the optimal route.
        let suggested = ContextAnalyzer.determineOptimalRoute(
            userInput: userInput,
            conversationHistory: history,
            userState: userContext
        )

        return RoutingStrategy(
            route: suggested,
            reason: "ContextAnalyzer heuristic",
            fallbackEnabled: routingConfiguration.enableIntelligentFallback,
            timestamp: Date()
        )
    }
}