import Foundation
import SwiftData

/// Read-only repository for Workout data access
/// Provides efficient workout queries with proper filtering
@MainActor
final class WorkoutReadRepository: WorkoutReadRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - ReadRepositoryProtocol
    
    func find(filter: WorkoutFilter) async throws -> [Workout] {
        let descriptor = createFetchDescriptor(for: filter)
        return try modelContext.fetch(descriptor)
    }
    
    func findFirst(filter: WorkoutFilter) async throws -> Workout? {
        var descriptor = createFetchDescriptor(for: filter)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    func count(filter: WorkoutFilter) async throws -> Int {
        let descriptor = createFetchDescriptor(for: filter)
        return try modelContext.fetchCount(descriptor)
    }
    
    // MARK: - WorkoutReadRepositoryProtocol
    
    func getRecentWorkouts(userId: UUID, days: Int, limit: Int?) async throws -> [Workout] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let filter = WorkoutFilter(
            userId: userId, 
            isCompleted: true, 
            startDate: startDate
        )
        
        var descriptor = createFetchDescriptor(for: filter)
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func getActiveWorkout(userId: UUID) async throws -> Workout? {
        let filter = WorkoutFilter(userId: userId, isCompleted: false)
        return try await findFirst(filter: filter)
    }
    
    func getUpcomingWorkouts(userId: UUID, limit: Int?) async throws -> [Workout] {
        let now = Date()
        let filter = WorkoutFilter(
            userId: userId, 
            isCompleted: false, 
            startDate: now
        )
        
        var descriptor = createFetchDescriptor(for: filter)
        descriptor.sortBy = [SortDescriptor(\.plannedDate, order: .forward)]
        
        // Only get workouts with planned dates in the future
        descriptor.predicate = #Predicate<Workout> { workout in
            workout.user?.id == userId &&
            workout.completedDate == nil &&
            (workout.plannedDate ?? Date.distantPast) > now
        }
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func getWorkout(id: UUID) async throws -> Workout? {
        var descriptor = FetchDescriptor<Workout>()
        descriptor.predicate = #Predicate<Workout> { workout in
            workout.id == id
        }
        descriptor.fetchLimit = 1
        
        return try modelContext.fetch(descriptor).first
    }
    
    func getWorkouts(userId: UUID, type: Workout.WorkoutType?, limit: Int?) async throws -> [Workout] {
        let filter = WorkoutFilter(userId: userId, workoutType: type)
        
        var descriptor = createFetchDescriptor(for: filter)
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    func getWorkoutStats(userId: UUID, startDate: Date, endDate: Date) async throws -> WorkoutStats {
        let filter = WorkoutFilter(
            userId: userId, 
            isCompleted: true,
            startDate: startDate, 
            endDate: endDate
        )
        
        let workouts = try await find(filter: filter)
        
        let totalWorkouts = workouts.count
        let totalDuration = workouts.compactMap { $0.durationSeconds }.reduce(0, +)
        let avgDuration = totalWorkouts > 0 ? totalDuration / TimeInterval(totalWorkouts) : 0
        
        // Calculate volume (weight × reps for all exercises)
        var totalVolume: Double = 0
        var muscleGroupCounts: [String: Int] = [:]
        
        for workout in workouts {
            for exercise in workout.exercises {
                // Track muscle groups
                for muscleGroup in exercise.muscleGroups {
                    muscleGroupCounts[muscleGroup, default: 0] += 1
                }
                
                // Calculate exercise volume
                for set in exercise.sets {
                    let weight = set.completedWeightKg ?? set.targetWeightKg ?? 0
                    let reps = Double(set.completedReps ?? set.targetReps ?? 0)
                    totalVolume += weight * reps
                }
            }
        }
        
        let avgVolume = totalWorkouts > 0 ? totalVolume / Double(totalWorkouts) : 0
        
        return WorkoutStats(
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            avgDuration: avgDuration,
            totalVolume: totalVolume,
            avgVolume: avgVolume,
            muscleGroupDistribution: muscleGroupCounts
        )
    }
    
    // MARK: - Private Helpers
    
    private func createFetchDescriptor(for filter: WorkoutFilter) -> FetchDescriptor<Workout> {
        var descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )
        
        var predicates: [Predicate<Workout>] = []
        
        if let userId = filter.userId {
            predicates.append(#Predicate { workout in
                workout.user?.id == userId
            })
        }
        
        if let isCompleted = filter.isCompleted {
            predicates.append(#Predicate { workout in
                (workout.completedDate != nil) == isCompleted
            })
        }
        
        if let workoutType = filter.workoutType {
            predicates.append(#Predicate { workout in
                workout.workoutTypeEnum == workoutType
            })
        }
        
        if let startDate = filter.startDate {
            predicates.append(#Predicate { workout in
                // Use completedDate if available, otherwise plannedDate
                let workoutDate = workout.completedDate ?? workout.plannedDate ?? Date.distantPast
                return workoutDate >= startDate
            })
        }
        
        if let endDate = filter.endDate {
            predicates.append(#Predicate { workout in
                let workoutDate = workout.completedDate ?? workout.plannedDate ?? Date.distantPast
                return workoutDate <= endDate
            })
        }
        
        if let muscleGroups = filter.muscleGroups, !muscleGroups.isEmpty {
            predicates.append(#Predicate { workout in
                // Check if any exercise targets the specified muscle groups
                workout.exercises.contains { exercise in
                    muscleGroups.contains { muscle in
                        exercise.muscleGroups.contains(muscle)
                    }
                }
            })
        }
        
        // Combine predicates with AND logic
        if !predicates.isEmpty {
            descriptor.predicate = predicates.reduce(nil) { result, predicate in
                if let result = result {
                    return #Predicate<Workout> { workout in
                        result.evaluate(workout) && predicate.evaluate(workout)
                    }
                } else {
                    return predicate
                }
            }
        }
        
        return descriptor
    }
}

