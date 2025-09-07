import SwiftData
import Foundation
import SwiftUI
import HealthKit

@Model
final class Workout: @unchecked Sendable {
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
    var distance: Double? // Distance in meters

    // HealthKit Integration
    var healthKitWorkoutID: String?
    var healthKitSyncedDate: Date?

    // Template reference removed - AI-native generation

    // AI Analysis
    var aiAnalysis: String?

    // MARK: - Relationships
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise] = []

    var user: User?

    // MARK: - Computed Properties
    var isCompleted: Bool {
        completedDate != nil
    }

    var duration: TimeInterval? {
        durationSeconds
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
        let hours = Int(duration) / 3_600
        let minutes = (Int(duration) % 3_600) / 60

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

    // Template creation method removed - AI generates personalized workouts on-demand
}

// MARK: - WorkoutType Enum
public enum WorkoutType: String, Codable, CaseIterable, Sendable {
    case strength
    case cardio
    case flexibility
    case sports
    case general
    case hiit
    case yoga
    case pilates

    public var displayName: String {
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

    var color: Color {
        switch self {
        case .strength: return .blue
        case .cardio: return .orange
        case .flexibility: return .purple
        case .sports: return .green
        case .general: return .gray
        case .hiit: return .red
        case .yoga: return .indigo
        case .pilates: return .teal
        }
    }

    /// Converts WorkoutType to HKWorkoutActivityType
    func toHealthKitType() -> HKWorkoutActivityType {
        switch self {
        case .strength:
            return .traditionalStrengthTraining
        case .cardio:
            return .running // Default cardio, could be more specific
        case .flexibility:
            return .flexibility
        case .sports:
            return .discSports
        case .general:
            return .other
        case .hiit:
            return .highIntensityIntervalTraining
        case .yoga:
            return .yoga
        case .pilates:
            return .pilates
        }
    }
}
