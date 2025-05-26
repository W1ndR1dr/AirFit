import SwiftData
import Foundation

@Model
final class ExerciseTemplate: Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var muscleGroupsData: Data?
    var orderIndex: Int
    var restSeconds: TimeInterval?
    var notes: String?
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \SetTemplate.exerciseTemplate)
    var sets: [SetTemplate] = []
    
    var workoutTemplate: WorkoutTemplate?
    
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
    
    var totalVolume: Double? {
        let volumes = sets.compactMap { set -> Double? in
            guard let weight = set.targetWeightKg,
                  let reps = set.targetReps else { return nil }
            return weight * Double(reps)
        }
        return volumes.isEmpty ? nil : volumes.reduce(0, +)
    }
    
    var formattedRestTime: String? {
        guard let rest = restSeconds else { return nil }
        let minutes = Int(rest) / 60
        let seconds = Int(rest) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.orderIndex = orderIndex
    }
    
    // MARK: - Methods
    func addSet(_ set: SetTemplate) {
        sets.append(set)
        set.exerciseTemplate = self
    }
    
    func removeSet(at index: Int) {
        guard sets.indices.contains(index) else { return }
        sets.remove(at: index)
        
        // Reorder remaining sets
        for (idx, set) in sets.enumerated() {
            set.setNumber = idx + 1
        }
    }
    
    func duplicateLastSet() {
        guard let lastSet = sets.last else { return }
        
        let newSet = SetTemplate(
            setNumber: lastSet.setNumber + 1,
            targetReps: lastSet.targetReps,
            targetWeightKg: lastSet.targetWeightKg,
            targetDurationSeconds: lastSet.targetDurationSeconds
        )
        addSet(newSet)
    }
}
