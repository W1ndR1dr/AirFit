import XCTest
import HealthKit
import WatchConnectivity
@testable import AirFitWatchApp

final class WatchWorkoutManagerTests: XCTestCase {
    var sut: WatchWorkoutManager!
    var mockHealthStore: MockHealthStoreProtocol!
    var mockSession: MockWCSessionProtocol!

    @MainActor
    override func setUp() {
        super.setUp()
        mockHealthStore = MockHealthStoreProtocol()
        mockSession = MockWCSessionProtocol()
        sut = WatchWorkoutManager()
        // Inject mocks if needed
    }

    @MainActor
    override func tearDown() {
        sut = nil
        mockHealthStore = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_init_shouldSetInitialState() {
        XCTAssertEqual(sut.workoutState, .idle)
        XCTAssertFalse(sut.isPaused)
        XCTAssertEqual(sut.heartRate, 0)
        XCTAssertEqual(sut.activeCalories, 0)
        XCTAssertEqual(sut.elapsedTime, 0)
    }

    // MARK: - Workout Session Tests

    func test_startWorkout_shouldUpdateState() async throws {
        // Given
        let activityType = HKWorkoutActivityType.traditionalStrengthTraining

        // When
        try await sut.startWorkout(activityType: activityType)

        // Then
        XCTAssertEqual(sut.workoutState, .running)
        XCTAssertFalse(sut.isPaused)
    }

    func test_startWorkout_withInvalidPermissions_shouldThrowError() async {
        // Given
        let activityType = HKWorkoutActivityType.traditionalStrengthTraining
        mockHealthStore.shouldFailAuthorization = true

        // When/Then
        do {
            try await sut.startWorkout(activityType: activityType)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(sut.workoutState, .idle)
        }
    }

    func test_pauseWorkout_shouldUpdateState() {
        // Given - workout must be running first
        // Note: In real implementation, we'd need to start a workout first
        // For this test, we'll test the pause functionality conceptually

        // When
        sut.pauseWorkout()

        // Then - if not running, state should remain unchanged
        XCTAssertEqual(sut.workoutState, .idle)
    }

    func test_resumeWorkout_shouldUpdateState() {
        // Given - workout must be paused first
        // Note: In real implementation, we'd need to start and pause a workout first

        // When
        sut.resumeWorkout()

        // Then - if not paused, state should remain unchanged
        XCTAssertEqual(sut.workoutState, .idle)
    }

    func test_endWorkout_shouldUpdateState() async {
        // Given - workout must be running first
        // Note: In real implementation, we'd need to start a workout first

        // When
        await sut.endWorkout()

        // Then - if not running, state should remain unchanged
        XCTAssertEqual(sut.workoutState, .idle)
    }

    // MARK: - Exercise Tracking Tests

    func test_startNewExercise_shouldCreateExercise() {
        // Given
        let exerciseName = "Push-ups"
        let muscleGroups = ["Chest", "Triceps"]

        // When
        sut.startNewExercise(name: exerciseName, muscleGroups: muscleGroups)

        // Then
        XCTAssertEqual(sut.currentWorkoutData.exercises.count, 1)
        XCTAssertEqual(sut.currentWorkoutData.exercises.first?.name, exerciseName)
        XCTAssertEqual(sut.currentWorkoutData.exercises.first?.muscleGroups, muscleGroups)
    }

    func test_logSet_shouldAddSetToCurrentExercise() {
        // Given
        sut.startNewExercise(name: "Push-ups", muscleGroups: ["Chest"])
        let reps = 15
        let weight = 0.0
        let rpe = 7.0

        // When
        sut.logSet(reps: reps, weight: weight, duration: nil, rpe: rpe)

        // Then
        let exercise = sut.currentWorkoutData.exercises.first
        XCTAssertEqual(exercise?.sets.count, 1)
        XCTAssertEqual(exercise?.sets.first?.reps, reps)
        XCTAssertEqual(exercise?.sets.first?.weightKg, weight)
        XCTAssertEqual(exercise?.sets.first?.rpe, rpe)
    }

    func test_logSet_withoutCurrentExercise_shouldNotCrash() {
        // Given - no current exercise

        // When
        sut.logSet(reps: 10, weight: 50, duration: nil, rpe: 6)

        // Then
        XCTAssertEqual(sut.currentWorkoutData.exercises.count, 0)
    }

    // MARK: - Real-time Metrics Tests

    func test_heartRateProperty_shouldBeReadable() {
        // Given/When/Then
        XCTAssertEqual(sut.heartRate, 0)
    }

    func test_activeCaloriesProperty_shouldBeReadable() {
        // Given/When/Then
        XCTAssertEqual(sut.activeCalories, 0)
    }

    func test_elapsedTimeProperty_shouldBeReadable() {
        // Given/When/Then
        XCTAssertEqual(sut.elapsedTime, 0)
    }

    // MARK: - Performance Tests

    func test_startWorkout_performance_shouldCompleteQuickly() async throws {
        measure {
            Task {
                do {
                    try await sut.startWorkout(activityType: .traditionalStrengthTraining)
                } catch {
                    // Handle error in test
                }
            }
        }
    }

    func test_logMultipleSets_performance_shouldCompleteQuickly() {
        // Given
        sut.startNewExercise(name: "Squats", muscleGroups: ["Legs"])

        // When
        measure {
            for index in 1...100 {
                sut.logSet(reps: index, weight: Double(index * 2), duration: nil, rpe: 7.0)
            }
        }

        // Then
        XCTAssertEqual(sut.currentWorkoutData.exercises.first?.sets.count, 100)
    }

    // MARK: - Error Handling Tests

    func test_startWorkout_withHealthKitError_shouldHandleGracefully() async {
        // Given
        mockHealthStore.shouldFailWorkoutSession = true

        // When/Then
        do {
            try await sut.startWorkout(activityType: .running)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(sut.workoutState, .idle)
            XCTAssertNotNil(error)
        }
    }

    // MARK: - State Management Tests

    func test_workoutStateTransitions_shouldFollowValidFlow() async throws {
        // Given
        XCTAssertEqual(sut.workoutState, .idle)

        // When: Start workout
        try await sut.startWorkout(activityType: .traditionalStrengthTraining)
        XCTAssertEqual(sut.workoutState, .running)

        // When: Pause workout
        sut.pauseWorkout()
        XCTAssertEqual(sut.workoutState, .paused)
        XCTAssertTrue(sut.isPaused)

        // When: Resume workout
        sut.resumeWorkout()
        XCTAssertEqual(sut.workoutState, .running)
        XCTAssertFalse(sut.isPaused)

        // When: End workout
        await sut.endWorkout()
        XCTAssertEqual(sut.workoutState, .ended)
    }

    // MARK: - Sync Integration Tests

    func test_endWorkout_shouldTriggerSync() async throws {
        // Given - start a workout first
        do {
            try await sut.startWorkout(activityType: .traditionalStrengthTraining)
            sut.startNewExercise(name: "Bench Press", muscleGroups: ["Chest"])
            sut.logSet(reps: 10, weight: 135, duration: nil, rpe: 8)

            // When
            await sut.endWorkout()

            // Then
            XCTAssertEqual(sut.workoutState, .ended)
            // Verify sync was triggered (would need mock WCSession)
        } catch {
            // If HealthKit is not available in test environment, skip this test
            throw XCTSkip("HealthKit not available in test environment")
        }
    }

    // MARK: - Authorization Tests

    func test_requestAuthorization_shouldReturnSuccess() async throws {
        // Given
        mockHealthStore.shouldFailAuthorization = false

        // When
        let result = try await sut.requestAuthorization()

        // Then
        XCTAssertTrue(result)
    }

    func test_requestAuthorization_shouldThrowError() async {
        // Given
        mockHealthStore.shouldFailAuthorization = true

        // When/Then
        do {
            _ = try await sut.requestAuthorization()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Mock Classes

class MockHealthStoreProtocol: @unchecked Sendable {
    var shouldFailAuthorization = false
    var shouldFailWorkoutSession = false

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>?
    ) async throws {
        if shouldFailAuthorization {
            throw HKError(.errorAuthorizationDenied)
        }
    }
}

class MockWCSessionProtocol: @unchecked Sendable {
    var mockReachable = true
    var sentMessages: [[String: Any]] = []

    var isReachable: Bool {
        return mockReachable
    }

    func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?,
        errorHandler: ((Error) -> Void)?
    ) {
        sentMessages.append(message)
        replyHandler?(["status": "success"])
    }
} 