import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class WorkoutViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var user: User!
    var mockCoach: MockCoachEngine!
    var mockHealth: MockHealthKitManager!
    var sut: WorkoutViewModel!

    override func setUp() async throws {
        container = try ModelContainer.createTestContainer()
        context = container.mainContext
        user = User(name: "Tester")
        context.insert(user)
        try context.save()
        mockCoach = MockCoachEngine()
        mockHealth = MockHealthKitManager()
        sut = WorkoutViewModel(
            modelContext: context,
            user: user,
            coachEngine: mockCoach,
            healthKitManager: mockHealth
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockCoach = nil
        mockHealth = nil
        user = nil
        context = nil
        container = nil
    }

    func test_loadWorkouts_fetchesUserWorkouts() async throws {
        let w1 = Workout(name: "W1", user: user)
        w1.completedDate = Date()
        let w2 = Workout(name: "W2", user: user)
        w2.completedDate = Date().addingTimeInterval(-3600)
        context.insert(w1)
        context.insert(w2)
        try context.save()

        await sut.loadWorkouts()
        XCTAssertEqual(sut.workouts.count, 2)
        XCTAssertEqual(sut.workouts.first?.id, w1.id)
    }

    func test_processReceivedWorkout_createsWorkout() async throws {
        let builder = WorkoutBuilderData(
            id: UUID(),
            workoutType: 0,
            startTime: Date(),
            endTime: Date().addingTimeInterval(60),
            exercises: [],
            totalCalories: 100,
            totalDistance: 0,
            duration: 60
        )
        await sut.processReceivedWorkout(data: builder)
        let fetched = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(fetched.count, 1)
    }

    func test_generateAIAnalysis_updatesSummary() async throws {
        let workout = Workout(name: "Test", user: user)
        workout.completedDate = Date()
        context.insert(workout)
        try context.save()
        mockCoach.mockAnalysis = "Well done"

        await sut.generateAIAnalysis(for: workout)
        XCTAssertEqual(sut.aiWorkoutSummary, "Well done")
        XCTAssertTrue(mockCoach.didGenerateAnalysis)
    }

    func test_calculateWeeklyStats_countsWorkouts() async throws {
        let today = Date()
        let w1 = Workout(name: "A", user: user)
        w1.completedDate = today
        w1.durationSeconds = 60
        w1.caloriesBurned = 50
        let w2 = Workout(name: "B", user: user)
        w2.completedDate = today.addingTimeInterval(-86400)
        w2.durationSeconds = 30
        w2.caloriesBurned = 40
        context.insert(w1)
        context.insert(w2)
        try context.save()

        await sut.loadWorkouts()
        XCTAssertEqual(sut.weeklyStats.totalWorkouts, 2)
        XCTAssertEqual(sut.weeklyStats.totalCalories, 90)
    }
}
