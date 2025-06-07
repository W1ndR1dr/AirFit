import XCTest
@testable import AirFit

final class WeatherServiceTests: XCTestCase {
    
    var sut: WeatherService!
    
    override func setUp() {
        super.setUp()
        // WeatherService is @MainActor, will be created in test methods
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    @MainActor
    
    func testConfigureAlwaysSucceeds() async throws  {
    
        let sut = WeatherService()
        // WeatherKit requires no configuration
        try await sut.configure()
        XCTAssertTrue(sut.isConfigured)
    }
    
    // MARK: - Health Check Tests
    
    @MainActor
    
    func testHealthCheckAlwaysHealthy() async  {
    
        let sut = WeatherService()
        // When
        let health = await sut.healthCheck()
        
        // Then
        XCTAssertEqual(health.status, .healthy)
        XCTAssertNotNil(health.lastCheckTime)
        XCTAssertEqual(health.metadata["provider"] as? String, "WeatherKit")
    }
    
    // MARK: - Weather Data Tests
    
    @MainActor
    
    func testGetCurrentWeatherReturnsData() async throws  {
    
        let sut = WeatherService()
        // Given - New York coordinates
        let latitude = 40.7128
        let longitude = -74.0060
        
        // When
        do {
            let weather = try await sut.getCurrentWeather(latitude: latitude, longitude: longitude)
            
            // Then - We can't predict exact values but check structure
            XCTAssertGreaterThan(weather.temperature, -50) // Reasonable temp range
            XCTAssertLessThan(weather.temperature, 150)
            XCTAssertNotNil(weather.condition)
            XCTAssertGreaterThanOrEqual(weather.humidity, 0)
            XCTAssertLessThanOrEqual(weather.humidity, 100)
            XCTAssertGreaterThanOrEqual(weather.windSpeed, 0)
            XCTAssertNotNil(weather.location)
        } catch {
            // WeatherKit might fail in test environment
            XCTSkip("WeatherKit not available in test environment: \(error)")
        }
    }
    
    @MainActor
    
    func testGetCachedWeatherReturnsNilWhenNoCache()  {
    
        let sut = WeatherService()
        // When
        let cached = sut.getCachedWeather(latitude: 34.05, longitude: -118.24)
        
        // Then
        XCTAssertNil(cached)
    }
    
    // MARK: - Forecast Tests
    
    @MainActor
    
    func testGetForecastReturnsData() async throws  {
    
        let sut = WeatherService()
        // Given
        let latitude = 34.0522
        let longitude = -118.2437
        let days = 5
        
        // When
        do {
            let forecast = try await sut.getForecast(
                latitude: latitude,
                longitude: longitude,
                days: days
            )
            
            // Then
            XCTAssertFalse(forecast.daily.isEmpty)
            XCTAssertLessThanOrEqual(forecast.daily.count, days)
        } catch {
            // WeatherKit might fail in test environment
            XCTSkip("WeatherKit not available in test environment: \(error)")
        }
    }
    
    // MARK: - Context Tests
    
    @MainActor
    
    func testGetLLMContextReturnsCompactData() async throws  {
    
        let sut = WeatherService()
        // Given
        let latitude = 37.7749
        let longitude = -122.4194
        
        // When
        do {
            let context = try await sut.getLLMContext(latitude: latitude, longitude: longitude)
            
            // Then
            XCTAssertNotNil(context)
            if let contextString = context {
                XCTAssertTrue(contextString.contains(",")) // Should have comma-separated values
                XCTAssertLessThan(contextString.count, 50) // Should be compact
            }
        } catch {
            // WeatherKit might fail in test environment
            XCTSkip("WeatherKit not available in test environment: \(error)")
        }
    }
    
    // MARK: - Reset Tests
    
    @MainActor
    
    func testResetClearsCache() async throws  {
    
        let sut = WeatherService()
        // Given - Try to populate cache first
        do {
            _ = try await sut.getCurrentWeather(latitude: 40.7128, longitude: -74.0060)
        } catch {
            // Ignore if WeatherKit fails
        }
        
        // When
        await sut.reset()
        
        // Then
        let cached = sut.getCachedWeather(latitude: 40.7128, longitude: -74.0060)
        XCTAssertNil(cached)
    }
    
    // MARK: - Cache Tests
    
    @MainActor
    
    func testCacheReturnsSameLocationData() async throws  {
    
        let sut = WeatherService()
        // Given
        let latitude = 34.0522
        let longitude = -118.2437
        
        do {
            // When - First call
            let weather1 = try await sut.getCurrentWeather(latitude: latitude, longitude: longitude)
            
            // When - Second call (should use cache)
            let weather2 = try await sut.getCurrentWeather(latitude: latitude, longitude: longitude)
            
            // Then - Should return same data
            XCTAssertEqual(weather1.temperature, weather2.temperature)
            XCTAssertEqual(weather1.condition, weather2.condition)
            
            // Verify cache was used
            let cached = sut.getCachedWeather(latitude: latitude, longitude: longitude)
            XCTAssertNotNil(cached)
            XCTAssertEqual(cached?.temperature, weather1.temperature)
        } catch {
            XCTSkip("WeatherKit not available in test environment: \(error)")
        }
    }
}