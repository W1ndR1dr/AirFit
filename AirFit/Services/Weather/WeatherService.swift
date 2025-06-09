import Foundation
@preconcurrency import WeatherKit
import CoreLocation

/// Clean WeatherKit implementation - no API keys, no network complexity
actor WeatherService: WeatherServiceProtocol, ServiceProtocol {
    // MARK: - Properties
    nonisolated let serviceIdentifier = "weatherkit-service"
    nonisolated var isConfigured: Bool { true } // WeatherKit requires no configuration
    
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = CLLocationManager()
    
    // Simple in-memory cache to avoid excessive requests
    private var cache: (location: CLLocation, weather: ServiceWeatherData, timestamp: Date)?
    private let cacheLifetime: TimeInterval = 600 // 10 minutes
    
    // MARK: - ServiceProtocol
    func configure() async throws {
        // WeatherKit requires no API keys or configuration
        AppLogger.info("WeatherKit ready - no configuration needed", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["provider": "WeatherKit", "status": "operational"]
        )
    }
    
    func reset() async {
        cache = nil
    }
    
    // MARK: - WeatherServiceProtocol
    func getCurrentWeather(latitude: Double, longitude: Double) async throws -> ServiceWeatherData {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        // Check cache first
        if let cached = cache,
           cached.location.distance(from: location) < 100, // Within 100m
           Date().timeIntervalSince(cached.timestamp) < cacheLifetime {
            return cached.weather
        }
        
        do {
            // WeatherKit's weather method needs to be called from MainActor context
            let weather = try await weatherService.weather(for: location)
            let current = weather.currentWeather
            
            let data = ServiceWeatherData(
                temperature: current.temperature.value,
                condition: mapCondition(current.condition),
                humidity: current.humidity,
                windSpeed: current.wind.speed.value,
                location: await getLocationName(for: location),
                timestamp: Date()
            )
            
            // Update cache
            cache = (location, data, Date())
            
            return data
        } catch {
            AppLogger.error("WeatherKit request failed", error: error, category: .services)
            throw AppError.networkError(underlying: error)
        }
    }
    
    func getForecast(latitude: Double, longitude: Double, days: Int) async throws -> WeatherForecast {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        do {
            let weather = try await weatherService.weather(for: location)
            let dailyForecasts = weather.dailyForecast.forecast.prefix(days).map { day in
                DailyForecast(
                    date: day.date,
                    highTemperature: day.highTemperature.value,
                    lowTemperature: day.lowTemperature.value,
                    condition: mapCondition(day.condition),
                    precipitationChance: day.precipitationChance
                )
            }
            
            return WeatherForecast(
                daily: Array(dailyForecasts),
                location: await getLocationName(for: location)
            )
        } catch {
            AppLogger.error("WeatherKit forecast request failed", error: error, category: .services)
            throw AppError.networkError(underlying: error)
        }
    }
    
    nonisolated func getCachedWeather(latitude: Double, longitude: Double) -> ServiceWeatherData? {
        // Since this is a read-only operation and we can't access actor state synchronously,
        // we'll return nil for now. In production, we'd use a different caching strategy
        return nil
    }
    
    // MARK: - LLM Context Helper
    /// Returns a token-efficient weather summary for LLM context
    func getLLMContext(latitude: Double, longitude: Double) async -> String? {
        do {
            let weather = try await getCurrentWeather(latitude: latitude, longitude: longitude)
            
            // Super concise format for token efficiency
            let temp = Int(weather.temperature)
            let condition = weather.condition.rawValue
            
            // Examples: "sunny,22C" or "rain,15C" or "snow,-2C"
            return "\(condition),\(temp)C"
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Helpers
    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> AirFit.WeatherCondition {
        // Map WeatherKit conditions to our simplified set
        switch condition {
        case .clear:
            return .clear
        case .partlyCloudy:
            return .partlyCloudy
        case .cloudy:
            return .cloudy
        case .rain:
            return .rain
        case .snow:
            return .snow
        case .thunderstorms:
            return .thunderstorm
        case .foggy:
            return .fog
        default:
            // For any other conditions, make a reasonable guess
            let description = String(describing: condition).lowercased()
            if description.contains("rain") || description.contains("drizzle") {
                return .rain
            } else if description.contains("snow") || description.contains("sleet") {
                return .snow
            } else if description.contains("cloud") {
                return .cloudy
            } else if description.contains("storm") {
                return .thunderstorm
            } else {
                return .partlyCloudy
            }
        }
    }
    
    private func getLocationName(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return placemark.locality ?? placemark.name ?? "Current Location"
            }
        } catch {
            AppLogger.debug("Geocoding failed: \(error)", category: .services)
        }
        return "Current Location"
    }
}