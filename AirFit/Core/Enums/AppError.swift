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
            return "Camera access is required to scan barcodes"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again"
        case .decodingError:
            return "Please try updating the app"
        case .unauthorized:
            return "Tap here to log in"
        case .healthKitNotAuthorized:
            return "Grant access in Settings > Privacy > Health"
        case .cameraNotAuthorized:
            return "Grant access in Settings > Privacy > Camera"
        default:
            return nil
        }
    }
}
