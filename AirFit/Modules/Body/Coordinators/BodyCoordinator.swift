import Observation

/// Manages navigation for the Body module
@MainActor
@Observable
final class BodyCoordinator: SheetCoordinator<BodyCoordinator.BodyDestination, BodyCoordinator.BodySheet> {

    // MARK: - Destinations
    enum BodyDestination: Hashable {
        case weightHistory
        case bodyFatHistory
        case bmiHistory
        case leanMassHistory
    }

    // MARK: - Sheets
    enum BodySheet: Identifiable, Hashable {
        case addMeasurement
        case capturePhoto
        case settings

        var id: String {
            switch self {
            case .addMeasurement:
                return "addMeasurement"
            case .capturePhoto:
                return "capturePhoto"
            case .settings:
                return "settings"
            }
        }
    }

    // MARK: - Sheet State
    
    var showingMeasurementEntry = false
    var showingPhotoCapture = false
    
    // MARK: - Navigation Methods
    
    func presentMeasurementEntry() {
        showingMeasurementEntry = true
    }
    
    func presentPhotoCapture() {
        showingPhotoCapture = true
    }
    
    func updateActiveTab(_ tab: TabType) {
        // This would update the active tab if needed
        // For now, just a placeholder
    }
    
    // MARK: - Compatibility Methods (for existing code)

    func resetNavigation() {
        popToRoot()
    }

    func dismissSheet() {
        activeSheet = nil
    }

    var presentedSheet: BodySheet? {
        get { activeSheet }
        set { activeSheet = newValue }
    }
    
    // MARK: - Types
    
    enum TabType {
        case body
        case nutrition
        case workout
        case dashboard
    }
}
