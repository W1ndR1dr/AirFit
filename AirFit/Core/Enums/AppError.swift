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
    case serviceUnavailable
    case invalidInput(message: String)
    case llm(String)
    case authentication(String)
    case keychain(String)
    case apiConfiguration(String)
    case configuration(String)

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
        case .serviceUnavailable:
            return "Service is currently unavailable"
        case .invalidInput(let message):
            return message
        case .llm(let message):
            return "AI Error: \(message)"
        case .authentication(let message):
            return "Authentication Error: \(message)"
        case .keychain(let message):
            return "Keychain Error: \(message)"
        case .apiConfiguration(let message):
            return "API Configuration Error: \(message)"
        case .configuration(let message):
            return "Configuration Error: \(message)"
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
        case .serviceUnavailable:
            return "Please try again later"
        case .invalidInput:
            return "Please check your input and try again"
        case .llm:
            return "Please try again or check your AI service configuration"
        case .authentication:
            return "Please check your API key configuration"
        case .keychain:
            return "Please try again. If the problem persists, reinstall the app"
        case .apiConfiguration:
            return "Please verify your API keys and try again"
        case .configuration:
            return "Please check your settings and try again"
        }
    }
}
