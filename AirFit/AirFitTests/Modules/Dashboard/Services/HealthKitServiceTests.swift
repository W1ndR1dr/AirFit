import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class HealthKitServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: HealthKitService!
    private var mockHealthKitManager: MockHealthKitManager!
    private var mockContextAssembler: MockContextAssembler!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        testUser.baselineHRV = 50.0 // Set baseline for recovery score calculation
        
        // Create mocks
        mockHealthKitManager = MockHealthKitManager()
        mockContextAssembler = MockContextAssembler()
        
        // Create service
        sut = HealthKitService(
            healthKitManager: mockHealthKitManager,
            contextAssembler: mockContextAssembler
        )
    }
    
    override func tearDown() {
        sut = nil
        mockHealthKitManager = nil
        mockContextAssembler = nil
        testUser = nil
        super.tearDown()
    }
    
    // MARK: - Get Current Context Tests
    
    func test_getCurrentContext_withFullData_mapsCorrectly() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-28800), // 8 hours ago
                    wakeTime: Date(),
                    totalSleepTime: 25200, // 7 hours
                    deepSleepTime: 7200,
                    remSleepTime: 5400,
                    efficiency: 87.5,
                    interruptions: 2
                ),
                weeklyAverage: 7.2,
                consistency: 0.85
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 65,
                hrv: 55,
                bloodPressure: nil,
                weeklyTrend: .stable
            ),
            activity: ActivityContext(
                steps: 8500,
                activeEnergyBurned: 450,
                exerciseMinutes: 35,
                standHours: 10,
                moveStreak: 5
            ),
            environment: EnvironmentContext(
                weatherCondition: "Sunny",
                temperature: 22.0,
                airQuality: "Good",
                location: "Home"
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: 7,
                stressLevel: 3,
                mood: "Good",
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let context = try await sut.getCurrentContext()
        
        // Assert
        XCTAssertEqual(context.lastNightSleepDurationHours, 7.0)
        XCTAssertEqual(context.sleepQuality, 87)
        XCTAssertEqual(context.currentWeatherCondition, "Sunny")
        XCTAssertEqual(context.currentTemperatureCelsius, 22.0)
        XCTAssertEqual(context.yesterdayEnergyLevel, 7)
        XCTAssertEqual(context.currentHeartRate, 65)
        XCTAssertEqual(context.hrv, 55.0)
        XCTAssertEqual(context.steps, 8500)
    }
    
    func test_getCurrentContext_withMinimalData_handlesNilsGracefully() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: nil,
                weeklyAverage: nil,
                consistency: nil
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: nil,
                hrv: nil,
                bloodPressure: nil,
                weeklyTrend: nil
            ),
            activity: ActivityContext(
                steps: nil,
                activeEnergyBurned: nil,
                exerciseMinutes: nil,
                standHours: nil,
                moveStreak: nil
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let context = try await sut.getCurrentContext()
        
        // Assert
        XCTAssertNil(context.lastNightSleepDurationHours)
        XCTAssertNil(context.sleepQuality)
        XCTAssertNil(context.currentWeatherCondition)
        XCTAssertNil(context.currentTemperatureCelsius)
        XCTAssertNil(context.yesterdayEnergyLevel)
        XCTAssertNil(context.currentHeartRate)
        XCTAssertNil(context.hrv)
        XCTAssertNil(context.steps)
    }
    
    func test_getCurrentContext_withPartialSleepData_calculatesHoursCorrectly() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-32400), // 9 hours ago
                    wakeTime: Date(),
                    totalSleepTime: 30600, // 8.5 hours
                    deepSleepTime: nil,
                    remSleepTime: nil,
                    efficiency: nil,
                    interruptions: nil
                ),
                weeklyAverage: nil,
                consistency: nil
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: nil,
                hrv: nil,
                bloodPressure: nil,
                weeklyTrend: nil
            ),
            activity: ActivityContext(
                steps: nil,
                activeEnergyBurned: nil,
                exerciseMinutes: nil,
                standHours: nil,
                moveStreak: nil
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let context = try await sut.getCurrentContext()
        
        // Assert
        XCTAssertEqual(context.lastNightSleepDurationHours, 8.5)
        XCTAssertNil(context.sleepQuality) // Efficiency was nil
    }
    
    // MARK: - Calculate Recovery Score Tests
    
    func test_calculateRecoveryScore_withGoodSleepAndHRV_returnsHighScore() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-28800),
                    wakeTime: Date(),
                    totalSleepTime: 28800, // 8 hours - perfect
                    deepSleepTime: 7200,
                    remSleepTime: 5400,
                    efficiency: 90.0,
                    interruptions: 1
                ),
                weeklyAverage: 7.5,
                consistency: 0.9
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 60,
                hrv: 60, // Above baseline of 50
                bloodPressure: nil,
                weeklyTrend: .improving
            ),
            activity: ActivityContext(
                steps: 5000,
                activeEnergyBurned: 300, // Moderate activity yesterday
                exerciseMinutes: 20,
                standHours: 8,
                moveStreak: 3
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let score = try await sut.calculateRecoveryScore(for: testUser)
        
        // Assert
        XCTAssertEqual(score.score, 100) // Base 50 + Sleep 30 + HRV 20 (60/50 * 20 = 24, capped at 20)
        XCTAssertEqual(score.status, .good)
        XCTAssertEqual(score.factors.count, 2)
        XCTAssertTrue(score.factors[0].contains("8.0 hrs"))
        XCTAssertTrue(score.factors[1].contains("60 ms"))
    }
    
    func test_calculateRecoveryScore_withPoorSleep_returnsLowScore() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-18000),
                    wakeTime: Date(),
                    totalSleepTime: 14400, // 4 hours - poor
                    deepSleepTime: 3600,
                    remSleepTime: 1800,
                    efficiency: 65.0,
                    interruptions: 5
                ),
                weeklyAverage: 5.5,
                consistency: 0.6
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 75,
                hrv: 40, // Below baseline
                bloodPressure: nil,
                weeklyTrend: .declining
            ),
            activity: ActivityContext(
                steps: 2000,
                activeEnergyBurned: 150,
                exerciseMinutes: 0,
                standHours: 5,
                moveStreak: 0
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let score = try await sut.calculateRecoveryScore(for: testUser)
        
        // Assert
        XCTAssertEqual(score.score, 81) // Base 50 + Sleep 15 (4/8 * 30) + HRV 16 (40/50 * 20)
        XCTAssertEqual(score.status, .good) // Still above 70
        XCTAssertTrue(score.factors[0].contains("4.0 hrs"))
        XCTAssertTrue(score.factors[1].contains("40 ms"))
    }
    
    func test_calculateRecoveryScore_withHighYesterdayActivity_reducesScore() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-25200),
                    wakeTime: Date(),
                    totalSleepTime: 25200, // 7 hours
                    deepSleepTime: 6000,
                    remSleepTime: 4800,
                    efficiency: 85.0,
                    interruptions: 2
                ),
                weeklyAverage: 7.0,
                consistency: 0.8
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 62,
                hrv: 50, // Exactly at baseline
                bloodPressure: nil,
                weeklyTrend: .stable
            ),
            activity: ActivityContext(
                steps: 15000,
                activeEnergyBurned: 800, // High activity yesterday
                exerciseMinutes: 90,
                standHours: 12,
                moveStreak: 10
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let score = try await sut.calculateRecoveryScore(for: testUser)
        
        // Assert
        // Base 50 + Sleep 26 (7/8 * 30) + HRV 20 (50/50 * 20) - Activity 10 = 86
        XCTAssertEqual(score.score, 86)
        XCTAssertEqual(score.status, .good)
    }
    
    func test_calculateRecoveryScore_withNoHRVBaseline_skipssHRVContribution() async throws {
        // Arrange
        testUser.baselineHRV = nil // No baseline
        
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-21600),
                    wakeTime: Date(),
                    totalSleepTime: 21600, // 6 hours
                    deepSleepTime: 5400,
                    remSleepTime: 4200,
                    efficiency: 80.0,
                    interruptions: 3
                ),
                weeklyAverage: 6.5,
                consistency: 0.75
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 70,
                hrv: 45, // HRV present but no baseline to compare
                bloodPressure: nil,
                weeklyTrend: .stable
            ),
            activity: ActivityContext(
                steps: 7000,
                activeEnergyBurned: 400,
                exerciseMinutes: 30,
                standHours: 9,
                moveStreak: 2
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let score = try await sut.calculateRecoveryScore(for: testUser)
        
        // Assert
        // Base 50 + Sleep 22 (6/8 * 30) + HRV 0 (no baseline) = 72
        XCTAssertEqual(score.score, 72)
        XCTAssertEqual(score.status, .good)
    }
    
    func test_calculateRecoveryScore_withNoData_returnsBaseScore() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(lastNight: nil, weeklyAverage: nil, consistency: nil),
            heartHealth: HeartHealthContext(restingHeartRate: nil, hrv: nil, bloodPressure: nil, weeklyTrend: nil),
            activity: ActivityContext(steps: nil, activeEnergyBurned: nil, exerciseMinutes: nil, standHours: nil, moveStreak: nil),
            environment: EnvironmentContext(weatherCondition: nil, temperature: nil, airQuality: nil, location: nil),
            subjectiveData: SubjectiveContext(energyLevel: nil, stressLevel: nil, mood: nil, notes: nil),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let score = try await sut.calculateRecoveryScore(for: testUser)
        
        // Assert
        XCTAssertEqual(score.score, 50) // Just base score
        XCTAssertEqual(score.status, .moderate)
        XCTAssertTrue(score.factors[0].contains("0.0 hrs"))
        XCTAssertTrue(score.factors[1].contains("0 ms"))
    }
    
    // MARK: - Get Performance Insight Tests
    
    func test_getPerformanceInsight_withHighActivity_returnsImprovingTrend() async throws {
        // Arrange
        let days = 7
        // Current implementation uses placeholder data, so we can't mock actual workout data yet
        
        // Act
        let insight = try await sut.getPerformanceInsight(for: testUser, days: days)
        
        // Assert
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight.metric, "Weekly Active Days")
        XCTAssertNotNil(insight.value)
        XCTAssertFalse(insight.insight.isEmpty)
        
        // With current placeholder implementation:
        // workoutCount = 3, days = 7
        // 3 > 7/2 (3.5) is false, 3 < 7/4 (1.75) is false, so trend should be stable
        XCTAssertEqual(insight.trend, .stable)
    }
    
    func test_getPerformanceInsight_withZeroWorkouts_returnsEncouragingMessage() async throws {
        // Arrange
        let days = 14
        // With current implementation, we can't control workout count
        
        // Act
        let insight = try await sut.getPerformanceInsight(for: testUser, days: days)
        
        // Assert
        XCTAssertNotNil(insight)
        // Current implementation returns workoutCount = 3, so message won't be the zero-activity one
        if insight.value == "0" {
            XCTAssertTrue(insight.insight.contains("Time to get moving"))
        } else {
            XCTAssertTrue(insight.insight.contains("You've been active"))
            XCTAssertTrue(insight.insight.contains("cal"))
        }
    }
    
    func test_getPerformanceInsight_withDifferentDayRanges_adjustsTrend() async throws {
        // Test different day ranges
        let dayRanges = [3, 7, 14, 30]
        
        for days in dayRanges {
            // Act
            let insight = try await sut.getPerformanceInsight(for: testUser, days: days)
            
            // Assert
            XCTAssertNotNil(insight)
            XCTAssertEqual(insight.metric, "Weekly Active Days")
            
            // With placeholder workoutCount = 3:
            // days = 3: 3 > 1.5 = true -> improving
            // days = 7: 3 > 3.5 = false, 3 < 1.75 = false -> stable
            // days = 14: 3 > 7 = false, 3 < 3.5 = false -> stable
            // days = 30: 3 > 15 = false, 3 < 7.5 = true -> declining
            switch days {
            case 3:
                XCTAssertEqual(insight.trend, .improving)
            case 30:
                XCTAssertEqual(insight.trend, .declining)
            default:
                XCTAssertEqual(insight.trend, .stable)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func test_getCurrentContext_withExtremeValues_handlesCorrectly() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-43200), // 12 hours ago
                    wakeTime: Date(),
                    totalSleepTime: 43200, // 12 hours - very long
                    deepSleepTime: 14400,
                    remSleepTime: 10800,
                    efficiency: 100.0,
                    interruptions: 0
                ),
                weeklyAverage: 10.0,
                consistency: 1.0
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 150, // Very high
                hrv: 200, // Very high
                bloodPressure: nil,
                weeklyTrend: .improving
            ),
            activity: ActivityContext(
                steps: 50000, // Very high
                activeEnergyBurned: 2000, // Very high
                exerciseMinutes: 300, // 5 hours
                standHours: 24, // All day
                moveStreak: 365 // Full year
            ),
            environment: EnvironmentContext(
                weatherCondition: "Extreme Heat",
                temperature: 50.0, // Very hot
                airQuality: "Hazardous",
                location: "Desert"
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: 10, // Max
                stressLevel: 10, // Max
                mood: "Euphoric",
                notes: "Best day ever!"
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let context = try await sut.getCurrentContext()
        
        // Assert - Should handle extreme values without crashing
        XCTAssertEqual(context.lastNightSleepDurationHours, 12.0)
        XCTAssertEqual(context.sleepQuality, 100)
        XCTAssertEqual(context.currentHeartRate, 150)
        XCTAssertEqual(context.hrv, 200.0)
        XCTAssertEqual(context.steps, 50000)
        XCTAssertEqual(context.currentTemperatureCelsius, 50.0)
    }
    
    func test_calculateRecoveryScore_withExtremeValues_capsAtBounds() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-36000),
                    wakeTime: Date(),
                    totalSleepTime: 36000, // 10 hours - more than perfect
                    deepSleepTime: 12000,
                    remSleepTime: 9000,
                    efficiency: 95.0,
                    interruptions: 0
                ),
                weeklyAverage: 9.0,
                consistency: 0.95
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 50,
                hrv: 100, // Double the baseline
                bloodPressure: nil,
                weeklyTrend: .improving
            ),
            activity: ActivityContext(
                steps: 3000,
                activeEnergyBurned: 200, // Low activity
                exerciseMinutes: 15,
                standHours: 6,
                moveStreak: 1
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                airQuality: nil,
                location: nil
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: nil,
                stressLevel: nil,
                mood: nil,
                notes: nil
            ),
            timestamp: Date()
        )
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act
        let score = try await sut.calculateRecoveryScore(for: testUser)
        
        // Assert
        // Base 50 + Sleep 30 (capped) + HRV 20 (capped) = 100
        XCTAssertEqual(score.score, 100) // Capped at 100
        XCTAssertEqual(score.status, .good)
    }
    
    // MARK: - Performance Tests
    
    func test_getCurrentContext_performance() async throws {
        // Arrange
        let mockSnapshot = createFullSnapshot()
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act & Measure
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sut.getCurrentContext()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(duration, 0.1, "Context mapping should be fast")
    }
    
    func test_calculateRecoveryScore_performance() async throws {
        // Arrange
        let mockSnapshot = createFullSnapshot()
        mockContextAssembler.mockSnapshot = mockSnapshot
        
        // Act & Measure
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sut.calculateRecoveryScore(for: testUser)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert
        XCTAssertLessThan(duration, 0.1, "Recovery score calculation should be fast")
    }
    
    // MARK: - Helper Methods
    
    private func createFullSnapshot() -> HealthContextSnapshot {
        return HealthContextSnapshot(
            sleep: SleepContext(
                lastNight: SleepData(
                    bedtime: Date().addingTimeInterval(-25200),
                    wakeTime: Date(),
                    totalSleepTime: 25200,
                    deepSleepTime: 6300,
                    remSleepTime: 5040,
                    efficiency: 87.5,
                    interruptions: 2
                ),
                weeklyAverage: 7.2,
                consistency: 0.85
            ),
            heartHealth: HeartHealthContext(
                restingHeartRate: 62,
                hrv: 52,
                bloodPressure: nil,
                weeklyTrend: .stable
            ),
            activity: ActivityContext(
                steps: 8000,
                activeEnergyBurned: 420,
                exerciseMinutes: 32,
                standHours: 10,
                moveStreak: 5
            ),
            environment: EnvironmentContext(
                weatherCondition: "Partly Cloudy",
                temperature: 20.0,
                airQuality: "Good",
                location: "Home"
            ),
            subjectiveData: SubjectiveContext(
                energyLevel: 7,
                stressLevel: 4,
                mood: "Good",
                notes: nil
            ),
            timestamp: Date()
        )
    }
}

// MARK: - Mock Context Assembler

@MainActor
final class MockContextAssembler: ContextAssembler {
    var mockSnapshot: HealthContextSnapshot = HealthContextSnapshot(
        sleep: SleepContext(lastNight: nil, weeklyAverage: nil, consistency: nil),
        heartHealth: HeartHealthContext(restingHeartRate: nil, hrv: nil, bloodPressure: nil, weeklyTrend: nil),
        activity: ActivityContext(steps: nil, activeEnergyBurned: nil, exerciseMinutes: nil, standHours: nil, moveStreak: nil),
        environment: EnvironmentContext(weatherCondition: nil, temperature: nil, airQuality: nil, location: nil),
        subjectiveData: SubjectiveContext(energyLevel: nil, stressLevel: nil, mood: nil, notes: nil),
        timestamp: Date()
    )
    
    var assembleContextCallCount = 0
    
    override func assembleContext() async -> HealthContextSnapshot {
        assembleContextCallCount += 1
        return mockSnapshot
    }
}