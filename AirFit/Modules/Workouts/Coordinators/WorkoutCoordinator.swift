import Observation

/// Manages navigation for the Workouts module
/// Uses SheetCoordinator since we only need navigation and sheets (no alerts)
@MainActor
@Observable
final class WorkoutCoordinator: SheetCoordinator<WorkoutCoordinator.WorkoutDestination, WorkoutCoordinator.WorkoutSheet> {

    // MARK: - Destinations
    enum WorkoutDestination: Hashable {
        case workoutDetail(Workout)
        case exerciseLibrary
        case allWorkouts
        case statistics
    }

    // MARK: - Sheets
    enum WorkoutSheet: Identifiable, Hashable {
        case newTemplate
        case exerciseDetail(Exercise)
        case voiceWorkoutInput  // New: for quick voice-based workout creation

        var id: String {
            switch self {
            case .newTemplate:
                return "newTemplate"
            case .exerciseDetail(let exercise):
                return "exerciseDetail-\(exercise.id)"
            case .voiceWorkoutInput:
                return "voiceWorkoutInput"
            }
        }
    }

    // MARK: - Compatibility Methods (for existing code)

    func resetNavigation() {
        popToRoot()
    }

    func dismissSheet() {
        activeSheet = nil
    }

    var presentedSheet: WorkoutSheet? {
        get { activeSheet }
        set { activeSheet = newValue }
    }

    // Note: navigateTo, pop, showSheet, and handleDeepLink are inherited from BaseCoordinator
}
