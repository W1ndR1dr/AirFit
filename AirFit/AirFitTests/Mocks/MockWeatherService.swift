import Foundation
import XCTest
@testable import AirFit

/// Mock implementation of WeatherServiceProtocol for testing
@MainActor
final class MockWeatherService: WeatherServiceProtocol, MockProtocol {
    // MARK: - MockProtocol
    nonisolated(unsafe) var invocations: [String: [Any]] = [:]
    nonisolated(unsafe) var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()

    // MARK: - ServiceProtocol
    var isConfigured: Bool = true
    var serviceIdentifier: String = "MockWeatherService"

    func configure() async throws {
        recordInvocation("configure")
        if shouldThrowError {
            throw errorToThrow
        }
        isConfigured = true
    }

    func reset() async {
        recordInvocation("reset")
        requestCount = 0
        lastRequestTime = nil
        cachedWeatherData.removeAll()
    }

    func healthCheck() async -> ServiceHealth {
        recordInvocation("healthCheck")
        return ServiceHealth(
            status: isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: 0.1,
            errorMessage: nil,
            metadata: ["service": "mock"]
        )
    }

    // MARK: - Additional Properties
    var isAvailable: Bool = true
    private(set) var lastRequestTime: Date?
    private(set) var requestCount: Int = 0

    // MARK: - Error Control
    var shouldThrowError = false
    var errorToThrow: Error = ServiceError.networkUnavailable

    // MARK: - Stubbed Responses
    var stubbedCurrentWeather: ServiceWeatherData?
    var stubbedForecast: WeatherForecast?
    var cachedWeatherData: [String: ServiceWeatherData] = [:]

    // MARK: - Response Delays
    var responseDelay: TimeInterval = 0

    init() {
        // Default stubbed weather
        stubbedCurrentWeather = ServiceWeatherData(
            temperature: 72.0,
            condition: .partlyCloudy,
            humidity: 65.0,
            windSpeed: 10.0,
            location: "Test Location",
            timestamp: Date()
        )

        // Default stubbed forecast
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date())!

        stubbedForecast = WeatherForecast(
            daily: [
                DailyForecast(
                    date: tomorrow,
                    highTemperature: 75.0,
                    lowTemperature: 60.0,
                    condition: .clear,
                    precipitationChance: 0.1
                ),
                DailyForecast(
                    date: dayAfter,
                    highTemperature: 73.0,
                    lowTemperature: 58.0,
                    condition: .rain,
                    precipitationChance: 0.7
                )
            ],
            location: "Test Location"
        )
    }

    // MARK: - WeatherServiceProtocol
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
        recordInvocation("getCurrentWeather", arguments: latitude, longitude)

        lastRequestTime = Date()
        requestCount += 1

        // Simulate network delay if configured
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        // Check for location-specific stubbed result
        let locationKey = "\(latitude),\(longitude)"
        if let weather = stubbedResults[locationKey] as? ServiceWeatherData {
            // Cache the result
            cachedWeatherData[locationKey] = weather
            return weather
        }

        if let weather = stubbedCurrentWeather {
            // Cache the result
            cachedWeatherData[locationKey] = weather
            return weather
        }

        throw ServiceError.notConfigured
    }

    func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
        recordInvocation("getForecast", arguments: latitude, longitude, days)

        lastRequestTime = Date()
        requestCount += 1

        // Simulate network delay if configured
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        // Check for location-specific stubbed result
        let locationKey = "\(latitude),\(longitude)-\(days)"
        if let forecast = stubbedResults[locationKey] as? WeatherForecast {
            return forecast
        }

        if let forecast = stubbedForecast {
            // Filter forecast to requested number of days
            let limitedForecast = WeatherForecast(
                daily: Array(forecast.daily.prefix(days)),
                location: forecast.location
            )
            return limitedForecast
        }

        throw ServiceError.notConfigured
    }

    func getCachedWeather(latitude: Double, longitude: Double) -> ServiceWeatherData? {
        recordInvocation("getCachedWeather", arguments: latitude, longitude)

        let locationKey = "\(latitude),\(longitude)"
        return cachedWeatherData[locationKey]
    }

    // MARK: - Test Helpers
    func stubWeather(_ weather: ServiceWeatherData, for latitude: Double, longitude: Double) {
        let locationKey = "\(latitude),\(longitude)"
        stub(locationKey, with: weather)
    }

    func stubForecast(_ forecast: WeatherForecast, for latitude: Double, longitude: Double, days: Int) {
        let locationKey = "\(latitude),\(longitude)-\(days)"
        stub(locationKey, with: forecast)
    }

    func simulateRateLimitError(retryAfter: TimeInterval? = nil) {
        shouldThrowError = true
        errorToThrow = ServiceError.rateLimitExceeded(retryAfter: retryAfter)
    }

    func simulateAuthenticationError(reason: String = "Invalid API key") {
        shouldThrowError = true
        errorToThrow = ServiceError.authenticationFailed(reason)
    }

    func verifyWeatherRequested(for latitude: Double, longitude: Double) {
        mockLock.lock()
        defer { mockLock.unlock() }

        guard let calls = invocations["getCurrentWeather"] as? [[Any]] else {
            XCTFail("No weather requests were made")
            return
        }

        let matching = calls.contains { args in
            guard args.count >= 2,
                  let lat = args[0] as? Double,
                  let lon = args[1] as? Double else {
                return false
            }
            return abs(lat - latitude) < 0.0001 && abs(lon - longitude) < 0.0001
        }

        XCTAssertTrue(matching, "No weather request found for coordinates: \(latitude), \(longitude)")
    }

    func resetCache() {
        mockLock.lock()
        defer { mockLock.unlock() }
        cachedWeatherData.removeAll()
    }
}
