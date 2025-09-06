import XCTest
import HealthKit
@testable import AirFit

@MainActor
final class HealthKitManagerTests: AirFitTestCase {
    
    var healthKitFake: HealthKitManagerFake!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        healthKitFake = HealthKitManagerFake()
        healthKitFake.setupRealisticMockData()
    }
    
    override func tearDownWithError() throws {
        healthKitFake.reset()
        healthKitFake = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization_Success() async throws {
        // Arrange
        healthKitFake.shouldThrowAuthorizationError = false
        
        // Act
        try await healthKitFake.requestAuthorization()
        
        // Assert
        XCTAssertEqual(healthKitFake.requestAuthorizationCallCount, 1)
        XCTAssertEqual(healthKitFake.authorizationStatus, .authorized)
    }
    
    func testRequestAuthorization_Failure() async {
        // Arrange
        healthKitFake.shouldThrowAuthorizationError = true
        
        // Act & Assert
        do {
            try await healthKitFake.requestAuthorization()
            XCTFail("Expected authorization error")
        } catch {
            XCTAssertEqual(healthKitFake.requestAuthorizationCallCount, 1)
            XCTAssertEqual(healthKitFake.authorizationStatus, .notDetermined)
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testRequestAuthorization_WithDelay() async throws {
        // Arrange
        let delay: TimeInterval = 0.1
        healthKitFake.authorizationDelay = delay
        
        // Act
        let startTime = Date()
        try await healthKitFake.requestAuthorization()
        let duration = Date().timeIntervalSince(startTime)
        
        // Assert
        XCTAssertGreaterThanOrEqual(duration, delay)
        XCTAssertEqual(healthKitFake.authorizationStatus, .authorized)
    }
    
    // MARK: - Data Fetching Tests
    
    func testFetchTodayActivityMetrics_Success() async throws {
        // Arrange
        healthKitFake.mockActivityMetrics.steps = 10000
        healthKitFake.mockActivityMetrics.activeEnergyBurned = Measurement(value: 500, unit: .kilocalories)
        
        // Act
        let metrics = try await healthKitFake.fetchTodayActivityMetrics()
        
        // Assert
        XCTAssertEqual(healthKitFake.fetchTodayActivityMetricsCallCount, 1)
        XCTAssertEqual(metrics.steps, 10000)
        XCTAssertEqual(metrics.activeEnergyBurned?.value, 500)
    }
    
    func testFetchTodayActivityMetrics_Failure() async {
        // Arrange
        healthKitFake.shouldThrowDataError = true
        
        // Act & Assert
        do {
            _ = try await healthKitFake.fetchTodayActivityMetrics()
            XCTFail("Expected data error")
        } catch {
            XCTAssertEqual(healthKitFake.fetchTodayActivityMetricsCallCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testFetchHeartHealthMetrics_ReturnsRealisticData() async throws {
        // Act
        let metrics = try await healthKitFake.fetchHeartHealthMetrics()
        
        // Assert
        XCTAssertEqual(healthKitFake.fetchHeartHealthMetricsCallCount, 1)
        XCTAssertEqual(metrics.restingHeartRate, 68)
        XCTAssertEqual(metrics.hrv?.value, 35.2)
        XCTAssertEqual(metrics.vo2Max, 42.5)
    }
    
    func testFetchDailyBiometrics_WithDateRange() async throws {
        // Arrange
        let startDate = MockDataGenerator.daysAgo(7)
        let endDate = Date()
        
        // Act
        let biometrics = try await healthKitFake.fetchDailyBiometrics(from: startDate, to: endDate)
        
        // Assert
        XCTAssertEqual(biometrics.count, healthKitFake.mockDailyBiometrics.count)
        XCTAssertTrue(biometrics.allSatisfy { $0.date >= startDate && $0.date <= endDate })
    }
    
    // MARK: - Save Operations Tests
    
    func testSaveFoodEntry_Success() async throws {
        // Arrange
        let foodEntry = createTestFoodEntry(name: "Test Meal", calories: 300)
        
        // Act
        let savedIds = try await healthKitFake.saveFoodEntry(foodEntry)
        
        // Assert
        XCTAssertEqual(healthKitFake.saveFoodEntryCallCount, 1)
        XCTAssertEqual(healthKitFake.savedFoodEntries.count, 1)
        XCTAssertEqual(healthKitFake.savedFoodEntries.first?.name, "Test Meal")
        XCTAssertEqual(savedIds.count, 3) // Mock returns 3 IDs
        XCTAssertTrue(savedIds.allSatisfy { !$0.isEmpty })
    }
    
    func testSaveWorkout_TracksCorrectly() async throws {
        // Arrange
        let workout = createTestWorkout(name: "Morning Run")
        
        // Act
        let workoutId = try await healthKitFake.saveWorkout(workout)
        
        // Assert
        XCTAssertEqual(healthKitFake.saveWorkoutCallCount, 1)
        XCTAssertEqual(healthKitFake.savedWorkouts.count, 1)
        XCTAssertEqual(healthKitFake.savedWorkouts.first?.name, "Morning Run")
        XCTAssertFalse(workoutId.isEmpty)
    }
    
    func testSaveBodyMass_RecordsCorrectValues() async throws {
        // Arrange
        let weight = 75.5
        let date = Date()
        
        // Act
        try await healthKitFake.saveBodyMass(weightKg: weight, date: date)
        
        // Assert
        XCTAssertEqual(healthKitFake.saveBodyMassCallCount, 1)
        XCTAssertEqual(healthKitFake.savedBodyMassEntries.count, 1)
        XCTAssertEqual(healthKitFake.savedBodyMassEntries.first?.weight, weight)
        assertDatesEqual(healthKitFake.savedBodyMassEntries.first?.date ?? Date(), date)
    }
    
    // MARK: - Observer Tests
    
    func testObserveHealthKitChanges_ReturnsToken() {
        // Act
        let token = healthKitFake.observeHealthKitChanges { }
        
        // Assert
        XCTAssertNotNil(token)
    }
    
    func testStopObserving_RemovesObserver() {
        // Arrange
        let token = healthKitFake.observeHealthKitChanges { }
        
        // Act
        healthKitFake.stopObserving(token: token)
        
        // Assert - No crash should occur
        XCTAssertTrue(true) // Test passes if no exception thrown
    }
    
    func testObserveBodyMetrics_CallsHandler() async throws {
        // Arrange
        var handlerCalled = false
        
        // Act
        try await healthKitFake.observeBodyMetrics {
            handlerCalled = true
        }
        
        healthKitFake.triggerBodyMetricsObservers()
        
        // Assert
        XCTAssertEqual(healthKitFake.observeBodyMetricsCallCount, 1)
        XCTAssertTrue(handlerCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testMultipleOperations_WithDataErrors() async {
        // Arrange
        healthKitFake.shouldThrowDataError = true
        
        // Act & Assert - All should throw errors
        await assertThrowsError(try await healthKitFake.fetchTodayActivityMetrics())
        await assertThrowsError(try await healthKitFake.fetchHeartHealthMetrics())
        await assertThrowsError(try await healthKitFake.fetchLatestBodyMetrics())
        await assertThrowsError(try await healthKitFake.fetchLastNightSleep())
        await assertThrowsError(try await healthKitFake.fetchRecentWorkouts(limit: 10))
        
        // Verify all methods were called despite errors
        XCTAssertEqual(healthKitFake.fetchTodayActivityMetricsCallCount, 1)
        XCTAssertEqual(healthKitFake.fetchHeartHealthMetricsCallCount, 1)
        XCTAssertEqual(healthKitFake.fetchLatestBodyMetricsCallCount, 1)
        XCTAssertEqual(healthKitFake.fetchLastNightSleepCallCount, 1)
        XCTAssertEqual(healthKitFake.fetchRecentWorkoutsCallCount, 1)
    }
    
    // MARK: - Data Validation Tests
    
    func testGetWorkoutData_FiltersDateRange() async {
        // Arrange
        let startDate = MockDataGenerator.daysAgo(5)
        let endDate = MockDataGenerator.daysAgo(2)
        
        // Create workout data with mixed dates
        healthKitFake.mockWorkoutData = [
            MockDataGenerator.createMockWorkoutData(date: MockDataGenerator.daysAgo(10)), // Outside range
            MockDataGenerator.createMockWorkoutData(date: MockDataGenerator.daysAgo(4)),  // Inside range
            MockDataGenerator.createMockWorkoutData(date: MockDataGenerator.daysAgo(3)),  // Inside range
            MockDataGenerator.createMockWorkoutData(date: MockDataGenerator.daysAgo(1))   // Outside range
        ]
        
        // Act
        let workouts = await healthKitFake.getWorkoutData(from: startDate, to: endDate)
        
        // Assert
        XCTAssertEqual(workouts.count, 2) // Only 2 should be in range
        XCTAssertTrue(workouts.allSatisfy { workout in
            workout.startDate >= startDate && workout.startDate <= endDate
        })
    }
    
    // MARK: - Performance Tests
    
    func testFetchOperations_WithDelay() async throws {
        // Arrange
        let delay: TimeInterval = 0.1
        healthKitFake.dataFetchDelay = delay
        
        // Act
        let startTime = Date()
        _ = try await healthKitFake.fetchTodayActivityMetrics()
        let duration = Date().timeIntervalSince(startTime)
        
        // Assert
        XCTAssertGreaterThanOrEqual(duration, delay)
    }
    
    func testResetFunctionality() {
        // Arrange - Perform some operations
        let _ = healthKitFake.observeHealthKitChanges { }
        healthKitFake.refreshAuthorizationStatus()
        
        // Act
        healthKitFake.reset()
        
        // Assert - All counters should be reset
        XCTAssertEqual(healthKitFake.refreshAuthorizationStatusCallCount, 0)
        XCTAssertEqual(healthKitFake.authorizationStatus, .notDetermined)
        XCTAssertEqual(healthKitFake.savedFoodEntries.count, 0)
        XCTAssertEqual(healthKitFake.savedWorkouts.count, 0)
        XCTAssertFalse(healthKitFake.shouldThrowDataError)
        XCTAssertFalse(healthKitFake.shouldThrowAuthorizationError)
    }
    
    // MARK: - Helper Methods
    
    private func assertThrowsError(_ expression: @autoclosure () async throws -> Any) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error - test passes
        }
    }
}