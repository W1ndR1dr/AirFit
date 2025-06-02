import Foundation

// MARK: - Weather Service Protocol
@MainActor
protocol WeatherServiceProtocol: ServiceProtocol {
    func getCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> WeatherData
    
    func getForecast(
        latitude: Double,
        longitude: Double,
        days: Int
    ) async throws -> WeatherForecast
    
    func getCachedWeather(
        latitude: Double,
        longitude: Double
    ) -> WeatherData?
}

// MARK: - Weather Data Types
struct WeatherData: Sendable, Codable {
    let temperature: Double
    let condition: String
    let humidity: Int
    let windSpeed: Double
    let uvIndex: Int?
    let timestamp: Date
}

struct WeatherForecast: Sendable, Codable {
    let days: [WeatherDay]
    let location: String
    let timestamp: Date
}

struct WeatherDay: Sendable, Codable {
    let date: Date
    let high: Double
    let low: Double
    let condition: String
    let precipitationChance: Int
}