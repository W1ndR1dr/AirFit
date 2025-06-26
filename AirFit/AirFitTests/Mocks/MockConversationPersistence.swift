import Foundation
import SwiftData
@testable import AirFit

@MainActor
final class MockConversationPersistence {
    // MARK: - Mock State
    private var sessions: [UUID: ConversationSession] = [:]
    private var responses: [UUID: [ConversationResponse]] = [:]

    // MARK: - Mock Configuration
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "Mock persistence error")

    // MARK: - Call Recording
    var saveSessionCallCount = 0
    var loadSessionCallCount = 0
    var saveResponseCallCount = 0
    var loadResponsesCallCount = 0
    var clearSessionCallCount = 0

    // MARK: - Mock Methods
    func saveSession(_ session: ConversationSession) async throws {
        saveSessionCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        sessions[session.userId] = session
    }

    func loadSession(for userId: UUID) async throws -> ConversationSession? {
        loadSessionCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return sessions[userId]
    }

    func saveResponse(_ response: ConversationResponse, for sessionId: UUID) async throws {
        saveResponseCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        if responses[sessionId] == nil {
            responses[sessionId] = []
        }
        responses[sessionId]?.append(response)
    }

    func loadResponses(for sessionId: UUID) async throws -> [ConversationResponse] {
        loadResponsesCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return responses[sessionId] ?? []
    }

    func clearSession(for userId: UUID) async throws {
        clearSessionCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        sessions.removeValue(forKey: userId)
        // Clear any responses for sessions belonging to this user
        if let session = sessions[userId] {
            responses.removeValue(forKey: session.id)
        }
    }

    // MARK: - Test Helpers
    func reset() {
        sessions.removeAll()
        responses.removeAll()

        saveSessionCallCount = 0
        loadSessionCallCount = 0
        saveResponseCallCount = 0
        loadResponsesCallCount = 0
        clearSessionCallCount = 0

        shouldThrowError = false
    }

    func stubSession(_ session: ConversationSession) {
        sessions[session.userId] = session
    }

    func stubResponses(_ responses: [ConversationResponse], for sessionId: UUID) {
        self.responses[sessionId] = responses
    }
}
