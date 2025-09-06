import Foundation
import SwiftUI

/// Container for all global enums used throughout the app
public enum GlobalEnums {
    // MARK: - User Related
    public enum BiologicalSex: String, Codable, CaseIterable, Sendable {
        case male
        case female

        public var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            }
        }
    }

    public enum ActivityLevel: String, Codable, CaseIterable, Sendable {
        case sedentary
        case lightlyActive = "lightly_active"
        case moderate
        case veryActive = "very_active"
        case extreme

        public var displayName: String {
            switch self {
            case .sedentary: return "Sedentary"
            case .lightlyActive: return "Lightly Active"
            case .moderate: return "Moderately Active"
            case .veryActive: return "Very Active"
            case .extreme: return "Extremely Active"
            }
        }

        public var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderate: return 1.55
            case .veryActive: return 1.725
            case .extreme: return 1.9
            }
        }
    }

    public enum FitnessGoal: String, Codable, CaseIterable, Sendable {
        case loseWeight = "lose_weight"
        case maintainWeight = "maintain_weight"
        case gainMuscle = "gain_muscle"

        public var displayName: String {
            switch self {
            case .loseWeight: return "Lose Weight"
            case .maintainWeight: return "Maintain Weight"
            case .gainMuscle: return "Build Muscle"
            }
        }

        public var calorieAdjustment: Double {
            switch self {
            case .loseWeight: return -500
            case .maintainWeight: return 0
            case .gainMuscle: return 300
            }
        }
    }

    // MARK: - App State
    public enum LoadingState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case error(Error)

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
                return true
            case let (.error(lhsError), .error(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }

    // MARK: - Navigation
    public enum AppTab: String, CaseIterable, Sendable {
        case chat
        case today
        case nutrition
        case workouts
        case body

        public var systemImage: String {
            switch self {
            case .chat: return "message.fill"
            case .today: return "sun.max.fill"
            case .nutrition: return "leaf.fill"
            case .workouts: return "figure.run"
            case .body: return "figure"
            }
        }

        public var displayName: String {
            switch self {
            case .chat: return "Chat"
            case .today: return "Today"
            case .nutrition: return "Nutrition"
            case .workouts: return "Workouts"
            case .body: return "Body"
            }
        }
    }

    // MARK: - Exercise Related
    public enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
        case strength
        case cardio
        case flexibility
        case plyometrics
        case balance
        case sports

        public var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .cardio: return "Cardio"
            case .flexibility: return "Flexibility"
            case .plyometrics: return "Plyometrics"
            case .balance: return "Balance"
            case .sports: return "Sports"
            }
        }
    }

    public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
        case chest
        case shoulders
        case biceps
        case triceps
        case forearms
        case abs
        case lats
        case middleBack
        case lowerBack
        case traps
        case quads
        case hamstrings
        case glutes
        case calves
        case adductors
        case abductors

        public var displayName: String {
            switch self {
            case .chest: return "Chest"
            case .shoulders: return "Shoulders"
            case .biceps: return "Biceps"
            case .triceps: return "Triceps"
            case .forearms: return "Forearms"
            case .abs: return "Abs"
            case .lats: return "Lats"
            case .middleBack: return "Middle Back"
            case .lowerBack: return "Lower Back"
            case .traps: return "Traps"
            case .quads: return "Quadriceps"
            case .hamstrings: return "Hamstrings"
            case .glutes: return "Glutes"
            case .calves: return "Calves"
            case .adductors: return "Adductors"
            case .abductors: return "Abductors"
            }
        }
    }

    public enum Equipment: String, Codable, CaseIterable, Sendable {
        case bodyweight
        case dumbbells
        case barbell
        case kettlebells
        case cables
        case machine
        case resistanceBands
        case foamRoller
        case medicineBall
        case stabilityBall
        case other

        public var displayName: String {
            switch self {
            case .bodyweight: return "Bodyweight"
            case .dumbbells: return "Dumbbells"
            case .barbell: return "Barbell"
            case .kettlebells: return "Kettlebells"
            case .cables: return "Cables"
            case .machine: return "Machine"
            case .resistanceBands: return "Resistance Bands"
            case .foamRoller: return "Foam Roller"
            case .medicineBall: return "Medicine Ball"
            case .stabilityBall: return "Stability Ball"
            case .other: return "Other"
            }
        }
    }

    public enum Difficulty: String, Codable, CaseIterable, Sendable {
        case beginner
        case intermediate
        case advanced

        public var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            }
        }
    }
}

// MARK: - Type Aliases for Convenience
public typealias BiologicalSex = GlobalEnums.BiologicalSex
public typealias ActivityLevel = GlobalEnums.ActivityLevel
public typealias FitnessGoal = GlobalEnums.FitnessGoal
public typealias LoadingState = GlobalEnums.LoadingState
public typealias AppTab = GlobalEnums.AppTab
public typealias ExerciseCategory = GlobalEnums.ExerciseCategory
public typealias MuscleGroup = GlobalEnums.MuscleGroup
public typealias Equipment = GlobalEnums.Equipment
public typealias Difficulty = GlobalEnums.Difficulty
