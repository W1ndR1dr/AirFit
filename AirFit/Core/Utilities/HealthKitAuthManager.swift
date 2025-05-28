import Foundation
import Observation

@MainActor
@Observable
final class HealthKitAuthManager {
    private let healthKitManager: HealthKitManaging
    var authorizationStatus: HealthKitAuthorizationStatus = .notDetermined

    init(healthKitManager: HealthKitManaging = HealthKitManager.shared) {
        self.healthKitManager = healthKitManager
        refreshStatus()
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            do {
                try await healthKitManager.requestAuthorization()
                refreshStatus()
                return authorizationStatus == .authorized
            } catch {
                refreshStatus()
                return false
            }
        }
    }

    func refreshStatus() {
        healthKitManager.refreshAuthorizationStatus()
        authorizationStatus = Self.map(status: healthKitManager.authorizationStatus)
    }

    private static func map(status: HealthKitManager.AuthorizationStatus) -> HealthKitAuthorizationStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        }
    }
}

enum HealthKitAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}
