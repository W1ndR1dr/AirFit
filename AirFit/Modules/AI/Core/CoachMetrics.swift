import Foundation

/// Central place to track/record routing metrics and token estimates.
/// Keeps CoachEngine/Orchestrator lean.
struct CoachMetrics {
    static func record(_ metrics: RoutingMetrics, via config: RoutingConfiguration) {
        config.recordRoutingMetrics(metrics)
    }

    /// Very rough heuristic, consistent with existing estimate.
    static func estimateTokens(for text: String) -> Int { max(text.count / 4, 1) }
}