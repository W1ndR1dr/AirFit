import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class FunctionCallDispatcherTests: XCTestCase {

    var dispatcher: FunctionCallDispatcher!
    var testUser: User!
    var testContext: FunctionContext!
    var modelContainer: ModelContainer!

    override func setUp() async throws {
        // Create in-memory model container for testing
        modelContainer = try ModelContainer.createTestContainer()

        // Create test user
        testUser = User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            preferredUnits: "metric"
        )

        // Create test context
        testContext = FunctionContext(
            modelContext: modelContainer.mainContext,
            conversationId: UUID(),
            userId: testUser.id
        )

        // Initialize dispatcher
        dispatcher = FunctionCallDispatcher()
    }

    override func tearDown() async throws {
        dispatcher = nil
        testUser = nil
        testContext = nil
        modelContainer = nil
    }

    // MARK: - Workout Function Tests

    func testGeneratePersonalizedWorkoutPlan() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "generatePersonalizedWorkoutPlan",
            arguments: [
                "goalFocus": AIAnyCodable("strength"),
                "durationMinutes": AIAnyCodable(45),
                "intensityPreference": AIAnyCodable("moderate"),
                "targetMuscleGroups": AIAnyCodable(["chest", "back"]),
                "availableEquipment": AIAnyCodable(["dumbbells"]),
                "workoutStyle": AIAnyCodable("traditional_sets")
            ]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertTrue(result.success)
        XCTAssertFalse(result.message.isEmpty)
        XCTAssertNotNil(result.data)
        XCTAssertEqual(result.functionName, "generatePersonalizedWorkoutPlan")
        XCTAssertLessThan(result.executionTimeMs, 1_000) // Should complete under 1 second

        // Verify data structure
        guard let data = result.data else {
            XCTFail("Expected data to be present")
            return
        }

        XCTAssertNotNil(data["planId"])
        XCTAssertNotNil(data["exerciseCount"])
        XCTAssertNotNil(data["estimatedCalories"])
        XCTAssertNotNil(data["exercises"])
    }

    func testAdaptPlanBasedOnFeedback() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "adaptPlanBasedOnFeedback",
            arguments: [
                "userFeedback": AIAnyCodable("The workouts are too intense, I'm feeling exhausted"),
                "adaptationType": AIAnyCodable("reduce_intensity"),
                "specificConcern": AIAnyCodable("too tired"),
                "urgencyLevel": AIAnyCodable("immediate"),
                "maintainGoals": AIAnyCodable(true)
            ]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("adapted"))
        XCTAssertNotNil(result.data)

        guard let data = result.data else {
            XCTFail("Expected data to be present")
            return
        }

        if case .string(let adaptationType) = data["adaptationType"] {
            XCTAssertEqual(adaptationType, "reduce_intensity")
        } else {
            XCTFail("Expected adaptationType to be a string")
        }

        if case .string(let urgencyLevel) = data["urgencyLevel"] {
            XCTAssertEqual(urgencyLevel, "immediate")
        } else {
            XCTFail("Expected urgencyLevel to be a string")
        }
    }

    // MARK: - Nutrition Function Tests

    func testParseAndLogComplexNutrition() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "parseAndLogComplexNutrition",
            arguments: [
                "naturalLanguageInput": AIAnyCodable("I had grilled chicken breast with brown rice and steamed broccoli for lunch"),
                "mealType": AIAnyCodable("lunch"),
                "confidenceThreshold": AIAnyCodable(0.8),
                "includeAlternatives": AIAnyCodable(true)
            ]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("logged"))
        XCTAssertNotNil(result.data)

        guard let data = result.data else {
            XCTFail("Expected data to be present")
            return
        }

        XCTAssertNotNil(data["entryId"])
        XCTAssertNotNil(data["totalCalories"])
        XCTAssertNotNil(data["totalProtein"])
        XCTAssertNotNil(data["items"])

        // Verify nutritional data is reasonable
        if case .double(let totalCalories) = data["totalCalories"] {
            XCTAssertGreaterThan(totalCalories, 0)
        } else {
            XCTFail("Expected totalCalories to be a double")
        }
    }

    // MARK: - Analytics Function Tests

    func testAnalyzePerformanceTrends() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "analyzePerformanceTrends",
            arguments: [
                "analysisQuery": AIAnyCodable("How has my workout performance changed over the past month?"),
                "metricsToAnalyze": AIAnyCodable(["workout_volume", "energy_levels", "strength_progression"]),
                "timePeriodDays": AIAnyCodable(30),
                "analysisDepth": AIAnyCodable("standard_analysis"),
                "includeRecommendations": AIAnyCodable(true)
            ]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("Analysis complete"))
        XCTAssertNotNil(result.data)

        guard let data = result.data else {
            XCTFail("Expected data to be present")
            return
        }

        XCTAssertNotNil(data["insights"])
        XCTAssertNotNil(data["trends"])
        XCTAssertNotNil(data["recommendations"])
        if case .int(let timePeriod) = data["timePeriod"] {
            XCTAssertEqual(timePeriod, 30)
        } else {
            XCTFail("Expected timePeriod to be an int")
        }
    }

    // MARK: - Goal Function Tests

    func testAssistGoalSettingOrRefinement() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "assistGoalSettingOrRefinement",
            arguments: [
                "aspirations": AIAnyCodable("I want to get stronger and build muscle"),
                "timeframe": AIAnyCodable("6 months"),
                "currentFitnessLevel": AIAnyCodable("intermediate"),
                "constraints": AIAnyCodable(["time_limited", "equipment_limited"]),
                "motivationFactors": AIAnyCodable(["health", "confidence"]),
                "goalType": AIAnyCodable("performance")
            ]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("SMART goal"))
        XCTAssertNotNil(result.data)

        guard let data = result.data else {
            XCTFail("Expected data to be present")
            return
        }

        XCTAssertNotNil(data["goalId"])
        XCTAssertNotNil(data["title"])
        XCTAssertNotNil(data["smartCriteria"])
        XCTAssertNotNil(data["milestones"])
    }

    // MARK: - Education Function Tests

    func testGenerateEducationalInsight() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "generateEducationalInsight",
            arguments: [
                "topic": AIAnyCodable("progressive_overload"),
                "userContext": AIAnyCodable("I'm not seeing strength gains anymore"),
                "knowledgeLevel": AIAnyCodable("intermediate"),
                "contentDepth": AIAnyCodable("detailed_explanation"),
                "outputFormat": AIAnyCodable("conversational"),
                "includeActionItems": AIAnyCodable(true),
                "relateToUserData": AIAnyCodable(true)
            ]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.message.contains("progressive overload"))
        XCTAssertNotNil(result.data)

        guard let data = result.data else {
            XCTFail("Expected data to be present")
            return
        }

        if case .string(let topic) = data["topic"] {
            XCTAssertEqual(topic, "progressive_overload")
        } else {
            XCTFail("Expected topic to be a string")
        }
        XCTAssertNotNil(data["content"])
        XCTAssertNotNil(data["keyPoints"])
        XCTAssertNotNil(data["actionItems"])
    }

    // MARK: - Error Handling Tests

    func testUnknownFunctionError() async throws {
        // Arrange
        let functionCall = AIFunctionCall(
            name: "unknownFunction",
            arguments: [:]
        )

        // Act
        let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Assert
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.message.contains("don't recognize"))
        XCTAssertNotNil(result.data?["error"])
    }

    // MARK: - Performance Tests

    func testFunctionExecutionPerformance() async throws {
        // Test that all functions complete within reasonable time
        let functionCalls = [
            AIFunctionCall(name: "generatePersonalizedWorkoutPlan", arguments: ["goalFocus": AIAnyCodable("strength")]),
            AIFunctionCall(name: "parseAndLogComplexNutrition", arguments: ["naturalLanguageInput": AIAnyCodable("chicken and rice")]),
            AIFunctionCall(name: "analyzePerformanceTrends", arguments: ["analysisQuery": AIAnyCodable("test query")]),
            AIFunctionCall(name: "assistGoalSettingOrRefinement", arguments: ["aspirations": AIAnyCodable("get fit")]),
            AIFunctionCall(name: "generateEducationalInsight", arguments: ["topic": AIAnyCodable("nutrition_timing"), "userContext": AIAnyCodable("test")])
        ]

        for functionCall in functionCalls {
            let startTime = Date()
            let result = try await dispatcher.execute(functionCall, for: testUser, context: testContext)
            let executionTime = Date().timeIntervalSince(startTime)

            XCTAssertTrue(result.success, "Function \(functionCall.name) should succeed")
            XCTAssertLessThan(executionTime, 1.0, "Function \(functionCall.name) should complete under 1 second")
            XCTAssertLessThan(result.executionTimeMs, 1_000, "Reported execution time should be under 1000ms")
        }
    }

    // MARK: - Metrics Tests

    func testMetricsTracking() async throws {
        // Execute a function to generate metrics
        let functionCall = AIFunctionCall(
            name: "generatePersonalizedWorkoutPlan",
            arguments: ["goalFocus": AIAnyCodable("strength")]
        )

        _ = try await dispatcher.execute(functionCall, for: testUser, context: testContext)

        // Check metrics
        let metrics = dispatcher.getMetrics()
        XCTAssertFalse(metrics.isEmpty)

        guard let functionMetrics = metrics["generatePersonalizedWorkoutPlan"] as? [String: Any] else {
            XCTFail("Expected metrics for generatePersonalizedWorkoutPlan")
            return
        }

        XCTAssertEqual(functionMetrics["totalCalls"] as? Int, 1)
        XCTAssertNotNil(functionMetrics["averageExecutionTimeMs"])
        XCTAssertEqual(functionMetrics["successRate"] as? Double, 1.0)
        XCTAssertEqual(functionMetrics["errorCount"] as? Int, 0)
    }
}
