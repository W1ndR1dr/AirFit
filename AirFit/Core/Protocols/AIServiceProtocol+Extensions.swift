import Foundation
import SwiftData

// MARK: - AI-Specific Service Protocol Extensions
// These protocols extend the base service protocols with AI-specific functionality
// used by the FunctionCallDispatcher and AI subsystem

/// AI-specific workout service capabilities  
protocol AIWorkoutServiceProtocol {
    /// Generate a personalized workout plan based on AI analysis
    func generatePlan(
        for user: User,
        goal: String,
        duration: Int,
        intensity: String,
        targetMuscles: [String],
        equipment: [String],
        constraints: String?,
        style: String
    ) async throws -> WorkoutPlanResult

    /// Adapt an existing plan based on user feedback
    func adaptPlan(
        _ plan: WorkoutPlanResult,
        feedback: String,
        adjustments: [String: Any],
        for user: User
    ) async throws -> WorkoutPlanResult
}

/// AI-specific analytics service capabilities
protocol AIAnalyticsServiceProtocol: AnalyticsServiceProtocol {
    /// Analyze performance with AI-driven insights
    func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult

    /// Generate predictive insights
    func generatePredictiveInsights(
        for user: User,
        timeframe: Int
    ) async throws -> PredictiveInsights
}

/// AI-specific goal service capabilities
protocol AIGoalServiceProtocol: GoalServiceProtocol {
    /// Create or refine goals using AI analysis
    func createOrRefineGoal(
        current: String?,
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        constraints: [String],
        motivations: [String],
        goalType: String?,
        for user: User
    ) async throws -> GoalResult

    /// Suggest goal adjustments based on progress
    func suggestGoalAdjustments(
        for goal: TrackedGoal,
        user: User
    ) async throws -> [GoalAdjustment]
}

// MARK: - Supporting Types for AI Services

struct WorkoutPlanResult: Sendable {
    let id: UUID
    let exercises: [PlannedExercise]
    let estimatedCalories: Int
    let estimatedDuration: Int
    let summary: String
    let difficulty: WorkoutDifficulty
    let focusAreas: [String]

    enum WorkoutDifficulty: String, Sendable {
        case beginner, intermediate, advanced, expert
    }
}

struct PlannedExercise: Sendable {
    let exerciseId: UUID
    let name: String
    let sets: Int
    let reps: String // Can be range like "8-12"
    let restSeconds: Int
    let notes: String?
    let alternatives: [String]
}

struct PerformanceAnalysisResult: Sendable {
    let summary: String
    let insights: [AIPerformanceInsight]
    let trends: [PerformanceTrend]
    let recommendations: [String]
    let dataPoints: Int
    let confidence: Double
}

struct AIPerformanceInsight: Sendable {
    let category: String
    let finding: String
    let impact: ImpactLevel
    let evidence: [String]

    enum ImpactLevel: String, Sendable {
        case low, medium, high, critical
    }
}

struct PerformanceTrend: Sendable {
    let metric: String
    let direction: TrendDirection
    let magnitude: Double
    let timeframe: String

    enum TrendDirection: String, Sendable {
        case improving, stable, declining, volatile
    }
}

struct PredictiveInsights: Sendable {
    let projections: [String: Double]
    let risks: [String]
    let opportunities: [String]
    let confidence: Double
}

struct GoalResult: Sendable {
    let id: UUID
    let title: String
    let description: String
    let targetDate: Date?
    let metrics: [GoalMetric]
    let milestones: [GoalMilestone]
    let smartCriteria: SMARTCriteria

    struct SMARTCriteria: Sendable {
        let specific: String
        let measurable: String
        let achievable: String
        let relevant: String
        let timeBound: String
    }
}

struct GoalMetric: Sendable {
    let name: String
    let currentValue: Double
    let targetValue: Double
    let unit: String
}

struct GoalMilestone: Sendable {
    let title: String
    let targetDate: Date
    let criteria: String
    let reward: String?
}

struct GoalAdjustment: Sendable {
    let type: AdjustmentType
    let reason: String
    let suggestedChange: String
    let impact: String

    enum AdjustmentType: String, Sendable {
        case timeline, target, approach, intensity
    }
}
