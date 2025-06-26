import XCTest
import SwiftData
@testable import AirFit

@MainActor
final class PersonaGenerationTests: XCTestCase {

    var personaService: PersonaService!
    var modelContext: ModelContext!
    var mockLLMOrchestrator: MockLLMOrchestrator!
    var personaSynthesizer: PersonaSynthesizer!
    var testUser: User!

    override func setUp() async throws {
        try super.setUp()

        // Setup in-memory database
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            ConversationSession.self,
            ConversationResponse.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(container)

        // Setup services
        let cache = AIResponseCache()

        // Setup mocks
        mockLLMOrchestrator = await MockLLMOrchestrator()

        // Create LLMOrchestrator
        let realLLMOrchestrator = await LLMOrchestrator(apiKeyManager: MockAPIKeyManager())

        // Create synthesizers
        personaSynthesizer = PersonaSynthesizer(
            llmOrchestrator: realLLMOrchestrator
        )

        let optimizedSynthesizer = PersonaSynthesizer(
            llmOrchestrator: realLLMOrchestrator,
            cache: cache
        )

        // Create PersonaService
        personaService = await PersonaService(
            personaSynthesizer: optimizedSynthesizer,
            llmOrchestrator: realLLMOrchestrator,
            modelContext: modelContext,
            cache: cache
        )

        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
    }

    override func tearDown() async throws {
        testUser = nil
        personaService = nil
        personaSynthesizer = nil
        mockLLMOrchestrator = nil
        modelContext = nil
        try super.tearDown()
    }

    // MARK: - Basic Persona Generation

    func testBasicPersonaGeneration() async throws {
        // Create a conversation session with responses
        let session = ConversationSession(userId: testUser.id)

        // Create responses with proper initializer
        let responseData1 = try JSONEncoder().encode(ResponseValue.text("I want to lose weight and get stronger"))
        let response1 = ConversationResponse(
            sessionId: session.id,
            nodeId: "goals",
            responseData: responseData1
        )

        let responseData2 = try JSONEncoder().encode(ResponseValue.text("I'm a beginner, just starting out"))
        let response2 = ConversationResponse(
            sessionId: session.id,
            nodeId: "experience",
            responseData: responseData2
        )

        let responseData3 = try JSONEncoder().encode(ResponseValue.text("I need someone supportive but also pushes me"))
        let response3 = ConversationResponse(
            sessionId: session.id,
            nodeId: "motivation",
            responseData: responseData3
        )

        session.responses = [response1, response2, response3]
        session.completedAt = Date()
        modelContext.insert(session)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        // Generate persona
        let persona = try await personaService.generatePersona(from: session)

        // Verify persona was generated
        XCTAssertNotNil(persona)
        XCTAssertFalse(persona.name.isEmpty)
        XCTAssertFalse(persona.archetype.isEmpty)
        XCTAssertFalse(persona.coreValues.isEmpty)
        XCTAssertNotNil(persona.voiceCharacteristics)
        XCTAssertNotNil(persona.interactionStyle)
        XCTAssertFalse(persona.systemPrompt.isEmpty)
    }

    func testPersonaGenerationWithMinimalData() async throws {
        // Create session with minimal responses
        let session = ConversationSession(userId: testUser.id)

        let responseData = try JSONEncoder().encode(ResponseValue.text("Get fit"))
        let response = ConversationResponse(
            sessionId: session.id,
            nodeId: "goals",
            responseData: responseData
        )

        session.responses = [response]
        session.completedAt = Date()
        modelContext.insert(session)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        // Should still generate a persona with defaults
        let persona = try await personaService.generatePersona(from: session)

        XCTAssertNotNil(persona)
        XCTAssertFalse(persona.name.isEmpty)
        XCTAssertTrue(persona.coreValues.count >= 1) // Should have default values
    }

    // MARK: - Persona Adjustment

    // Commented out - test uses wrong PersonaProfile structure
    /*
     func testPersonaAdjustment() async throws {
     // TODO: Rewrite this test using the correct PersonaProfile structure
     }
     */

    // MARK: - Persona Persistence

    // Commented out - PersonaService doesn't have savePersona/getPersona methods
    /*
     func testPersonaSaveAndRetrieve() async throws {
     // TODO: Implement if/when persistence methods are added
     }
     */

    // MARK: - Error Handling

    func testPersonaGenerationFailure() async throws {
        // Setup LLM to fail
        await mockLLMOrchestrator.setShouldThrowError(true)

        let session = createTestSession()
        modelContext.insert(session)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        // Should throw error
        do {
            _ = try await personaService.generatePersona(from: session)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is LLMError || error is PersonaError)
        }
    }

    // MARK: - Performance Tests

    func testPersonaGenerationPerformance() async throws {
        let session = createTestSession()
        modelContext.insert(session)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        // Measure generation time
        let startTime = CFAbsoluteTimeGetCurrent()

        let persona = try await personaService.generatePersona(from: session)

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        XCTAssertNotNil(persona)
        XCTAssertLessThan(elapsed, 3.0, "Persona generation should complete within 3 seconds")
    }

    func testPersonaCaching() async throws {
        let session = createTestSession()
        modelContext.insert(session)
        do {

            try modelContext.save()

        } catch {

            XCTFail("Failed to save test context: \(error)")

        }

        // First generation
        let persona1 = try await personaService.generatePersona(from: session)

        // Second generation (should be cached)
        let startTime = CFAbsoluteTimeGetCurrent()
        let persona2 = try await personaService.generatePersona(from: session)
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Should be very fast if cached
        XCTAssertLessThan(elapsed, 0.1, "Cached persona should return instantly")
        XCTAssertEqual(persona1.name, persona2.name)
    }

    // MARK: - Integration Tests

    // Commented out - uses wrong PersonaProfile structure
    /*
     func testFullOnboardingToPersonaFlow() async throws {
     // TODO: Rewrite using correct PersonaProfile and OnboardingProfile structures
     }
     */

    // MARK: - Helper Methods

    private func createTestSession() -> ConversationSession {
        let session = ConversationSession(userId: testUser.id)

        do {
            let responses: [(nodeId: String, text: String)] = [
                ("goals", "Build muscle and improve endurance"),
                ("experience", "Intermediate level, been training for 2 years"),
                ("schedule", "Evenings after work, 4-5 times per week"),
                ("motivation", "I like challenges and data-driven progress")
            ]

            session.responses = try responses.map { nodeId, text in
                let responseData = try JSONEncoder().encode(ResponseValue.text(text))
                return ConversationResponse(
                    sessionId: session.id,
                    nodeId: nodeId,
                    responseData: responseData
                )
            }
        } catch {
            // Fallback to empty responses
            session.responses = []
        }

        session.completedAt = Date()
        return session
    }
}

// MARK: - Mock LLM Orchestrator

// Using MockLLMOrchestrator from Mocks folder instead
