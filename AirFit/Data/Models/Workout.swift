import SwiftData
import Foundation

@Model
final class Workout: Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var plannedDate: Date?
    var completedDate: Date?
    var durationSeconds: TimeInterval?
    var caloriesBurned: Double?
    var notes: String?
    var workoutType: String
    var intensity: String? // "low", "moderate", "high"
    
    // HealthKit Integration
    var healthKitWorkoutID: String?
    var healthKitSyncedDate: Date?
    
    // Template Reference
    var templateID: UUID?
    
    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise] = []
    
    var user: User?
    
    // MARK: - Computed Properties
    var isCompleted: Bool {
        completedDate != nil
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + ((set.completedWeightKg ?? 0) * Double(set.completedReps ?? 0))
            }
        }
    }
    
    var workoutTypeEnum: WorkoutType? {
        WorkoutType(rawValue: workoutType)
    }
    
    var formattedDuration: String? {
        guard let duration = durationSeconds else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        workoutType: WorkoutType = .general,
        plannedDate: Date? = nil,
        user: User? = nil
    ) {
        self.id = id
        self.name = name
        self.workoutType = workoutType.rawValue
        self.plannedDate = plannedDate
        self.user = user
    }
    
    // MARK: - Methods
    func startWorkout() {
        if completedDate == nil {
            completedDate = Date()
        }
    }
    
    func completeWorkout() {
        completedDate = Date()
        if let startTime = plannedDate {
            durationSeconds = Date().timeIntervalSince(startTime)
        }
    }
    
    func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        exercise.workout = self
    }
    
    func createFromTemplate(_ template: WorkoutTemplate) {
        self.name = template.name
        self.workoutType = template.workoutType
        self.templateID = template.id
        
        // Copy exercises from template
        for templateExercise in template.exercises {
            let exercise = Exercise(
                name: templateExercise.name,
                muscleGroups: templateExercise.muscleGroups
            )
            
            // Copy sets from template
            for templateSet in templateExercise.sets {
                let set = ExerciseSet(
                    setNumber: templateSet.setNumber,
                    targetReps: templateSet.targetReps,
                    targetWeightKg: templateSet.targetWeightKg,
                    targetDurationSeconds: templateSet.targetDurationSeconds
                )
                exercise.addSet(set)
            }
            
            addExercise(exercise)
        }
    }
}

// MARK: - WorkoutType Enum
enum WorkoutType: String, Codable, CaseIterable, Sendable {
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"
    case sports = "sports"
    case general = "general"
    case hiit = "hiit"
    case yoga = "yoga"
    case pilates = "pilates"
    
    var displayName: String {
        switch self {
        case .strength: return "Strength Training"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        case .sports: return "Sports"
        case .general: return "General"
        case .hiit: return "HIIT"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        }
    }
    
    var systemImage: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "figure.run"
        case .flexibility: return "figure.flexibility"
        case .sports: return "sportscourt.fill"
        case .general: return "figure.mixed.cardio"
        case .hiit: return "flame.fill"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        }
    }
}
