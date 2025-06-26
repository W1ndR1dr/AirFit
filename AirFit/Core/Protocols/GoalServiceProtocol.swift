import Foundation
import SwiftData

/// Protocol defining goal management operations for the fitness app
@MainActor
protocol GoalServiceProtocol: AnyObject, Sendable {
    // MARK: - Goal Management

    /// Creates a new goal
    func createGoal(_ goal: TrackedGoal) async throws

    /// Updates an existing goal
    func updateGoal(_ goal: TrackedGoal) async throws

    /// Deletes a goal
    func deleteGoal(_ goal: TrackedGoal) async throws

    /// Marks a goal as completed
    func completeGoal(_ goal: TrackedGoal) async throws

    // MARK: - Goal Retrieval

    /// Gets all active goals for a user
    func getActiveGoals(for userId: UUID) async throws -> [TrackedGoal]

    /// Gets all goals for a user
    func getAllGoals(for userId: UUID) async throws -> [TrackedGoal]

    /// Gets a specific goal by ID
    func getGoal(by id: UUID) async throws -> TrackedGoal?

    // MARK: - Progress Tracking

    /// Updates progress for a specific goal
    func updateProgress(for goalId: UUID, progress: Double) async throws

    /// Records a milestone achievement for a goal
    func recordMilestone(for goalId: UUID, milestone: TrackedGoalMilestone) async throws

    // MARK: - Context Assembly

    /// Gets goal context for AI coach integration
    func getGoalsContext(for userId: UUID) async throws -> GoalsContext

    // MARK: - Analytics

    /// Gets goal statistics for a user
    func getGoalStatistics(for userId: UUID) async throws -> GoalStatistics
}
