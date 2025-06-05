import Foundation
@testable import AirFit

// MARK: - Mock AI Analytics Service
// This is the AI-based performance analytics service

actor MockAIAnalyticsService: AIAnalyticsServiceProtocol {
    
    // MARK: - AnalyticsServiceProtocol (base protocol)
    func trackEvent(_ event: String, properties: [String: Any]?) async {
        // Mock implementation - just log
        print("Mock: Tracked event '\(event)' with properties: \(properties ?? [:])")
    }
    
    func getUserInsights(for user: User) async throws -> [String] {
        // Return mock insights
        return [
            "You're most active on weekdays",
            "Your protein intake has improved by 15%",
            "Consider adding more variety to your workouts"
        ]
    }
    
    func getProgressSummary(for user: User, timeframe: TimeInterval) async throws -> ProgressSummary {
        return ProgressSummary(
            caloriesAverage: 2100,
            workoutsCompleted: 12,
            streakDays: 7,
            topActivities: ["Strength Training", "Running"],
            improvements: ["Consistency", "Form"]
        )
    }
    
    // MARK: - AIAnalyticsServiceProtocol methods

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
            dataPoints: days * metrics.count,
            confidence: 0.85
        )
    }

    private func generateInsights(for metrics: [String], days: Int) -> [AIPerformanceInsight] {
        var insights: [AIPerformanceInsight] = []

        for metric in metrics.prefix(3) {
            let (finding, impact) = switch metric {
            case "workout_volume":
                ("Your workout volume has increased by 15% over the past \(days) days", AIPerformanceInsight.ImpactLevel.high)
            case "energy_levels":
                ("Energy levels show a positive correlation with sleep quality", AIPerformanceInsight.ImpactLevel.medium)
            case "sleep_quality":
                ("Sleep quality has been consistently above average this period", AIPerformanceInsight.ImpactLevel.high)
            case "strength_progression":
                ("Strength gains are tracking well with your current program", AIPerformanceInsight.ImpactLevel.high)
            case "recovery_metrics":
                ("Recovery time has improved by 20% since starting the program", AIPerformanceInsight.ImpactLevel.medium)
            default:
                ("\(metric.replacingOccurrences(of: "_", with: " ")) shows positive trends", AIPerformanceInsight.ImpactLevel.low)
            }
            
            insights.append(AIPerformanceInsight(
                category: metric.replacingOccurrences(of: "_", with: " ").capitalized,
                finding: finding,
                impact: impact,
                evidence: ["Based on \(days) days of data", "Statistical significance: p < 0.05"]
            ))
        }

        return insights
    }

    private func generateTrends(for metrics: [String]) -> [PerformanceTrend] {
        return metrics.prefix(3).map { metric in
            PerformanceTrend(
                metric: metric,
                direction: [PerformanceTrend.TrendDirection.improving, .stable, .declining].randomElement() ?? .stable,
                magnitude: Double.random(in: 0.1...0.8),
                timeframe: "\(Int.random(in: 7...30)) days"
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
        insights: [AIPerformanceInsight],
        trends: [PerformanceTrend]
    ) -> String {
        let positiveCount = trends.filter { $0.direction == .improving }.count
        let stableCount = trends.filter { $0.direction == .stable }.count

        if positiveCount > stableCount {
            return "Your performance metrics show strong positive trends with \(insights.count) key insights identified."
        } else {
            return "Your performance is stable with \(insights.count) areas showing consistent progress."
        }
    }
    
    func generatePredictiveInsights(
        for user: User,
        timeframe: Int
    ) async throws -> PredictiveInsights {
        // Generate mock predictive insights
        return PredictiveInsights(
            projections: [
                "weight_loss": 0.75,
                "strength_gain": 0.82,
                "endurance": 0.68
            ],
            risks: [
                "Potential overtraining if current volume continues",
                "Hydration levels may need attention"
            ],
            opportunities: [
                "Adding yoga could improve recovery by 20%",
                "Morning workouts show 15% better performance"
            ],
            confidence: 0.78
        )
    }
}