import SwiftUI
import Observation

/// Manages navigation state for the Dashboard module
///
/// ## Refactored to use BaseCoordinator
/// Inherits all navigation, sheet, and alert functionality from BaseCoordinator.
/// Just specify the types and add any custom methods needed.
@MainActor
@Observable
final class DashboardCoordinator: BaseCoordinator<DashboardCoordinator.Destination, DashboardCoordinator.DashboardSheet, DashboardCoordinator.AlertItem> {

    // MARK: - Navigation Destinations
    enum Destination: Hashable {
        case nutritionDetail
        case workoutHistory
        case recoveryDetail
        case settings
    }

    // MARK: - Sheet Types
    enum DashboardSheet: Identifiable {
        case energyLogging
        case quickFoodEntry
        case quickWorkoutStart

        var id: String {
            switch self {
            case .energyLogging: return "energy"
            case .quickFoodEntry: return "food"
            case .quickWorkoutStart: return "workout"
            }
        }
    }

    // MARK: - Alert Item
    struct AlertItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let dismissButton: String
    }

    // MARK: - Custom Methods

    /// Helper to create alerts with default button
    func showAlert(title: String, message: String, dismissButton: String = "OK") {
        showAlert(AlertItem(
            title: title,
            message: message,
            dismissButton: dismissButton
        ))
    }

    // MARK: - Compatibility (for existing code)

    func navigate(to destination: Destination) {
        navigateTo(destination)
    }

    func navigateBack() {
        pop()
    }

    func navigateToRoot() {
        popToRoot()
    }

    var selectedSheet: DashboardSheet? {
        get { activeSheet }
        set { activeSheet = newValue }
    }

    var alertItem: AlertItem? {
        get { activeAlert }
        set { activeAlert = newValue }
    }
}
