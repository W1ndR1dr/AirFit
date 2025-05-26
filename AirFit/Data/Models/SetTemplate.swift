import SwiftData
import Foundation

@Model
final class SetTemplate: Sendable {
    // MARK: - Properties
    var id: UUID
    var setNumber: Int
    var targetReps: Int?
    var targetWeightKg: Double?
    var targetDurationSeconds: TimeInterval?
    var notes: String?
    
    // MARK: - Relationships
    var exerciseTemplate: ExerciseTemplate?
    
    // MARK: - Computed Properties
    var isTimeBasedSet: Bool {
        targetDurationSeconds != nil
    }
    
    var isRepBasedSet: Bool {
        targetReps != nil
    }
    
    var formattedTarget: String {
        if let reps = targetReps, let weight = targetWeightKg {
            return "\(reps) × \(Int(weight))kg"
        } else if let reps = targetReps {
            return "\(reps) reps"
        } else if let duration = targetDurationSeconds {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        } else {
            return "No target"
        }
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
    func duplicate() -> SetTemplate {
        SetTemplate(
            setNumber: setNumber,
            targetReps: targetReps,
            targetWeightKg: targetWeightKg,
            targetDurationSeconds: targetDurationSeconds
        )
    }
}
