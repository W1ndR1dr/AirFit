import XCTest
@testable import AirFit

final class ServiceProtocolsTests: XCTestCase {
    
    // MARK: - ServiceHealth Tests
    
    func testServiceHealthInitialization() {
        // Given
        let health = ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: 0.5,
            errorMessage: nil,
            metadata: ["key": "value"]
        )
        
        // Then
        XCTAssertEqual(health.status, .healthy)
        XCTAssertNotNil(health.lastCheckTime)
        XCTAssertEqual(health.responseTime, 0.5)
        XCTAssertNil(health.errorMessage)
        XCTAssertEqual(health.metadata["key"], "value")
        XCTAssertTrue(health.isOperational)
    }
    
    func testServiceHealthOperationalStatus() {
        // Test healthy
        let healthy = ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [:]
        )
        XCTAssertTrue(healthy.isOperational)
        
        // Test degraded
        let degraded = ServiceHealth(
            status: .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: "Some issues",
            metadata: [:]
        )
        XCTAssertTrue(degraded.isOperational)
        
        // Test unhealthy
        let unhealthy = ServiceHealth(
            status: .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: "Service down",
            metadata: [:]
        )
        XCTAssertFalse(unhealthy.isOperational)
        
        // Test unknown
        let unknown = ServiceHealth(
            status: .unknown,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [:]
        )
        XCTAssertFalse(unknown.isOperational)
    }
    
    // MARK: - Model Tests
    
    func testAIModelInitialization() {
        let model = AIModel(
            id: "gpt-4",
            name: "GPT-4",
            contextWindow: 8192
        )
        
        XCTAssertEqual(model.id, "gpt-4")
        XCTAssertEqual(model.name, "GPT-4")
        XCTAssertEqual(model.contextWindow, 8192)
    }
    
    func testWeatherDataInitialization() {
        let weather = WeatherData(
            temperature: 72.5,
            condition: .partlyCloudy,
            humidity: 65.0,
            windSpeed: 10.5,
            location: "New York",
            timestamp: Date()
        )
        
        XCTAssertEqual(weather.temperature, 72.5)
        XCTAssertEqual(weather.condition, .partlyCloudy)
        XCTAssertEqual(weather.humidity, 65.0)
        XCTAssertEqual(weather.windSpeed, 10.5)
        XCTAssertEqual(weather.location, "New York")
        XCTAssertNotNil(weather.timestamp)
    }
    
    func testWeatherConditionCases() {
        let conditions: [WeatherCondition] = [
            .clear, .partlyCloudy, .cloudy, .rain,
            .snow, .thunderstorm, .fog
        ]
        
        for condition in conditions {
            XCTAssertNotNil(condition.rawValue)
        }
    }
    
    func testGoalTypeEnumeration() {
        let goalTypes = GoalType.allCases
        XCTAssertEqual(goalTypes.count, 7)
        XCTAssertTrue(goalTypes.contains(.weightLoss))
        XCTAssertTrue(goalTypes.contains(.muscleGain))
        XCTAssertTrue(goalTypes.contains(.custom))
    }
    
    func testWorkoutTypeEnumeration() {
        let workoutTypes = WorkoutType.allCases
        XCTAssertEqual(workoutTypes.count, 5)
        XCTAssertTrue(workoutTypes.contains(.strength))
        XCTAssertTrue(workoutTypes.contains(.cardio))
        XCTAssertTrue(workoutTypes.contains(.custom))
    }
    
    // MARK: - Analytics Types Tests
    
    func testAnalyticsEventCreation() {
        let event = AnalyticsEvent(
            name: "workout_completed",
            properties: ["duration": 3600, "type": "strength"],
            timestamp: Date()
        )
        
        XCTAssertEqual(event.name, "workout_completed")
        XCTAssertEqual(event.properties["duration"] as? Int, 3600)
        XCTAssertEqual(event.properties["type"] as? String, "strength")
        XCTAssertNotNil(event.timestamp)
    }
    
    func testTrendDirection() {
        let upTrend = Trend(direction: .up, changePercentage: 15.5)
        XCTAssertEqual(upTrend.direction, .up)
        XCTAssertEqual(upTrend.changePercentage, 15.5)
        
        let downTrend = Trend(direction: .down, changePercentage: -10.2)
        XCTAssertEqual(downTrend.direction, .down)
        XCTAssertEqual(downTrend.changePercentage, -10.2)
        
        let stableTrend = Trend(direction: .stable, changePercentage: 0.5)
        XCTAssertEqual(stableTrend.direction, .stable)
        XCTAssertEqual(stableTrend.changePercentage, 0.5)
    }
    
    func testMacroBalance() {
        let balance = MacroBalance(
            proteinPercentage: 30.0,
            carbsPercentage: 45.0,
            fatPercentage: 25.0
        )
        
        XCTAssertEqual(balance.proteinPercentage, 30.0)
        XCTAssertEqual(balance.carbsPercentage, 45.0)
        XCTAssertEqual(balance.fatPercentage, 25.0)
        XCTAssertEqual(
            balance.proteinPercentage + balance.carbsPercentage + balance.fatPercentage,
            100.0,
            accuracy: 0.001
        )
    }
}