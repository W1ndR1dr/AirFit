import Foundation
import SwiftData
import XCTest
@testable import AirFit

/// Mock implementation of GoalServiceProtocol for testing
final class MockGoalService: GoalServiceProtocol, AIGoalServiceProtocol, MockProtocol, @unchecked Sendable {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    // MARK: - Error Control
    nonisolated(unsafe) var shouldThrowError = false
    nonisolated(unsafe) var errorToThrow: Error = AppError.unknown(message: "Mock goal service error")

    // MARK: - Data Storage
    private var goals: [UUID: ServiceGoal] = [:]
    private var userGoals: [UUID: Set<UUID>] = [:] // User ID to Goal IDs mapping

    // MARK: - Stubbed Responses
    var stubbedGoal: ServiceGoal?
    var stubbedGoals: [ServiceGoal] = []
    var stubbedCompletionStatus: Bool = false

    // MARK: - GoalServiceProtocol
    func createGoal(_ goalData: GoalCreationData, for user: User) async throws -> ServiceGoal {
        recordInvocation("createGoal", arguments: goalData.type, goalData.target, user.id)

        if shouldThrowError {
            throw errorToThrow
        }

        if let stubbed = stubbedGoal {
            goals[stubbed.id] = stubbed
            var userGoalSet = userGoals[user.id] ?? Set<UUID>()
            userGoalSet.insert(stubbed.id)
            userGoals[user.id] = userGoalSet
            return stubbed
        }

        // Create a new goal
        let goal = ServiceGoal(
            id: UUID(),
            type: goalData.type,
            target: goalData.target,
            currentValue: 0,
            deadline: goalData.deadline,
            createdAt: Date(),
            updatedAt: Date()
        )

        goals[goal.id] = goal
        var userGoalSet = userGoals[user.id] ?? Set<UUID>()
        userGoalSet.insert(goal.id)
        userGoals[user.id] = userGoalSet

        return goal
    }

    func updateGoal(_ goal: ServiceGoal, updates: GoalUpdate) async throws {
        recordInvocation("updateGoal", arguments: goal.id, updates.target as Any, updates.deadline as Any)

        if shouldThrowError {
            throw errorToThrow
        }

        guard let existingGoal = goals[goal.id] else {
            throw AppError.unknown(message: "Goal not found")
        }

        // Create updated goal
        let updatedGoal = ServiceGoal(
            id: existingGoal.id,
            type: existingGoal.type,
            target: updates.target ?? existingGoal.target,
            currentValue: existingGoal.currentValue,
            deadline: updates.deadline ?? existingGoal.deadline,
            createdAt: existingGoal.createdAt,
            updatedAt: Date()
        )

        goals[goal.id] = updatedGoal
    }

    func deleteGoal(_ goal: ServiceGoal) async throws {
        recordInvocation("deleteGoal", arguments: goal.id)

        if shouldThrowError {
            throw errorToThrow
        }

        guard goals[goal.id] != nil else {
            throw AppError.unknown(message: "Goal not found")
        }

        goals.removeValue(forKey: goal.id)

        // Remove from user goals mapping
        for (userId, var goalIds) in userGoals {
            if goalIds.contains(goal.id) {
                goalIds.remove(goal.id)
                userGoals[userId] = goalIds
            }
        }
    }

    func getActiveGoals(for user: User) async throws -> [ServiceGoal] {
        recordInvocation("getActiveGoals", arguments: user.id)

        if shouldThrowError {
            throw errorToThrow
        }

        if !stubbedGoals.isEmpty {
            return stubbedGoals
        }

        // Return goals for the user
        guard let goalIds = userGoals[user.id] else {
            return []
        }

        let activeGoals = goalIds.compactMap { goals[$0] }
            .filter { goal in
                // Filter out completed or expired goals
                if let deadline = goal.deadline, deadline < Date() {
                    return false
                }
                return goal.currentValue < goal.target
            }
            .sorted { $0.createdAt > $1.createdAt }

        return activeGoals
    }

