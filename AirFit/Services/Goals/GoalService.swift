import Foundation
import SwiftData

/// # GoalService
/// 
/// ## Purpose
/// Manages user fitness and health goals, tracks progress, and provides contextual
/// goal information to the AI coach for personalized guidance.
///
/// ## Dependencies
/// - `ModelContext`: SwiftData context for persisting and querying goal data
///
/// ## Key Responsibilities
/// - Create, update, and delete fitness/nutrition goals
/// - Track goal progress and milestones
/// - Identify goals needing attention based on deadlines
/// - Calculate goal statistics and completion rates
/// - Provide goal context for AI coaching decisions
/// - Monitor goal streaks and achievements
///
/// ## Usage
/// ```swift
/// let goalService = await container.resolve(GoalServiceProtocol.self)
/// 
/// // Create a new goal
/// let goal = TrackedGoal(title: "Lose 10 lbs", type: .weightLoss)
/// try await goalService.createGoal(goal)
/// 
/// // Update progress
/// try await goalService.updateProgress(for: goal.id, progress: 5.0)
/// 
/// // Get goal context for AI
/// let context = try await goalService.getGoalsContext(for: userId)
/// ```
///
/// ## Important Notes
/// - Automatically marks goals complete when target is reached
/// - Provides rich context for AI coaching recommendations
/// - Tracks both quantitative and qualitative goals
@MainActor
final class GoalService: GoalServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "goal-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For @MainActor classes, we need to return a simple value
        // The actual state is tracked in _isConfigured
        true
    }
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        // Check if we can access goals data
        let canAccessData = (try? modelContext.fetch(FetchDescriptor<TrackedGoal>())) != nil
        
        return ServiceHealth(
            status: canAccessData ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: canAccessData ? nil : "Cannot access goals data",
            metadata: ["modelContext": "true"]
        )
    }
    
    // MARK: - Goal Management
    
    func createGoal(_ goal: TrackedGoal) async throws {
        modelContext.insert(goal)
        try modelContext.save()
        
        AppLogger.info("Created goal: \(goal.title) - Target: \(goal.targetValue ?? "N/A")", category: .services)
    }
    
    func updateGoal(_ goal: TrackedGoal) async throws {
        goal.lastModifiedDate = Date()
        try modelContext.save()
        
        AppLogger.info("Updated goal: \(goal.title)", category: .services)
    }
    
    func deleteGoal(_ goal: TrackedGoal) async throws {
        modelContext.delete(goal)
        try modelContext.save()
        
        AppLogger.info("Deleted goal: \(goal.title)", category: .services)
    }
    
    func completeGoal(_ goal: TrackedGoal) async throws {
        goal.status = .completed
        goal.completedDate = Date()
        goal.lastModifiedDate = Date()
        try modelContext.save()
        
        AppLogger.info("Completed goal: \(goal.title)", category: .services)
    }
    
    // MARK: - Goal Retrieval
    
    func getActiveGoals(for userId: UUID) async throws -> [TrackedGoal] {
        let descriptor = FetchDescriptor<TrackedGoal>(
            predicate: #Predicate { goal in
                goal.userId == userId && goal.status.rawValue == "active"
            },
            sortBy: [SortDescriptor(\.priority, order: .reverse), SortDescriptor(\.createdDate)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func getAllGoals(for userId: UUID) async throws -> [TrackedGoal] {
        let descriptor = FetchDescriptor<TrackedGoal>(
            predicate: #Predicate { goal in
                goal.userId == userId
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func getGoal(by id: UUID) async throws -> TrackedGoal? {
        let descriptor = FetchDescriptor<TrackedGoal>(
            predicate: #Predicate { goal in
                goal.id == id
            }
        )
        
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Progress Tracking
    
    func updateProgress(for goalId: UUID, progress: Double) async throws {
        guard let goal = try await getGoal(by: goalId) else {
            throw AppError.unknown(message: "Goal not found")
        }
        
        goal.currentProgress = progress
        goal.lastProgressUpdate = Date()
        goal.lastModifiedDate = Date()
        
        // Check if goal is completed
        if let targetValue = goal.targetValueNumeric,
           progress >= targetValue {
            goal.status = .completed
            goal.completedDate = Date()
        }
        
        try modelContext.save()
        
        AppLogger.info("Updated progress for goal \(goal.title): \(progress)", category: .services)
    }
    
    func recordMilestone(for goalId: UUID, milestone: TrackedGoalMilestone) async throws {
        guard let goal = try await getGoal(by: goalId) else {
            throw AppError.unknown(message: "Goal not found")
        }
        
        goal.milestones.append(milestone)
        goal.lastModifiedDate = Date()
        try modelContext.save()
        
        AppLogger.info("Recorded milestone for goal \(goal.title): \(milestone.title)", category: .services)
    }
    
    // MARK: - Context Assembly
    
    func getGoalsContext(for userId: UUID) async throws -> GoalsContext {
        let activeGoals = try await getActiveGoals(for: userId)
        
        // Calculate overall progress and insights
        let goalSummaries = activeGoals.map { goal in
            GoalSummary(
                id: goal.id,
                title: goal.title,
                type: goal.type,
                category: goal.category,
                targetValue: goal.targetValue,
                currentProgress: goal.currentProgress,
                progressPercentage: goal.progressPercentage,
                deadline: goal.deadline,
                daysRemaining: goal.daysRemaining,
                isOnTrack: goal.isOnTrack,
                priority: goal.priority
            )
        }
        
        // Identify goals needing attention
        let goalsNeedingAttention = activeGoals.filter { goal in
            guard let deadline = goal.deadline else { return false }
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
            let progressNeeded = 100.0 - goal.progressPercentage
            
            // Flag if behind schedule
            if daysRemaining > 0 {
                let expectedProgress = (1.0 - (Double(daysRemaining) / Double(goal.totalDays ?? 30))) * 100
                return goal.progressPercentage < expectedProgress * 0.8 // 20% buffer
            }
            return daysRemaining <= 7 && progressNeeded > 20
        }
        
        // Recent achievements
        let recentAchievements = try await getRecentCompletedGoals(for: userId, days: 30)
        
        return GoalsContext(
            activeGoals: goalSummaries,
            totalActiveGoals: activeGoals.count,
            goalsNeedingAttention: goalsNeedingAttention.map { $0.id },
            recentAchievements: recentAchievements.map { $0.title },
            primaryGoal: activeGoals.first { $0.priority.rawValue == "high" }?.id
        )
    }
    
    // MARK: - Analytics
    
    func getGoalStatistics(for userId: UUID) async throws -> GoalStatistics {
        let allGoals = try await getAllGoals(for: userId)
        
        let completed = allGoals.filter { $0.status.rawValue == "completed" }
        let active = allGoals.filter { $0.status.rawValue == "active" }
        let paused = allGoals.filter { $0.status.rawValue == "paused" }
        
        let completionRate = allGoals.isEmpty ? 0.0 : Double(completed.count) / Double(allGoals.count)
        
        // Calculate average time to complete
        let completionTimes = completed.compactMap { goal -> Int? in
            guard let completedDate = goal.completedDate else { return nil }
            return Calendar.current.dateComponents([.day], from: goal.createdDate, to: completedDate).day
        }
        let averageCompletionDays = completionTimes.isEmpty ? 0 : completionTimes.reduce(0, +) / completionTimes.count
        
        return GoalStatistics(
            totalGoals: allGoals.count,
            activeGoals: active.count,
            completedGoals: completed.count,
            pausedGoals: paused.count,
            completionRate: completionRate,
            averageCompletionDays: averageCompletionDays,
            currentStreak: calculateStreak(from: completed)
        )
    }
    
    // MARK: - Private Helpers
    
    private func getRecentCompletedGoals(for userId: UUID, days: Int) async throws -> [TrackedGoal] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<TrackedGoal>(
            predicate: #Predicate { goal in
                goal.userId == userId &&
                goal.status.rawValue == "completed" &&
                goal.completedDate != nil &&
                goal.completedDate! >= cutoffDate
            },
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    private func calculateStreak(from completedGoals: [TrackedGoal]) -> Int {
        // Calculate consecutive days with completed goals
        let sortedByCompletion = completedGoals
            .compactMap { goal -> Date? in goal.completedDate }
            .sorted(by: >)
        
        guard !sortedByCompletion.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = Date()
        let calendar = Calendar.current
        
        for completionDate in sortedByCompletion {
            let daysDifference = calendar.dateComponents([.day], from: completionDate, to: currentDate).day ?? 0
            
            if daysDifference <= 1 {
                streak += 1
                currentDate = completionDate
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Supporting Types

/// Context structure for AI coach integration
struct GoalsContext: Codable {
    let activeGoals: [GoalSummary]
    let totalActiveGoals: Int
    let goalsNeedingAttention: [UUID]
    let recentAchievements: [String]
    let primaryGoal: UUID?
}

/// Lightweight goal summary for context
struct GoalSummary: Codable {
    let id: UUID
    let title: String
    let type: TrackedGoalType
    let category: TrackedGoalCategory
    let targetValue: String?
    let currentProgress: Double
    let progressPercentage: Double
    let deadline: Date?
    let daysRemaining: Int?
    let isOnTrack: Bool
    let priority: TrackedGoalPriority
}

/// Goal statistics for analytics
struct GoalStatistics {
    let totalGoals: Int
    let activeGoals: Int
    let completedGoals: Int
    let pausedGoals: Int
    let completionRate: Double
    let averageCompletionDays: Int
    let currentStreak: Int
}
