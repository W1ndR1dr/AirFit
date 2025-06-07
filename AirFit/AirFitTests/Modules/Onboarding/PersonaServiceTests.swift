import XCTest
@testable import AirFit
import SwiftData

@MainActor
final class PersonaServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: PersonaService!
    private var mockPersonaSynthesizer: MockOptimizedPersonaSynthesizer!
    private var mockLLMOrchestrator: MockLLMOrchestrator!
    private var mockCache: MockAIResponseCache!
    private var container: DIContainer!
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var testUser: User!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        // Setup handled in async setupTest method
    }
    
    override func tearDown() {
        sut = nil
        mockPersonaSynthesizer = nil
        mockLLMOrchestrator = nil
        mockCache = nil
        container = nil
        modelContainer = nil
        modelContext = nil
        testUser = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func setupTest(
        shouldSynthesizerThrow: Bool = false,
        synthesizerError: Error = PersonaError.invalidResponse("Test error"),
        shouldLLMThrow: Bool = false,
        llmError: Error = AppError.networkError("Test error")
    ) async throws {
        // Create test container
        container = try await DITestHelper.createTestContainer()
        modelContainer = try await container.resolve(ModelContainer.self)
        modelContext = ModelContext(modelContainer)
        
        // Create test user
        testUser = User(email: "test@example.com", name: "Test User")
        modelContext.insert(testUser)
        try modelContext.save()
        
        // Setup mocks
        mockPersonaSynthesizer = MockOptimizedPersonaSynthesizer()
        mockPersonaSynthesizer.stubbedSynthesizeResult = shouldSynthesizerThrow 
            ? .failure(synthesizerError) 
            : .success(PersonaProfile.mock)
        
        mockLLMOrchestrator = MockLLMOrchestrator()
        mockLLMOrchestrator.stubbedCompleteResult = shouldLLMThrow
            ? .failure(llmError)
            : .success(LLMResponse(
                content: """
                {
                    "name": "Coach Alex",
                    "archetype": "Motivational Expert",
                    "energy": "high",
                    "warmth": "very_warm",
                    "formality": "casual"
                }
                """,
                model: "claude-3-haiku",
                usage: LLMUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
            ))
        
        mockCache = MockAIResponseCache()
        
        // Create SUT
        sut = PersonaService(
            personaSynthesizer: mockPersonaSynthesizer,
            llmOrchestrator: mockLLMOrchestrator,
            modelContext: modelContext,
            cache: mockCache
        )
    }
    
    private func createConversationSession(
        with responses: [(nodeId: String, value: ResponseValue)]
    ) -> ConversationSession {
        let session = ConversationSession(userId: testUser.id)
        
        for (nodeId, value) in responses {
            let responseData = try! JSONEncoder().encode(value)
            let response = ConversationResponse(
                sessionId: session.id,
                nodeId: nodeId,
                responseData: responseData
            )
            session.responses.append(response)
        }
        
        return session
    }
    
    // MARK: - Generate Persona Tests
    
    func test_generatePersona_withValidSession_returnsPersonaProfile() async throws {
        // Arrange
        try await setupTest()
        let session = createConversationSession(with: [
            ("name", .text("Sarah")),
            ("goals", .text("Lose weight and build strength")),
            ("experience", .choice("intermediate"))
        ])
        
        // Act
        let persona = try await sut.generatePersona(from: session)
        
        // Assert
        XCTAssertEqual(persona.name, "Coach Sarah")
        XCTAssertNotNil(persona.systemPrompt)
        mockPersonaSynthesizer.verify("synthesizePersona", called: 1)
    }
    
    func test_generatePersona_extractsUserName() async throws {
        // Arrange
        try await setupTest()
        let session = createConversationSession(with: [
            ("name", .text("John Doe")),
            ("goals", .text("Get fit"))
        ])
        
        // Act
        _ = try await sut.generatePersona(from: session)
        
        // Assert
        let lastConversationData = mockPersonaSynthesizer.lastConversationData
        XCTAssertEqual(lastConversationData?.userName, "John Doe")
    }
    
    func test_generatePersona_extractsPrimaryGoal() async throws {
        // Arrange
        try await setupTest()
        let session = createConversationSession(with: [
            ("name", .text("User")),
            ("primaryGoal", .text("Run a marathon"))
        ])
        
        // Act
        _ = try await sut.generatePersona(from: session)
        
        // Assert
        let lastConversationData = mockPersonaSynthesizer.lastConversationData
        XCTAssertEqual(lastConversationData?.primaryGoal, "Run a marathon")
    }
    
    func test_generatePersona_withEmptySession_usesDefaults() async throws {
        // Arrange
        try await setupTest()
        let session = ConversationSession(userId: testUser.id)
        
        // Act
        _ = try await sut.generatePersona(from: session)
        
        // Assert
        let lastConversationData = mockPersonaSynthesizer.lastConversationData
        XCTAssertEqual(lastConversationData?.userName, "Friend")
        XCTAssertEqual(lastConversationData?.primaryGoal, "improve fitness")
    }
    
    func test_generatePersona_whenSynthesizerFails_throwsError() async throws {
        // Arrange
        try await setupTest(shouldSynthesizerThrow: true)
        let session = createConversationSession(with: [
            ("name", .text("User"))
        ])
        
        // Act & Assert
        do {
            _ = try await sut.generatePersona(from: session)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is PersonaError)
        }
    }
    
    // MARK: - Adjust Persona Tests
    
    func test_adjustPersona_withValidAdjustment_returnsModifiedPersona() async throws {
        // Arrange
        try await setupTest()
        let originalPersona = PersonaProfile.mock
        
        // Act
        let adjusted = try await sut.adjustPersona(
            originalPersona,
            adjustment: "Be more energetic and use more emojis"
        )
        
        // Assert
        XCTAssertEqual(adjusted.name, "Coach Alex") // From mock response
        XCTAssertEqual(adjusted.archetype, "Motivational Expert")
        mockLLMOrchestrator.verify("complete", called: 1)
    }
    
    func test_adjustPersona_preservesOriginalValues() async throws {
        // Arrange
        try await setupTest()
        let originalPersona = PersonaProfile.mock
        
        // Configure mock to return partial update
        mockLLMOrchestrator.stubbedCompleteResult = .success(LLMResponse(
            content: """
            {
                "energy": "very_high",
                "warmth": "warm"
            }
            """,
            model: "claude-3-haiku",
            usage: LLMUsage(promptTokens: 100, completionTokens: 50, totalTokens: 150)
        ))
        
        // Act
        let adjusted = try await sut.adjustPersona(
            originalPersona,
            adjustment: "More energy"
        )
        
        // Assert
        XCTAssertEqual(adjusted.name, originalPersona.name) // Preserved
        XCTAssertEqual(adjusted.coreValues, originalPersona.coreValues) // Preserved
        XCTAssertEqual(adjusted.voiceCharacteristics.energy, .veryHigh) // Updated
    }
    
    func test_adjustPersona_whenLLMFails_throwsError() async throws {
        // Arrange
        try await setupTest(shouldLLMThrow: true)
        let persona = PersonaProfile.mock
        
        // Act & Assert
        do {
            _ = try await sut.adjustPersona(persona, adjustment: "Be different")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Save Persona Tests
    
    func test_savePersona_createsNewProfile() async throws {
        // Arrange
        try await setupTest()
        let persona = PersonaProfile.mock
        
        // Act
        try await sut.savePersona(persona, for: testUser.id)
        
        // Assert
        XCTAssertNotNil(testUser.onboardingProfile)
        XCTAssertEqual(testUser.onboardingProfile?.name, "Coach Sarah")
        XCTAssertNotNil(testUser.onboardingProfile?.personaData)
        XCTAssertTrue(testUser.onboardingProfile?.isComplete ?? false)
    }
    
    func test_savePersona_updatesExistingProfile() async throws {
        // Arrange
        try await setupTest()
        
        // Create existing profile
        let existingProfile = OnboardingProfile.mock
        existingProfile.name = "Old Coach"
        testUser.onboardingProfile = existingProfile
        try modelContext.save()
        
        let newPersona = PersonaProfile.mockWithName("New Coach")
        
        // Act
        try await sut.savePersona(newPersona, for: testUser.id)
        
        // Assert
        XCTAssertEqual(testUser.onboardingProfile?.name, "New Coach")
        XCTAssertEqual(testUser.onboardingProfile?.id, existingProfile.id) // Same profile updated
    }
    
    func test_savePersona_whenUserNotFound_throwsError() async throws {
        // Arrange
        try await setupTest()
        let persona = PersonaProfile.mock
        let nonExistentUserId = UUID()
        
        // Act & Assert
        do {
            try await sut.savePersona(persona, for: nonExistentUserId)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? AppError, AppError.userNotFound)
        }
    }
    
    // MARK: - Response Processing Tests
    
    func test_generatePersona_handlesAllResponseTypes() async throws {
        // Arrange
        try await setupTest()
        let session = createConversationSession(with: [
            ("text_node", .text("Text response")),
            ("choice_node", .choice("option_a")),
            ("multi_node", .multiChoice(["option1", "option2"])),
            ("slider_node", .slider(7.5)),
            ("voice_node", .voice("Voice transcription", duration: 5.0))
        ])
        
        // Act
        _ = try await sut.generatePersona(from: session)
        
        // Assert
        let lastConversationData = mockPersonaSynthesizer.lastConversationData
        XCTAssertEqual(lastConversationData?.responses["text_node"] as? String, "Text response")
        XCTAssertEqual(lastConversationData?.responses["choice_node"] as? String, "option_a")
        XCTAssertEqual((lastConversationData?.responses["multi_node"] as? [String])?.count, 2)
        XCTAssertEqual(lastConversationData?.responses["slider_node"] as? Double, 7.5)
        XCTAssertEqual(lastConversationData?.responses["voice_node"] as? String, "Voice transcription")
    }
    
    // MARK: - Performance Tests
    
    func test_generatePersona_performance() async throws {
        // Arrange
        try await setupTest()
        mockPersonaSynthesizer.generationDelay = 0.1 // Simulate some processing
        
        let session = createConversationSession(with: [
            ("name", .text("User")),
            ("goals", .text("Get fit"))
        ])
        
        // Act & Assert
        let start = Date()
        _ = try await sut.generatePersona(from: session)
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(duration, 3.0, "Persona generation should complete within 3 seconds")
    }
}

