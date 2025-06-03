import Foundation
@testable import AirFit

// MARK: - MockWeatherService
@MainActor
final class MockWeatherService: WeatherServiceProtocol, MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    // ServiceProtocol conformance
    var isConfigured: Bool = true
    let serviceIdentifier: String = "MockWeatherService"
    
    // Stubbed responses
    var stubbedCurrentWeatherResult: ServiceWeatherData = ServiceWeatherData(
        temperature: 72.0,
        feelsLike: 75.0,
        condition: "Sunny",
        humidity: 65,
        windSpeed: 5.0,
        uvIndex: 5,
        airQualityIndex: 50,
        timestamp: Date()
    )
    var stubbedCurrentWeatherError: Error?
    
    var stubbedForecastResult: WeatherForecast = WeatherForecast(
        days: [
            WeatherDay(
                date: Date(),
                high: 75.0,
                low: 60.0,
                condition: "Partly Cloudy",
                precipitationChance: 20
            )
        ],
        location: "Test Location"
    )
    var stubbedForecastError: Error?
    
    var stubbedCachedWeatherResult: ServiceWeatherData?
    var stubbedConfigureError: Error?
    var stubbedHealthCheckResult: ServiceHealth = ServiceHealth(
        status: .healthy,
        lastCheckTime: Date(),
        responseTime: 0.5,
        errorMessage: nil,
        metadata: [:]
    )
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
        recordInvocation("getCurrentWeather", arguments: latitude, longitude)
        
        if let error = stubbedCurrentWeatherError {
            throw error
        }
        
        return stubbedCurrentWeatherResult
    }
    
    func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
        recordInvocation("getForecast", arguments: latitude, longitude, days)
        
        if let error = stubbedForecastError {
            throw error
        }
        
        return stubbedForecastResult
    }
    
    func getCachedWeather(latitude: Double, longitude: Double) -> ServiceWeatherData? {
        recordInvocation("getCachedWeather", arguments: latitude, longitude)
        return stubbedCachedWeatherResult
    }
    
    // ServiceProtocol methods
    func configure() async throws {
        recordInvocation("configure", arguments: nil)
        
        if let error = stubbedConfigureError {
            throw error
        }
    }
    
    func reset() async {
        recordInvocation("reset", arguments: nil)
        isConfigured = false
    }
    
    func healthCheck() async -> ServiceHealth {
        recordInvocation("healthCheck", arguments: nil)
        return stubbedHealthCheckResult
    }
    
    // Helper methods for testing
    func stubCurrentWeather(with weather: ServiceWeatherData) {
        stubbedCurrentWeatherResult = weather
    }
    
    func stubCurrentWeatherError(with error: Error) {
        stubbedCurrentWeatherError = error
    }
    
    func stubForecast(with forecast: WeatherForecast) {
        stubbedForecastResult = forecast
    }
    
    func stubForecastError(with error: Error) {
        stubbedForecastError = error
    }
    
    func stubCachedWeather(with weather: ServiceWeatherData?) {
        stubbedCachedWeatherResult = weather
    }
    
    func stubHealthCheck(with health: ServiceHealth) {
        stubbedHealthCheckResult = health
    }
}