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
        case dashboard
        case meals
        case discover
        case progress
        case settings

        public var systemImage: String {
            switch self {
            case .dashboard: return "house.fill"
            case .meals: return "fork.knife"
            case .discover: return "magnifyingglass"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
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
