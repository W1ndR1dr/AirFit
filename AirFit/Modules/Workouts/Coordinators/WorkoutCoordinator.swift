import SwiftUI
import Observation

@MainActor
@Observable
final class WorkoutCoordinator {
    // MARK: - Navigation
    var path = NavigationPath()
    // MARK: - Sheet Presentation
    var presentedSheet: WorkoutSheet?

    // MARK: - Destinations
    enum WorkoutDestination: Hashable {
        case workoutDetail(Workout)
        case exerciseLibrary
        case allWorkouts
        case statistics
    }

    // MARK: - Sheets
    enum WorkoutSheet: Identifiable, Hashable {
        case templatePicker
        case newTemplate
        case exerciseDetail(Exercise)

        var id: String {
            switch self {
            case .templatePicker:
                return "templatePicker"
            case .newTemplate:
                return "newTemplate"
            case .exerciseDetail(let exercise):
                return "exerciseDetail-\(exercise.id)"
            }
        }
    }

    // MARK: - Navigation Control
    func navigateTo(_ destination: WorkoutDestination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func resetNavigation() {
        path = NavigationPath()
    }

    // MARK: - Sheet Control
    func showSheet(_ sheet: WorkoutSheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    // MARK: - Deep Linking
    func handleDeepLink(_ destination: WorkoutDestination) {
        resetNavigation()
        navigateTo(destination)
    }
}
