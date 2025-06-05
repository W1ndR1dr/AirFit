import Foundation
@testable import AirFit

// MARK: - Mock AI Analytics Service
// This is the AI-based performance analytics service

actor MockAIAnalyticsService: AnalyticsServiceProtocol {

    func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult {

        // Simulate analysis processing time
        try await Task.sleep(nanoseconds: 400_000_000) // 400ms

        let insights = generateInsights(for: metrics, days: days)
        let trends = generateTrends(for: metrics)
        let recommendations = includeRecommendations ? generateRecommendations(for: metrics) : []
        let summary = generateAnalysisSummary(query: query, insights: insights, trends: trends)

        return PerformanceAnalysisResult(
            summary: summary,
            insights: insights,
            trends: trends,
            recommendations: recommendations,
            dataPoints: days * metrics.count
        )
    }

    private func generateInsights(for metrics: [String], days: Int) -> [String] {
        var insights: [String] = []

        for metric in metrics.prefix(3) {
            switch metric {
            case "workout_volume":
                insights.append("Your workout volume has increased by 15% over the past \(days) days")
            case "energy_levels":
                insights.append("Energy levels show a positive correlation with sleep quality")
            case "sleep_quality":
                insights.append("Sleep quality has been consistently above average this period")
            case "strength_progression":
                insights.append("Strength gains are tracking well with your current program")
            case "recovery_metrics":
                insights.append("Recovery time has improved by 20% since starting the program")
            default:
                insights.append("\(metric.replacingOccurrences(of: "_", with: " ")) shows positive trends")
            }
        }

        return insights
    }

    private func generateTrends(for metrics: [String]) -> [PerformanceAnalysisResult.TrendInfo] {
        return metrics.prefix(3).map { metric in
            PerformanceAnalysisResult.TrendInfo(
                metric: metric,
                direction: ["improving", "stable", "declining"].randomElement() ?? "stable",
                magnitude: Double.random(in: 0.1...0.8),
                significance: ["high", "medium", "low"].randomElement() ?? "medium"
            )
        }
    }

    private func generateRecommendations(for metrics: [String]) -> [String] {
        var recommendations: [String] = []

        if metrics.contains("sleep_quality") {
            recommendations.append("Consider maintaining your current sleep schedule for optimal recovery")
        }

        if metrics.contains("workout_volume") {
            recommendations.append("Your current training volume is well-suited to your goals")
        }

        if metrics.contains("energy_levels") {
            recommendations.append("Focus on pre-workout nutrition to maintain energy levels")
        }

        recommendations.append("Continue tracking these metrics to identify long-term patterns")

        return recommendations
    }

    private func generateAnalysisSummary(
        query: String,
        insights: [String],
        trends: [PerformanceAnalysisResult.TrendInfo]
    ) -> String {
        let positiveCount = trends.filter { $0.direction == "improving" }.count
        let stableCount = trends.filter { $0.direction == "stable" }.count

        if positiveCount > stableCount {
            return "Your performance metrics show strong positive trends with \(insights.count) key insights identified."
        } else {
            return "Your performance is stable with \(insights.count) areas showing consistent progress."
        }
    }
}