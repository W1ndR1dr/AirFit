import Foundation
import LocalAuthentication

/// Manages biometric authentication for the app
@MainActor
final class BiometricAuthManager: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "biometric-auth-manager"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        get { false } // Return false as default for nonisolated access
    }
    
    private var context = LAContext()
    
    /// Check if biometric authentication is available
    var canUseBiometrics: Bool {
        checkBiometrics()
    }
    
    private func checkBiometrics() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// The type of biometric authentication available
    var biometricType: BiometricType {
        getBiometricType()
    }
    
    private func getBiometricType() -> BiometricType {
        guard checkBiometrics() else { return .none }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    /// Authenticate using biometrics
    func authenticate(reason: String) async throws -> Bool {
        guard checkBiometrics() else {
            throw BiometricError.notAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if let error = error as? LAError {
                    continuation.resume(throwing: BiometricError.fromLAError(error))
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    /// Reset the authentication context
    func resetContext() {
        context.invalidate()
        context = LAContext()
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        resetContext()
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: checkBiometrics() ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: checkBiometrics() ? nil : "Biometrics not available",
            metadata: [
                "biometricType": getBiometricType().displayName,
                "canUseBiometrics": "\(checkBiometrics())"
            ]
        )
    }
}

// MARK: - Supporting Types
enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none
    
    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Not Available"
        }
    }
    
    var icon: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock"
        }
    }
}

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed
    case userCancelled
    case userFallback
    case systemCancel
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockout
    case other(String)
    
    static func fromLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        default:
            return .other(error.localizedDescription)
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled"
        case .userFallback:
            return "User chose to use passcode"
        case .systemCancel:
            return "Authentication was cancelled by the system"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .biometryNotAvailable:
            return "Biometric authentication is not available"
        case .biometryNotEnrolled:
            return "No biometric data is enrolled"
        case .biometryLockout:
            return "Biometry is locked out due to too many failed attempts"
        case .other(let message):
            return message
        }
    }
}
