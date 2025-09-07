import Foundation
import SwiftData

// MARK: - Repository Protocol Base

/// Base protocol for all read repositories
/// Provides boundary enforcement for data access layers
protocol ReadRepositoryProtocol: Sendable {
    associatedtype Entity
    associatedtype Filter
    
    func find(filter: Filter) async throws -> [Entity]
    func findFirst(filter: Filter) async throws -> Entity?
    func count(filter: Filter) async throws -> Int
}

// MARK: - User Repository

/// Read-only access to User data
/// Eliminates direct SwiftData dependencies in ViewModels
@MainActor
protocol UserReadRepositoryProtocol: ReadRepositoryProtocol {
    typealias Entity = User
    typealias Filter = UserFilter
    
    /// Find active user for the current session
    func findActiveUser() async throws -> User?
    
    /// Find user by ID
    func findUser(id: UUID) async throws -> User?
    
    /// Check if user has completed onboarding
    func hasCompletedOnboarding(userId: UUID) async throws -> Bool
    
    /// Get user's basic profile info without relationships
    func getUserProfile(userId: UUID) async throws -> UserProfile?
}

struct UserFilter: Sendable {
    let isActive: Bool?
    let hasCompletedOnboarding: Bool?
    let ids: [UUID]?
    
    init(isActive: Bool? = nil, hasCompletedOnboarding: Bool? = nil, ids: [UUID]? = nil) {
        self.isActive = isActive
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.ids = ids
    }
}

struct UserProfile: Sendable {
    let id: UUID
    let name: String
    let email: String?
    let createdAt: Date
    let lastActiveDate: Date
    let hasCompletedOnboarding: Bool
}

// MARK: - Chat History Repository

/// Read-only access to Chat data
/// Provides efficient message retrieval with filtering
@MainActor
protocol ChatHistoryRepositoryProtocol: ReadRepositoryProtocol {
    typealias Entity = ChatMessage
    typealias Filter = ChatFilter
    
    /// Get messages for a specific session
    func getMessages(sessionId: UUID, limit: Int?, offset: Int?) async throws -> [ChatMessage]
    
    /// Search messages by content
    func searchMessages(userId: UUID, query: String, limit: Int?) async throws -> [ChatMessage]
    
    /// Get active session for user
    func getActiveSession(userId: UUID) async throws -> ChatSession?
    
    /// Get recent sessions for user
    func getRecentSessions(userId: UUID, limit: Int) async throws -> [ChatSession]
    
    /// Get message count for session
    func getMessageCount(sessionId: UUID) async throws -> Int
}

struct ChatFilter: Sendable {
    let sessionId: UUID?
    let userId: UUID?
    let role: MessageRole?
    let afterDate: Date?
    let beforeDate: Date?
    let containsText: String?
    
    init(sessionId: UUID? = nil, userId: UUID? = nil, role: MessageRole? = nil, 
         afterDate: Date? = nil, beforeDate: Date? = nil, containsText: String? = nil) {
        self.sessionId = sessionId
        self.userId = userId
        self.role = role
        self.afterDate = afterDate
        self.beforeDate = beforeDate
        self.containsText = containsText
    }
}

// MARK: - Workout Repository

/// Read-only access to Workout data
/// Provides efficient workout queries with proper filtering
@MainActor
protocol WorkoutReadRepositoryProtocol: ReadRepositoryProtocol {
    typealias Entity = Workout
    typealias Filter = WorkoutFilter
    
    /// Get recent workouts for user
    func getRecentWorkouts(userId: UUID, days: Int, limit: Int?) async throws -> [Workout]
    
    /// Get active workout for user (not completed)
    func getActiveWorkout(userId: UUID) async throws -> Workout?
    
    /// Get upcoming planned workouts
    func getUpcomingWorkouts(userId: UUID, limit: Int?) async throws -> [Workout]
    
    /// Get workout by ID
    func getWorkout(id: UUID) async throws -> Workout?
    
    /// Get workouts by type
    func getWorkouts(userId: UUID, type: WorkoutType?, limit: Int?) async throws -> [Workout]
    
    /// Get workout statistics for date range
    func getWorkoutStats(userId: UUID, startDate: Date, endDate: Date) async throws -> WorkoutStats
}

struct WorkoutFilter: Sendable {
    let userId: UUID?
    let isCompleted: Bool?
    let workoutType: WorkoutType?
    let startDate: Date?
    let endDate: Date?
    let muscleGroups: [String]?
    
    init(userId: UUID? = nil, isCompleted: Bool? = nil, workoutType: WorkoutType? = nil,
         startDate: Date? = nil, endDate: Date? = nil, muscleGroups: [String]? = nil) {
        self.userId = userId
        self.isCompleted = isCompleted
        self.workoutType = workoutType
        self.startDate = startDate
        self.endDate = endDate
        self.muscleGroups = muscleGroups
    }
}

struct WorkoutStats: Sendable {
    let totalWorkouts: Int
    let totalDuration: TimeInterval
    let avgDuration: TimeInterval
    let totalVolume: Double
    let avgVolume: Double
    let muscleGroupDistribution: [String: Int]
}

// MARK: - Food Entry Repository

/// Read-only access to Food data
/// Provides nutrition data queries
@MainActor
protocol FoodEntryRepositoryProtocol: ReadRepositoryProtocol {
    typealias Entity = FoodEntry
    typealias Filter = FoodFilter
    
    /// Get food entries for specific date
    func getFoodEntries(userId: UUID, date: Date) async throws -> [FoodEntry]
    
    /// Get food entries for date range
    func getFoodEntries(userId: UUID, startDate: Date, endDate: Date) async throws -> [FoodEntry]
    
    /// Get recent food entries
    func getRecentFoodEntries(userId: UUID, limit: Int) async throws -> [FoodEntry]
    
    /// Get nutrition summary for date
    func getNutritionSummary(userId: UUID, date: Date) async throws -> NutritionDataSummary?
}

struct FoodFilter: Sendable {
    let userId: UUID?
    let startDate: Date?
    let endDate: Date?
    let mealType: MealType?
    
    init(userId: UUID? = nil, startDate: Date? = nil, endDate: Date? = nil, mealType: MealType? = nil) {
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.mealType = mealType
    }
}

struct NutritionDataSummary: Sendable {
    let date: Date
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let entryCount: Int
}

// MARK: - Daily Log Repository

/// Read-only access to DailyLog data
/// Provides subjective data queries
@MainActor
protocol DailyLogRepositoryProtocol: ReadRepositoryProtocol {
    typealias Entity = DailyLog
    typealias Filter = DailyLogFilter
    
    /// Get daily log for specific date
    func getDailyLog(userId: UUID, date: Date) async throws -> DailyLog?
    
    /// Get recent daily logs
    func getRecentDailyLogs(userId: UUID, days: Int) async throws -> [DailyLog]
    
    /// Check if user checked in today
    func hasCheckedInToday(userId: UUID) async throws -> Bool
    
    /// Get energy level trend
    func getEnergyLevelTrend(userId: UUID, days: Int) async throws -> [EnergyDataPoint]
}

struct DailyLogFilter: Sendable {
    let userId: UUID?
    let startDate: Date?
    let endDate: Date?
    let hasCheckedIn: Bool?
    
    init(userId: UUID? = nil, startDate: Date? = nil, endDate: Date? = nil, hasCheckedIn: Bool? = nil) {
        self.userId = userId
        self.startDate = startDate
        self.endDate = endDate
        self.hasCheckedIn = hasCheckedIn
    }
}

struct EnergyDataPoint: Sendable {
    let date: Date
    let energyLevel: Double?
    let stressLevel: Double?
}