import Foundation

// MARK: - Workout Completion Data
//
// Purpose: Capture what was actually performed during a workout vs what was planned.
// This data is sent from watch to iPhone after workout completion for AI analysis.

/// Complete workout execution data for AI analysis
public struct WorkoutCompletionData: Codable, Sendable {
    /// The original planned workout
    let plannedWorkout: PlannedWorkoutData
    
    /// What was actually performed
    let actualExercises: [ActualExerciseData]
    
    /// Overall workout metrics
    let totalDuration: TimeInterval
    let totalCalories: Double
    let averageHeartRate: Double?
    
    /// User feedback
    let overallRPE: Double?
    let notes: String?
    
    /// Timing information
    let startTime: Date
    let endTime: Date
    
    /// HealthKit workout ID for reference
    let healthKitWorkoutID: String?
    
    public init(
        plannedWorkout: PlannedWorkoutData,
        actualExercises: [ActualExerciseData],
        totalDuration: TimeInterval,
        totalCalories: Double,
        averageHeartRate: Double? = nil,
        overallRPE: Double? = nil,
        notes: String? = nil,
        startTime: Date,
        endTime: Date,
        healthKitWorkoutID: String? = nil
    ) {
        self.plannedWorkout = plannedWorkout
        self.actualExercises = actualExercises
        self.totalDuration = totalDuration
        self.totalCalories = totalCalories
        self.averageHeartRate = averageHeartRate
        self.overallRPE = overallRPE
        self.notes = notes
        self.startTime = startTime
        self.endTime = endTime
        self.healthKitWorkoutID = healthKitWorkoutID
    }
}

/// Exercise as actually performed
public struct ActualExerciseData: Codable, Sendable {
    /// ID from planned exercise for matching
    let plannedExerciseId: UUID
    
    /// Exercise name (may have been modified)
    let name: String
    
    /// What was actually done
    let sets: [ActualSetData]
    
    /// Was this exercise skipped entirely?
    let wasSkipped: Bool
    
    /// If modified, why?
    let modificationReason: String?
    
    public init(
        plannedExerciseId: UUID,
        name: String,
        sets: [ActualSetData],
        wasSkipped: Bool = false,
        modificationReason: String? = nil
    ) {
        self.plannedExerciseId = plannedExerciseId
        self.name = name
        self.sets = sets
        self.wasSkipped = wasSkipped
        self.modificationReason = modificationReason
    }
}

/// Individual set performance
public struct ActualSetData: Codable, Sendable {
    /// What was planned
    let plannedReps: Int
    let plannedWeight: Double?
    
    /// What was actually done
    let actualReps: Int
    let actualWeight: Double
    let rpe: Double
    
    /// Timing
    let restTaken: TimeInterval?
    let completedAt: Date
    
    public init(
        plannedReps: Int,
        plannedWeight: Double? = nil,
        actualReps: Int,
        actualWeight: Double,
        rpe: Double,
        restTaken: TimeInterval? = nil,
        completedAt: Date
    ) {
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.rpe = rpe
        self.restTaken = restTaken
        self.completedAt = completedAt
    }
}

// MARK: - Analysis Extensions

extension WorkoutCompletionData {
    /// Calculate adherence to plan (0-1)
    var planAdherence: Double {
        let plannedExerciseCount = Double(plannedWorkout.plannedExercises.count)
        let completedExerciseCount = Double(actualExercises.filter { !$0.wasSkipped }.count)
        
        guard plannedExerciseCount > 0 else { return 0 }
        return completedExerciseCount / plannedExerciseCount
    }
    
    /// Average RPE across all sets
    var averageRPE: Double? {
        let allRPEs = actualExercises.flatMap { $0.sets.map { $0.rpe } }
        guard !allRPEs.isEmpty else { return nil }
        return allRPEs.reduce(0, +) / Double(allRPEs.count)
    }
    
    /// Total volume (sets x reps x weight)
    var totalVolume: Double {
        actualExercises.flatMap { $0.sets }.reduce(0) { total, set in
            total + (Double(set.actualReps) * set.actualWeight)
        }
    }
    
