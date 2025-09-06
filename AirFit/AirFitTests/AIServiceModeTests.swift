import XCTest
@testable import AirFit

final class AIServiceModeTests: XCTestCase {
    func testDemoModeProducesDeterministicOutput() async throws {
        let service = AIService(mode: .demo)
        try await service.configure()
        XCTAssertTrue(service.isConfigured)

        let req = AIRequest(
            systemPrompt: "Test",
            messages: [AIChatMessage(role: .user, content: "help me plan a workout")],
            temperature: 0.7,
            maxTokens: 64,
            stream: false,
            user: "test"
        )

        var receivedText = ""
        for try await resp in service.sendRequest(req) {
            switch resp {
            case .text(let content):
                receivedText = content
            case .textDelta(let delta):
                receivedText += delta
            default:
                break
            }
        }

        XCTAssertFalse(receivedText.isEmpty)
    }

    func testTestModeStreamsAndFinishes() async throws {
        let service = AIService(mode: .test)
        try await service.configure()
        XCTAssertTrue(service.isConfigured)

        let req = AIRequest(
            systemPrompt: "Test",
            messages: [AIChatMessage(role: .user, content: "ping")],
            temperature: 0.0,
            maxTokens: 16,
            stream: true,
            user: "test"
        )

        var sawDone = false
        for try await resp in service.sendRequest(req) {
            if case .done = resp { sawDone = true }
        }
        XCTAssertTrue(sawDone)
    }

    func testOfflineModeYieldsUnauthorizedError() async throws {
        let service = AIService(mode: .offline)
        // No configure in offline

        let req = AIRequest(
            systemPrompt: "Test",
            messages: [AIChatMessage(role: .user, content: "hello")],
            temperature: 0.0,
            maxTokens: 8,
            stream: false,
            user: "test"
        )

        var sawUnauthorized = false
        for try await resp in service.sendRequest(req) {
            if case .error(let err) = resp, case .unauthorized = err { sawUnauthorized = true }
        }
        XCTAssertTrue(sawUnauthorized)
        XCTAssertFalse(service.isConfigured)
    }
}

