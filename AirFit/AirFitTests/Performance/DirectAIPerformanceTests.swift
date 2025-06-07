import XCTest
import SwiftData
@testable import AirFit

final class DirectAIPerformanceTests: XCTestCase {
    
    private var coachEngine: CoachEngine!
    private var mockModelContext: ModelContext!
    private var testUser: User!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test model context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: User.self, configurations: config)
        mockModelContext = ModelContext(container)
        
        // Create test user with persona
        testUser = User(email: "test@example.com", name: "Test User")
        
        // Create onboarding profile with mock data
        let onboardingProfile = OnboardingProfile(
            personaPromptData: Data(),
            communicationPreferencesData: Data(),
            rawFullProfileData: Data()
        )
        
        // Create a test persona profile
        let testPersona = createTestPersonaProfile()
        onboardingProfile.persona = testPersona
        
        testUser.onboardingProfile = onboardingProfile
        mockModelContext.insert(testUser)
        try mockModelContext.save()
        
        // Create CoachEngine with mock services
        coachEngine = CoachEngine.createDefault(modelContext: mockModelContext)
    }
    
    override func tearDown() async throws {
        coachEngine = nil
        mockModelContext = nil
        testUser = nil
        try await super.tearDown()
    }
    
    // MARK: - Nutrition Parsing Performance Tests
    
    func test_nutritionParsing_directAI_performance() async throws {
        // Given - variety of nutrition parsing scenarios
        let testCases = [
            "apple and banana",
            "grilled chicken with rice", 
            "protein shake 30g whey",
            "oatmeal with blueberries and honey",
            "salmon 6oz with quinoa and vegetables",
            "2 eggs scrambled with cheese and toast"
        ]
        
        var totalExecutionTime: TimeInterval = 0
        var successCount = 0
        var tokenUsageTotal = 0
        
        // When - test direct AI performance
        for testCase in testCases {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let result = try await coachEngine.parseAndLogNutritionDirect(
                    foodText: testCase,
                    for: testUser,
                    conversationId: UUID()
                )
                
                let executionTime = CFAbsoluteTimeGetCurrent() - startTime
                totalExecutionTime += executionTime
                successCount += 1
                tokenUsageTotal += result.tokenCount
                
                // Validate performance characteristics
                XCTAssertLessThan(result.processingTimeMs, 5000, "Direct AI parsing should complete within 5 seconds")
                XCTAssertGreaterThan(result.items.count, 0, "Should parse at least one item")
                XCTAssertLessThan(result.tokenCount, 300, "Should be token-efficient")
                
            } catch {
                XCTFail("Direct AI parsing failed for '\(testCase)': \(error)")
            }
        }
        
        // Then - verify performance targets
        let averageExecutionTime = totalExecutionTime / Double(testCases.count)
        let averageTokenUsage = Double(tokenUsageTotal) / Double(testCases.count)
        
        XCTAssertEqual(successCount, testCases.count, "All test cases should succeed")
        XCTAssertLessThan(averageExecutionTime, 3.0, "Average execution time should be under 3 seconds")
        XCTAssertLessThan(averageTokenUsage, 200, "Average token usage should be under 200 tokens")
        
        print("🚀 Direct AI Nutrition Performance:")
        print("   Success Rate: \(successCount)/\(testCases.count) (100%)")
        print("   Average Time: \(Int(averageExecutionTime * 1000))ms")
        print("   Average Tokens: \(Int(averageTokenUsage))")
    }
    
    func test_educationalContent_directAI_performance() async throws {
        // Given - variety of educational topics
        let topics = [
            "progressive_overload",
            "nutrition_timing", 
            "recovery_science",
            "hydration",
            "sleep_optimization"
        ]
        
        var totalExecutionTime: TimeInterval = 0
        var successCount = 0
        var totalTokenUsage = 0
        
        // When - test direct AI educational content generation
        for topic in topics {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let result = try await coachEngine.generateEducationalContentDirect(
                    topic: topic,
                    userContext: "I'm an intermediate athlete looking to improve",
                    for: testUser
                )
                
                let executionTime = CFAbsoluteTimeGetCurrent() - startTime
                totalExecutionTime += executionTime
                successCount += 1
                totalTokenUsage += result.tokenCount
                
                // Validate content quality and performance
                XCTAssertGreaterThan(result.content.count, 200, "Content should be substantial")
                XCTAssertLessThan(result.content.count, 1500, "Content should be concise")
                XCTAssertGreaterThan(result.personalizationLevel, 0.1, "Should have meaningful personalization")
                XCTAssertLessThan(result.tokenCount, 600, "Should be token-efficient")
                
            } catch {
                XCTFail("Educational content generation failed for '\(topic)': \(error)")
            }
        }
        
        // Then - verify performance targets
        let averageExecutionTime = totalExecutionTime / Double(topics.count)
        let averageTokenUsage = Double(totalTokenUsage) / Double(topics.count)
        
        XCTAssertEqual(successCount, topics.count, "All content generation should succeed")
        XCTAssertLessThan(averageExecutionTime, 5.0, "Average execution time should be under 5 seconds")
        XCTAssertLessThan(averageTokenUsage, 500, "Average token usage should be under 500 tokens")
        
        print("📚 Direct AI Educational Content Performance:")
        print("   Success Rate: \(successCount)/\(topics.count) (100%)")
        print("   Average Time: \(Int(averageExecutionTime * 1000))ms")
        print("   Average Tokens: \(Int(averageTokenUsage))")
    }
    
    // MARK: - Token Efficiency Tests
    
    func test_tokenEfficiency_shortVsLongInput() async throws {
        // Given - varying input lengths
        let shortInput = "apple"
        let mediumInput = "grilled chicken breast with brown rice"
        let longInput = "grilled chicken breast 8oz with brown rice 1.5 cups, steamed broccoli, side salad with olive oil dressing and cherry tomatoes"
        
        // When - test token usage scaling
        let shortResult = try await coachEngine.parseAndLogNutritionDirect(
            foodText: shortInput,
            for: testUser,
            conversationId: UUID()
        )
        
        let mediumResult = try await coachEngine.parseAndLogNutritionDirect(
            foodText: mediumInput,
            for: testUser,
            conversationId: UUID()
        )
        
        let longResult = try await coachEngine.parseAndLogNutritionDirect(
            foodText: longInput,
            for: testUser,
            conversationId: UUID()
        )
        
        // Then - verify token efficiency principles
        XCTAssertGreaterThan(shortResult.tokenCount, 0, "Should track tokens for short input")
        XCTAssertGreaterThan(mediumResult.tokenCount, shortResult.tokenCount, "Medium input should use more tokens")
        XCTAssertGreaterThan(longResult.tokenCount, mediumResult.tokenCount, "Long input should use most tokens")
        
        // Efficiency targets
        XCTAssertLessThan(shortResult.tokenCount, 150, "Simple parsing should be very token-efficient")
        XCTAssertLessThan(mediumResult.tokenCount, 250, "Medium parsing should be reasonably efficient")
        XCTAssertLessThan(longResult.tokenCount, 400, "Complex parsing should still be reasonable")
        
        print("🔧 Token Efficiency Analysis:")
        print("   Short ('\(shortInput)'): \(shortResult.tokenCount) tokens")
        print("   Medium ('\(mediumInput.prefix(30))...'): \(mediumResult.tokenCount) tokens")
        print("   Long ('\(longInput.prefix(30))...'): \(longResult.tokenCount) tokens")
    }
    
    // MARK: - Stress Testing
    
    func test_directAI_concurrentRequests() async throws {
        // Given - multiple concurrent requests
        let concurrentRequests = 5
        let testInputs = [
            "chicken and rice",
            "protein shake",
            "salmon salad", 
            "oatmeal breakfast",
            "turkey sandwich"
        ]
        
        // When - execute concurrent direct AI requests
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Capture necessary values before entering task group
        let engine = self.coachEngine!
        let user = self.testUser!
        
        await withTaskGroup(of: Void.self) { group in
            for (index, input) in testInputs.enumerated() {
                group.addTask {
                    do {
                        let result = try await engine.parseAndLogNutritionDirect(
                            foodText: input,
                            for: user,
                            conversationId: UUID()
                        )
                        
                        // Validate each concurrent result
                        XCTAssertGreaterThan(result.items.count, 0, "Concurrent request \(index) should parse items")
                        XCTAssertEqual(result.parseStrategy, .directAI, "Should use direct AI strategy")
                        
                    } catch {
                        XCTFail("Concurrent request \(index) failed: \(error)")
                    }
                }
            }
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - verify concurrent performance
        XCTAssertLessThan(totalTime, 10.0, "Concurrent requests should complete within 10 seconds")
        
        print("⚡ Concurrent Request Performance:")
        print("   \(concurrentRequests) requests completed in \(Int(totalTime * 1000))ms")
        print("   Average per request: \(Int(totalTime * 1000 / Double(concurrentRequests)))ms")
    }
    
    // MARK: - Regression Performance Tests
    
    func test_performance_regressionBaseline() async throws {
        // Given - baseline performance test for monitoring regressions
        let standardInput = "grilled chicken breast 6oz with brown rice 1 cup and steamed vegetables"
        let iterations = 3
        
        var executionTimes: [TimeInterval] = []
        var tokenCounts: [Int] = []
        
        // When - run multiple iterations for consistency
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let result = try await coachEngine.parseAndLogNutritionDirect(
                foodText: standardInput,
                for: testUser,
                conversationId: UUID()
            )
            
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            executionTimes.append(executionTime)
            tokenCounts.append(result.tokenCount)
        }
        
        // Then - establish baseline metrics
        let averageTime = executionTimes.reduce(0, +) / Double(iterations)
        let averageTokens = Double(tokenCounts.reduce(0, +)) / Double(iterations)
        
        // Performance regression thresholds
        XCTAssertLessThan(averageTime, 5.0, "Baseline performance should be under 5 seconds")
        XCTAssertLessThan(averageTokens, 300, "Baseline token usage should be under 300")
        
        print("📊 Performance Baseline Established:")
        print("   Average Execution Time: \(Int(averageTime * 1000))ms")
        print("   Average Token Count: \(Int(averageTokens))")
        print("   Standard Input: '\(standardInput)'")
        
        // Store baseline for future comparison (in real implementation, this might be persisted)
        UserDefaults.standard.set(averageTime, forKey: "DirectAI.Performance.Baseline.Time")
        UserDefaults.standard.set(averageTokens, forKey: "DirectAI.Performance.Baseline.Tokens")
    }
    
    // MARK: - Helper Methods
    
    private func createTestPersonaProfile() -> PersonaProfile {
        let voiceCharacteristics = VoiceCharacteristics(
            energy: .moderate,
            pace: .natural,
            warmth: .friendly,
            vocabulary: .moderate,
            sentenceStructure: .moderate
        )
        
        let interactionStyle = InteractionStyle(
            greetingStyle: "Hey there!",
            closingStyle: "Keep it up!",
            encouragementPhrases: ["Great job!", "You're doing awesome!", "Keep going!"],
            acknowledgmentStyle: "I hear you",
            correctionApproach: "gentle",
            humorLevel: .light,
            formalityLevel: .balanced,
            responseLength: .moderate
        )
        
        let metadata = PersonaMetadata(
            createdAt: Date(),
            version: "1.0",
            sourceInsights: ConversationPersonalityInsights(
                dominantTraits: ["supportive", "balanced"],
                communicationStyle: .conversational,
                motivationType: .health,
                energyLevel: .moderate,
                preferredComplexity: .moderate,
                emotionalTone: ["encouraging", "positive"],
                stressResponse: .wantsEncouragement,
                preferredTimes: ["morning", "evening"],
                extractedAt: Date()
            ),
            generationDuration: 2.5,
            tokenCount: 1500,
            previewReady: true
        )
        
        return PersonaProfile(
            id: UUID(),
            name: "Test Coach",
            archetype: "Supportive Mentor",
            systemPrompt: "You are a supportive fitness coach.",
            coreValues: ["health", "balance", "progress"],
            backgroundStory: "A test coach for performance testing.",
            voiceCharacteristics: voiceCharacteristics,
            interactionStyle: interactionStyle,
            adaptationRules: [],
            metadata: metadata
        )
    }
}

// MARK: - Performance Metrics Helper

extension DirectAIPerformanceTests {
    
    /// Helper to measure and validate performance characteristics
    private func measurePerformance<T: Sendable>(
        operation: @Sendable () async throws -> T,
        expectedMaxTime: TimeInterval = 5.0,
        description: String
    ) async throws -> (result: T, executionTime: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(executionTime, expectedMaxTime, "\(description) should complete within \(expectedMaxTime) seconds")
        
        return (result, executionTime)
    }
} 