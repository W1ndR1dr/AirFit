import Foundation

public enum AppError: LocalizedError, Sendable {
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case validationError(message: String)
    case unauthorized
    case serverError(code: Int, message: String?)
    case unknown(message: String)
    case healthKitNotAuthorized
    case cameraNotAuthorized
    case userNotFound
    case unsupportedProvider

    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Unable to process server response"
        case .validationError(let message):
            return message
        case .unauthorized:
            return "Please log in to continue"
        case let .serverError(code, message):
            return message ?? "Server error (Code: \(code))"
        case .unknown(let message):
            return message
        case .healthKitNotAuthorized:
            return "Health access is required for this feature"
        case .cameraNotAuthorized:
            return "Camera access is required to take meal photos"
        case .userNotFound:
            return "User profile not found"
        case .unsupportedProvider:
            return "This AI provider is not supported"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again"
        case .decodingError:
            return "Please try updating the app"
        case .validationError:
            return nil
        case .unauthorized:
            return "Tap here to log in"
        case .serverError:
            return "Please try again later"
        case .unknown:
            return nil
        case .healthKitNotAuthorized:
            return "Grant access in Settings > Privacy > Health"
        case .cameraNotAuthorized:
            return "Grant access in Settings > Privacy > Camera"
        case .userNotFound:
            return "Please complete the setup process"
        case .unsupportedProvider:
            return "Please check your AI provider configuration"
        }
    }
}
