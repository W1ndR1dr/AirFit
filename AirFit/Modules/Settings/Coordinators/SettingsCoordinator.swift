import SwiftUI
import Observation

/// Manages navigation for the Settings module
/// Uses BaseCoordinator for complete navigation, sheet, and alert handling
@MainActor
@Observable
final class SettingsCoordinator: BaseCoordinator<SettingsDestination, SettingsCoordinator.SettingsSheet, SettingsCoordinator.SettingsAlert> {

    // MARK: - Sheet Types
    enum SettingsSheet: Identifiable {
        case personaRefinement
        case apiKeyEntry(provider: AIProvider)
        case dataExport
        case deleteAccount

        var id: String {
            switch self {
            case .personaRefinement: return "persona"
            case .apiKeyEntry(let provider): return "apikey_\(provider.rawValue)"
            case .dataExport: return "export"
            case .deleteAccount: return "delete"
            }
        }
    }

    // MARK: - Alert Types
    enum SettingsAlert: Identifiable {
        case confirmDelete(action: () -> Void)
        case exportSuccess(url: URL)
        case apiKeyInvalid
        case error(message: String)
        case demoModeEnabled
        case demoModeDisabled

        var id: String {
            switch self {
            case .confirmDelete: return "delete"
            case .exportSuccess: return "export"
            case .apiKeyInvalid: return "apikey"
            case .error: return "error"
            case .demoModeEnabled: return "demo_enabled"
            case .demoModeDisabled: return "demo_disabled"
            }
        }
    }

    // MARK: - Compatibility Methods

    func navigateBack() {
        pop()
    }

    func navigateToRoot() {
        popToRoot()
    }
}
