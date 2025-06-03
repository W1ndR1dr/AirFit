import SwiftUI
import Observation

@MainActor
@Observable
final class SettingsCoordinator {
    // MARK: - Navigation State
    var navigationPath = NavigationPath()
    var activeSheet: SettingsSheet?
    var activeAlert: SettingsAlert?
    
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
        
        var id: String {
            switch self {
            case .confirmDelete: return "delete"
            case .exportSuccess: return "export"
            case .apiKeyInvalid: return "apikey"
            case .error: return "error"
            }
        }
    }
    
    // MARK: - Navigation Methods
    func navigateTo(_ destination: SettingsDestination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
    
    func showSheet(_ sheet: SettingsSheet) {
        activeSheet = sheet
    }
    
    func showAlert(_ alert: SettingsAlert) {
        activeAlert = alert
    }
    
    func dismiss() {
        activeSheet = nil
        activeAlert = nil
    }
}
