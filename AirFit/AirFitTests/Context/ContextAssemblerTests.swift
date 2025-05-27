import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class ContextAssemblerTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var healthKit: MockHealthKitManager!
    var sut: ContextAssembler!

    override func setUp() async throws {
        await MainActor.run { super.setUp() }
        container = try ModelContainer.createTestContainerWithSampleData()
        context = container.mainContext
        healthKit = MockHealthKitManager()
        sut = ContextAssembler(healthKitManager: healthKit)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        healthKit = nil
        sut = nil
        await MainActor.run { super.tearDown() }
    }

    func test_assembleSnapshot_withCompleteData_shouldPopulateFields() async {
        // Arrange
        healthKit.activityResult = .success(ActivityMetrics(steps: 5000))
        healthKit.heartResult = .success(HeartHealthMetrics(restingHeartRate: 60))
        healthKit.bodyResult = .success(BodyMetrics(weight: Measurement(value: 70, unit: .kilograms)))
        let sleepSession = SleepAnalysis.SleepSession(bedtime: Date(), wakeTime: Date(), totalSleepTime: 7 * 3600, timeInBed: 8 * 3600, efficiency: 87, remTime: nil, coreTime: nil, deepTime: nil, awakeTime: nil)
        healthKit.sleepResult = .success(sleepSession)

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: context)

        // Assert
        XCTAssertEqual(snapshot.activity.steps, 5000)
        XCTAssertEqual(snapshot.heartHealth.restingHeartRate, 60)
        XCTAssertEqual(snapshot.body.weight?.value, 70)
        XCTAssertEqual(snapshot.sleep.lastNight?.efficiency, 87)
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 4)
        XCTAssertEqual(snapshot.appContext.lastMealSummary, "Breakfast, 1 item")
        XCTAssertEqual(snapshot.environment.weatherCondition, "Clear")
        healthKit.verify("fetchTodayActivityMetrics", called: 1)
        healthKit.verify("fetchHeartHealthMetrics", called: 1)
        healthKit.verify("fetchLatestBodyMetrics", called: 1)
        healthKit.verify("fetchLastNightSleep", called: 1)
    }

    func test_assembleSnapshot_withHealthKitErrors_shouldUseDefaults() async {
        // Arrange
        enum TestError: Error { case sample }
        healthKit.activityResult = .failure(TestError.sample)
        healthKit.heartResult = .failure(TestError.sample)
        healthKit.bodyResult = .failure(TestError.sample)
        healthKit.sleepResult = .failure(TestError.sample)

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: context)

        // Assert
        XCTAssertNil(snapshot.activity.steps)
        XCTAssertNil(snapshot.heartHealth.restingHeartRate)
        XCTAssertNil(snapshot.body.weight)
        XCTAssertNil(snapshot.sleep.lastNight)
        XCTAssertEqual(snapshot.subjectiveData.energyLevel, 4)
    }

    func test_assembleSnapshot_withoutDailyLog_shouldReturnEmptySubjectiveData() async throws {
        // Arrange
        // Recreate container without sample data
        container = try ModelContainer.createTestContainer()
        context = container.mainContext
        sut = ContextAssembler(healthKitManager: healthKit)

        // Act
        let snapshot = await sut.assembleSnapshot(modelContext: context)

        // Assert
        XCTAssertNil(snapshot.subjectiveData.energyLevel)
        XCTAssertNil(snapshot.appContext.lastMealSummary)
    }

    func test_concurrentAssembly_shouldReturnForAllTasks() async {
        let results = await withTaskGroup(of: HealthContextSnapshot.self) { group in
            for _ in 0..<5 {
                group.addTask { await self.sut.assembleSnapshot(modelContext: self.context) }
            }
            return await group.reduce(into: [HealthContextSnapshot]()) { $0.append($1) }
        }
        XCTAssertEqual(results.count, 5)
    }

    func test_performance_assembleSnapshot() async {
        measure {
            let expectation = self.expectation(description: "assemble")
            Task {
                _ = await self.sut.assembleSnapshot(modelContext: self.context)
                expectation.fulfill()
            }
            self.wait(for: [expectation], timeout: 1)
        }
    }
}
