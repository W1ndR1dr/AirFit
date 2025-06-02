import XCTest
import SwiftData
@testable import AirFit

/// Performance tests for onboarding - Carmack style validation
final class OnboardingPerformanceTests: XCTestCase {
    
    var coordinator: OnboardingFlowCoordinator!
    var cache: AIResponseCache!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let container = try ModelContainer.createTestContainer()
        modelContext = container.mainContext
        
        cache = AIResponseCache()
        
        let llmOrchestrator = MockLLMOrchestrator()
        let optimizedSynthesizer = OptimizedPersonaSynthesizer(
            llmOrchestrator: llmOrchestrator,
            cache: cache
        )
        
        // Use regular PersonaSynthesizer wrapper
        let synthesizer = PersonaSynthesizer(llmOrchestrator: llmOrchestrator)
        
        let personaService = PersonaService(
            personaSynthesizer: synthesizer,
            llmOrchestrator: llmOrchestrator,
            modelContext: modelContext,
            cache: cache
        )
        
        coordinator = OnboardingFlowCoordinator(
            conversationManager: ConversationFlowManager(),
            personaService: personaService,
            userService: MockUserService(),
            modelContext: modelContext
        )
    }
    
    // MARK: - Persona Generation Performance
    
    func testPersonaGenerationUnder3Seconds() async throws {
        // Setup conversation
        await coordinator.beginConversation()
        
        guard let session = coordinator.conversationSession else {
            XCTFail("No session created")
            return
        }
        
        // Add realistic responses
        session.responses = createRealisticResponses()
        try modelContext.save()
        
        // Measure generation time
        let startTime = CFAbsoluteTimeGetCurrent()
        await coordinator.completeConversation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNotNil(coordinator.generatedPersona)
        XCTAssertLessThan(duration, 3.0, "Persona generation took \(String(format: "%.2f", duration))s - target is <3s")
    }
    
    func testCachedPersonaGenerationUnder100ms() async throws {
        // First generation
        await setupAndGeneratePersona()
        
        // Clear persona but keep cache
        coordinator.generatedPersona = nil
        
        // Second generation (should hit cache)
        let startTime = CFAbsoluteTimeGetCurrent()
        await coordinator.completeConversation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(duration, 0.1, "Cached generation took \(String(format: "%.3f", duration))s - target is <100ms")
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageUnder50MB() async throws {
        let initialMemory = getMemoryUsage()
        
        // Generate 5 personas
        for _ in 0..<5 {
            await setupAndGeneratePersona()
            coordinator.cleanup() // Simulate completion
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncreaseMB = Double(finalMemory - initialMemory) / 1_048_576
        
        XCTAssertLessThan(memoryIncreaseMB, 50.0, "Memory increased by \(String(format: "%.1f", memoryIncreaseMB))MB - target is <50MB")
    }
    
    func testMemoryWarningHandling() async throws {
        await setupAndGeneratePersona()
        
        let initialPersona = coordinator.generatedPersona
        XCTAssertNotNil(initialPersona)
        
        // Simulate memory warning
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Give time for async handling
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Should clear non-essential memory
        XCTAssertNil(coordinator.conversationSession)
        XCTAssertNotNil(coordinator.generatedPersona) // Should keep persona
    }
    
    // MARK: - Cache Performance
    
    func testOnboardingCachePerformance() async throws {
        let cache = OnboardingCache()
        let userId = UUID()
        
        let conversationData = ConversationData(
            userName: "Test",
            primaryGoal: "Fitness",
            responses: createLargeResponseDict()
        )
        
        let responses = createRealisticResponses()
        
        // Measure save time
        let saveStart = CFAbsoluteTimeGetCurrent()
        await cache.saveSession(
            userId: userId,
            conversationData: conversationData,
            insights: nil,
            currentStep: "conversation",
            responses: responses
        )
        let saveDuration = CFAbsoluteTimeGetCurrent() - saveStart
        
        // Should be nearly instant (async save)
        XCTAssertLessThan(saveDuration, 0.01, "Save took \(String(format: "%.3f", saveDuration))s")
        
        // Measure restore time
        let restoreStart = CFAbsoluteTimeGetCurrent()
        let restored = await cache.restoreSession(userId: userId)
        let restoreDuration = CFAbsoluteTimeGetCurrent() - restoreStart
        
        XCTAssertNotNil(restored)
        XCTAssertLessThan(restoreDuration, 0.1, "Restore took \(String(format: "%.3f", restoreDuration))s - target is <100ms")
    }
    
    // MARK: - Network Optimization
    
    func testRequestOptimizerBatching() async throws {
        let optimizer = RequestOptimizer()
        var requests: [URLRequest] = []
        
        // Create batch-compatible requests
        for i in 0..<5 {
            var request = URLRequest(url: URL(string: "https://api.example.com/api/batch-compatible/\(i)")!)
            request.httpMethod = "GET"
            requests.append(request)
        }
        
        // Measure concurrent execution
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Result<Data, Error>.self) { group in
            for request in requests {
                group.addTask {
                    do {
                        let data = try await optimizer.execute(request)
                        return .success(data)
                    } catch {
                        return .failure(error)
                    }
                }
            }
            
            var results: [Result<Data, Error>] = []
            for await result in group {
                results.append(result)
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should batch efficiently
        XCTAssertLessThan(duration, 1.0, "Batch execution took \(String(format: "%.2f", duration))s")
    }
    
    // MARK: - End-to-End Performance
    
    func testCompleteOnboardingFlowPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. Start onboarding
        coordinator.start()
        
        // 2. Begin conversation
        await coordinator.beginConversation()
        
        // 3. Simulate user responses (instant)
        if let session = coordinator.conversationSession {
            session.responses = createRealisticResponses()
            try modelContext.save()
        }
        
        // 4. Complete conversation and generate persona
        await coordinator.completeConversation()
        
        // 5. Accept persona
        await coordinator.acceptPersona()
        
        let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertEqual(coordinator.currentView, .complete)
        XCTAssertLessThan(totalDuration, 5.0, "Complete flow took \(String(format: "%.2f", totalDuration))s - target is <5s")
    }
    
    // MARK: - Helper Methods
    
    private func setupAndGeneratePersona() async {
        coordinator.start()
        await coordinator.beginConversation()
        
        if let session = coordinator.conversationSession {
            session.responses = createRealisticResponses()
            try? modelContext.save()
        }
        
        await coordinator.completeConversation()
    }
    
    private func createRealisticResponses() -> [ConversationResponse] {
        [
            ConversationResponse(
                nodeId: "name",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Alex"))
            ),
            ConversationResponse(
                nodeId: "goals",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Lose 20 pounds and build muscle"))
            ),
            ConversationResponse(
                nodeId: "experience",
                responseType: "choice",
                responseData: try! JSONEncoder().encode(ResponseValue.choice("intermediate"))
            ),
            ConversationResponse(
                nodeId: "preferences",
                responseType: "multiChoice",
                responseData: try! JSONEncoder().encode(ResponseValue.multiChoice(["morning", "gym", "strength training"]))
            ),
            ConversationResponse(
                nodeId: "lifestyle",
                responseType: "text",
                responseData: try! JSONEncoder().encode(ResponseValue.text("Busy professional, sedentary job"))
            )
        ]
    }
    
    private func createLargeResponseDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        for i in 0..<100 {
            dict["key\(i)"] = "value\(i)"
        }
        return dict
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

