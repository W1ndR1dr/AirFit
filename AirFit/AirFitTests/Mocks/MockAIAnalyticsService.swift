import Foundation
@testable import AirFit

/// Mock implementation of AIAnalyticsServiceProtocol for testing
@MainActor
final class MockAIAnalyticsService: AIAnalyticsServiceProtocol, @preconcurrency MockProtocol {
    // MARK: - MockProtocol
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    // MARK: - Mock Results
    var mockAnalysisResult = PerformanceAnalysisResult(
        summary: "Mock analysis summary",
        insights: [
            AIPerformanceInsight(
                category: "Workout",
                finding: "Consistent training pattern",
                impact: .high,
                evidence: ["5 workouts per week", "Progressive overload detected"]
            ),
            AIPerformanceInsight(
                category: "Nutrition",
                finding: "Protein intake optimal",
                impact: .medium,
                evidence: ["Average 150g protein daily", "Good timing around workouts"]
            )
        ],
        trends: [
            PerformanceTrend(
                metric: "Consistency",
                direction: .improving,
                magnitude: 15.0,
                timeframe: "Last 30 days"
            )
        ],
        recommendations: ["Recommendation 1", "Recommendation 2"],
        dataPoints: 100,
        confidence: 0.85
    )

    // MARK: - AIAnalyticsServiceProtocol
    func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult {
        recordInvocation(#function, arguments: [
            "query": query,
            "metrics": metrics,
            "days": days,
            "depth": depth,
            "includeRecommendations": includeRecommendations,
            "user": user.id
        ])

        if let stubbed = stubbedResults[#function] as? PerformanceAnalysisResult {
            return stubbed
        }

        return mockAnalysisResult
    }

    func generatePredictiveInsights(
        for user: User,
        timeframe: Int
    ) async throws -> PredictiveInsights {
        recordInvocation(#function, arguments: [
            "user": user.id,
            "timeframe": timeframe
        ])

        if let stubbed = stubbedResults[#function] as? PredictiveInsights {
            return stubbed
        }

        return PredictiveInsights(
            projections: [
                "weightLoss": 8.5,
                "muscleGain": 2.3,
                "endurance": 15.0
            ],
            risks: [
                "Potential plateau in 3 weeks",
                "Recovery time may increase"
            ],
            opportunities: [
                "Strength gains possible with current routine",
                "Cardio improvements expected"
            ],
            confidence: 0.75
        )
    }

    // MARK: - AnalyticsServiceProtocol

    func trackEvent(_ event: AnalyticsEvent) async {
        recordInvocation(#function, arguments: event)
    }

    func trackScreen(_ screen: String, properties: [String: String]?) async {
        recordInvocation(#function, arguments: screen, properties ?? [:])
    }

    func setUserProperties(_ properties: [String: String]) async {
        recordInvocation(#function, arguments: properties)
    }

    func trackWorkoutCompleted(_ workout: Workout) async {
        recordInvocation(#function, arguments: workout.id)
    }

    func trackMealLogged(_ meal: FoodEntry) async {
        recordInvocation(#function, arguments: meal.id)
    }

    func getInsights(for user: User) async throws -> UserInsights {
        recordInvocation(#function, arguments: user.id)

        if let stubbed = stubbedResults[#function] as? UserInsights {
            return stubbed
        }

        return UserInsights(
            workoutFrequency: 4.5,
            averageWorkoutDuration: 3_600,
            caloriesTrend: Trend(direction: .stable, changePercentage: 2.3),
            macroBalance: MacroBalance(
                proteinPercentage: 30,
                carbsPercentage: 40,
                fatPercentage: 30
            ),
            streakDays: 7,
            achievements: [
                UserAchievement(
                    id: "week-streak",
                    title: "Week Warrior",
                    description: "7 day streak",
                    unlockedAt: Date(),
                    icon: "🔥"
                )
            ]
        )
    }
}