    /// Generate summary for AI analysis
    func generateSummaryForAI() -> String {
        var summary = "Workout Completion Summary:\n"
        summary += "Plan: \(plannedWorkout.name)\n"
        summary += "Duration: \(Int(totalDuration / 60)) minutes (planned: \(plannedWorkout.estimatedDuration) min)\n"
        summary += "Exercises completed: \(actualExercises.filter { !$0.wasSkipped }.count)/\(plannedWorkout.plannedExercises.count)\n"
        
        if let avgRPE = averageRPE {
            summary += "Average RPE: \(String(format: "%.1f", avgRPE))/10\n"
        }
        
        summary += "\nExercise Details:\n"
        for exercise in actualExercises {
            if exercise.wasSkipped {
                summary += "- \(exercise.name): SKIPPED"
                if let reason = exercise.modificationReason {
                    summary += " (Reason: \(reason))"
                }
                summary += "\n"
            } else {
                let plannedExercise = plannedWorkout.plannedExercises.first { $0.id == exercise.plannedExerciseId }
                summary += "- \(exercise.name): \(exercise.sets.count) sets"
                if let planned = plannedExercise {
                    summary += " (planned: \(planned.sets) sets)"
                }
                
                // Show performance vs plan
                let avgWeight = exercise.sets.map { $0.actualWeight }.reduce(0, +) / Double(exercise.sets.count)
                let avgReps = exercise.sets.map { Double($0.actualReps) }.reduce(0, +) / Double(exercise.sets.count)
                summary += String(format: " - Avg: %.0f reps @ %.1f kg", avgReps, avgWeight)
                summary += "\n"
            }
        }
        
        if let notes = notes {
            summary += "\nUser notes: \(notes)\n"
        }
        
        return summary
    }
}

// MARK: - Conversion from WorkoutBuilderData

extension WorkoutCompletionData {
    /// Create completion data from watch workout data and planned workout
    static func from(
        workoutData: WorkoutBuilderData,
        plannedWorkout: PlannedWorkoutData,
        healthKitID: String? = nil
    ) -> WorkoutCompletionData {
        
        // Map actual exercises to planned exercises
        var actualExercises: [ActualExerciseData] = []
        
        for plannedExercise in plannedWorkout.plannedExercises {
            // Try to find matching exercise in workout data
            if let actualExercise = workoutData.exercises.first(where: { 
                $0.name.lowercased() == plannedExercise.name.lowercased() 
            }) {
                // Exercise was performed
                let actualSets = actualExercise.sets.map { set in
                    ActualSetData(
                        plannedReps: plannedExercise.targetReps,
                        plannedWeight: nil, // We don't track planned weight yet
                        actualReps: set.reps ?? 0,
                        actualWeight: set.weightKg ?? 0,
                        rpe: set.rpe ?? 7,
                        restTaken: nil, // Could calculate from timestamps
                        completedAt: set.completedAt
                    )
                }
                
                actualExercises.append(ActualExerciseData(
                    plannedExerciseId: plannedExercise.id,
                    name: actualExercise.name,
                    sets: actualSets,
                    wasSkipped: false
                ))
            } else {
                // Exercise was skipped
                actualExercises.append(ActualExerciseData(
                    plannedExerciseId: plannedExercise.id,
                    name: plannedExercise.name,
                    sets: [],
                    wasSkipped: true
                ))
            }
        }
        
        return WorkoutCompletionData(
            plannedWorkout: plannedWorkout,
            actualExercises: actualExercises,
            totalDuration: workoutData.duration,
            totalCalories: workoutData.totalCalories,
            averageHeartRate: nil, // Could add from HealthKit
            overallRPE: nil, // Could prompt user
            notes: nil,
            startTime: workoutData.startTime ?? Date(),
            endTime: workoutData.endTime ?? Date(),
            healthKitWorkoutID: healthKitID
        )
    }
}