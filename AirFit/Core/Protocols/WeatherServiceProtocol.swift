import Foundation

// MARK: - Weather Service Protocol
@MainActor
protocol WeatherServiceProtocol: ServiceProtocol {
    func getCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> ServiceWeatherData
    
    func getForecast(
        latitude: Double,
        longitude: Double,
        days: Int
    ) async throws -> WeatherForecast
    
    func getCachedWeather(
        latitude: Double,
        longitude: Double
    ) -> ServiceWeatherData?
}

// MARK: - Weather Data Types
// ServiceWeatherData is defined in ServiceTypes.swift
// WeatherForecast is defined in ServiceTypes.swift

struct WeatherDay: Sendable, Codable {
    let date: Date
    let high: Double
    let low: Double
    let condition: String
    let precipitationChance: Int
}