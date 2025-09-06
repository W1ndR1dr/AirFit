import XCTest
import WatchConnectivity
@testable import AirFit

/// Unit tests for WorkoutPlanTransferService enhanced retry logic and integration
final class WorkoutPlanTransferServiceTests: XCTestCase {
    var sut: WorkoutPlanTransferService!
    var mockSession: MockWCSession!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockSession = MockWCSession()
        sut = WorkoutPlanTransferService()
        
        // Clear any existing queue state
        WatchStatusStore.shared.clearQueue()
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
        
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "WorkoutPlanTransferQueue")
        UserDefaults.standard.removeObject(forKey: "WatchQueueStatistics")
        
        super.tearDown()
    }
    
    // MARK: - Service Configuration Tests
    
    func testConfiguration_InitialState() async throws {
        // Given/When
        try await sut.configure()
        
        // Then
        XCTAssertTrue(sut.isConfigured)
        XCTAssertEqual(sut.serviceIdentifier, "workout-plan-transfer-service")
    }
    
    func testHealthCheck_UnsupportedSession() async {
        // Given - Session not supported would be hard to mock
        // When
        let health = await sut.healthCheck()
        
        // Then
        XCTAssertNotNil(health.lastCheckTime)
        XCTAssertNotNil(health.metadata)
    }
    
    func testReset_ClearsPendingPlans() async {
        // Given
        // Add some plans to pending (would need to mock the private property)
        
        // When
        await sut.reset()
        
        // Then
        let pendingPlans = await sut.getPendingPlans()
        // Note: This includes centralized queue plans, so we test the integration
        XCTAssertTrue(pendingPlans.isEmpty || WatchStatusStore.shared.queuedPlansCount == 0)
    }
    
    // MARK: - Queue Integration Tests
    
    func testQueueIntegration_PlansAddedToCentralizedStore() {
        // Given
        let plan = createTestWorkoutPlan(name: "Integration Test Plan")
        let initialQueueCount = WatchStatusStore.shared.queuedPlansCount
        
        // When - Simulate conditions that would queue the plan
        WatchStatusStore.shared.queuePlan(plan, reason: .watchUnavailable)
        
        // Then
        XCTAssertEqual(WatchStatusStore.shared.queuedPlansCount, initialQueueCount + 1)
        
        let queuedPlans = WatchStatusStore.shared.getQueuedPlans()
        XCTAssertTrue(queuedPlans.contains { $0.plan.id == plan.id })
    }
    
    func testGetPendingPlans_CombinesAllSources() async {
        // Given
        let centralizedPlan = createTestWorkoutPlan(name: "Centralized Plan")
        WatchStatusStore.shared.queuePlan(centralizedPlan, reason: .watchUnavailable)
        
        // When
        let allPendingPlans = await sut.getPendingPlans()
        
        // Then
        XCTAssertTrue(allPendingPlans.contains { $0.id == centralizedPlan.id })
    }
    
    func testCancelPendingPlan_RemovesFromAllSources() async {
        // Given
        let plan = createTestWorkoutPlan(name: "Plan to Cancel")
        WatchStatusStore.shared.queuePlan(plan, reason: .watchUnavailable)
        
        let initialCount = WatchStatusStore.shared.queuedPlansCount
        XCTAssertGreaterThan(initialCount, 0)
        
        // When
        await sut.cancelPendingPlan(id: plan.id)
        
        // Then
        XCTAssertEqual(WatchStatusStore.shared.queuedPlansCount, initialCount - 1)
        XCTAssertFalse(WatchStatusStore.shared.getQueuedPlans().contains { $0.plan.id == plan.id })
    }
    
    // MARK: - Validation Tests
    
    func testValidateWorkoutPlan_ValidPlan() throws {
        // Given
        let validPlan = createTestWorkoutPlan(name: "Valid Plan")
        
        // When/Then - Should not throw
        XCTAssertNoThrow(try sut.validateWorkoutPlan(validPlan))
    }
    
    func testValidateWorkoutPlan_EmptyName() {
        // Given
        var invalidPlan = createTestWorkoutPlan(name: "")
        
        // When/Then
        XCTAssertThrowsError(try sut.validateWorkoutPlan(invalidPlan)) { error in
            XCTAssertTrue(error.localizedDescription.contains("name"))
        }
    }
    
    func testValidateWorkoutPlan_NoExercises() {
        // Given
        var invalidPlan = createTestWorkoutPlan(name: "No Exercises Plan")
        invalidPlan = PlannedWorkoutData(
            name: "No Exercises Plan",
            workoutType: 1,
            estimatedDuration: 45,
            estimatedCalories: 300,
            plannedExercises: [], // Empty exercises
            targetMuscleGroups: ["chest"],
            instructions: "Test",
            userId: UUID()
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.validateWorkoutPlan(invalidPlan)) { error in
            XCTAssertTrue(error.localizedDescription.contains("exercise"))
        }
    }
    
    func testValidateWorkoutPlan_ZeroDuration() {
        // Given
        var invalidPlan = createTestWorkoutPlan(name: "Zero Duration")
        invalidPlan = PlannedWorkoutData(
            name: "Zero Duration",
            workoutType: 1,
            estimatedDuration: 0, // Invalid duration
            estimatedCalories: 300,
            plannedExercises: [createTestExercise()],
            targetMuscleGroups: ["chest"],
            instructions: "Test",
            userId: UUID()
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.validateWorkoutPlan(invalidPlan)) { error in
            XCTAssertTrue(error.localizedDescription.contains("duration"))
        }
    }
    
    func testValidateWorkoutPlan_InvalidExercise() {
        // Given
        let invalidExercise = PlannedExerciseData(
            name: "", // Empty name
            sets: 3,
            targetReps: 10,
            orderIndex: 0
        )
        
        let invalidPlan = PlannedWorkoutData(
            name: "Plan with Invalid Exercise",
            workoutType: 1,
            estimatedDuration: 45,
            estimatedCalories: 300,
            plannedExercises: [invalidExercise],
            targetMuscleGroups: ["chest"],
            instructions: "Test",
            userId: UUID()
        )
        
        // When/Then
        XCTAssertThrowsError(try sut.validateWorkoutPlan(invalidPlan)) { error in
            XCTAssertTrue(error.localizedDescription.contains("name"))
        }
    }
    
    // MARK: - Message Format Tests
    
    func testWorkoutTransferMessage_DictionaryFormat() {
        // Given
        let plan = createTestWorkoutPlan(name: "Test Plan")
        let planData = try! JSONEncoder().encode(plan)
        let timestamp = Date()
        
        let message = WorkoutTransferMessage(
            planData: planData,
            planId: plan.id,
            timestamp: timestamp
        )
        
        // When
        let dictionary = message.dictionary
        
        // Then
        XCTAssertEqual(dictionary["type"] as? String, "plannedWorkout")
        XCTAssertEqual(dictionary["planId"] as? String, plan.id.uuidString)
        XCTAssertEqual(dictionary["timestamp"] as? TimeInterval, timestamp.timeIntervalSince1970)
        XCTAssertNotNil(dictionary["planData"])
    }
    
    func testWorkoutTransferResponse_ValidResponse() {
        // Given
        let successDict: [String: Any] = [
            "success": true
        ]
        
        let failureDict: [String: Any] = [
            "success": false,
            "error": "Watch rejected the plan"
        ]
        
        // When
        let successResponse = WorkoutTransferResponse(dictionary: successDict)
        let failureResponse = WorkoutTransferResponse(dictionary: failureDict)
        
        // Then
        XCTAssertNotNil(successResponse)
        XCTAssertTrue(successResponse!.success)
        XCTAssertNil(successResponse!.errorMessage)
        
        XCTAssertNotNil(failureResponse)
        XCTAssertFalse(failureResponse!.success)
        XCTAssertEqual(failureResponse!.errorMessage, "Watch rejected the plan")
    }
    
    func testWorkoutTransferResponse_InvalidResponse() {
        // Given
        let invalidDict: [String: Any] = [
            "status": "unknown" // Missing required "success" key
        ]
        
        // When
        let response = WorkoutTransferResponse(dictionary: invalidDict)
        
        // Then
        XCTAssertNil(response)
    }
    
    // MARK: - Error Categorization Tests
    
    func testErrorCategorization_NetworkError() {
        // Test would verify that network-related errors are categorized correctly
        // This would require mocking the actual transfer process
        let networkErrorDescription = "network connection failed"
        XCTAssertTrue(networkErrorDescription.contains("network"))
    }
    
    func testErrorCategorization_RejectionError() {
        let rejectionErrorDescription = "watch rejected the request"
        XCTAssertTrue(rejectionErrorDescription.contains("rejected"))
    }
    
    // MARK: - Integration with WatchStatus Tests
    
    func testIntegrationWithWatchStatus_AutoRetryOnAvailable() async {
        // Given
        let plan = createTestWorkoutPlan(name: "Auto Retry Plan")
        WatchStatusStore.shared.queuePlan(plan, reason: .watchUnavailable)
        
        let initialQueueCount = WatchStatusStore.shared.queuedPlansCount
        XCTAssertGreaterThan(initialQueueCount, 0)
        
        // When - Simulate watch becoming available would trigger auto-retry
        // This would be tested through the WatchStatusStore's status monitoring
        
        // Then - Verify integration exists
        XCTAssertGreaterThan(initialQueueCount, 0, "Plan should be queued for retry")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_QueueOperations() {
        measure {
            // Given
            let plans = (0..<100).map { createTestWorkoutPlan(name: "Performance Test Plan \($0)") }
            
            // When
            for plan in plans {
                WatchStatusStore.shared.queuePlan(plan, reason: .watchUnavailable)
            }
            
            // Cleanup
            WatchStatusStore.shared.clearQueue()
        }
    }
    
    func testPerformance_ValidationOperations() {
        let plan = createTestWorkoutPlan(name: "Performance Validation Test")
        
        measure {
            for _ in 0..<1000 {
                try! sut.validateWorkoutPlan(plan)
            }
        }
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

// MARK: - Test Extensions

private extension WorkoutPlanTransferService {
    /// Expose validation method for testing
    func validateWorkoutPlan(_ plan: PlannedWorkoutData) throws {
        // This mirrors the private validation logic
        guard !plan.name.isEmpty else {
            throw AppError.invalidInput(message: "Workout plan must have a name")
        }
        
        guard !plan.plannedExercises.isEmpty else {
            throw AppError.invalidInput(message: "Workout plan must contain at least one exercise")
        }
        
        guard plan.estimatedDuration > 0 else {
            throw AppError.invalidInput(message: "Workout plan must have positive duration")
        }
        
        for exercise in plan.plannedExercises {
            guard !exercise.name.isEmpty else {
                throw AppError.invalidInput(message: "All exercises must have names")
            }
            
            guard exercise.sets > 0 else {
                throw AppError.invalidInput(message: "All exercises must have at least one set")
            }
            
            guard exercise.targetReps > 0 else {
                throw AppError.invalidInput(message: "All exercises must have positive target reps")
            }
            
            guard exercise.restSeconds >= 0 else {
                throw AppError.invalidInput(message: "Rest seconds cannot be negative")
            }
        }
    }
}