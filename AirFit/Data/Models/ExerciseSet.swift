import SwiftData
import Foundation

@Model
final class ExerciseSet: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var setNumber: Int
    var targetReps: Int?
    var completedReps: Int?
    var targetWeightKg: Double?
    var completedWeightKg: Double?
    var targetDurationSeconds: TimeInterval?
    var completedDurationSeconds: TimeInterval?
    var rpe: Double? // Rate of Perceived Exertion (1-10)
    var restDurationSeconds: TimeInterval?
    var notes: String?
    var completedAt: Date?

    // MARK: - Relationships
    var exercise: Exercise?

    // MARK: - Computed Properties
    var isCompleted: Bool {
        completedReps != nil || completedDurationSeconds != nil
    }

    var volume: Double? {
        guard let weight = completedWeightKg ?? targetWeightKg,
              let reps = completedReps ?? targetReps else { return nil }
        return weight * Double(reps)
    }

    var oneRepMax: Double? {
        guard let weight = completedWeightKg ?? targetWeightKg,
              let reps = completedReps ?? targetReps,
              reps > 0 else { return nil }

        // Epley Formula: 1RM = weight × (1 + reps/30)
        return weight * (1 + Double(reps) / 30)
    }

    var intensityPercentage: Double? {
        guard let weight = completedWeightKg ?? targetWeightKg,
              let oneRM = oneRepMax,
              oneRM > 0 else { return nil }
        return (weight / oneRM) * 100
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        setNumber: Int,
        targetReps: Int? = nil,
        targetWeightKg: Double? = nil,
        targetDurationSeconds: TimeInterval? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.targetDurationSeconds = targetDurationSeconds
    }

    // MARK: - Methods
    func complete(
        reps: Int? = nil,
        weight: Double? = nil,
        duration: TimeInterval? = nil,
        rpe: Double? = nil
    ) {
        self.completedReps = reps ?? targetReps
        self.completedWeightKg = weight ?? targetWeightKg
        self.completedDurationSeconds = duration ?? targetDurationSeconds
        self.rpe = rpe
        self.completedAt = Date()
    }

    func reset() {
        completedReps = nil
        completedWeightKg = nil
        completedDurationSeconds = nil
        rpe = nil
        completedAt = nil
    }
}
