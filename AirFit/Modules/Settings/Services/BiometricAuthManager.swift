import Foundation
import LocalAuthentication

/// Manages biometric authentication for the app
final class BiometricAuthManager {
    private let context = LAContext()
    
    /// Check if biometric authentication is available
    var canUseBiometrics: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// The type of biometric authentication available
    var biometricType: BiometricType {
        guard canUseBiometrics else { return .none }
        
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
        guard canUseBiometrics else {
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            throw BiometricError.fromLAError(error)
        }
    }
    
    /// Reset the authentication context
    func reset() {
        context.invalidate()
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
