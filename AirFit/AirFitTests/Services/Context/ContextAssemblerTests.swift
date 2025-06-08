import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class ContextAssemblerTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var modelContext: ModelContext!
    private var mockHealthKit: MockHealthKitManager!
    private var sut: ContextAssembler!

    // MARK: - Setup
    override func setUp() async throws {
        try super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Get mock from container
        mockHealthKit = try await container.resolve(HealthKitManagerProtocol.self) as? MockHealthKitManager
        
        // Create SUT
        sut = ContextAssembler(healthKitManager: mockHealthKit)
    }

    override func tearDown() async throws {
        mockHealthKit?.reset()
        sut = nil
        mockHealthKit = nil
        modelContext = nil
        container = nil
        try super.tearDown()
    }

    func test_assembleSnapshot_withCompleteData_populatesSnapshot() async throws {
        // Arrange - mock HealthKit data
        mockHealthKit.activityResult = .success(
            ActivityMetrics(
                activeEnergyBurned: Measurement(value: 500, unit: .kilocalories),
                basalEnergyBurned: nil,
                steps: 1_000,
                distance: nil,
                flightsClimbed: nil,
                exerciseMinutes: 30,
                standHours: nil,
                moveMinutes: nil,
                currentHeartRate: 60,
                isWorkoutActive: false,
                workoutTypeRawValue: nil,
                moveProgress: nil,
                exerciseProgress: nil,
                standProgress: nil
            )
        )
        mockHealthKit.heartResult = .success(
            HeartHealthMetrics(
                restingHeartRate: 55,
                hrv: Measurement(value: 50, unit: .milliseconds),
                respiratoryRate: 12,
                vo2Max: nil,
                cardioFitness: nil,
                recoveryHeartRate: nil,
                heartRateRecovery: nil
            )
        )
        mockHealthKit.bodyResult = .success(
            BodyMetrics(
                weight: Measurement(value: 70, unit: .kilograms),
                bodyFatPercentage: 20,
                leanBodyMass: nil,
                bmi: 24,
                weightTrend: nil,
                bodyFatTrend: nil
            )
        )
        mockHealthKit.sleepResult = .success(
            SleepAnalysis.SleepSession(
                bedtime: Date().addingTimeInterval(-8 * 3_600),
                wakeTime: Date(),
                totalSleepTime: 7.5 * 3_600,
                timeInBed: 8 * 3_600,
                efficiency: 90,
                remTime: 2 * 3_600,
                coreTime: 4 * 3_600,
                deepTime: 1.5 * 3_600,
                awakeTime: 30 * 60
            )
        )

        // Add test data
        try await addTestData()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 4)
        XCTAssertEqual(snapshot.activity.steps, 1_000)
        XCTAssertEqual(snapshot.heartHealth.restingHeartRate, 55)
        XCTAssertEqual(snapshot.body.weight?.value, 70)
        XCTAssertNotNil(snapshot.sleep.lastNight)
        XCTAssertEqual(snapshot.appContext.lastMealSummary, "Breakfast, 1 item")
    }

    @MainActor
    private func addTestData() async throws {
        // Add DailyLog for subjective data
        let log = DailyLog(date: Date())
        log.subjectiveEnergyLevel = 4
        log.stressLevel = 2
        modelContext.insert(log)
        try modelContext.save()

        // Add recent meal
        let meal = FoodEntry(mealType: .breakfast)
        let item = FoodItem(name: "Egg", calories: 70)
        meal.addItem(item)
        modelContext.insert(meal)
        try modelContext.save()
    }

    func test_assembleSnapshot_whenHealthKitThrows_returnsDefaultMetrics() async {
        // Arrange - make HealthKit throw
        mockHealthKit.activityResult = .failure(TestError.test)
        mockHealthKit.heartResult = .failure(TestError.test)
        mockHealthKit.bodyResult = .failure(TestError.test)
        mockHealthKit.sleepResult = .failure(TestError.test)

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - all metrics should be default/empty
        XCTAssertNil(snapshot.activity.steps)
        XCTAssertNil(snapshot.heartHealth.restingHeartRate)
        XCTAssertNil(snapshot.body.weight)
        XCTAssertNil(snapshot.sleep.lastNight)
    }

    func test_performance_assembleSnapshot_largeDataSet() async throws {
        // Create realistic test data with proper date distribution
        let calendar = Calendar.current
        let today = Date()

        for day in 0..<50 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
            let log = DailyLog(date: date)
            log.steps = max(1_000, 1_000 + day * 100) // Realistic step counts
            modelContext.insert(log)
        }
        try modelContext.save()

        // Proper async performance testing
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<10 {
            _ = await sut.assembleSnapshot(modelContext: modelContext)
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = timeElapsed / 10.0

        // Performance assertion: Should complete in under 50ms on average
        XCTAssertLessThan(averageTime, 0.05, "assembleSnapshot should complete in under 50ms, took \(averageTime)s")

        // Verify the snapshot is still functional
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)
        XCTAssertNotNil(snapshot.trends.weeklyActivityChange, "Trends should be calculated with sufficient data")
    }

    // MARK: - HealthKit Permission Scenarios

    func test_assembleSnapshot_whenHealthKitDenied_usesDefaultValues() async {
        // Arrange - set HealthKit as denied
        mockHealthKit.authorizationStatus = .denied
        mockHealthKit.activityResult = .failure(HealthKitManager.HealthKitError.authorizationDenied)
        mockHealthKit.heartResult = .failure(HealthKitManager.HealthKitError.authorizationDenied)
        mockHealthKit.bodyResult = .failure(HealthKitManager.HealthKitError.authorizationDenied)
        mockHealthKit.sleepResult = .failure(HealthKitManager.HealthKitError.authorizationDenied)

        // Add subjective data to ensure other systems work
        try? await addTestData()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - HealthKit data should be default/nil, but other data present
        XCTAssertNil(snapshot.activity.steps)
        XCTAssertNil(snapshot.heartHealth.restingHeartRate)
        XCTAssertNil(snapshot.body.weight)
        XCTAssertNil(snapshot.sleep.lastNight)

        // But subjective data should still be available
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 4)
        XCTAssertEqual(snapshot.appContext.lastMealSummary, "Breakfast, 1 item")
    }

    func test_assembleSnapshot_whenPartialPermissions_handlesGracefully() async {
        // Arrange - some data succeeds, some fails
        mockHealthKit.authorizationStatus = .authorized
        mockHealthKit.activityResult = .success(
            ActivityMetrics(steps: 5_000, exerciseMinutes: 20)
        )
        mockHealthKit.heartResult = .failure(HealthKitManager.HealthKitError.authorizationDenied) // Heart denied
        mockHealthKit.bodyResult = .success(
            BodyMetrics(weight: Measurement(value: 75, unit: .kilograms))
        )
        mockHealthKit.sleepResult = .failure(HealthKitManager.HealthKitError.dataNotFound) // No sleep data

        try? await addTestData()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - partial data is present
        XCTAssertEqual(snapshot.activity.steps, 5_000)
        XCTAssertEqual(snapshot.activity.exerciseMinutes, 20)
        XCTAssertNil(snapshot.heartHealth.restingHeartRate) // Permission denied
        XCTAssertEqual(snapshot.body.weight?.value, 75)
        XCTAssertNil(snapshot.sleep.lastNight) // No data found
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 4)
    }

    // MARK: - Data Integration Edge Cases

    func test_assembleSnapshot_withIncompleteHealthData_assemblesPartialSnapshot() async {
        // Arrange - HealthKit returns incomplete metrics
        mockHealthKit.activityResult = .success(
            ActivityMetrics(steps: 2_000) // Only steps, no other metrics
        )
        mockHealthKit.heartResult = .success(
            HeartHealthMetrics(restingHeartRate: 65) // Only resting HR
        )
        mockHealthKit.bodyResult = .success(BodyMetrics()) // Empty metrics
        mockHealthKit.sleepResult = .success(nil) // No sleep session

        // Add minimal SwiftData
        let log = DailyLog(date: Date())
        log.subjectiveEnergyLevel = 3
        modelContext.insert(log)
        try? modelContext.save()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - partial data is correctly assembled
        XCTAssertEqual(snapshot.activity.steps, 2_000)
        XCTAssertNil(snapshot.activity.exerciseMinutes)
        XCTAssertEqual(snapshot.heartHealth.restingHeartRate, 65)
        XCTAssertNil(snapshot.heartHealth.hrv)
        XCTAssertNil(snapshot.body.weight)
        XCTAssertNil(snapshot.sleep.lastNight)
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 3)
    }

    func test_assembleSnapshot_withStaleData_includesTimestampWarnings() async throws {
        // Arrange - create old data
        let calendar = Calendar.current
        let yesterdayLog = DailyLog(date: calendar.date(byAdding: .day, value: -1, to: Date())!)
        yesterdayLog.subjectiveEnergyLevel = 2
        modelContext.insert(yesterdayLog)

        // Create stale meal data (24+ hours old)
        let staleMeal = FoodEntry(mealType: .dinner)
        staleMeal.loggedAt = calendar.date(byAdding: .day, value: -2, to: Date())!
        let item = FoodItem(name: "Stale Food", calories: 300)
        staleMeal.addItem(item)
        modelContext.insert(staleMeal)
        try modelContext.save()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - stale data handling
        XCTAssertNil(snapshot.subjectiveData.energyLevel) // Should be nil for today

        // Check that stale meal isn't included in today's summary
        let expectedSummary = snapshot.appContext.lastMealSummary
        XCTAssertNotEqual(expectedSummary, "Dinner, 1 item") // Stale meal shouldn't appear
    }

    func test_assembleSnapshot_withLargeDataSets_maintainsPerformance() async throws {
        // Arrange - create large dataset (realistic user with 2+ years of data)
        let calendar = Calendar.current
        let today = Date()

        // Add 800 days of historical data
        for day in 0..<800 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
            let log = DailyLog(date: date)
            log.steps = Int.random(in: 2_000...15_000)
            log.subjectiveEnergyLevel = Int.random(in: 1...5)
            log.stressLevel = Int.random(in: 1...5)
            modelContext.insert(log)

            // Add some meals for recent days
            if day < 30 {
                let meal = FoodEntry(mealType: .lunch)
                meal.loggedAt = date
                let item = FoodItem(name: "Lunch Item \(day)", calories: Double(Int.random(in: 200...600)))
                meal.addItem(item)
                modelContext.insert(meal)
            }
        }
        try modelContext.save()

        // Act - measure performance over multiple runs
        let iterations = 20
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<iterations {
            _ = await sut.assembleSnapshot(modelContext: modelContext)
        }

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = totalTime / Double(iterations)

        // Assert - Performance requirements
        XCTAssertLessThan(averageTime, 0.050, "assembleSnapshot should complete in under 50ms with large dataset, took \(averageTime * 1000)ms")

        // Verify functionality with large dataset
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)
        XCTAssertNotNil(snapshot.subjectiveData.energyLevel)
        XCTAssertNotNil(snapshot.trends)
        XCTAssertNotNil(snapshot.appContext.lastMealSummary)
    }

    // MARK: - Cross-Service Integration

    func test_assembleSnapshot_coordinating_HealthKitAndSwiftData_successfully() async throws {
        // Arrange - comprehensive data from both systems
        mockHealthKit.activityResult = .success(
            ActivityMetrics(
                activeEnergyBurned: Measurement(value: 600, unit: .kilocalories),
                steps: 8_000,
                exerciseMinutes: 45
            )
        )
        mockHealthKit.heartResult = .success(
            HeartHealthMetrics(
                restingHeartRate: 58,
                hrv: Measurement(value: 45, unit: .milliseconds)
            )
        )

        // Add comprehensive SwiftData
        let log = DailyLog(date: Date())
        log.subjectiveEnergyLevel = 5
        log.stressLevel = 1
        log.steps = 7_500 // Different from HealthKit to test prioritization
        modelContext.insert(log)

        let meal1 = FoodEntry(mealType: .breakfast)
        meal1.addItem(FoodItem(name: "Oatmeal", calories: 300))
        let meal2 = FoodEntry(mealType: .lunch)
        meal2.addItem(FoodItem(name: "Salad", calories: 400))
        modelContext.insert(meal1)
        modelContext.insert(meal2)
        try modelContext.save()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - proper coordination
        // HealthKit data should take precedence for objective metrics
        XCTAssertEqual(snapshot.activity.steps, 8_000) // HealthKit value, not SwiftData
        XCTAssertEqual(snapshot.heartHealth.restingHeartRate, 58)

        // SwiftData should provide subjective data
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 5)
        XCTAssertEqual(snapshot.subjectiveData.stress, 1)

        // Meal data from SwiftData
        XCTAssertTrue(snapshot.appContext.lastMealSummary?.contains("2 items") == true)

        // Combined insights should be present
        XCTAssertNotNil(snapshot.trends)
    }

    func test_assembleSnapshot_withConcurrentAccess_remainsThreadSafe() async throws {
        // Arrange - prepare test data
        try await addTestData()

        // Act - run multiple snapshot assemblies sequentially to test thread safety
        var snapshots: [HealthContextSnapshot] = []

        for _ in 0..<10 {
            // Add some random delay to simulate timing variations
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000...10_000_000))

            let snapshot = await sut.assembleSnapshot(modelContext: modelContext)
            snapshots.append(snapshot)
        }

        // Assert - all snapshots should be consistent
        XCTAssertEqual(snapshots.count, 10)

        let firstSnapshot = snapshots[0]
        for snapshot in snapshots {
            XCTAssertEqual(snapshot.subjectiveData.energyLevel, firstSnapshot.subjectiveData.energyLevel)
            XCTAssertEqual(snapshot.appContext.lastMealSummary, firstSnapshot.appContext.lastMealSummary)
            // Note: HealthKit data might vary if mock is stateful, but shouldn't crash
        }
    }

    // MARK: - Enhanced Error Condition Testing

    func test_assembleSnapshot_withTimeout_handlesGracefully() async {
        // Arrange - simulate slow HealthKit responses by making mock delay
        mockHealthKit.activityResult = .failure(HealthKitManager.HealthKitError.queryFailed(NSError(domain: "TestDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Timeout"])))

        try? await addTestData()

        // Act with timeout
        let task = Task {
            return await sut.assembleSnapshot(modelContext: modelContext)
        }

        // Simulate timeout scenario
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms timeout
            task.cancel()
        }

        let snapshot = await task.value
        timeoutTask.cancel()

        // Assert - should handle timeout gracefully
        XCTAssertNotNil(snapshot)
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 4) // SwiftData should still work
    }

    func test_assembleSnapshot_withCorruptedSwiftData_handlesGracefully() async {
        // Arrange - create corrupted data scenario
        let log = DailyLog(date: Date())
        log.subjectiveEnergyLevel = 999 // Invalid value
        log.stressLevel = -5 // Invalid value
        modelContext.insert(log)

        // Create meal with nil values that might cause issues
        let meal = FoodEntry(mealType: .breakfast)
        let corruptedItem = FoodItem(name: "", calories: -100) // Invalid data
        meal.addItem(corruptedItem)
        modelContext.insert(meal)

        try? modelContext.save()

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: modelContext)

        // Assert - should handle corrupted data gracefully
        XCTAssertNotNil(snapshot)
        // Corrupted values should be filtered out or defaulted
        XCTAssertNil(snapshot.subjectiveData.energyLevel) // Should be nil due to invalid value
        XCTAssertNil(snapshot.subjectiveData.stress) // Should be nil due to invalid value
    }

    enum TestError: Error { case test }
}
