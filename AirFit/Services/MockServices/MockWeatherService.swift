import Foundation

/// Mock implementation of WeatherServiceProtocol for testing
@MainActor
final class MockWeatherService: WeatherServiceProtocol {
    
    // MARK: - Properties
    let serviceIdentifier = "mock-weather-service"
    private(set) var isConfigured: Bool = false
    
    // Test control properties
    var shouldFail = false
    var failureError: Error = ServiceError.notConfigured
    var responseDelay: TimeInterval = 0
    var mockWeatherData: WeatherData?
    var mockForecast: WeatherForecast?
    var requestHistory: [(latitude: Double, longitude: Double, type: RequestType)] = []
    
    enum RequestType {
        case current
        case forecast(days: Int)
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        if shouldFail {
            throw failureError
        }
        isConfigured = true
    }
    
    func reset() async {
        isConfigured = false
        mockWeatherData = nil
        mockForecast = nil
        requestHistory.removeAll()
    }
    
    func healthCheck() async -> ServiceHealth {
        if !isConfigured {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: "Not configured",
                metadata: [:]
            )
        }
        
        if shouldFail {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: failureError.localizedDescription,
                metadata: [:]
            )
        }
        
        return ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.05,
            errorMessage: nil,
            metadata: ["provider": "mock"]
        )
    }
    
    // MARK: - WeatherServiceProtocol
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        requestHistory.append((latitude, longitude, .current))
        
        // Simulate network delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        // Check for failure
        if shouldFail {
            throw failureError
        }
        
        // Return mock data or generate default
        return mockWeatherData ?? generateDefaultWeatherData(latitude: latitude, longitude: longitude)
    }
    
    func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
        requestHistory.append((latitude, longitude, .forecast(days: days)))
        
        // Simulate network delay
        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }
        
        // Check for failure
        if shouldFail {
            throw failureError
        }
        
        // Return mock data or generate default
        return mockForecast ?? generateDefaultForecast(latitude: latitude, longitude: longitude, days: days)
    }
    
    func getCachedWeather(latitude: Double, longitude: Double) -> WeatherData? {
        // Return mock cached data if available
        if let mockData = mockWeatherData,
           mockData.location == "Cached Location" {
            return mockData
        }
        return nil
    }
    
    // MARK: - Test Helpers
    
    func setMockWeather(_ weather: WeatherData) {
        mockWeatherData = weather
    }
    
    func setMockForecast(_ forecast: WeatherForecast) {
        mockForecast = forecast
    }
    
    func clearHistory() {
        requestHistory.removeAll()
    }
    
    func getLastRequest() -> (latitude: Double, longitude: Double, type: RequestType)? {
        requestHistory.last
    }
    
    // MARK: - Private Methods
    
    private func generateDefaultWeatherData(latitude: Double, longitude: Double) -> WeatherData {
        WeatherData(
            temperature: 72.0,
            condition: .partlyCloudy,
            humidity: 65.0,
            windSpeed: 8.5,
            location: "Mock Location (\(String(format: "%.2f", latitude)), \(String(format: "%.2f", longitude)))",
            timestamp: Date()
        )
    }
    
    private func generateDefaultForecast(latitude: Double, longitude: Double, days: Int) -> WeatherForecast {
        let dailyForecasts = (0..<days).map { dayOffset in
            DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date())!,
                highTemperature: 75.0 + Double(dayOffset),
                lowTemperature: 60.0 + Double(dayOffset),
                condition: dayOffset % 3 == 0 ? .rain : .partlyCloudy,
                precipitationChance: dayOffset % 3 == 0 ? 80.0 : 20.0
            )
        }
        
        return WeatherForecast(
            daily: dailyForecasts,
            location: "Mock Location (\(String(format: "%.2f", latitude)), \(String(format: "%.2f", longitude)))"
        )
    }
}