// MARK: - Mock Helpers

final class MockOptimizedPersonaSynthesizer: @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    var stubbedSynthesizeResult: Result<PersonaProfile, Error> = .success(.mock)
    var generationDelay: TimeInterval = 0
    var lastConversationData: ConversationData?
    var lastInsights: ConversationPersonalityInsights?
    
    func synthesizePersona(
        from conversationData: ConversationData,
        insights: ConversationPersonalityInsights
    ) async throws -> PersonaProfile {
        recordInvocation(#function, arguments: conversationData, insights)
        
        lastConversationData = conversationData
        lastInsights = insights
        
        if generationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(generationDelay * 1_000_000_000))
        }
        
        switch stubbedSynthesizeResult {
        case .success(let persona):
            return persona
        case .failure(let error):
            throw error
        }
    }
}

final class MockAIResponseCache: @preconcurrency MockProtocol {
    var invocations: [String: [Any]] = [:]
    var stubbedResults: [String: Any] = [:]
    let mockLock = NSLock()
    
    private var cache: [String: Any] = [:]
    
    func get(_ key: String) -> Any? {
        recordInvocation(#function, arguments: key)
        return cache[key]
    }
    
    func set(_ key: String, value: Any) {
        recordInvocation(#function, arguments: key, value)
        cache[key] = value
    }
    
    func clear() {
        recordInvocation(#function)
        cache.removeAll()
    }
}