import Foundation
import SwiftData

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var name: String
    var workoutType: String
    var plannedDate: Date?
    var completedDate: Date?
    var durationSeconds: TimeInterval?

    // Relationships
    @Relationship var exercises: [Exercise]
    @Relationship var user: User?

    init(name: String, workoutType: String, plannedDate: Date? = nil, user: User? = nil) {
        self.id = UUID()
        self.name = name
        self.workoutType = workoutType
        self.plannedDate = plannedDate
        self.completedDate = nil
        self.durationSeconds = nil
        self.exercises = []
        self.user = user
    }

    var isCompleted: Bool { completedDate != nil }

    var totalSets: Int { exercises.flatMap { $0.sets }.count }

    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                let w = set.completedWeightKg ?? set.targetWeightKg ?? 0
                let r = Double(set.completedReps ?? set.targetReps ?? 0)
                return setTotal + (w * r)
            }
        }
    }

    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        exercise.workout = self
    }

    func completeWorkout(on date: Date = Date()) {
        completedDate = date
    }

    // Convenience to mimic prior API
    var workoutTypeEnum: WorkoutTypeEnum? { .init(rawValue: workoutType) }
}

enum WorkoutTypeEnum: String {
    case strength
    case cardio
    case unknown

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .unknown: return "Unknown"
        }
    }
}

@Model
final class Exercise {
    var name: String
    var muscleGroups: [String]
    @Relationship var sets: [ExerciseSet]
    @Relationship var workout: Workout?

    init(name: String, muscleGroups: [String] = []) {
        self.name = name
        self.muscleGroups = muscleGroups
        self.sets = []
    }

    func addSet(_ set: ExerciseSet) {
        sets.append(set)
        set.exercise = self
    }

    var completedSets: [ExerciseSet] { sets.filter { $0.completedReps != nil } }
}

@Model
final class ExerciseSet {
    var setNumber: Int?
    var targetReps: Int?
    var targetWeightKg: Double?

    var completedReps: Int?
    var completedWeightKg: Double?
    var rpe: Double?

    @Relationship var exercise: Exercise?

    init(setNumber: Int? = nil, targetReps: Int? = nil, targetWeightKg: Double? = nil) {
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
    }

    func complete(reps: Int, weight: Double, rpe: Double? = nil) {
        self.completedReps = reps
        self.completedWeightKg = weight
        self.rpe = rpe
    }

    var oneRepMax: Double? {
        guard let w = completedWeightKg, let r = completedReps, r > 0 else { return nil }
        // Epley estimate
        return w * (1.0 + Double(r)/30.0)
    }
}

