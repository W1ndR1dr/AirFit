import SwiftData
import Foundation

@Model
final class Exercise: Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var muscleGroupsData: Data?
    var equipmentData: Data?
    var notes: String?
    var orderIndex: Int
    var restSeconds: TimeInterval?
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
    var sets: [ExerciseSet] = []
    
    var workout: Workout?
    
    // MARK: - Computed Properties
    var muscleGroups: [String] {
        get {
            guard let data = muscleGroupsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            muscleGroupsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var equipment: [String] {
        get {
            guard let data = equipmentData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            equipmentData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted }
    }
    
    var bestSet: ExerciseSet? {
        sets.max { set1, set2 in
            let volume1 = (set1.completedWeightKg ?? 0) * Double(set1.completedReps ?? 0)
            let volume2 = (set2.completedWeightKg ?? 0) * Double(set2.completedReps ?? 0)
            return volume1 < volume2
        }
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        muscleGroups: [String] = [],
        equipment: [String] = [],
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
        self.muscleGroups = muscleGroups
        self.equipment = equipment
    }
    
    // MARK: - Methods
    func addSet(_ set: ExerciseSet) {
        sets.append(set)
        set.exercise = self
    }
    
    func duplicateLastSet() {
        guard let lastSet = sets.last else { return }
        
        let newSet = ExerciseSet(
            setNumber: lastSet.setNumber + 1,
            targetReps: lastSet.targetReps,
            targetWeightKg: lastSet.targetWeightKg,
            targetDurationSeconds: lastSet.targetDurationSeconds
        )
        addSet(newSet)
    }
}
