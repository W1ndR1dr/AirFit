import SwiftUI
import Observation

/// Manages navigation state for the Dashboard module
@MainActor
final class DashboardCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedSheet: DashboardSheet?
    @Published var alertItem: AlertItem?
    
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
    
    // MARK: - Navigation Methods
    func navigate(to destination: Destination) {
        path.append(destination)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateToRoot() {
        path.removeLast(path.count)
    }
    
    // MARK: - Sheet Presentation
    func showSheet(_ sheet: DashboardSheet) {
        selectedSheet = sheet
    }
    
    func dismissSheet() {
        selectedSheet = nil
    }
    
    // MARK: - Alert Presentation
    func showAlert(title: String, message: String, dismissButton: String = "OK") {
        alertItem = AlertItem(
            title: title,
            message: message,
            dismissButton: dismissButton
        )
    }
    
    func dismissAlert() {
        alertItem = nil
    }
}