// MARK: - Workout Repository Extensions

extension WorkoutReadRepository {
    
    /// Get workout streak for user (consecutive days with workouts)
    func getWorkoutStreak(userId: UUID) async throws -> Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let filter = WorkoutFilter(
            userId: userId,
            isCompleted: true,
            startDate: thirtyDaysAgo
        )
        
        let workouts = try await find(filter: filter)
            .compactMap { workout -> Date? in
                guard let completedDate = workout.completedDate else { return nil }
                return Calendar.current.startOfDay(for: completedDate)
            }
            .sorted(by: >)
        
        guard !workouts.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current
        
        // Allow for rest days (max 2-day gaps)
        var gapDays = 0
        let maxGapDays = 2
        
        for workoutDate in workouts {
            let daysDiff = calendar.dateComponents([.day], from: workoutDate, to: currentDate).day ?? 0
            
            if daysDiff <= 1 + gapDays {
                streak += 1
                currentDate = workoutDate
                gapDays = 0
            } else if daysDiff <= maxGapDays {
                gapDays += daysDiff - 1
                currentDate = workoutDate
            } else {
                break // Streak broken
            }
        }
        
        return streak
    }
    
    /// Get workout frequency for the past week
    func getWeeklyFrequency(userId: UUID) async throws -> Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let workouts = try await getRecentWorkouts(userId: userId, days: 7, limit: nil)
        
        return Double(workouts.count) / 7.0
    }
    
    /// Get workouts by muscle group preference
    func getWorkoutsByMuscleGroup(
        userId: UUID, 
        muscleGroups: [String], 
        days: Int = 30,
        limit: Int? = nil
    ) async throws -> [Workout] {
        let filter = WorkoutFilter(
            userId: userId,
            isCompleted: true,
            muscleGroups: muscleGroups
        )
        
        var descriptor = createFetchDescriptor(for: filter)
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    /// Get total volume lifted in the past period
    func getTotalVolume(userId: UUID, days: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let stats = try await getWorkoutStats(
            userId: userId, 
            startDate: startDate, 
            endDate: Date()
        )
        
        return stats.totalVolume
    }
}

// MARK: - Repository Error Handling

extension WorkoutReadRepository {
    enum RepositoryError: Error, LocalizedError {
        case workoutNotFound(UUID)
        case invalidDateRange
        case dataCorruption(String)
        
        var errorDescription: String? {
            switch self {
            case .workoutNotFound(let id):
                return "Workout with ID \(id) not found"
            case .invalidDateRange:
                return "Invalid date range provided"
            case .dataCorruption(let details):
                return "Data corruption detected: \(details)"
            }
        }
    }
    
    /// Safe method to get workout by ID with error handling
    func getWorkoutOrThrow(id: UUID) async throws -> Workout {
        guard let workout = try await getWorkout(id: id) else {
            throw RepositoryError.workoutNotFound(id)
        }
        return workout
    }
}