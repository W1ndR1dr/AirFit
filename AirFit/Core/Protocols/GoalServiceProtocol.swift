import Foundation
import SwiftData

/// Protocol for goal management operations
protocol GoalServiceProtocol: AnyObject, Sendable {
    func createGoal(
        _ goalData: GoalCreationData,
        for user: User
    ) async throws -> ServiceGoal
    
    func updateGoal(
        _ goal: ServiceGoal,
        updates: GoalUpdate
    ) async throws
    
    func deleteGoal(_ goal: ServiceGoal) async throws
    
    func getActiveGoals(for user: User) async throws -> [ServiceGoal]
    
    func trackProgress(
        for goal: ServiceGoal,
        value: Double
    ) async throws
    
    func checkGoalCompletion(_ goal: ServiceGoal) async -> Bool
}

// MARK: - Supporting Types

struct ServiceGoal: Sendable, Identifiable {
    let id: UUID
    let type: GoalType
    let target: Double
    let currentValue: Double
    let deadline: Date?
    let createdAt: Date
    let updatedAt: Date
}

enum GoalType: String, Sendable, CaseIterable {
    case weightLoss
    case muscleGain
    case stepCount
    case workoutFrequency
    case calorieIntake
    case waterIntake
    case custom
}

struct GoalCreationData: Sendable {
    let type: GoalType
    let target: Double
    let deadline: Date?
    let description: String?
}

struct GoalUpdate: Sendable {
    let target: Double?
    let deadline: Date?
    let description: String?
}