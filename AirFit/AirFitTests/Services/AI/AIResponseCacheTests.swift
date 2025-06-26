import XCTest
@testable import AirFit

@MainActor
final class AIResponseCacheTests: XCTestCase {

    private var cache: AIResponseCache!

    override func setUp() async throws {
        try await super.setUp()
        cache = AIResponseCache()
        try await cache.configure()
    }

    override func tearDown() async throws {
        await cache.reset()
        cache = nil
        try await super.tearDown()
    }

    // MARK: - Memory Leak Tests

    func testTasksCancelledOnReset() async throws {
        // Create some cache entries to trigger disk writes
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Test")],
            model: "gpt-4",
            temperature: 0.7
        )

        let response = LLMResponse(
            content: "Test response",
            model: "gpt-4",
            usage: TokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30),
            finishReason: .stop,
            metadata: [:]
        )

        // Add multiple entries to trigger disk writes
        for i in 0..<5 {
            var modifiedRequest = request
            modifiedRequest.messages = [LLMMessage(role: .user, content: "Test \(i)")]
            await cache.set(request: modifiedRequest, response: response)
        }

        // Reset should cancel all tasks
        await cache.reset()

        // Give tasks time to cancel
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify cache is cleared
        let stats = await cache.getStatistics()
        XCTAssertEqual(stats.memoryEntries, 0)
    }

    func testNoDanglingTasksAfterReset() async throws {
        // Configure creates tasks
        try await cache.configure()

        // Reset should clean them up
        await cache.reset()

        // Reconfigure should work without issues
        try await cache.configure()

        // Verify cache is functional
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Test")],
            model: "gpt-4",
            temperature: 0.7
        )

        let cachedResponse = await cache.get(request: request)
        XCTAssertNil(cachedResponse) // Should be empty after reset
    }

    // MARK: - Basic Functionality Tests

    func testCacheHitAndMiss() async throws {
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Test prompt")],
            model: "gpt-4",
            temperature: 0.7
        )

        // First access should miss
        let miss = await cache.get(request: request)
        XCTAssertNil(miss)

        // Store response
        let response = LLMResponse(
            content: "Test response",
            model: "gpt-4",
            usage: TokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30),
            finishReason: .stop,
            metadata: ["test": "value"]
        )

        await cache.set(request: request, response: response)

        // Second access should hit
        let hit = await cache.get(request: request)
        XCTAssertNotNil(hit)
        XCTAssertEqual(hit?.content, "Test response")

        // Verify statistics
        let stats = await cache.getStatistics()
        XCTAssertEqual(stats.hitCount, 1)
        XCTAssertEqual(stats.missCount, 1)
        XCTAssertEqual(stats.hitRate, 0.5)
    }

    func testCacheExpiration() async throws {
        let request = LLMRequest(
            messages: [LLMMessage(role: .user, content: "Expiring test")],
            model: "gpt-4",
            temperature: 0.7
        )

        let response = LLMResponse(
            content: "This will expire",
            model: "gpt-4",
            usage: TokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30),
            finishReason: .stop,
            metadata: [:]
        )

        // Set with very short TTL
        await cache.set(request: request, response: response, ttl: 0.1)

        // Should hit immediately
        let immediate = await cache.get(request: request)
        XCTAssertNotNil(immediate)

        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Should miss after expiration
        let expired = await cache.get(request: request)
        XCTAssertNil(expired)
    }

    func testTagInvalidation() async throws {
        // Create requests with different tags
        let requests = [
            LLMRequest(
                messages: [LLMMessage(role: .user, content: "Task 1")],
                model: "gpt-4",
                temperature: 0.2,
                metadata: ["task": "workout"]
            ),
            LLMRequest(
                messages: [LLMMessage(role: .user, content: "Task 2")],
                model: "gpt-4",
                temperature: 0.2,
                metadata: ["task": "nutrition"]
            ),
            LLMRequest(
                messages: [LLMMessage(role: .user, content: "Task 3")],
                model: "gpt-4",
                temperature: 0.2,
                metadata: ["task": "workout"]
            )
        ]

        let response = LLMResponse(
            content: "Generic response",
            model: "gpt-4",
            usage: TokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30),
            finishReason: .stop,
            metadata: [:]
        )

        // Cache all requests
        for request in requests {
            await cache.set(request: request, response: response)
        }

        // Verify all cached
        for request in requests {
            let cached = await cache.get(request: request)
            XCTAssertNotNil(cached)
        }

        // Invalidate workout-related entries
        await cache.invalidate(tag: "task:workout")

        // Workout entries should be gone
        let workout1 = await cache.get(request: requests[0])
        let workout2 = await cache.get(request: requests[2])
        XCTAssertNil(workout1)
        XCTAssertNil(workout2)

        // Nutrition entry should remain
        let nutrition = await cache.get(request: requests[1])
        XCTAssertNotNil(nutrition)
    }
}

// MARK: - Test Helpers

extension LLMRequest {
    init(messages: [LLMMessage], model: String, temperature: Double, metadata: [String: String] = [:]) {
        self.init(
            messages: messages,
            model: model,
            temperature: temperature,
            maxTokens: nil,
            systemPrompt: nil,
            stopSequences: nil,
            metadata: metadata
        )
    }
}
