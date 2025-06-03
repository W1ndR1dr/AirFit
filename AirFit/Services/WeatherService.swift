import Foundation
import CoreLocation

/// Weather service implementation supporting multiple providers
@MainActor
final class WeatherService: WeatherServiceProtocol {
    
    // MARK: - Properties
    let serviceIdentifier = "weather-service"
    private(set) var isConfigured: Bool = false
    
    private let networkManager: NetworkManagementProtocol
    // TODO: Switch to WeatherKit - no API keys needed
    // private let apiKeyManager: APIKeyManagerProtocol
    private let configuration: ServiceConfiguration
    private let cache = WeatherCache()
    
    private var apiKey: String?
    
    // MARK: - Initialization
    init(
        networkManager: NetworkManagementProtocol = NetworkManager.shared,
        configuration: ServiceConfiguration = .shared
    ) {
        self.networkManager = networkManager
        self.configuration = configuration
    }
    
    // MARK: - ServiceProtocol
    
    func configure() async throws {
        // TODO: Implement WeatherKit integration - no API keys needed
        // For now, mark as configured without API key requirements
        isConfigured = true
        AppLogger.info("Weather service configured (TODO: implement WeatherKit)", category: .networking)
    }
    
    func reset() async {
        apiKey = nil
        isConfigured = false
        await cache.clear()
    }
    
    func healthCheck() async -> ServiceHealth {
        guard isConfigured else {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: "Service not configured",
                metadata: [:]
            )
        }
        
        let startTime = Date()
        
