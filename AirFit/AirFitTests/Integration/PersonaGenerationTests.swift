import XCTest
import SwiftData
@testable import AirFit

final class PersonaGenerationTests: XCTestCase {
    
    var personaService: PersonaService!
    var modelContext: ModelContext!
    var mockLLMOrchestrator: MockLLMOrchestrator!
    var personaSynthesizer: PersonaSynthesizer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test container
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        
        // Create mock LLM orchestrator
        mockLLMOrchestrator = MockLLMOrchestrator()
        
        // Create persona synthesizer with mock
        personaSynthesizer = PersonaSynthesizer(llmOrchestrator: mockLLMOrchestrator)
        
        // Create persona service
        personaService = PersonaService(
            personaSynthesizer: personaSynthesizer,
            llmOrchestrator: mockLLMOrchestrator,
            modelContext: modelContext
        )
    }
    
    override func tearDown() async throws {
        personaService = nil
        modelContext = nil
        mockLLMOrchestrator = nil
        personaSynthesizer = nil
        try await super.tearDown()
    }
    
    // MARK: - Persona Generation Tests
    
    func testPersonaGenerationFromConversation() async throws {
        // Create test conversation session
        let session = createTestConversationSession()
        modelContext.insert(session)
        try modelContext.save()
        
        // Generate persona
        let startTime = CFAbsoluteTimeGetCurrent()
        let persona = try await personaService.generatePersona(from: session)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Verify persona properties
        XCTAssertFalse(persona.name.isEmpty)
        XCTAssertFalse(persona.archetype.isEmpty)
        XCTAssertFalse(persona.systemPrompt.isEmpty)
        XCTAssertFalse(persona.coreValues.isEmpty)
        XCTAssertFalse(persona.backgroundStory.isEmpty)
        
        // Verify voice characteristics
        XCTAssertNotNil(persona.voiceCharacteristics)
        
        // Verify interaction style
        XCTAssertNotNil(persona.interactionStyle)
        XCTAssertFalse(persona.interactionStyle.encouragementPhrases.isEmpty)
        
        // Verify metadata
        XCTAssertTrue(persona.metadata.previewReady)
        XCTAssertGreaterThan(persona.metadata.tokenCount, 0)
        
        // Performance check
        XCTAssertLessThan(duration, 5.0, "Persona generation took \(duration)s, exceeding 5s target")
    }
    
    func testPersonaGenerationWithMinimalData() async throws {
        // Create minimal session
        let session = ConversationSession(userId: UUID())
        session.responses = [
            ConversationResponse(
                nodeId: "name",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("User"))
            ),
            ConversationResponse(
                nodeId: "goals",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Get fit"))
            )
        ]
        modelContext.insert(session)
        
        // Generate persona
        let persona = try await personaService.generatePersona(from: session)
        
        // Should still generate valid persona
        XCTAssertFalse(persona.name.isEmpty)
        XCTAssertEqual(persona.name, "Coach") // Default fallback
    }
    
    // MARK: - Persona Adjustment Tests
    
    func testPersonaAdjustment() async throws {
        // Create initial persona
        let originalPersona = createTestPersona()
        
        // Apply adjustment
        let adjustment = "Be more energetic and use more motivational language"
        let adjustedPersona = try await personaService.adjustPersona(originalPersona, adjustment: adjustment)
        
        // Verify adjustment was applied
        XCTAssertEqual(adjustedPersona.id, originalPersona.id) // Same persona ID
        XCTAssertNotEqual(adjustedPersona.metadata.lastModified, originalPersona.metadata.createdAt)
        
        // In mock, we simulate energy change
        XCTAssertEqual(adjustedPersona.voiceCharacteristics.energy, .high)
    }
    
    func testMultipleAdjustments() async throws {
        var persona = createTestPersona()
        
        // Apply multiple adjustments
        let adjustments = [
            "Be more casual",
            "Add humor",
            "Be more concise"
        ]
        
        for adjustment in adjustments {
            persona = try await personaService.adjustPersona(persona, adjustment: adjustment)
        }
        
        // Verify cumulative adjustments
        XCTAssertEqual(persona.interactionStyle.formalityLevel, .casual)
        XCTAssertEqual(persona.interactionStyle.humorLevel, .moderate)
        XCTAssertEqual(persona.interactionStyle.responseLength, .concise)
    }
    
    // MARK: - Persona Saving Tests
    
    func testPersonaSaving() async throws {
        let userId = UUID()
        let persona = createTestPersona()
        
        // Save persona
        try await personaService.savePersona(persona, for: userId)
        
        // Verify saved
        let descriptor = FetchDescriptor<OnboardingProfile>(
            predicate: #Predicate { profile in
                profile.userId == userId
            }
        )
        let profiles = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.personaName, persona.name)
        XCTAssertNotNil(profiles.first?.personaData)
    }
    
    func testPersonaUpdate() async throws {
        let userId = UUID()
        
        // Save initial persona
        let persona1 = createTestPersona(name: "Coach Alex")
        try await personaService.savePersona(persona1, for: userId)
        
        // Update with new persona
        let persona2 = createTestPersona(name: "Coach Blake")
        try await personaService.savePersona(persona2, for: userId)
        
        // Verify only one profile exists
        let descriptor = FetchDescriptor<OnboardingProfile>()
        let profiles = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.personaName, "Coach Blake")
    }
    
    // MARK: - Performance Tests
    
    func testPersonaGenerationPerformance() async throws {
        let session = createTestConversationSession()
        
        measure {
            let expectation = XCTestExpectation(description: "Persona generation")
            
            Task {
                _ = try await personaService.generatePersona(from: session)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testConcurrentPersonaGeneration() async throws {
        let sessions = (0..<5).map { _ in createTestConversationSession() }
        
        await withTaskGroup(of: PersonaProfile?.self) { group in
            for session in sessions {
                group.addTask { [personaService] in
                    try? await personaService?.generatePersona(from: session)
                }
            }
            
            var results: [PersonaProfile?] = []
            for await result in group {
                results.append(result)
            }
            
            // All should succeed
            XCTAssertEqual(results.compactMap { $0 }.count, sessions.count)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testPersonaGenerationFailure() async throws {
        // Configure mock to fail
        mockLLMOrchestrator.shouldFail = true
        
        let session = createTestConversationSession()
        
        do {
            _ = try await personaService.generatePersona(from: session)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testInvalidResponseData() async throws {
        let session = ConversationSession(userId: UUID())
        session.responses = [
            ConversationResponse(
                nodeId: "invalid",
                responseType: "unknown",
                responseData: Data() // Invalid data
            )
        ]
        
        // Should handle gracefully
        let persona = try await personaService.generatePersona(from: session)
        XCTAssertFalse(persona.name.isEmpty) // Should use defaults
    }
    
    // MARK: - Helper Methods
    
    private func createTestConversationSession() -> ConversationSession {
        let session = ConversationSession(userId: UUID())
        session.responses = [
            ConversationResponse(
                nodeId: "name",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Alex"))
            ),
            ConversationResponse(
                nodeId: "goals",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Build muscle and lose fat"))
            ),
            ConversationResponse(
                nodeId: "experience",
                responseType: "choice",
                responseData: try! JSONEncoder().encode(ResponseValue.choice("intermediate"))
            ),
            ConversationResponse(
                nodeId: "preferences",
                responseType: "multiChoice",
                responseData: try! JSONEncoder().encode(ResponseValue.multiChoice(["morning", "gym", "strength"]))
            ),
            ConversationResponse(
                nodeId: "personality",
                responseType: "slider",
                responseData: try! JSONEncoder().encode(ResponseValue.slider(0.8))
            )
        ]
        return session
    }
    
    private func createTestPersona(name: String = "Coach Test") -> PersonaProfile {
        PersonaProfile(
            id: UUID(),
            name: name,
            archetype: "The Motivator",
            systemPrompt: "You are an encouraging fitness coach...",
            coreValues: ["Progress", "Consistency", "Balance"],
            backgroundStory: "Former athlete turned coach...",
            voiceCharacteristics: VoiceCharacteristics(
                energy: .moderate,
                pace: .natural,
                warmth: .warm,
                vocabulary: .moderate,
                sentenceStructure: .moderate
            ),
            interactionStyle: InteractionStyle(
                greetingStyle: "Hey there!",
                closingStyle: "Keep it up!",
                encouragementPhrases: ["Great job!", "You've got this!"],
                acknowledgmentStyle: "I hear you",
                correctionApproach: "Let's adjust",
                humorLevel: .light,
                formalityLevel: .balanced,
                responseLength: .moderate
            ),
            adaptationRules: [],
            metadata: PersonaMetadata(
                createdAt: Date(),
                version: "1.0",
                sourceInsights: PersonalityInsights(
                    traits: [:],
                    motivationalDrivers: [],
                    communicationProfile: CommunicationProfile(
                        preferredTone: .casual,
                        detailLevel: .moderate,
                        feedbackStyle: .positive,
                        interactionFrequency: .regular
                    ),
                    stressResponses: [:],
                    timePreferences: TimePreferences(),
                    coachingPreferences: CoachingPreferences(
                        preferredIntensity: .moderate,
                        accountabilityLevel: .high,
                        motivationStyle: .positive,
                        feedbackTiming: .immediate
                    ),
                    inferredDemographics: nil,
                    extractedAt: Date()
                ),
                generationDuration: 3.0,
                tokenCount: 450,
                previewReady: true
            )
        )
    }
}

// MARK: - Mock LLM Orchestrator

private class MockLLMOrchestrator: LLMOrchestrator {
    var shouldFail = false
    
    override func complete(_ request: LLMRequest) async throws -> LLMResponse {
        if shouldFail {
            throw LLMError.requestFailed("Mock failure")
        }
        
        // Return mock responses based on request
        if request.messages.last?.content.contains("personality insights") == true {
            return LLMResponse(
                content: """
                {
                    "dominantTraits": ["supportive", "encouraging", "structured"],
                    "communicationStyle": "conversational",
                    "motivationType": "achievement",
                    "energyLevel": "high",
                    "preferredComplexity": "moderate",
                    "emotionalTone": ["warm", "positive"],
                    "stressResponse": "needsSupport",
                    "preferredTimes": ["morning", "evening"]
                }
                """,
                model: "mock",
                usage: LLMUsage(promptTokens: 100, completionTokens: 200, totalTokens: 300),
                finishReason: .stop
            )
        } else if request.messages.last?.content.contains("adjustment") == true {
            // Parse adjustment request
            let content = request.messages.last?.content ?? ""
            var response: [String: Any] = [:]
            
            if content.contains("energetic") {
                response["energy"] = "high"
            }
            if content.contains("casual") {
                response["formality"] = "casual"
            }
            if content.contains("humor") {
                response["humorLevel"] = "moderate"
            }
            if content.contains("concise") {
                response["responseLength"] = "concise"
            }
            
            let jsonData = try! JSONSerialization.data(withJSONObject: response)
            return LLMResponse(
                content: String(data: jsonData, encoding: .utf8),
                model: "mock",
                usage: LLMUsage(promptTokens: 50, completionTokens: 100, totalTokens: 150),
                finishReason: .stop
            )
        } else {
            // Default persona generation response
            return LLMResponse(
                content: """
                {
                    "name": "Coach",
                    "archetype": "The Motivator",
                    "systemPrompt": "You are an encouraging fitness coach",
                    "coreValues": ["Progress", "Consistency", "Balance"],
                    "backgroundStory": "Experienced coach helping people achieve their goals"
                }
                """,
                model: "mock",
                usage: LLMUsage(promptTokens: 200, completionTokens: 400, totalTokens: 600),
                finishReason: .stop
            )
        }
    }
}