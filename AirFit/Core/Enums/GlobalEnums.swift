import Foundation

// MARK: - User Related
enum BiologicalSex: String, Codable, CaseIterable, Sendable {
    case male = "male"
    case female = "female"
    case other = "other"

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary = "sedentary"
    case lightlyActive = "lightly_active"
    case moderate = "moderate"
    case veryActive = "very_active"
    case extreme = "extreme"

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderate: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extreme: return "Extremely Active"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderate: return 1.55
        case .veryActive: return 1.725
        case .extreme: return 1.9
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable, Sendable {
    case loseWeight = "lose_weight"
    case maintainWeight = "maintain_weight"
    case gainMuscle = "gain_muscle"

    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .maintainWeight: return "Maintain Weight"
        case .gainMuscle: return "Build Muscle"
        }
    }

    var calorieAdjustment: Double {
        switch self {
        case .loseWeight: return -500
        case .maintainWeight: return 0
        case .gainMuscle: return 300
        }
    }
}

// MARK: - App State
enum LoadingState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case error(Error)

    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Navigation
enum AppTab: String, CaseIterable, Sendable {
    case dashboard
    case meals
    case discover
    case progress
    case settings

    var systemImage: String {
        switch self {
        case .dashboard: return "house.fill"
        case .meals: return "fork.knife"
        case .discover: return "magnifyingglass"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
}