        do {
            // Test with a known location (New York)
            _ = try await getCurrentWeather(latitude: 40.7128, longitude: -74.0060)
            
            let responseTime = Date().timeIntervalSince(startTime)
            
            return ServiceHealth(
                status: .healthy,
                lastCheckTime: Date(),
                responseTime: responseTime,
                errorMessage: nil,
                metadata: [
                    "provider": configuration.weather.apiProvider.rawValue,
                    "cacheEnabled": String(configuration.weather.cacheEnabled)
                ]
            )
        } catch {
            return ServiceHealth(
                status: .unhealthy,
                lastCheckTime: Date(),
                responseTime: nil,
                errorMessage: error.localizedDescription,
                metadata: ["provider": configuration.weather.apiProvider.rawValue]
            )
        }
    }
    
    // MARK: - WeatherServiceProtocol
    
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
        guard isConfigured else {
            throw ServiceError.notConfigured
        }
        
        // Check cache first
        if configuration.weather.cacheEnabled,
           let cached = getCachedWeather(latitude: latitude, longitude: longitude) {
            return cached
        }
        
        // Fetch from API
        let weather = try await fetchCurrentWeather(latitude: latitude, longitude: longitude)
        
        // Cache the result
        if configuration.weather.cacheEnabled {
            await cache.store(weather, latitude: latitude, longitude: longitude)
        }
        
        return weather
    }
    
    func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
        guard isConfigured else {
            throw ServiceError.notConfigured
        }
        
        // Check cache first
        if configuration.weather.cacheEnabled,
           let cached = await cache.getForecast(latitude: latitude, longitude: longitude, days: days) {
            return cached
        }
        
        // Fetch from API
        let forecast = try await fetchForecast(latitude: latitude, longitude: longitude, days: days)
        
        // Cache the result
        if configuration.weather.cacheEnabled {
            await cache.store(forecast, latitude: latitude, longitude: longitude, days: days)
        }
        
        return forecast
    }
    
    func getCachedWeather(latitude: Double, longitude: Double) -> ServiceWeatherData? {
        guard configuration.weather.cacheEnabled else { return nil }
        return cache.getCurrent(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Private Methods
    
    private func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
        // TODO: Replace with WeatherKit implementation
        // For now, return mock weather data
        return ServiceWeatherData(
            temperature: 72.0, // Default pleasant temperature
            condition: .partlyCloudy,
            humidity: 45.0,
            windSpeed: 8.0,
            location: "Current Location",
            timestamp: Date()
        )
    }
    
    private func fetchForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
        // TODO: Replace with WeatherKit implementation
        // For now, return mock forecast data
        let dailyForecasts = (0..<days).map { dayOffset in
            DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date(),
                highTemperature: 75.0 + Double(dayOffset * 2),
                lowTemperature: 55.0 + Double(dayOffset),
                condition: dayOffset % 2 == 0 ? .sunny : .partlyCloudy,
                precipitationChance: Double(dayOffset * 10)
            )
        }
        
        return WeatherForecast(
            daily: dailyForecasts,
            location: "Current Location"
        )
    }
    
    // MARK: - External API Implementation (TODO: Remove when WeatherKit is implemented)
    
    /*
    private func fetchOpenWeatherCurrent(latitude: Double, longitude: Double, apiKey: String) async throws -> ServiceWeatherData {
        let units = configuration.weather.defaultUnits == .metric ? "metric" : "imperial"
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=\(units)")!
        
        let request = networkManager.buildRequest(url: url, method: "GET", headers: [:])
        let response: OpenWeatherResponse = try await networkManager.performRequest(request, expecting: OpenWeatherResponse.self)
        
        return ServiceWeatherData(
            temperature: response.main.temp,
            condition: mapOpenWeatherCondition(response.weather.first?.main ?? ""),
            humidity: Double(response.main.humidity),
            windSpeed: response.wind.speed,
            location: response.name,
            timestamp: Date()
        )
    }
    
    private func fetchOpenWeatherForecast(latitude: Double, longitude: Double, days: Int, apiKey: String) async throws -> WeatherForecast {
        let units = configuration.weather.defaultUnits == .metric ? "metric" : "imperial"
        let url = URL(string: "https://api.openweathermap.org/data/2.5/forecast/daily?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=\(units)&cnt=\(days)")!
        
        let request = networkManager.buildRequest(url: url, method: "GET", headers: [:])
        let response: OpenWeatherForecastResponse = try await networkManager.performRequest(request, expecting: OpenWeatherForecastResponse.self)
        
        let dailyForecasts = response.list.map { day in
            DailyForecast(
                date: Date(timeIntervalSince1970: TimeInterval(day.dt)),
                highTemperature: day.temp.max,
                lowTemperature: day.temp.min,
                condition: mapOpenWeatherCondition(day.weather.first?.main ?? ""),
                precipitationChance: Double(day.pop ?? 0) * 100
            )
        }
        
        return WeatherForecast(
            daily: dailyForecasts,
            location: response.city.name
        )
    }
    
    // MARK: - WeatherAPI Implementation
    
    private func fetchWeatherAPICurrent(latitude: Double, longitude: Double, apiKey: String) async throws -> ServiceWeatherData {
        let url = URL(string: "https://api.weatherapi.com/v1/current.json?key=\(apiKey)&q=\(latitude),\(longitude)")!
        
        let request = networkManager.buildRequest(url: url, method: "GET", headers: [:])
        let response: WeatherAPICurrentResponse = try await networkManager.performRequest(request, expecting: WeatherAPICurrentResponse.self)
        
        let temp = configuration.weather.defaultUnits == .metric ? response.current.temp_c : response.current.temp_f
        let wind = configuration.weather.defaultUnits == .metric ? response.current.wind_kph : response.current.wind_mph
        
        return ServiceWeatherData(
            temperature: temp,
            condition: mapWeatherAPICondition(response.current.condition.code),
            humidity: Double(response.current.humidity),
            windSpeed: wind,
            location: response.location.name,
            timestamp: Date()
        )
    }
    
    private func fetchWeatherAPIForecast(latitude: Double, longitude: Double, days: Int, apiKey: String) async throws -> WeatherForecast {
        let url = URL(string: "https://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(latitude),\(longitude)&days=\(days)")!
        
        let request = networkManager.buildRequest(url: url, method: "GET", headers: [:])
        let response: WeatherAPIForecastResponse = try await networkManager.performRequest(request, expecting: WeatherAPIForecastResponse.self)
        
        let dailyForecasts = response.forecast.forecastday.map { day in
            let maxTemp = configuration.weather.defaultUnits == .metric ? day.day.maxtemp_c : day.day.maxtemp_f
            let minTemp = configuration.weather.defaultUnits == .metric ? day.day.mintemp_c : day.day.mintemp_f
            
            return DailyForecast(
                date: ISO8601DateFormatter().date(from: day.date) ?? Date(),
                highTemperature: maxTemp,
                lowTemperature: minTemp,
                condition: mapWeatherAPICondition(day.day.condition.code),
                precipitationChance: Double(day.day.daily_chance_of_rain)
            )
        }
        
        return WeatherForecast(
            daily: dailyForecasts,
            location: response.location.name
        )
    }
    
    // MARK: - Condition Mapping
    
    private func mapOpenWeatherCondition(_ condition: String) -> WeatherCondition {
        switch condition.lowercased() {
        case "clear":
            return .clear
        case "clouds":
            return .cloudy
        case "rain", "drizzle":
            return .rain
        case "snow":
            return .snow
        case "thunderstorm":
            return .thunderstorm
        case "mist", "fog":
            return .fog
        default:
            return .partlyCloudy
        }
    }
    
    private func mapWeatherAPICondition(_ code: Int) -> WeatherCondition {
        switch code {
        case 1000:
            return .clear
        case 1003, 1006:
            return .partlyCloudy
        case 1009:
            return .cloudy
        case 1063...1201:
            return .rain
        case 1204...1237:
            return .snow
        case 1273...1282:
            return .thunderstorm
        case 1135, 1147:
            return .fog
        default:
            return .partlyCloudy
        }
    }
}

// MARK: - Weather Cache
@MainActor
private final class WeatherCache {
    private var currentCache: [String: (data: ServiceWeatherData, timestamp: Date)] = [:]
    private var forecastCache: [String: (data: WeatherForecast, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 600 // 10 minutes
    
    func getCurrent(latitude: Double, longitude: Double) -> ServiceWeatherData? {
        let key = cacheKey(latitude: latitude, longitude: longitude)
        guard let cached = currentCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheDuration else {
            return nil
        }
        return cached.data
    }
    
    func getForecast(latitude: Double, longitude: Double, days: Int) async -> WeatherForecast? {
        let key = "\(cacheKey(latitude: latitude, longitude: longitude))_\(days)"
        guard let cached = forecastCache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheDuration else {
            return nil
        }
        return cached.data
    }
    
    func store(_ weather: ServiceWeatherData, latitude: Double, longitude: Double) async {
        let key = cacheKey(latitude: latitude, longitude: longitude)
        currentCache[key] = (weather, Date())
    }
    
    func store(_ forecast: WeatherForecast, latitude: Double, longitude: Double, days: Int) async {
        let key = "\(cacheKey(latitude: latitude, longitude: longitude))_\(days)"
        forecastCache[key] = (forecast, Date())
    }
    
    func clear() async {
        currentCache.removeAll()
        forecastCache.removeAll()
    }
    
    private func cacheKey(latitude: Double, longitude: Double) -> String {
        "\(String(format: "%.2f", latitude))_\(String(format: "%.2f", longitude))"
    }
}

// MARK: - API Response Models

private struct OpenWeatherResponse: Decodable {
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let name: String
    
    struct Main: Decodable {
        let temp: Double
        let humidity: Int
    }
    
    struct Weather: Decodable {
        let main: String
    }
    
    struct Wind: Decodable {
        let speed: Double
    }
}

private struct OpenWeatherForecastResponse: Decodable {
    let city: City
    let list: [Day]
    
    struct City: Decodable {
        let name: String
    }
    
    struct Day: Decodable {
        let dt: Int
        let temp: Temp
        let weather: [Weather]
        let pop: Double?
        
        struct Temp: Decodable {
            let min: Double
            let max: Double
        }
        
        struct Weather: Decodable {
            let main: String
        }
    }
}

private struct WeatherAPICurrentResponse: Decodable {
    let location: Location
    let current: Current
    
    struct Location: Decodable {
        let name: String
    }
    
    struct Current: Decodable {
        let temp_c: Double
        let temp_f: Double
        let humidity: Int
        let wind_kph: Double
        let wind_mph: Double
        let condition: Condition
        
        struct Condition: Decodable {
            let code: Int
        }
    }
}

private struct WeatherAPIForecastResponse: Decodable {
    let location: Location
    let forecast: Forecast
    
    struct Location: Decodable {
        let name: String
    }
    
    struct Forecast: Decodable {
        let forecastday: [ForecastDay]
        
        struct ForecastDay: Decodable {
            let date: String
            let day: Day
            
            struct Day: Decodable {
                let maxtemp_c: Double
                let maxtemp_f: Double
                let mintemp_c: Double
                let mintemp_f: Double
                let daily_chance_of_rain: Int
                let condition: Condition
                
                struct Condition: Decodable {
                    let code: Int
                }
            }
        }
    }
    */
}