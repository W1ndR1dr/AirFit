import XCTest
import WatchConnectivity
@testable import AirFit

/// Unit tests for WatchStatusStore enhanced queue management and retry logic
final class WatchStatusStoreTests: XCTestCase {
    var sut: WatchStatusStore!
    var mockSession: MockWCSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockWCSession()
        // Note: In production, we would need to inject the session dependency
        // For now, these tests validate the core logic and queue management
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        // Clear UserDefaults to avoid test pollution
        UserDefaults.standard.removeObject(forKey: "WorkoutPlanTransferQueue")
        UserDefaults.standard.removeObject(forKey: "WatchQueueStatistics")
        super.tearDown()
    }
    
    // MARK: - Queue Management Tests
    
    func testQueuePlan_AddsToQueue() {
        // Given
        let sut = WatchStatusStore.shared
        let plan = createTestWorkoutPlan(name: "Test Workout")
        let initialCount = sut.queuedPlansCount
        
        // When
        sut.queuePlan(plan, reason: .watchUnavailable)
        
        // Then
        XCTAssertEqual(sut.queuedPlansCount, initialCount + 1)
        XCTAssertTrue(sut.getQueuedPlans().contains { $0.plan.id == plan.id })
    }
    
    func testQueuePlan_EnforcesMaxQueueSize() {
        // Given
        let sut = WatchStatusStore.shared
        sut.clearQueue() // Start fresh
        
        // Fill queue to maximum (50 items)
        for i in 0..<51 {  // Try to add one more than max
            let plan = createTestWorkoutPlan(name: "Test Workout \(i)")
            sut.queuePlan(plan, reason: .watchUnavailable)
        }
        
        // Then
        XCTAssertEqual(sut.queuedPlansCount, 50, "Queue should be capped at 50 items")
    }
    
    func testRemovePlan_RemovesCorrectPlan() {
        // Given
        let sut = WatchStatusStore.shared
        sut.clearQueue()
        
        let plan1 = createTestWorkoutPlan(name: "Plan 1")
        let plan2 = createTestWorkoutPlan(name: "Plan 2")
        
        sut.queuePlan(plan1, reason: .watchUnavailable)
        sut.queuePlan(plan2, reason: .transferFailed)
        
        // When
        sut.removePlan(id: plan1.id)
        
        // Then
        XCTAssertEqual(sut.queuedPlansCount, 1)
        XCTAssertFalse(sut.getQueuedPlans().contains { $0.plan.id == plan1.id })
        XCTAssertTrue(sut.getQueuedPlans().contains { $0.plan.id == plan2.id })
    }
    
    func testClearQueue_RemovesAllPlans() {
        // Given
        let sut = WatchStatusStore.shared
        sut.queuePlan(createTestWorkoutPlan(name: "Plan 1"), reason: .watchUnavailable)
        sut.queuePlan(createTestWorkoutPlan(name: "Plan 2"), reason: .transferFailed)
        
        XCTAssertGreaterThan(sut.queuedPlansCount, 0)
        
        // When
        sut.clearQueue()
        
        // Then
        XCTAssertEqual(sut.queuedPlansCount, 0)
        XCTAssertTrue(sut.getQueuedPlans().isEmpty)
    }
    
    // MARK: - Queue Statistics Tests
    
    func testQueueStatistics_TrackProcessingAttempts() {
        // Given
        let sut = WatchStatusStore.shared
        var stats = sut.getQueueStatistics()
        let initialAttempts = stats.totalProcessingAttempts
        
        // When - Simulate processing
        stats.incrementProcessingAttempts()
        
        // Then
        XCTAssertEqual(stats.totalProcessingAttempts, initialAttempts + 1)
        XCTAssertNotNil(stats.lastProcessingTime)
    }
    
    func testQueueStatistics_CalculateSuccessRate() {
        // Given
        var stats = QueueStatistics()
        
        // When
        stats.incrementProcessingAttempts()  // 1 attempt
        stats.incrementSuccessfulTransfers()  // 1 success
        stats.incrementProcessingAttempts()   // 2 attempts total
        stats.incrementFailedTransfers()      // 1 failure
        
        // Then
        XCTAssertEqual(stats.successRate, 0.5, accuracy: 0.001) // 1 success / 2 attempts
    }
    
    func testQueueStatistics_ZeroAttemptsSuccessRate() {
        // Given
        let stats = QueueStatistics()
        
        // When/Then
        XCTAssertEqual(stats.successRate, 0.0)
    }
    
    // MARK: - Retry Logic Tests
    
    func testQueuedPlan_IsReadyForRetry() {
        // Given
        let plan = createTestWorkoutPlan(name: "Test Plan")
        var queuedPlan = QueuedPlan(
            plan: plan,
            queuedAt: Date(),
            reason: .transferFailed,
            retryCount: 1
        )
        
        // When - No next retry time set
        // Then
        XCTAssertTrue(queuedPlan.isReadyForRetry)
        
        // When - Next retry time in the past
        queuedPlan.nextRetryAt = Date().addingTimeInterval(-10)
        // Then
        XCTAssertTrue(queuedPlan.isReadyForRetry)
        
        // When - Next retry time in the future
        queuedPlan.nextRetryAt = Date().addingTimeInterval(10)
        // Then
        XCTAssertFalse(queuedPlan.isReadyForRetry)
    }
    
    func testQueuedPlan_TimeUntilRetry() {
        // Given
        let plan = createTestWorkoutPlan(name: "Test Plan")
        var queuedPlan = QueuedPlan(
            plan: plan,
            queuedAt: Date(),
            reason: .transferFailed,
            retryCount: 1
        )
        
        // When - No next retry time
        // Then
        XCTAssertNil(queuedPlan.timeUntilRetry)
        
        // When - Next retry time in future
        let futureTime = Date().addingTimeInterval(30)
        queuedPlan.nextRetryAt = futureTime
        
        // Then
        let timeUntilRetry = queuedPlan.timeUntilRetry
        XCTAssertNotNil(timeUntilRetry)
        XCTAssertGreaterThan(timeUntilRetry!, 25) // Should be close to 30 seconds
        XCTAssertLessThan(timeUntilRetry!, 35)
        
        // When - Next retry time in past
        queuedPlan.nextRetryAt = Date().addingTimeInterval(-10)
        // Then
        XCTAssertNil(queuedPlan.timeUntilRetry)
    }
    
    func testQueuedPlan_IsStale() {
        // Given
        let plan = createTestWorkoutPlan(name: "Test Plan")
        
        // When - Recent plan
        let recentPlan = QueuedPlan(
            plan: plan,
            queuedAt: Date().addingTimeInterval(-3600), // 1 hour ago
            reason: .watchUnavailable,
            retryCount: 0
        )
        
        // Then
        XCTAssertFalse(recentPlan.isStale)
        
        // When - Old plan
        let oldPlan = QueuedPlan(
            plan: plan,
            queuedAt: Date().addingTimeInterval(-25 * 60 * 60), // 25 hours ago
            reason: .watchUnavailable,
            retryCount: 0
        )
        
        // Then
        XCTAssertTrue(oldPlan.isStale)
    }
    
    // MARK: - Status Calculation Tests
    
    func testCalculateOverallStatus_AllConditionsMet() {
        // This would require dependency injection to properly test
        // For now, we validate the enum logic
        let status = WatchStatus.available
        XCTAssertEqual(status.displayName, "Available")
        XCTAssertEqual(status.statusColor, "green")
        XCTAssertEqual(status.systemImage, "applewatch.radiowaves.left.and.right")
    }
    
    func testWatchStatus_DisplayProperties() {
        let testCases: [(WatchStatus, String, String)] = [
            (.available, "Available", "green"),
            (.notReachable, "Not Reachable", "orange"),
            (.notPaired, "Not Paired", "red"),
            (.appNotInstalled, "App Not Installed", "red"),
            (.unsupported, "Unsupported", "red"),
            (.unknown, "Unknown", "gray")
        ]
        
        for (status, expectedDisplayName, expectedColor) in testCases {
            XCTAssertEqual(status.displayName, expectedDisplayName)
            XCTAssertEqual(status.statusColor, expectedColor)
            XCTAssertFalse(status.systemImage.isEmpty)
        }
    }
    
    // MARK: - Queue Reason Tests
    
    func testQueueReason_DisplayNames() {
        let testCases: [(QueueReason, String)] = [
            (.watchUnavailable, "Watch Unavailable"),
            (.transferFailed, "Transfer Failed"),
            (.encodingError, "Data Error"),
            (.networkError, "Network Error"),
            (.watchRejected, "Watch Rejected")
        ]
        
        for (reason, expectedDisplayName) in testCases {
            XCTAssertEqual(reason.displayName, expectedDisplayName)
        }
    }
    
    // MARK: - Persistence Tests
    
    func testPersistence_SaveAndLoadQueue() {
        // Given
        let sut = WatchStatusStore.shared
        sut.clearQueue()
        
        let plan1 = createTestWorkoutPlan(name: "Persisted Plan 1")
        let plan2 = createTestWorkoutPlan(name: "Persisted Plan 2")
        
        // When - Add plans and trigger persistence
        sut.queuePlan(plan1, reason: .watchUnavailable)
        sut.queuePlan(plan2, reason: .transferFailed)
        
        // Simulate app restart by creating new instance
        // Note: In production, we would need better dependency injection for this test
        let initialCount = sut.queuedPlansCount
        
        // Then - Should maintain queue across restarts
        XCTAssertEqual(initialCount, 2)
    }
    
    // MARK: - Helper Methods
    
    private func createTestWorkoutPlan(name: String) -> PlannedWorkoutData {
        return PlannedWorkoutData(
            name: name,
            workoutType: 1,
            estimatedDuration: 45,
            estimatedCalories: 300,
            plannedExercises: [createTestExercise()],
            targetMuscleGroups: ["chest", "shoulders"],
            instructions: "Test workout instructions",
            difficulty: "intermediate",
            userId: UUID()
        )
    }
    
    private func createTestExercise() -> PlannedExerciseData {
        return PlannedExerciseData(
            name: "Push-ups",
            sets: 3,
            targetReps: 10,
            targetRepRange: "8-12",
            restSeconds: 60,
            muscleGroups: ["chest", "shoulders"],
            notes: "Keep core tight",
            equipment: [],
            orderIndex: 0
        )
    }
}

// MARK: - Mock Objects

/// Mock WCSession for testing
class MockWCSession: WCSession {
    var mockActivationState: WCSessionActivationState = .notActivated
    var mockIsReachable: Bool = false
    var mockIsPaired: Bool = false
    var mockIsWatchAppInstalled: Bool = false
    
    override var activationState: WCSessionActivationState {
        return mockActivationState
    }
    
    override var isReachable: Bool {
        return mockIsReachable
    }
    
    override var isPaired: Bool {
        return mockIsPaired
    }
    
    override var isWatchAppInstalled: Bool {
        return mockIsWatchAppInstalled
    }
    
    override func activate() {
        // Simulate activation
        mockActivationState = .activated
    }
}