    func trackProgress(for goal: ServiceGoal, value: Double) async throws {
        recordInvocation("trackProgress", arguments: goal.id, value)

        if shouldThrowError {
            throw errorToThrow
        }

        guard let existingGoal = goals[goal.id] else {
            throw AppError.unknown(message: "Goal not found")
        }

        // Update goal with new progress value
        let updatedGoal = ServiceGoal(
            id: existingGoal.id,
            type: existingGoal.type,
            target: existingGoal.target,
            currentValue: existingGoal.currentValue + value,
            deadline: existingGoal.deadline,
            createdAt: existingGoal.createdAt,
            updatedAt: Date()
        )

        goals[goal.id] = updatedGoal
    }

    func checkGoalCompletion(_ goal: ServiceGoal) async -> Bool {
        recordInvocation("checkGoalCompletion", arguments: goal.id)

        if stubbedCompletionStatus {
            return stubbedCompletionStatus
        }

        guard let currentGoal = goals[goal.id] else {
            return false
        }

        return currentGoal.currentValue >= currentGoal.target
    }

    // MARK: - Test Helpers
    func stubGoal(_ goal: ServiceGoal) {
        stubbedGoal = goal
    }

    func stubActiveGoals(_ goals: [ServiceGoal]) {
        stubbedGoals = goals
    }

    func stubCompletionStatus(_ isCompleted: Bool) {
        stubbedCompletionStatus = isCompleted
    }

    func getGoal(byId id: UUID) -> ServiceGoal? {
        mockLock.lock()
        defer { mockLock.unlock() }
        return goals[id]
    }

    func verifyGoalCreated(type: GoalType, target: Double) {
        mockLock.lock()
        defer { mockLock.unlock() }

        guard let calls = invocations["createGoal"] as? [[Any]] else {
            XCTFail("No goals were created")
            return
        }

        let matching = calls.contains { args in
            guard args.count >= 2,
                  let goalType = args[0] as? GoalType,
                  let goalTarget = args[1] as? Double else {
                return false
            }
            return goalType == type && abs(goalTarget - target) < 0.0001
        }

        XCTAssertTrue(matching, "No goal created with type: \(type) and target: \(target)")
    }

    func verifyProgressTracked(goalId: UUID, value: Double) {
        mockLock.lock()
        defer { mockLock.unlock() }

        guard let calls = invocations["trackProgress"] as? [[Any]] else {
            XCTFail("No progress was tracked")
            return
        }

        let matching = calls.contains { args in
            guard args.count >= 2,
                  let id = args[0] as? UUID,
                  let trackedValue = args[1] as? Double else {
                return false
            }
            return id == goalId && abs(trackedValue - value) < 0.0001
        }

        XCTAssertTrue(matching, "No progress tracked for goal: \(goalId) with value: \(value)")
    }

    func resetAllGoals() {
        mockLock.lock()
        defer { mockLock.unlock() }
        goals.removeAll()
        userGoals.removeAll()
        stubbedGoals.removeAll()
    }

    // MARK: - AIGoalServiceProtocol
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
        recordInvocation("createOrRefineGoal", arguments: current ?? "", aspirations, timeframe ?? "", fitnessLevel ?? "", constraints, motivations, goalType ?? "", user.id)

        if shouldThrowError {
            throw errorToThrow
        }

        return GoalResult(
            id: UUID(),
            title: aspirations,
            description: "Mock goal based on: \(aspirations)",
            targetDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            metrics: [],
            milestones: [],
            smartCriteria: GoalResult.SMARTCriteria(
                specific: aspirations,
                measurable: "Track progress daily",
                achievable: "Based on your fitness level",
                relevant: "Aligned with your motivations",
                timeBound: timeframe ?? "30 days"
            )
        )
    }

    func suggestGoalAdjustments(
        for goal: ServiceGoal,
        user: User
    ) async throws -> [GoalAdjustment] {
        recordInvocation("suggestGoalAdjustments", arguments: goal.id, user.id)

        if shouldThrowError {
            throw errorToThrow
        }

        return []
    }
}
