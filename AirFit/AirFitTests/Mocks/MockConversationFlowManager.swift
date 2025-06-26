import Foundation
import SwiftData
@testable import AirFit

// MARK: - Mock PersonalityInsights
extension PersonalityInsights {
    static var mock: PersonalityInsights {
        var insights = PersonalityInsights()
        insights.traits = [
            .authorityPreference: 0.7,
            .socialOrientation: 0.8,
            .structureNeed: 0.6,
            .intensityPreference: 0.75,
            .dataOrientation: 0.4,
            .emotionalSupport: 0.5
        ]
        insights.motivationalDrivers = [.achievement, .health]
        insights.communicationStyle = CommunicationProfile()
        insights.communicationStyle.preferredTone = .balanced
        insights.communicationStyle.detailLevel = .moderate
        insights.communicationStyle.encouragementStyle = .balanced
        insights.communicationStyle.feedbackTiming = .periodic
        return insights
    }
}

@MainActor
final class MockConversationFlowManager: ObservableObject {
    // MARK: - Published Properties (to match real class)
    @Published private(set) var currentNode: ConversationNode?
    @Published private(set) var session: ConversationSession?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var progress: Double = 0.0

    // MARK: - Mock Configuration
    var shouldThrowError = false
    var errorToThrow: Error = AppError.unknown(message: "Mock error")
    var mockInsights = PersonalityInsights.mock
    var nodeToReturn: ConversationNode?

    // MARK: - Call Recording
    var startNewSessionCallCount = 0
    var resumeSessionCallCount = 0
    var submitResponseCallCount = 0
    var skipCurrentNodeCallCount = 0
    var generateInsightsCallCount = 0

    var lastStartedUserId: UUID?
    var lastResumedSession: ConversationSession?
    var lastSubmittedResponse: ResponseValue?

    // MARK: - Mock Methods
    func startNewSession(userId: UUID) async {
        startNewSessionCallCount += 1
        lastStartedUserId = userId

        if shouldThrowError {
            error = errorToThrow
            return
        }

        // Create a mock session
        session = ConversationSession(userId: userId)
        currentNode = nodeToReturn ?? ConversationNode(
            nodeType: .opening,
            question: ConversationQuestion(
                primary: "Mock question",
                clarifications: [],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .text(minLength: 1, maxLength: 500, placeholder: "Type your answer"),
            dataKey: "opening",
            validationRules: ValidationRules()
        )
    }

    func resumeSession(_ existingSession: ConversationSession) async {
        resumeSessionCallCount += 1
        lastResumedSession = existingSession
        session = existingSession

        currentNode = nodeToReturn ?? ConversationNode(
            nodeType: .opening,
            question: ConversationQuestion(
                primary: "Resumed question",
                clarifications: [],
                examples: nil,
                voicePrompt: nil
            ),
            inputType: .text(minLength: 1, maxLength: 500, placeholder: "Type your answer"),
            dataKey: existingSession.currentNodeId ?? "opening",
            validationRules: ValidationRules()
        )
    }

    func submitResponse(_ response: ResponseValue) async throws {
        submitResponseCallCount += 1
        lastSubmittedResponse = response

        if shouldThrowError {
            throw errorToThrow
        }

        // Simulate progress update
        progress = min(1.0, progress + 0.1)
    }

    func skipCurrentNode() async {
        skipCurrentNodeCallCount += 1
        // Simulate moving to next node
        progress = min(1.0, progress + 0.1)
    }

    func generateInsights() -> PersonalityInsights {
        generateInsightsCallCount += 1
        return mockInsights
    }

    // MARK: - Test Helpers
    func simulateProgressUpdate(_ newProgress: Double) {
        progress = newProgress
    }

    func simulateError(_ error: Error) {
        self.error = error
    }

    func simulateLoading(_ loading: Bool) {
        isLoading = loading
    }

    func reset() {
        currentNode = nil
        session = nil
        isLoading = false
        error = nil
        progress = 0.0

        startNewSessionCallCount = 0
        resumeSessionCallCount = 0
        submitResponseCallCount = 0
        skipCurrentNodeCallCount = 0
        generateInsightsCallCount = 0

        lastStartedUserId = nil
        lastResumedSession = nil
        lastSubmittedResponse = nil
    }
}
