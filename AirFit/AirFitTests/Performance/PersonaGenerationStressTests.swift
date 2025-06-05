import XCTest
import SwiftData
@testable import AirFit

/// Stress tests for persona generation system
/// Validates performance under various load conditions
final class PersonaGenerationStressTests: XCTestCase {
    
    var orchestrator: OnboardingOrchestrator!
    var synthesizer: PersonaSynthesizer!
    var llmOrchestrator: LLMOrchestrator!
    var modelContext: ModelContext!
    var monitor: MonitoringService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Setup test environment
        let container = try ModelContainer(for: User.self, configurations: .init(isStoredInMemoryOnly: true))
        modelContext = ModelContext(container)
        
        // Initialize services
        let apiKeyManager = MockAPIKeyManager()
        llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        synthesizer = PersonaSynthesizer(llmOrchestrator: llmOrchestrator)
        monitor = MonitoringService.shared
        
        // Initialize orchestrator
        let conversationManager = ConversationManager(modelContext: modelContext)
        orchestrator = await OnboardingOrchestrator(
            conversationManager: conversationManager,
            personaSynthesizer: synthesizer,
            modelContext: modelContext
        )
    }
    
    override func tearDown() async throws {
        await monitor.resetMetrics()
        try await super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    /// Test persona generation stays under 5 second target
    func testPersonaGenerationPerformance() async throws {
        let testData = createTestConversationData()
        let insights = createTestInsights()
        
        let expectation = XCTestExpectation(description: "Persona generation completes")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let persona = try await synthesizer.synthesizePersona(
            from: testData,
            insights: insights
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNotNil(persona)
        XCTAssertLessThan(duration, 5.0, "Persona generation took \(duration)s, exceeding 5s target")
        
        // Verify quality metrics
        XCTAssertFalse(persona.name.isEmpty)
        XCTAssertFalse(persona.systemPrompt.isEmpty)
        XCTAssertLessThan(persona.metadata.tokenCount, 600, "System prompt too long")
        
        await monitor.trackPersonaGeneration(duration: duration, success: true, model: "test")
        expectation.fulfill()
        
        await fulfillment(of: [expectation], timeout: 10)
    }
    
    /// Test concurrent persona generation
    func testConcurrentPersonaGeneration() async throws {
        let concurrentCount = 5
        var durations: [TimeInterval] = []
        
        await withTaskGroup(of: (TimeInterval, PersonaProfile?).self) { group in
            for i in 0..<concurrentCount {
                group.addTask { [self] in
                    let testData = self.createTestConversationData(variant: i)
                    let insights = self.createTestInsights(variant: i)
                    
                    let startTime = CFAbsoluteTimeGetCurrent()
                    
                    do {
                        let persona = try await self.synthesizer.synthesizePersona(
                            from: testData,
                            insights: insights
                        )
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        return (duration, persona)
                    } catch {
                        return (CFAbsoluteTimeGetCurrent() - startTime, nil)
                    }
                }
            }
            
            for await (duration, persona) in group {
                durations.append(duration)
                XCTAssertNotNil(persona, "Persona generation failed")
            }
        }
        
        // All should complete under 10s even with concurrency
        let maxDuration = durations.max() ?? 0
        XCTAssertLessThan(maxDuration, 10.0, "Concurrent generation too slow: \(maxDuration)s")
        
        // Average should still be reasonable
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        XCTAssertLessThan(avgDuration, 7.0, "Average generation time too high: \(avgDuration)s")
    }
    
    /// Test memory usage during stress
    func testMemoryUsageUnderLoad() async throws {
        let initialMemory = getMemoryUsage()
        var personas: [PersonaProfile] = []
        
        // Generate multiple personas
        for i in 0..<10 {
            let testData = createTestConversationData(variant: i)
            let insights = createTestInsights(variant: i)
            
            let persona = try await synthesizer.synthesizePersona(
                from: testData,
                insights: insights
            )
            personas.append(persona)
        }
        
        let peakMemory = getMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1_000_000
        
        XCTAssertLessThan(memoryIncreaseMB, 50, "Memory usage increased by \(memoryIncreaseMB)MB")
        
        // Verify all personas are valid
        for persona in personas {
            XCTAssertFalse(persona.name.isEmpty)
            XCTAssertFalse(persona.systemPrompt.isEmpty)
        }
    }
    
    /// Test cache effectiveness
    func testCachePerformance() async throws {
        let testData = createTestConversationData()
        let insights = createTestInsights()
        
        // First generation (cache miss)
        let firstStart = CFAbsoluteTimeGetCurrent()
        let persona1 = try await synthesizer.synthesizePersona(
            from: testData,
            insights: insights
        )
        let firstDuration = CFAbsoluteTimeGetCurrent() - firstStart
        
        // Second generation (cache hit)
        let secondStart = CFAbsoluteTimeGetCurrent()
        let persona2 = try await synthesizer.synthesizePersona(
            from: testData,
            insights: insights
        )
        let secondDuration = CFAbsoluteTimeGetCurrent() - secondStart
        
        // Cache should make it much faster
        XCTAssertLessThan(secondDuration, firstDuration * 0.1, 
                         "Cache not effective: first=\(firstDuration)s, second=\(secondDuration)s")
        
        // Personas should be identical
        XCTAssertEqual(persona1.name, persona2.name)
        XCTAssertEqual(persona1.systemPrompt, persona2.systemPrompt)
    }
    
    /// Test error recovery under stress
    func testErrorRecoveryUnderLoad() async throws {
        let recovery = OnboardingRecovery(
            modelContext: modelContext,
            analytics: ConversationAnalytics()
        )
        
        let sessionId = UUID().uuidString
        
        // Simulate various errors
        let errors: [OnboardingOrchestratorError] = [
            .networkError(NSError(domain: "test", code: -1)),
            .timeout,
            .synthesisFailed("Test failure"),
            .responseProcessingFailed("Invalid response")
        ]
        
        for (index, error) in errors.enumerated() {
            let canRecover = await recovery.canRecover(from: error, sessionId: sessionId)
            XCTAssertTrue(canRecover, "Should be able to recover from \(error)")
            
            let plan = await recovery.createRecoveryPlan(for: error, sessionId: sessionId)
            XCTAssertNotEqual(plan.strategy, .none)
            XCTAssertFalse(plan.actions.isEmpty)
            
            await recovery.recordError(error, sessionId: sessionId)
        }
        
        // After max retries, should not recover
        let finalError = OnboardingOrchestratorError.networkError(NSError(domain: "test", code: -1))
        let canRecoverFinal = await recovery.canRecover(from: finalError, sessionId: sessionId)
        XCTAssertFalse(canRecoverFinal, "Should not recover after max retries")
    }
    
    // MARK: - Stress Scenarios
    
    /// Test with extremely long conversation history
    func testLongConversationHistory() async throws {
        var testData = createTestConversationData()
        
        // Add 50 conversation turns
        for i in 0..<50 {
            testData.responses.append(ConversationResponse(
                nodeId: "node_\(i)",
                question: "Question \(i)",
                answer: "This is a detailed answer for question \(i) with some context.",
                timestamp: Date()
            ))
        }
        
        let insights = createTestInsights()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let persona = try await synthesizer.synthesizePersona(
            from: testData,
            insights: insights
        )
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNotNil(persona)
        XCTAssertLessThan(duration, 8.0, "Long conversation synthesis too slow: \(duration)s")
    }
    
    /// Test rapid successive requests
    func testRapidSuccessiveRequests() async throws {
        let requestCount = 20
        var successCount = 0
        var totalDuration: TimeInterval = 0
        
        for i in 0..<requestCount {
            let testData = createTestConversationData(variant: i)
            let insights = createTestInsights(variant: i)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                _ = try await synthesizer.synthesizePersona(
                    from: testData,
                    insights: insights
                )
                successCount += 1
                totalDuration += CFAbsoluteTimeGetCurrent() - startTime
            } catch {
                // Track failures but continue
                print("Request \(i) failed: \(error)")
            }
            
            // Small delay between requests
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        
        let successRate = Double(successCount) / Double(requestCount)
        XCTAssertGreaterThan(successRate, 0.9, "Success rate too low: \(successRate)")
        
        let avgDuration = totalDuration / Double(successCount)
        XCTAssertLessThan(avgDuration, 6.0, "Average duration too high: \(avgDuration)s")
    }
    
    // MARK: - Helper Methods
    
    private func createTestConversationData(variant: Int = 0) -> ConversationData {
        ConversationData(
            sessionId: UUID(),
            userId: UUID(),
            startTime: Date(),
            endTime: Date(),
            summary: "Test conversation \(variant) for stress testing",
            extractedData: [
                "primaryGoal": "Get fit and healthy",
                "fitnessLevel": "intermediate",
                "preferences": ["morning workouts", "strength training"]
            ],
            responses: [
                ConversationResponse(
                    nodeId: "greeting",
                    question: "How can I help you today?",
                    answer: "I want to get in better shape variant \(variant)",
                    timestamp: Date()
                )
            ],
            nodeCount: 12,
            completionPercentage: 100
        )
    }
    
    private func createTestInsights(variant: Int = 0) -> PersonalityInsights {
        PersonalityInsights(
            dominantTraits: ["supportive", "encouraging"],
            communicationStyle: .conversational,
            motivationType: .intrinsic,
            energyLevel: .moderate,
            preferredComplexity: .moderate,
            emotionalTone: ["warm", "friendly"],
            stressResponse: .needsSupport,
            preferredTimes: ["morning"],
            extractedAt: Date()
        )
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

