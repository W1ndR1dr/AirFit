import Foundation
@testable import AirFit

// MARK: - Mock AI Performance Analytics
// Placeholder for future AI-based performance analytics features

@MainActor
final class MockAIPerformanceAnalytics {
    
    // MARK: - Mock State
    private(set) var analyzePerformanceCalls = 0
    private(set) var generatePredictiveInsightsCalls = 0
    
    // MARK: - Mock Methods
    func analyzePerformance(query: String, for user: User) async throws -> String {
        analyzePerformanceCalls += 1
        return "Mock performance analysis for: \(query)"
    }
    
    func generatePredictiveInsights(for user: User, timeframe: Int) async throws -> [String] {
        generatePredictiveInsightsCalls += 1
        return [
            "You're likely to reach your goal in \(timeframe) days",
            "Consider increasing protein intake by 10g",
            "Your workout consistency is improving"
        ]
    }
    
    // MARK: - Test Helpers
    func reset() {
        analyzePerformanceCalls = 0
        generatePredictiveInsightsCalls = 0
    }
}