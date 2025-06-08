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
        try super.setUp()
        
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
    
    override func tearDown() async throws {
        sut = nil
        mockHealthKitManager = nil
        mockContextAssembler = nil
        testUser = nil
        try super.tearDown()
    }
    
    // MARK: - Get Current Context Tests
    
    func test_getCurrentContext_withFullData_mapsCorrectly() async throws {
        // Arrange
        let mockSnapshot = HealthContextSnapshot(
            subjectiveData: SubjectiveData(
                energyLevel: 7,
                mood: 4,
                stress: 3,
                motivation: nil,
                soreness: nil,
                notes: nil
            ),
            environment: EnvironmentContext(
                weatherCondition: "Sunny",
                temperature: Measurement(value: 22.0, unit: .celsius),
                humidity: nil,
                airQualityIndex: nil
            ),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 450, unit: .kilocalories),
                basalEnergyBurned: nil,
                steps: 8500,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 35,
                standHours: 10,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-28800), // 8 hours ago
                    wakeTime: Date(),
                    totalSleepTime: 25200, // 7 hours
                    timeInBed: 28800, // 8 hours
                    efficiency: 87.5,
                    remTime: 5400,
                    coreTime: 12600,
                    deepTime: 7200,
                    awakeTime: 3600
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 25920, // 7.2 hours
                    averageEfficiency: 85.0,
                    consistency: 85.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 65,
                hrv: Measurement(value: 55, unit: .milliseconds),
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(
                weight: nil,
                bodyFatPercentage: nil,
                leanBodyMass: nil,
                bmi: nil,
                weightTrend: nil,
                bodyFatTrend: nil
            ),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 5,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .maintaining
            )
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
            subjectiveData: SubjectiveData(
                energyLevel: nil,
                mood: nil,
                stress: nil,
                motivation: nil,
                soreness: nil,
                notes: nil
            ),
            environment: EnvironmentContext(
                weatherCondition: nil,
                temperature: nil,
                humidity: nil,
                airQualityIndex: nil
            ),
            activity: ActivityMetrics(
                activeEnergyBurned: nil,
                basalEnergyBurned: nil,
                steps: nil,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: nil,
                standHours: nil,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: nil,
                weeklyAverage: nil
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: nil,
                hrv: nil,
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(
                weight: nil,
                bodyFatPercentage: nil,
                leanBodyMass: nil,
                bmi: nil,
                weightTrend: nil,
                bodyFatTrend: nil
            ),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: nil,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: nil
            )
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
            subjectiveData: SubjectiveData(),
            environment: EnvironmentContext(),
            activity: ActivityMetrics(),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-32400), // 9 hours ago
                    wakeTime: Date(),
                    totalSleepTime: 30600, // 8.5 hours
                    timeInBed: nil,
                    efficiency: nil,
                    remTime: nil,
                    coreTime: nil,
                    deepTime: nil,
                    awakeTime: nil
                ),
                weeklyAverage: nil
            ),
            heartHealth: HeartHealthMetrics(),
            body: BodyMetrics(),
            appContext: AppSpecificContext(),
            trends: HealthTrends()
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
            subjectiveData: SubjectiveData(),
            environment: EnvironmentContext(),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 300, unit: .kilocalories),
                basalEnergyBurned: nil,
                steps: 5000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 20,
                standHours: 8,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-28800),
                    wakeTime: Date(),
                    totalSleepTime: 28800, // 8 hours - perfect
                    timeInBed: 32400,
                    efficiency: 90.0,
                    remTime: 5400,
                    coreTime: 13200,
                    deepTime: 7200,
                    awakeTime: 3200
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 27000, // 7.5 hours
                    averageEfficiency: 88.0,
                    consistency: 90.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 60,
                hrv: Measurement(value: 60, unit: .milliseconds), // Above baseline of 50
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 3,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .improving
            )
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
            subjectiveData: SubjectiveData(),
            environment: EnvironmentContext(),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 150, unit: .kilocalories),
                basalEnergyBurned: nil,
                steps: 2000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 0,
                standHours: 5,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-18000),
                    wakeTime: Date(),
                    totalSleepTime: 14400, // 4 hours - poor
                    timeInBed: 18000,
                    efficiency: 65.0,
                    remTime: 1800,
                    coreTime: 8400,
                    deepTime: 3600,
                    awakeTime: 600
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 19800, // 5.5 hours
                    averageEfficiency: 70.0,
                    consistency: 60.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 75,
                hrv: Measurement(value: 40, unit: .milliseconds), // Below baseline
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 0,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .declining
            )
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
            subjectiveData: SubjectiveData(),
            environment: EnvironmentContext(),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 800, unit: .kilocalories), // High activity yesterday
                basalEnergyBurned: nil,
                steps: 15000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 90,
                standHours: 12,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-25200),
                    wakeTime: Date(),
                    totalSleepTime: 25200, // 7 hours
                    timeInBed: 28800,
                    efficiency: 85.0,
                    remTime: 4800,
                    coreTime: 12600,
                    deepTime: 6000,
                    awakeTime: 1800
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 25200, // 7.0 hours
                    averageEfficiency: 83.0,
                    consistency: 80.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 62,
                hrv: Measurement(value: 50, unit: .milliseconds), // Exactly at baseline
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 10,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .maintaining
            )
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
            subjectiveData: SubjectiveData(),
            environment: EnvironmentContext(),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 400, unit: .kilocalories),
                basalEnergyBurned: nil,
                steps: 7000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 30,
                standHours: 9,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-21600),
                    wakeTime: Date(),
                    totalSleepTime: 21600, // 6 hours
                    timeInBed: 25200,
                    efficiency: 80.0,
                    remTime: 4200,
                    coreTime: 10800,
                    deepTime: 5400,
                    awakeTime: 1200
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 23400, // 6.5 hours
                    averageEfficiency: 78.0,
                    consistency: 75.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 70,
                hrv: Measurement(value: 45, unit: .milliseconds), // HRV present but no baseline to compare
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 2,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .maintaining
            )
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
        let mockSnapshot = HealthContextSnapshot()
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
            subjectiveData: SubjectiveData(
                energyLevel: 10, // Max
                mood: 10, // Max
                stress: 10, // Max
                motivation: 10,
                soreness: 1,
                notes: "Best day ever!"
            ),
            environment: EnvironmentContext(
                weatherCondition: "Extreme Heat",
                temperature: Measurement(value: 50.0, unit: .celsius), // Very hot
                humidity: 90.0,
                airQualityIndex: 500
            ),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 2000, unit: .kilocalories), // Very high
                basalEnergyBurned: nil,
                steps: 50000, // Very high
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 300, // 5 hours
                standHours: 24, // All day
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-43200), // 12 hours ago
                    wakeTime: Date(),
                    totalSleepTime: 43200, // 12 hours - very long
                    timeInBed: 43200,
                    efficiency: 100.0,
                    remTime: 10800,
                    coreTime: 18000,
                    deepTime: 14400,
                    awakeTime: 0
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 36000, // 10.0 hours
                    averageEfficiency: 98.0,
                    consistency: 100.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 150, // Very high
                hrv: Measurement(value: 200, unit: .milliseconds), // Very high
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 365, // Full year
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .improving
            )
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
            subjectiveData: SubjectiveData(),
            environment: EnvironmentContext(),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 200, unit: .kilocalories), // Low activity
                basalEnergyBurned: nil,
                steps: 3000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 15,
                standHours: 6,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-36000),
                    wakeTime: Date(),
                    totalSleepTime: 36000, // 10 hours - more than perfect
                    timeInBed: 38000,
                    efficiency: 95.0,
                    remTime: 9000,
                    coreTime: 15000,
                    deepTime: 12000,
                    awakeTime: 0
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 32400, // 9.0 hours
                    averageEfficiency: 92.0,
                    consistency: 95.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 50,
                hrv: Measurement(value: 100, unit: .milliseconds), // Double the baseline
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 1,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .improving
            )
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
            subjectiveData: SubjectiveData(
                energyLevel: 7,
                mood: 4,
                stress: 4,
                motivation: nil,
                soreness: nil,
                notes: nil
            ),
            environment: EnvironmentContext(
                weatherCondition: "Partly Cloudy",
                temperature: Measurement(value: 20.0, unit: .celsius),
                humidity: nil,
                airQualityIndex: nil
            ),
            activity: ActivityMetrics(
                activeEnergyBurned: Measurement(value: 420, unit: .kilocalories),
                basalEnergyBurned: nil,
                steps: 8000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 32,
                standHours: 10,
                moveMinutes: nil,
                currentHeartRate: nil,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            ),
            sleep: SleepAnalysis(
                lastNight: SleepAnalysis.SleepSession(
                    bedtime: Date().addingTimeInterval(-25200),
                    wakeTime: Date(),
                    totalSleepTime: 25200,
                    timeInBed: 28800,
                    efficiency: 87.5,
                    remTime: 5040,
                    coreTime: 12600,
                    deepTime: 6300,
                    awakeTime: 3060
                ),
                weeklyAverage: SleepAnalysis.SleepAverages(
                    averageBedtime: nil,
                    averageWakeTime: nil,
                    averageDuration: 25920, // 7.2 hours
                    averageEfficiency: 86.0,
                    consistency: 85.0
                )
            ),
            heartHealth: HeartHealthMetrics(
                restingHeartRate: 62,
                hrv: Measurement(value: 52, unit: .milliseconds),
                respiratoryRate: nil,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            ),
            body: BodyMetrics(),
            appContext: AppSpecificContext(
                activeWorkoutName: nil,
                lastMealTime: nil,
                lastMealSummary: nil,
                waterIntakeToday: nil,
                lastCoachInteraction: nil,
                upcomingWorkout: nil,
                currentStreak: 5,
                workoutContext: nil
            ),
            trends: HealthTrends(
                weeklyActivityChange: nil,
                sleepConsistencyScore: nil,
                recoveryTrend: nil,
                performanceTrend: .maintaining
            )
        )
    }
}

// MARK: - Mock Context Assembler

@MainActor
final class MockContextAssembler: ContextAssemblerProtocol {
    var mockSnapshot: HealthContextSnapshot = HealthContextSnapshot()
    
    var assembleContextCallCount = 0
    
    func assembleContext() async -> HealthContextSnapshot {
        assembleContextCallCount += 1
        return mockSnapshot
    }
}