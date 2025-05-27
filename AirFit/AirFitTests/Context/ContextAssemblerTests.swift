import XCTest
import SwiftData
@testable import AirFit

final class ContextAssemblerTests: XCTestCase {
    var modelContainer: ModelContainer!
    var context: ModelContext!
    var mockHealthKit: MockHealthKitManager!
    var sut: ContextAssembler!

    @MainActor
    override func setUp() async throws {
        modelContainer = try ModelContainer.createTestContainer()
        context = modelContainer.mainContext
        mockHealthKit = MockHealthKitManager()
        sut = ContextAssembler(healthKitManager: mockHealthKit)
    }

    @MainActor
    override func tearDown() async throws {
        sut = nil
        mockHealthKit = nil
        context = nil
        modelContainer = nil
    }

    @MainActor
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
                workoutType: nil,
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
        let snapshot = await sut.assembleSnapshot(modelContext: context)

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
        context.insert(log)
        try context.save()

        // Add recent meal
        let meal = FoodEntry(mealType: .breakfast)
        let item = FoodItem(name: "Egg", calories: 70)
        meal.addItem(item)
        context.insert(meal)
        try context.save()
    }

    @MainActor
    func test_assembleSnapshot_whenHealthKitThrows_returnsDefaultMetrics() async {
        // Arrange - make HealthKit throw
        mockHealthKit.activityResult = .failure(TestError.test)
        mockHealthKit.heartResult = .failure(TestError.test)
        mockHealthKit.bodyResult = .failure(TestError.test)
        mockHealthKit.sleepResult = .failure(TestError.test)

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: context)

        // Assert - all metrics should be default/empty
        XCTAssertNil(snapshot.activity.steps)
        XCTAssertNil(snapshot.heartHealth.restingHeartRate)
        XCTAssertNil(snapshot.body.weight)
        XCTAssertNil(snapshot.sleep.lastNight)
    }

    @MainActor
    func test_performance_assembleSnapshot_largeDataSet() async throws {
        // Create realistic test data with proper date distribution
        let calendar = Calendar.current
        let today = Date()

        for day in 0..<50 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
            let log = DailyLog(date: date)
            log.steps = max(1_000, 1_000 + day * 100) // Realistic step counts
            context.insert(log)
        }
        try context.save()

        // Proper async performance testing
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<10 {
            _ = await sut.assembleSnapshot(modelContext: context)
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = timeElapsed / 10.0

        // Performance assertion: Should complete in under 50ms on average
        XCTAssertLessThan(averageTime, 0.05, "assembleSnapshot should complete in under 50ms, took \(averageTime)s")

        // Verify the snapshot is still functional
        let snapshot = await sut.assembleSnapshot(modelContext: context)
        XCTAssertNotNil(snapshot.trends.weeklyActivityChange, "Trends should be calculated with sufficient data")
    }

    enum TestError: Error { case test }
}
