import Foundation

// MARK: - Service Errors

enum ServiceError: LocalizedError {
    case notConfigured
    case invalidConfiguration(String)
    case networkUnavailable
    case authenticationFailed(String)
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case invalidResponse(String)
    case streamingError(String)
    case timeout
    case cancelled
    case providerError(code: String, message: String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service is not configured"
        case .invalidConfiguration(let detail):
            return "Invalid configuration: \(detail)"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Retry after \(Int(retryAfter)) seconds"
            }
            return "Rate limit exceeded"
        case .invalidResponse(let detail):
            return "Invalid response: \(detail)"
        case .streamingError(let detail):
            return "Streaming error: \(detail)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .providerError(let code, let message):
            return "Provider error [\(code)]: \(message)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Weather Types

struct ServiceWeatherData: Sendable {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Double
    let windSpeed: Double
    let location: String
    let timestamp: Date
}

struct WeatherForecast: Sendable {
    let daily: [DailyForecast]
    let location: String
}

struct DailyForecast: Sendable {
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let condition: WeatherCondition
    let precipitationChance: Double
}

enum WeatherCondition: String, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case thunderstorm
    case fog
}
