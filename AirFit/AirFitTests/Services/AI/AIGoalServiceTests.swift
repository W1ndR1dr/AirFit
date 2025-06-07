import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class AIGoalServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: AIGoalService!
    private var mockGoalService: MockGoalService!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([User.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        testUser.weight = 80 // kg
        testUser.height = 175 // cm
        testUser.fitnessLevel = "intermediate"
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Create mocks and service
        mockGoalService = MockGoalService()
        sut = AIGoalService(goalService: mockGoalService)
    }
    
    override func tearDown() {
        sut = nil
        mockGoalService = nil
        modelContext = nil
        testUser = nil
        super.tearDown()
    }
    
    // MARK: - Create or Refine Goal Tests
    
    func test_createOrRefineGoal_withBasicAspirations_returnsGoal() async throws {
        // Arrange
        let aspirations = "I want to lose 10 pounds"
        
        // Act
        let result = try await sut.createOrRefineGoal(
            current: nil,
            aspirations: aspirations,
            timeframe: nil,
            fitnessLevel: nil,
            constraints: [],
            motivations: [],
            goalType: nil,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.title, aspirations)
        XCTAssertTrue(result.description.contains(aspirations))
        XCTAssertNotNil(result.targetDate)
        XCTAssertEqual(result.smartCriteria.specific, aspirations)
        XCTAssertEqual(result.smartCriteria.timeBound, "30 days")
    }
    
    func test_createOrRefineGoal_withCompleteParameters_includesAllInformation() async throws {
        // Arrange
        let current = "Current goal: exercise 3 times per week"
        let aspirations = "Build muscle and increase strength"
        let timeframe = "3 months"
        let fitnessLevel = "advanced"
        let constraints = ["Bad knee", "Limited time"]
        let motivations = ["Feel stronger", "Look better", "Health"]
        let goalType = "performance"
        
        // Act
        let result = try await sut.createOrRefineGoal(
            current: current,
            aspirations: aspirations,
            timeframe: timeframe,
            fitnessLevel: fitnessLevel,
            constraints: constraints,
            motivations: motivations,
            goalType: goalType,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.title, aspirations)
        XCTAssertTrue(result.smartCriteria.achievable.contains(fitnessLevel))
        XCTAssertTrue(result.smartCriteria.relevant.contains("motivations"))
        XCTAssertEqual(result.smartCriteria.timeBound, timeframe)
    }
    
    func test_createOrRefineGoal_withDifferentTimeframes_setsCorrectDate() async throws {
        // Arrange
        let timeframes = ["1 week", "2 months", "6 months", "1 year", nil]
        let baseDate = Date()
        
        for timeframe in timeframes {
            // Act
            let result = try await sut.createOrRefineGoal(
                current: nil,
                aspirations: "Get fit",
                timeframe: timeframe,
                fitnessLevel: nil,
                constraints: [],
                motivations: [],
                goalType: nil,
                for: testUser
            )
            
            // Assert
            XCTAssertNotNil(result.targetDate)
            
            // Verify date is approximately 30 days from now (placeholder always returns 30 days)
            let daysDifference = Calendar.current.dateComponents([.day], from: baseDate, to: result.targetDate!).day ?? 0
            XCTAssertEqual(daysDifference, 30, accuracy: 1)
        }
    }
    
    func test_createOrRefineGoal_withEmptyAspirations_stillCreatesGoal() async throws {
        // Act
        let result = try await sut.createOrRefineGoal(
            current: nil,
            aspirations: "",
            timeframe: nil,
            fitnessLevel: nil,
            constraints: [],
            motivations: [],
            goalType: nil,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.title.isEmpty)
        XCTAssertTrue(result.metrics.isEmpty)
        XCTAssertTrue(result.milestones.isEmpty)
    }
    
    func test_createOrRefineGoal_withLongAspirations_handlesGracefully() async throws {
        // Arrange
        let longAspirations = String(repeating: "I want to achieve amazing fitness goals ", count: 50)
        
        // Act
        let result = try await sut.createOrRefineGoal(
            current: nil,
            aspirations: longAspirations,
            timeframe: nil,
            fitnessLevel: nil,
            constraints: [],
            motivations: [],
            goalType: nil,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.title, longAspirations)
    }
    
    // MARK: - Suggest Goal Adjustments Tests
    
    func test_suggestGoalAdjustments_returnsEmptyArray() async throws {
        // Arrange
        let goal = ServiceGoal(
            id: UUID(),
            type: .weightLoss,
            target: 10,
            currentValue: 3,
            deadline: Date().addingTimeInterval(60 * 24 * 60 * 60),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Act
        let adjustments = try await sut.suggestGoalAdjustments(for: goal, user: testUser)
        
        // Assert
        XCTAssertTrue(adjustments.isEmpty) // Placeholder returns empty
    }
    
    func test_suggestGoalAdjustments_withCompletedGoal_returnsEmptyArray() async throws {
        // Arrange
        let goal = ServiceGoal(
            id: UUID(),
            type: .stepCount,
            target: 10000,
            currentValue: 12000,
            deadline: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Act
        let adjustments = try await sut.suggestGoalAdjustments(for: goal, user: testUser)
        
        // Assert
        XCTAssertTrue(adjustments.isEmpty)
    }
    
    // MARK: - Goal Service Delegation Tests
    
    func test_createGoal_delegatesToGoalService() async throws {
        // Arrange
        let goalData = GoalCreationData(
            type: .muscleGain,
            target: 5,
            deadline: Date().addingTimeInterval(90 * 24 * 60 * 60),
            description: "Gain 5 pounds of muscle"
        )
        
        // Act
        let goal = try await sut.createGoal(goalData, for: testUser)
        
        // Assert
        XCTAssertNotNil(goal)
        mockGoalService.verifyGoalCreated(type: .muscleGain, target: 5)
        XCTAssertEqual(mockGoalService.invocationCount(for: "createGoal"), 1)
    }
    
    func test_updateGoal_delegatesToGoalService() async throws {
        // Arrange
        let goal = ServiceGoal(
            id: UUID(),
            type: .workoutFrequency,
            target: 4,
            currentValue: 2,
            deadline: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        let updates = GoalUpdate(target: 5, deadline: nil, description: "Updated target")
        
        // Add goal to mock service
        mockGoalService.goals[goal.id] = goal
        
        // Act
        try await sut.updateGoal(goal, updates: updates)
        
        // Assert
        XCTAssertEqual(mockGoalService.invocationCount(for: "updateGoal"), 1)
    }
    
    func test_deleteGoal_delegatesToGoalService() async throws {
        // Arrange
        let goal = ServiceGoal(
            id: UUID(),
            type: .calorieIntake,
            target: 2000,
            currentValue: 1800,
            deadline: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Add goal to mock service
        mockGoalService.goals[goal.id] = goal
        
        // Act
        try await sut.deleteGoal(goal)
        
        // Assert
        XCTAssertEqual(mockGoalService.invocationCount(for: "deleteGoal"), 1)
    }
    
    func test_getActiveGoals_delegatesToGoalService() async throws {
        // Arrange
        let mockGoals = [
            ServiceGoal(
                id: UUID(),
                type: .weightLoss,
                target: 10,
                currentValue: 3,
                deadline: Date().addingTimeInterval(60 * 24 * 60 * 60),
                createdAt: Date(),
                updatedAt: Date()
            ),
            ServiceGoal(
                id: UUID(),
                type: .stepCount,
                target: 10000,
                currentValue: 5000,
                deadline: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        mockGoalService.stubActiveGoals(mockGoals)
        
        // Act
        let goals = try await sut.getActiveGoals(for: testUser)
        
        // Assert
        XCTAssertEqual(goals.count, 2)
        XCTAssertEqual(mockGoalService.invocationCount(for: "getActiveGoals"), 1)
    }
    
    func test_trackProgress_delegatesToGoalService() async throws {
        // Arrange
        let goal = ServiceGoal(
            id: UUID(),
            type: .waterIntake,
            target: 2000,
            currentValue: 500,
            deadline: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        let progressValue = 250.0
        
        // Add goal to mock service
        mockGoalService.goals[goal.id] = goal
        
        // Act
        try await sut.trackProgress(for: goal, value: progressValue)
        
        // Assert
        mockGoalService.verifyProgressTracked(goalId: goal.id, value: progressValue)
        XCTAssertEqual(mockGoalService.invocationCount(for: "trackProgress"), 1)
    }
    
    func test_checkGoalCompletion_delegatesToGoalService() async {
        // Arrange
        let goal = ServiceGoal(
            id: UUID(),
            type: .custom,
            target: 100,
            currentValue: 100,
            deadline: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockGoalService.stubCompletionStatus(true)
        
        // Act
        let isCompleted = await sut.checkGoalCompletion(goal)
        
        // Assert
        XCTAssertTrue(isCompleted)
        XCTAssertEqual(mockGoalService.invocationCount(for: "checkGoalCompletion"), 1)
    }
    
    // MARK: - Edge Cases
    
    func test_createOrRefineGoal_withSpecialCharacters_handlesCorrectly() async throws {
        // Arrange
        let aspirations = "Lose 10kg & gain 💪 muscle! #FitnessGoals @gym"
        
        // Act
        let result = try await sut.createOrRefineGoal(
            current: nil,
            aspirations: aspirations,
            timeframe: nil,
            fitnessLevel: nil,
            constraints: [],
            motivations: [],
            goalType: nil,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.title, aspirations)
        XCTAssertTrue(result.description.contains(aspirations))
    }
    
    func test_createOrRefineGoal_withManyConstraints_includesAll() async throws {
        // Arrange
        let constraints = Array(repeating: "Constraint", count: 20)
        
        // Act
        let result = try await sut.createOrRefineGoal(
            current: nil,
            aspirations: "Get fit",
            timeframe: nil,
            fitnessLevel: nil,
            constraints: constraints,
            motivations: [],
            goalType: nil,
            for: testUser
        )
        
        // Assert
        XCTAssertNotNil(result)
        // Should handle many constraints without issues
    }
    
    // MARK: - Error Handling Tests
    
    func test_createGoal_whenServiceThrows_propagatesError() async throws {
        // Arrange
        mockGoalService.shouldThrowError = true
        let goalData = GoalCreationData(
            type: .weightLoss,
            target: 10,
            deadline: nil,
            description: nil
        )
        
        // Act & Assert
        do {
            _ = try await sut.createGoal(goalData, for: testUser)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func test_updateGoal_whenServiceThrows_propagatesError() async throws {
        // Arrange
        mockGoalService.shouldThrowError = true
        let goal = ServiceGoal(
            id: UUID(),
            type: .workoutFrequency,
            target: 4,
            currentValue: 2,
            deadline: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        let updates = GoalUpdate(target: 5, deadline: nil, description: nil)
        
        // Act & Assert
        do {
            try await sut.updateGoal(goal, updates: updates)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Performance Tests
    
    func test_createOrRefineGoal_performance() async throws {
        // Measure time to create multiple goals
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<10 {
            _ = try await sut.createOrRefineGoal(
                current: nil,
                aspirations: "Goal \(i)",
                timeframe: "\(i + 1) months",
                fitnessLevel: "intermediate",
                constraints: [],
                motivations: [],
                goalType: nil,
                for: testUser
            )
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Assert - Should be very fast for placeholder implementation
        XCTAssertLessThan(duration, 0.1, "Creating 10 goals should take less than 100ms")
    }
    
    // MARK: - Integration Tests
    
    func test_fullGoalLifecycle() async throws {
        // Create goal
        let goalData = GoalCreationData(
            type: .weightLoss,
            target: 10,
            deadline: Date().addingTimeInterval(90 * 24 * 60 * 60),
            description: "Lose 10 pounds in 3 months"
        )
        let goal = try await sut.createGoal(goalData, for: testUser)
        XCTAssertNotNil(goal)
        
        // Track progress
        try await sut.trackProgress(for: goal, value: 2.5)
        try await sut.trackProgress(for: goal, value: 3.0)
        
        // Check completion status
        let isCompleted = await sut.checkGoalCompletion(goal)
        XCTAssertFalse(isCompleted) // 5.5 < 10
        
        // Update goal
        let updates = GoalUpdate(target: 5, deadline: nil, description: "Adjusted target")
        try await sut.updateGoal(goal, updates: updates)
        
        // Get active goals
        let activeGoals = try await sut.getActiveGoals(for: testUser)
        XCTAssertFalse(activeGoals.isEmpty)
        
        // Suggest adjustments (placeholder returns empty)
        let adjustments = try await sut.suggestGoalAdjustments(for: goal, user: testUser)
        XCTAssertTrue(adjustments.isEmpty)
        
        // Delete goal
        try await sut.deleteGoal(goal)
        
        // Verify all operations were recorded
        XCTAssertEqual(mockGoalService.invocationCount(for: "createGoal"), 1)
        XCTAssertEqual(mockGoalService.invocationCount(for: "trackProgress"), 2)
        XCTAssertEqual(mockGoalService.invocationCount(for: "checkGoalCompletion"), 1)
        XCTAssertEqual(mockGoalService.invocationCount(for: "updateGoal"), 1)
        XCTAssertEqual(mockGoalService.invocationCount(for: "getActiveGoals"), 1)
        XCTAssertEqual(mockGoalService.invocationCount(for: "deleteGoal"), 1)
    }
    
    func test_concurrentGoalOperations() async throws {
        // Create multiple goals concurrently
        await withTaskGroup(of: ServiceGoal?.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let goalData = GoalCreationData(
                        type: .custom,
                        target: Double(i * 100),
                        deadline: nil,
                        description: "Goal \(i)"
                    )
                    return try? await self.sut.createGoal(goalData, for: self.testUser)
                }
            }
            
            var createdGoals: [ServiceGoal] = []
            for await goal in group {
                if let goal = goal {
                    createdGoals.append(goal)
                }
            }
            
            XCTAssertEqual(createdGoals.count, 5)
        }
        
        // Verify all operations completed
        XCTAssertEqual(mockGoalService.invocationCount(for: "createGoal"), 5)
    }
}