import Foundation
import SwiftData

/// AI Goal Service - Wraps the base GoalServiceProtocol and adds AI-specific functionality
@MainActor
final class AIGoalService: AIGoalServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-goal-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        MainActor.assumeIsolated { _isConfigured }
    }
    
    private let goalService: GoalServiceProtocol
    
    init(goalService: GoalServiceProtocol) {
        self.goalService = goalService
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
            metadata: ["hasGoalService": "true"]
        )
    }
    
    // MARK: - AI-specific methods
    
    func createOrRefineGoal(
        current: String?,
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        constraints: [String],
        motivations: [String],
        goalType: String?,
        for user: User
    ) async throws -> GoalResult {
        // AI analysis to create a refined goal
        // This would normally use the AI service to analyze the input
        
        let goalFamily = mapGoalTypeToCategory(goalType)
        let deadline = calculateDeadline(from: timeframe)
        
        return GoalResult(
            id: UUID(),
            title: aspirations,
            description: "Goal based on: \(aspirations)",
            targetDate: deadline,
            metrics: generateMetrics(for: aspirations, goalType: goalType),
            milestones: generateMilestones(for: aspirations, deadline: deadline),
            smartCriteria: GoalResult.SMARTCriteria(
                specific: aspirations,
                measurable: "Track progress daily",
                achievable: "Based on your fitness level: \(fitnessLevel ?? "intermediate")",
                relevant: "Aligned with your motivations: \(motivations.joined(separator: ", "))",
                timeBound: timeframe ?? "30 days"
            )
        )
    }
    
    func suggestGoalAdjustments(
        for goal: TrackedGoal,
        user: User
    ) async throws -> [GoalAdjustment] {
        // Analyze goal progress and suggest adjustments
        var adjustments: [GoalAdjustment] = []
        
        // Check if goal is off track
        if !goal.isOnTrack {
            if let daysRemaining = goal.daysRemaining, daysRemaining < 14 {
                // Timeline adjustment
                adjustments.append(GoalAdjustment(
                    type: .timeline,
                    reason: "Current progress indicates you may need more time",
                    suggestedChange: "Extend deadline by 2 weeks",
                    impact: "Gives you breathing room while maintaining momentum"
                ))
            } else {
                // Intensity adjustment
                adjustments.append(GoalAdjustment(
                    type: .intensity,
                    reason: "Progress is slower than expected",
                    suggestedChange: "Increase weekly effort by 20%",
                    impact: "Get back on track to meet your deadline"
                ))
            }
        }
        
        // Check if goal is too easy
        if goal.progressPercentage > 80 && (goal.daysRemaining ?? 0) > 30 {
            adjustments.append(GoalAdjustment(
                type: .target,
                reason: "You're progressing faster than expected",
                suggestedChange: "Consider raising your target by 20%",
                impact: "Challenge yourself to achieve even more"
            ))
        }
        
        return adjustments
    }
    
    // MARK: - GoalServiceProtocol forwarding
    
    func createGoal(_ goal: TrackedGoal) async throws {
        try await goalService.createGoal(goal)
    }
    
    func updateGoal(_ goal: TrackedGoal) async throws {
        try await goalService.updateGoal(goal)
    }
    
    func deleteGoal(_ goal: TrackedGoal) async throws {
        try await goalService.deleteGoal(goal)
    }
    
    func completeGoal(_ goal: TrackedGoal) async throws {
        try await goalService.completeGoal(goal)
    }
    
    func getActiveGoals(for userId: UUID) async throws -> [TrackedGoal] {
        try await goalService.getActiveGoals(for: userId)
    }
    
    func getAllGoals(for userId: UUID) async throws -> [TrackedGoal] {
        try await goalService.getAllGoals(for: userId)
    }
    
    func getGoal(by id: UUID) async throws -> TrackedGoal? {
        try await goalService.getGoal(by: id)
    }
    
    func updateProgress(for goalId: UUID, progress: Double) async throws {
        try await goalService.updateProgress(for: goalId, progress: progress)
    }
    
    func recordMilestone(for goalId: UUID, milestone: TrackedGoalMilestone) async throws {
        try await goalService.recordMilestone(for: goalId, milestone: milestone)
    }
    
    func getGoalsContext(for userId: UUID) async throws -> GoalsContext {
        try await goalService.getGoalsContext(for: userId)
    }
    
    func getGoalStatistics(for userId: UUID) async throws -> GoalStatistics {
        try await goalService.getGoalStatistics(for: userId)
    }
    
    // MARK: - Private Helpers
    
    private func mapGoalTypeToCategory(_ goalType: String?) -> TrackedGoalCategory {
        guard let goalType = goalType else { return .fitness }
        
        switch goalType.lowercased() {
        case "nutrition", "diet":
            return .nutrition
        case "wellness", "health":
            return .wellness
        case "recovery", "rest":
            return .recovery
        case "mindfulness", "mental":
            return .mindfulness
        default:
            return .fitness
        }
    }
    
    private func calculateDeadline(from timeframe: String?) -> Date? {
        guard let timeframe = timeframe else {
            return Date().addingTimeInterval(30 * 24 * 60 * 60) // Default 30 days
        }
        
        // Parse timeframe string (e.g., "30 days", "3 months", "1 year")
        let components = timeframe.lowercased().split(separator: " ")
        guard components.count >= 2,
              let value = Int(components[0]) else {
            return Date().addingTimeInterval(30 * 24 * 60 * 60)
        }
        
        let unit = String(components[1])
        let calendar = Calendar.current
        
        switch unit {
        case "day", "days":
            return calendar.date(byAdding: .day, value: value, to: Date())
        case "week", "weeks":
            return calendar.date(byAdding: .weekOfYear, value: value, to: Date())
        case "month", "months":
            return calendar.date(byAdding: .month, value: value, to: Date())
        case "year", "years":
            return calendar.date(byAdding: .year, value: value, to: Date())
        default:
            return Date().addingTimeInterval(30 * 24 * 60 * 60)
        }
    }
    
    private func generateMetrics(for aspirations: String, goalType: String?) -> [GoalMetric] {
        // Generate relevant metrics based on goal type
        var metrics: [GoalMetric] = []
        
        if aspirations.lowercased().contains("weight") {
            metrics.append(GoalMetric(
                name: "Body Weight",
                currentValue: 0,
                targetValue: 0,
                unit: "lbs"
            ))
        }
        
        if aspirations.lowercased().contains("strength") {
            metrics.append(GoalMetric(
                name: "Total Weight Lifted",
                currentValue: 0,
                targetValue: 0,
                unit: "lbs/week"
            ))
        }
        
        if aspirations.lowercased().contains("run") || aspirations.lowercased().contains("cardio") {
            metrics.append(GoalMetric(
                name: "Weekly Distance",
                currentValue: 0,
                targetValue: 0,
                unit: "miles"
            ))
        }
        
        return metrics
    }
    
    private func generateMilestones(for aspirations: String, deadline: Date?) -> [GoalMilestone] {
        guard let deadline = deadline else { return [] }
        
        let totalDays = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 30
        var milestones: [GoalMilestone] = []
        
        // Create 3 milestones at 25%, 50%, and 75% of timeline
        let intervals = [0.25, 0.5, 0.75]
        
        for (index, interval) in intervals.enumerated() {
            let daysToMilestone = Int(Double(totalDays) * interval)
            let milestoneDate = Calendar.current.date(byAdding: .day, value: daysToMilestone, to: Date()) ?? Date()
            
            milestones.append(GoalMilestone(
                title: "Milestone \(index + 1)",
                targetDate: milestoneDate,
                criteria: "\(Int(interval * 100))% progress achieved",
                reward: nil
            ))
        }
        
        return milestones
    }
}