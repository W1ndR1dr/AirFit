import Foundation

/// Interface for AI powered features used throughout the app.
protocol AIServiceProtocol: Sendable {
    /// Analyze a free form goal description and return a structured goal.
    func analyzeGoal(_ goalText: String) async throws -> StructuredGoal
}
