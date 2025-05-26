import Foundation

/// Interface for AI powered features used throughout the app.
protocol AIServiceProtocol: Sendable {
    /// Analyze a free form goal description and return insights.
    func analyzeGoal(_ goalText: String) async throws -> String
}
