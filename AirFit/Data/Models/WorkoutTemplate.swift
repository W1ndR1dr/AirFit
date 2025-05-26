import SwiftData
import Foundation

@Model
final class WorkoutTemplate: @unchecked Sendable {
    // MARK: - Properties
    var id: UUID
    var name: String
    var descriptionText: String?
    var workoutType: String
    var estimatedDuration: TimeInterval?
    var difficulty: String? // "beginner", "intermediate", "advanced"
    var isSystemTemplate: Bool = false
    var isFavorite: Bool = false
    var lastUsedDate: Date?
    var useCount: Int = 0

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.workoutTemplate)
    var exercises: [ExerciseTemplate] = []

    // MARK: - Computed Properties
    var workoutTypeEnum: WorkoutType? {
        WorkoutType(rawValue: workoutType)
    }

    var difficultyLevel: DifficultyLevel? {
        guard let difficulty = difficulty else { return nil }
        return DifficultyLevel(rawValue: difficulty)
    }

    var formattedDuration: String? {
        guard let duration = estimatedDuration else { return nil }
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        name: String,
        workoutType: WorkoutType = .general,
        isSystemTemplate: Bool = false
    ) {
        self.id = id
        self.name = name
        self.workoutType = workoutType.rawValue
        self.isSystemTemplate = isSystemTemplate
    }

    // MARK: - Methods
    func recordUse() {
        lastUsedDate = Date()
        useCount += 1
    }

    func toggleFavorite() {
        isFavorite.toggle()
    }

    func addExercise(_ exercise: ExerciseTemplate) {
        exercises.append(exercise)
        exercise.workoutTemplate = self
    }
}

// MARK: - DifficultyLevel Enum
enum DifficultyLevel: String, Sendable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "SuccessColor"
        case .intermediate: return "WarningColor"
        case .advanced: return "ErrorColor"
        }
    }
}
