import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class AIWorkoutServiceTests: XCTestCase {
    // MARK: - Properties
    private var container: DIContainer!
    private var sut: AIWorkoutService!
    private var mockWorkoutService: MockWorkoutService!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container
        container = try await DITestHelper.createTestContainer()
        
        // Get model context from container
        let modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = modelContainer.mainContext
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        testUser.weight = 70 // kg
        testUser.height = 175 // cm
        testUser.fitnessLevel = "intermediate"
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Get mock from container
        mockWorkoutService = try await container.resolve(WorkoutServiceProtocol.self) as? MockWorkoutService
        XCTAssertNotNil(mockWorkoutService, "Expected MockWorkoutService from test container")
        
        // Create service with injected dependencies
        sut = AIWorkoutService(workoutService: mockWorkoutService)
    }
    
    override func tearDown() async throws {
        mockWorkoutService?.reset()
        sut = nil
        mockWorkoutService = nil
        modelContext = nil
        testUser = nil
        container = nil
        try await super.tearDown()
    }
    
    // MARK: - Generate Plan Tests
    
    func test_generatePlan_withBasicParameters_returnsValidPlan() async throws {
        // Arrange
        let goal = "strength"
        let duration = 45
        let intensity = "moderate"
        let targetMuscles = ["chest", "triceps"]
        let equipment = ["dumbbells", "bench"]
        let style = "traditional"
        
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: goal,
            duration: duration,
            intensity: intensity,
            targetMuscles: targetMuscles,
            equipment: equipment,
            constraints: nil,
            style: style
        )
        
        // Assert
        XCTAssertNotNil(plan)
        XCTAssertNotEqual(plan.id, UUID())
        XCTAssertEqual(plan.estimatedDuration, duration)
        XCTAssertEqual(plan.estimatedCalories, duration * 5) // Simple calculation
        XCTAssertEqual(plan.focusAreas, targetMuscles)
        XCTAssertEqual(plan.difficulty, .intermediate)
        XCTAssertTrue(plan.summary.contains("strength"))
    }
    
    func test_generatePlan_withAllParameters_includesConstraints() async throws {
        // Arrange
        let goal = "hypertrophy"
        let duration = 60
        let intensity = "high"
        let targetMuscles = ["full_body"]
        let equipment = ["barbell", "dumbbells", "cables"]
        let constraints = "Bad lower back, avoid heavy deadlifts"
        let style = "superset"
        
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: goal,
            duration: duration,
            intensity: intensity,
            targetMuscles: targetMuscles,
            equipment: equipment,
            constraints: constraints,
            style: style
        )
        
        // Assert
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan.estimatedDuration, 60)
        XCTAssertEqual(plan.estimatedCalories, 300) // 60 * 5
        XCTAssertEqual(plan.focusAreas, ["full_body"])
        XCTAssertTrue(plan.summary.contains("hypertrophy"))
    }
    
    func test_generatePlan_withMinimalDuration_createsShortWorkout() async throws {
        // Arrange
        let duration = 15 // Quick workout
        
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: "active_recovery",
            duration: duration,
            intensity: "light",
            targetMuscles: ["core"],
            equipment: ["bodyweight"],
            constraints: nil,
            style: "circuit"
        )
        
        // Assert
        XCTAssertEqual(plan.estimatedDuration, 15)
        XCTAssertEqual(plan.estimatedCalories, 75) // 15 * 5
        XCTAssertTrue(plan.summary.contains("active_recovery"))
    }
    
    func test_generatePlan_withMaximalDuration_createsLongWorkout() async throws {
        // Arrange
        let duration = 120 // 2 hour workout
        
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: "endurance",
            duration: duration,
            intensity: "moderate",
            targetMuscles: ["legs", "core"],
            equipment: ["full_gym"],
            constraints: nil,
            style: "traditional"
        )
        
        // Assert
        XCTAssertEqual(plan.estimatedDuration, 120)
        XCTAssertEqual(plan.estimatedCalories, 600) // 120 * 5
        XCTAssertTrue(plan.summary.contains("endurance"))
    }
    
    func test_generatePlan_withMultipleMuscleGroups_includesAllInFocusAreas() async throws {
        // Arrange
        let targetMuscles = ["chest", "back", "shoulders", "arms", "core"]
        
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: "hypertrophy",
            duration: 90,
            intensity: "high",
            targetMuscles: targetMuscles,
            equipment: ["full_gym"],
            constraints: nil,
            style: "traditional"
        )
        
        // Assert
        XCTAssertEqual(plan.focusAreas, targetMuscles)
        XCTAssertEqual(plan.focusAreas.count, 5)
    }
    
    // MARK: - Adapt Plan Tests
    
    func test_adaptPlan_withFeedback_returnsSamePlan() async throws {
        // Arrange
        let originalPlan = WorkoutPlanResult(
            id: UUID(),
            exercises: [],
            estimatedCalories: 250,
            estimatedDuration: 45,
            summary: "Original workout",
            difficulty: .intermediate,
            focusAreas: ["chest", "triceps"]
        )
        let feedback = "Too easy, need more challenge"
        let adjustments: [String: Any] = ["intensity": "high", "addSets": true]
        
        // Act
        let adaptedPlan = try await sut.adaptPlan(
            originalPlan,
            feedback: feedback,
            adjustments: adjustments
        )
        
        // Assert
        XCTAssertEqual(adaptedPlan.id, originalPlan.id)
        XCTAssertEqual(adaptedPlan.estimatedCalories, originalPlan.estimatedCalories)
        XCTAssertEqual(adaptedPlan.estimatedDuration, originalPlan.estimatedDuration)
        XCTAssertEqual(adaptedPlan.difficulty, originalPlan.difficulty)
        XCTAssertEqual(adaptedPlan.focusAreas, originalPlan.focusAreas)
    }
    
    func test_adaptPlan_withEmptyAdjustments_returnsOriginalPlan() async throws {
        // Arrange
        let originalPlan = WorkoutPlanResult(
            id: UUID(),
            exercises: [],
            estimatedCalories: 200,
            estimatedDuration: 30,
            summary: "Quick workout",
            difficulty: .beginner,
            focusAreas: ["legs"]
        )
        
        // Act
        let adaptedPlan = try await sut.adaptPlan(
            originalPlan,
            feedback: "Perfect as is",
            adjustments: [:]
        )
        
        // Assert
        XCTAssertEqual(adaptedPlan.id, originalPlan.id)
        XCTAssertEqual(adaptedPlan.summary, originalPlan.summary)
    }
    
    // MARK: - WorkoutService Delegation Tests
    
    func test_startWorkout_delegatesToWorkoutService() async throws {
        // Arrange
        let workoutType = WorkoutType.strength
        let mockWorkout = Workout(name: "Test Workout", user: testUser)
        mockWorkoutService.mockWorkout = mockWorkout
        
        // Act
        let workout = try await sut.startWorkout(type: workoutType, user: testUser)
        
        // Assert
        XCTAssertEqual(workout.id, mockWorkout.id)
        XCTAssertEqual(mockWorkoutService.startWorkoutCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastStartWorkoutType, workoutType)
    }
    
    func test_pauseWorkout_delegatesToWorkoutService() async throws {
        // Arrange
        let workout = Workout(name: "Test Workout", user: testUser)
        
        // Act
        try await sut.pauseWorkout(workout)
        
        // Assert
        XCTAssertEqual(mockWorkoutService.pauseWorkoutCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastPausedWorkout?.id, workout.id)
    }
    
    func test_resumeWorkout_delegatesToWorkoutService() async throws {
        // Arrange
        let workout = Workout(name: "Test Workout", user: testUser)
        
        // Act
        try await sut.resumeWorkout(workout)
        
        // Assert
        XCTAssertEqual(mockWorkoutService.resumeWorkoutCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastResumedWorkout?.id, workout.id)
    }
    
    func test_endWorkout_delegatesToWorkoutService() async throws {
        // Arrange
        let workout = Workout(name: "Test Workout", user: testUser)
        
        // Act
        try await sut.endWorkout(workout)
        
        // Assert
        XCTAssertEqual(mockWorkoutService.endWorkoutCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastEndedWorkout?.id, workout.id)
    }
    
    func test_logExercise_delegatesToWorkoutService() async throws {
        // Arrange
        let workout = Workout(name: "Test Workout", user: testUser)
        let exercise = Exercise(name: "Bench Press", workout: workout)
        
        // Act
        try await sut.logExercise(exercise, in: workout)
        
        // Assert
        XCTAssertEqual(mockWorkoutService.logExerciseCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastLoggedExercise?.name, "Bench Press")
    }
    
    func test_getWorkoutHistory_delegatesToWorkoutService() async throws {
        // Arrange
        let mockHistory = [
            Workout(name: "Workout 1", user: testUser),
            Workout(name: "Workout 2", user: testUser)
        ]
        mockWorkoutService.mockWorkoutHistory = mockHistory
        
        // Act
        let history = try await sut.getWorkoutHistory(for: testUser, limit: 10)
        
        // Assert
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(mockWorkoutService.getWorkoutHistoryCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastHistoryLimit, 10)
    }
    
    func test_getWorkoutTemplates_delegatesToWorkoutService() async throws {
        // Arrange
        let mockTemplates = [
            WorkoutTemplate(name: "Push Day", exercises: [], user: testUser),
            WorkoutTemplate(name: "Pull Day", exercises: [], user: testUser)
        ]
        mockWorkoutService.mockTemplates = mockTemplates
        
        // Act
        let templates = try await sut.getWorkoutTemplates()
        
        // Assert
        XCTAssertEqual(templates.count, 2)
        XCTAssertEqual(mockWorkoutService.getWorkoutTemplatesCallCount, 1)
    }
    
    func test_saveWorkoutTemplate_delegatesToWorkoutService() async throws {
        // Arrange
        let template = WorkoutTemplate(name: "Leg Day", exercises: [], user: testUser)
        
        // Act
        try await sut.saveWorkoutTemplate(template)
        
        // Assert
        XCTAssertEqual(mockWorkoutService.saveWorkoutTemplateCallCount, 1)
        XCTAssertEqual(mockWorkoutService.lastSavedTemplate?.name, "Leg Day")
    }
    
    // MARK: - Edge Cases
    
    func test_generatePlan_withEmptyTargetMuscles_returnsValidPlan() async throws {
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: "general_fitness",
            duration: 30,
            intensity: "moderate",
            targetMuscles: [],
            equipment: ["bodyweight"],
            constraints: nil,
            style: "circuit"
        )
        
        // Assert
        XCTAssertNotNil(plan)
        XCTAssertTrue(plan.focusAreas.isEmpty)
    }
    
    func test_generatePlan_withEmptyEquipment_returnsValidPlan() async throws {
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: "strength",
            duration: 45,
            intensity: "high",
            targetMuscles: ["chest"],
            equipment: [],
            constraints: nil,
            style: "traditional"
        )
        
        // Assert
        XCTAssertNotNil(plan)
        // Should still create a plan even without equipment specified
    }
    
    func test_generatePlan_withVeryLongConstraints_handlesGracefully() async throws {
        // Arrange
        let longConstraints = String(repeating: "constraint ", count: 100)
        
        // Act
        let plan = try await sut.generatePlan(
            for: testUser,
            goal: "strength",
            duration: 45,
            intensity: "moderate",
            targetMuscles: ["back"],
            equipment: ["full_gym"],
            constraints: longConstraints,
            style: "traditional"
        )
        
        // Assert
        XCTAssertNotNil(plan)
        // Should handle long constraints without issues
    }
    
    // MARK: - Performance Tests
    
    func test_generatePlan_performance() async throws {
        // Measure time to generate multiple plans
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<10 {
            _ = try await sut.generatePlan(
                for: testUser,
                goal: "strength",
                duration: 30 + i * 5,
                intensity: "moderate",
                targetMuscles: ["chest"],
                equipment: ["dumbbells"],
                constraints: nil,
                style: "traditional"
            )
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert - Should be very fast since it's a simple implementation
        XCTAssertLessThan(duration, 0.1, "Generating 10 plans should take less than 100ms")
    }
    
    // MARK: - Error Handling Tests
    
    func test_startWorkout_whenServiceThrows_propagatesError() async throws {
        // Arrange
        mockWorkoutService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await sut.startWorkout(type: .strength, user: testUser)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_getWorkoutHistory_whenServiceThrows_propagatesError() async throws {
        // Arrange
        mockWorkoutService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await sut.getWorkoutHistory(for: testUser, limit: 10)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}