import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class PersonaEngineTests: XCTestCase {
    // MARK: - Properties
    var sut: PersonaEngine!
    var modelContext: ModelContext!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        sut = PersonaEngine()
    }
    
    override func tearDown() {
        sut = nil
        modelContext = nil
        super.tearDown()
    }
    
    // MARK: - System Prompt Building Tests
    
    func test_buildSystemPrompt_withValidInputs_shouldGenerateCompletePrompt() throws {
        // Given
        let personaMode = PersonaMode.empathetic
        let userGoal = "lose weight and build muscle"
        let userContext = "Working professional, busy schedule, prefers morning workouts"
        let healthContext = createTestHealthContext()
        let conversationHistory: [AIChatMessage] = []
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            personaMode: personaMode,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("AirFit"))
        XCTAssertTrue(prompt.contains(userGoal))
        XCTAssertTrue(prompt.contains(userContext))
        XCTAssertFalse(prompt.contains("{{PERSONA_INSTRUCTIONS}}"))
        XCTAssertFalse(prompt.contains("{{USER_GOAL}}"))
        XCTAssertFalse(prompt.contains("{{USER_CONTEXT}}"))
        XCTAssertFalse(prompt.contains("{{HEALTH_CONTEXT_JSON}}"))
        XCTAssertFalse(prompt.contains("{{CURRENT_DATETIME_UTC}}"))
        
        // Verify prompt is reasonable size
        let estimatedTokens = prompt.count / 4
        XCTAssertLessThan(estimatedTokens, 1000)
    }
    
    func test_buildSystemPrompt_withLongInputs_shouldThrowIfTooLong() throws {
        // Given
        let personaMode = PersonaMode.empathetic
        let userGoal = String(repeating: "very long goal ", count: 100)
        let userContext = String(repeating: "very long context ", count: 100)
        let healthContext = createMassiveHealthContext()
        let conversationHistory = createLongConversationHistory(count: 50)
        let availableFunctions = createManyTestFunctions(count: 50)
        
        // When & Then
        XCTAssertThrowsError(try sut.buildSystemPrompt(
            personaMode: personaMode,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )) { error in
            guard let personaError = error as? PersonaEngineError,
                  case .promptTooLong(let tokens) = personaError else {
                XCTFail("Expected PersonaEngineError.promptTooLong")
                return
            }
            XCTAssertGreaterThan(tokens, 1000)
        }
    }
    
    func test_buildSystemPrompt_differentPersonaModes_produceDifferentPrompts() throws {
        // Given
        let userGoal = "improve fitness"
        let userContext = "Beginner level"
        let healthContext = createTestHealthContext()
        let conversationHistory: [AIChatMessage] = []
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let empatheticPrompt = try sut.buildSystemPrompt(
            personaMode: .empathetic,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        let directPrompt = try sut.buildSystemPrompt(
            personaMode: .direct,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        let playfulPrompt = try sut.buildSystemPrompt(
            personaMode: .playful,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertNotEqual(empatheticPrompt, directPrompt)
        XCTAssertNotEqual(directPrompt, playfulPrompt)
        XCTAssertNotEqual(empatheticPrompt, playfulPrompt)
    }
    
    func test_buildSystemPrompt_withConversationHistory_includesRecentMessages() throws {
        // Given
        let personaMode = PersonaMode.balanced
        let userGoal = "stay healthy"
        let userContext = "Active lifestyle"
        let healthContext = createTestHealthContext()
        let conversationHistory = [
            AIChatMessage(role: .user, content: "What should I eat today?"),
            AIChatMessage(role: .assistant, content: "Based on your goals..."),
            AIChatMessage(role: .user, content: "I had pizza for lunch")
        ]
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            personaMode: personaMode,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("pizza"))
        XCTAssertTrue(prompt.contains("eat today"))
    }
    
    func test_buildSystemPrompt_withAvailableFunctions_includesFunctionDefinitions() throws {
        // Given
        let personaMode = PersonaMode.balanced
        let userGoal = "track nutrition"
        let userContext = "Calorie counting"
        let healthContext = createTestHealthContext()
        let conversationHistory: [AIChatMessage] = []
        let availableFunctions = [
            AIFunctionDefinition(
                name: "log_food",
                description: "Log food intake",
                parameters: [
                    "food": "string",
                    "calories": "number"
                ]
            )
        ]
        
        // When
        let prompt = try sut.buildSystemPrompt(
            personaMode: personaMode,
            userGoal: userGoal,
            userContext: userContext,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertTrue(prompt.contains("log_food"))
        XCTAssertTrue(prompt.contains("Log food intake"))
    }
    
    // MARK: - Legacy API Tests
    
    func test_buildSystemPrompt_legacyAPI_migratesBlendToPersonaMode() throws {
        // Given
        let userProfile = createTestUserProfile()
        let healthContext = createTestHealthContext()
        let conversationHistory: [AIChatMessage] = []
        let availableFunctions: [AIFunctionDefinition] = []
        
        // When
        let prompt = try sut.buildSystemPrompt(
            userProfile: userProfile,
            healthContext: healthContext,
            conversationHistory: conversationHistory,
            availableFunctions: availableFunctions
        )
        
        // Then
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("AirFit"))
        // Should have migrated blend to a persona mode
        let estimatedTokens = prompt.count / 4
        XCTAssertLessThan(estimatedTokens, 1000)
    }
    
    // MARK: - Performance Tests
    
    func test_buildSystemPrompt_performance() throws {
        // Given
        let personaMode = PersonaMode.balanced
        let userGoal = "improve fitness"
        let userContext = "Regular exerciser"
        let healthContext = createTestHealthContext()
        let conversationHistory = createTestConversationHistory()
        let availableFunctions = createTestFunctions()
        
        // Measure
        measure {
            do {
                _ = try sut.buildSystemPrompt(
                    personaMode: personaMode,
                    userGoal: userGoal,
                    userContext: userContext,
                    healthContext: healthContext,
                    conversationHistory: conversationHistory,
                    availableFunctions: availableFunctions
                )
            } catch {
                XCTFail("Should not throw: \(error)")
            }
        }
    }
    
    // MARK: - Test Helpers
    
    private func createTestHealthContext() -> HealthContextSnapshot {
        HealthContextSnapshot(
            timestamp: Date(),
            metrics: [
                "sleepHours": 7.5,
                "steps": 8000,
                "restingHeartRate": 65,
                "activeCalories": 450
            ],
            summary: "Good sleep, moderate activity"
        )
    }
    
    private func createMassiveHealthContext() -> HealthContextSnapshot {
        var metrics: [String: Double] = [:]
        for i in 0..<100 {
            metrics["metric_\(i)"] = Double(i)
        }
        
        return HealthContextSnapshot(
            timestamp: Date(),
            metrics: metrics,
            summary: String(repeating: "Very long health summary ", count: 100)
        )
    }
    
    private func createTestUserProfile() -> UserProfileJsonBlob {
        var lifeContext = LifeContext()
        lifeContext.isDeskJob = true
        lifeContext.scheduleType = .unpredictableChaotic
        
        var goal = Goal()
        goal.family = .strengthTone
        goal.rawText = "Get stronger"
        
        UserProfileJsonBlob(
            lifeContext: lifeContext,
            goal: goal,
            blend: Blend(
                encouragingEmpathetic: 0.5,
                authoritativeDirect: 0.3,
                playfullyProvocative: 0.2
            ),
            timezone: "America/Los_Angeles",
            engagementPreferences: EngagementPreferences(
                preferredTone: .balanced
            )
        )
    }
    
    private func createTestConversationHistory() -> [AIChatMessage] {
        [
            AIChatMessage(role: .user, content: "Hi coach"),
            AIChatMessage(role: .assistant, content: "Hello! Ready to work on your goals?"),
            AIChatMessage(role: .user, content: "Yes, let's do this!")
        ]
    }
    
    private func createLongConversationHistory(count: Int) -> [AIChatMessage] {
        var messages: [AIChatMessage] = []
        for i in 0..<count {
            messages.append(AIChatMessage(role: i % 2 == 0 ? .user : .assistant, content: "Message \(i)"))
        }
        return messages
    }
    
    private func createTestFunctions() -> [AIFunctionDefinition] {
        [
            AIFunctionDefinition(
                name: "log_workout",
                description: "Log a workout session",
                parameters: ["type": "string", "duration": "number"]
            ),
            AIFunctionDefinition(
                name: "get_nutrition_summary",
                description: "Get daily nutrition summary",
                parameters: ["date": "string"]
            )
        ]
    }
    
    private func createManyTestFunctions(count: Int) -> [AIFunctionDefinition] {
        (0..<count).map { i in
            AIFunctionDefinition(
                name: "function_\(i)",
                description: String(repeating: "Long description ", count: 20),
                parameters: Dictionary(uniqueKeysWithValues: (0..<10).map { j in
                    ("param_\(j)", "string")
                })
            )
        }
    }
}

// MARK: - PersonaEngineError

enum PersonaEngineError: LocalizedError {
    case promptTooLong(Int)
    
    var errorDescription: String? {
        switch self {
        case .promptTooLong(let tokens):
            return "Prompt too long: \(tokens) tokens"
        }
    }
}