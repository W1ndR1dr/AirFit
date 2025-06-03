import XCTest
@testable import AirFit
import SwiftData

@MainActor
final class ConversationViewModelTests: XCTestCase {
    var viewModel: ConversationViewModel!
    var mockFlowManager: MockConversationFlowManager!
    var mockPersistence: MockConversationPersistence!
    var mockAnalytics: MockConversationAnalytics!
    var testUserId: UUID!
    
    override func setUp() async throws {
        try await super.setUp()
        
        testUserId = UUID()
        mockFlowManager = MockConversationFlowManager()
        mockPersistence = MockConversationPersistence()
        mockAnalytics = MockConversationAnalytics()
        
        viewModel = ConversationViewModel(
            flowManager: mockFlowManager,
            persistence: mockPersistence,
            analytics: mockAnalytics,
            userId: testUserId
        )
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockFlowManager = nil
        mockPersistence = nil
        mockAnalytics = nil
        testUserId = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Start Tests
    
    func test_start_withNoExistingSession_startsNewSession() async {
        // Arrange
        mockPersistence.mockSession = nil
        
        // Act
        await viewModel.start()
        
        // Assert
        XCTAssertEqual(mockFlowManager.startNewSessionCallCount, 1)
        XCTAssertEqual(mockFlowManager.lastStartedUserId, testUserId)
        XCTAssertEqual(mockAnalytics.trackedEvents.count, 1)
        XCTAssertTrue(mockAnalytics.trackedEvents.contains { 
            if case .sessionStarted(let userId) = $0 {
                return userId == testUserId
            }
            return false
        })
    }
    
    func test_start_withExistingSession_resumesSession() async {
        // Arrange
        let existingSession = ConversationSession(
            id: UUID(),
            userId: testUserId,
            startedAt: Date(),
            currentNodeId: "test-node"
        )
        mockPersistence.mockSession = existingSession
        
        // Act
        await viewModel.start()
        
        // Assert
        XCTAssertEqual(mockFlowManager.resumeSessionCallCount, 1)
        XCTAssertEqual(mockFlowManager.lastResumedSession?.id, existingSession.id)
        XCTAssertEqual(mockAnalytics.trackedEvents.count, 2)
        XCTAssertTrue(mockAnalytics.trackedEvents.contains {
            if case .sessionResumed(let userId, let nodeId) = $0 {
                return userId == testUserId && nodeId == "test-node"
            }
            return false
        })
    }
    
    func test_start_multipleCalls_onlyStartsOnce() async {
        // Arrange
        mockPersistence.mockSession = nil
        
        // Act
        await viewModel.start()
        await viewModel.start()
        await viewModel.start()
        
        // Assert
        XCTAssertEqual(mockFlowManager.startNewSessionCallCount, 1)
    }
    
    func test_start_withPersistenceError_setsError() async {
        // Arrange
        mockPersistence.shouldThrowError = true
        
        // Act
        await viewModel.start()
        
        // Assert
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(mockAnalytics.trackedEvents.count, 2)
        XCTAssertTrue(mockAnalytics.trackedEvents.contains {
            if case .errorOccurred = $0 {
                return true
            }
            return false
        })
    }
    
    // MARK: - Submit Response Tests
    
    func test_submitResponse_withCurrentNode_submitsToFlowManager() async {
        // Arrange
        let testNode = ConversationNode.mock
        viewModel.currentNode = testNode
        mockFlowManager.currentNode = testNode
        let response = ResponseValue.text("Test response")
        
        // Act
        await viewModel.submitResponse(response)
        
        // Assert
        XCTAssertEqual(mockFlowManager.submitResponseCallCount, 1)
        XCTAssertEqual(mockFlowManager.lastSubmittedResponse, response)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(mockAnalytics.trackedEvents.contains {
            if case .responseSubmitted(let nodeId, _, _) = $0 {
                return nodeId == testNode.id.uuidString
            }
            return false
        })
    }
    
    func test_submitResponse_withNoCurrentNode_doesNothing() async {
        // Arrange
        viewModel.currentNode = nil
        let response = ResponseValue.text("Test response")
        
        // Act
        await viewModel.submitResponse(response)
        
        // Assert
        XCTAssertEqual(mockFlowManager.submitResponseCallCount, 0)
        XCTAssertEqual(mockAnalytics.trackedEvents.count, 0)
    }
    
    func test_submitResponse_withError_setsError() async {
        // Arrange
        let testNode = ConversationNode.mock
        viewModel.currentNode = testNode
        mockFlowManager.shouldThrowError = true
        let response = ResponseValue.text("Test response")
        
        // Act
        await viewModel.submitResponse(response)
        
        // Assert
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(mockAnalytics.trackedEvents.contains {
            if case .errorOccurred(let nodeId, _) = $0 {
                return nodeId == testNode.id.uuidString
            }
            return false
        })
    }
    
    func test_submitResponse_completesConversation_callsCompletion() async {
        // Arrange
        let testNode = ConversationNode.mock
        viewModel.currentNode = testNode
        mockFlowManager.currentNode = nil // Will be nil after submission
        mockFlowManager.mockInsights = PersonalityInsights.mock
        
        var completionCalled = false
        var receivedInsights: PersonalityInsights?
        viewModel.onCompletion = { insights in
            completionCalled = true
            receivedInsights = insights
        }
        
        let response = ResponseValue.text("Test response")
        
        // Act
        await viewModel.submitResponse(response)
        
        // Assert
        XCTAssertTrue(completionCalled)
        XCTAssertNotNil(receivedInsights)
        XCTAssertEqual(receivedInsights?.communicationTone, PersonalityInsights.mock.communicationTone)
    }
    
    // MARK: - Skip Tests
    
    func test_skipCurrentQuestion_withCurrentNode_skipsInFlowManager() async {
        // Arrange
        let testNode = ConversationNode.mock
        viewModel.currentNode = testNode
        
        // Act
        await viewModel.skipCurrentQuestion()
        
        // Assert
        XCTAssertEqual(mockFlowManager.skipCurrentNodeCallCount, 1)
        XCTAssertTrue(mockAnalytics.trackedEvents.contains {
            if case .questionSkipped(let nodeId) = $0 {
                return nodeId == testNode.id.uuidString
            }
            return false
        })
    }
    
    // MARK: - Progress Tests
    
    func test_progressTracking_updatesCorrectly() {
        // Arrange
        let expectation = expectation(description: "Progress updated")
        
        // Act
        mockFlowManager.simulateProgressUpdate(0.5)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.completionPercentage, 0.5, accuracy: 0.01)
    }
}

// MARK: - Mock Classes

@MainActor
final class MockConversationFlowManager: ConversationFlowManager {
    var startNewSessionCallCount = 0
    var resumeSessionCallCount = 0
    var submitResponseCallCount = 0
    var skipCurrentNodeCallCount = 0
    
    var lastStartedUserId: UUID?
    var lastResumedSession: ConversationSession?
    var lastSubmittedResponse: ResponseValue?
    
    var shouldThrowError = false
    var mockInsights = PersonalityInsights.mock
    
    override func startNewSession(userId: UUID) async {
        startNewSessionCallCount += 1
        lastStartedUserId = userId
        
        if shouldThrowError {
            throw AppError.genericError("Mock error")
        }
    }
    
    override func resumeSession(_ session: ConversationSession) async {
        resumeSessionCallCount += 1
        lastResumedSession = session
    }
    
    override func submitResponse(_ response: ResponseValue) async throws {
        submitResponseCallCount += 1
        lastSubmittedResponse = response
        
        if shouldThrowError {
            throw AppError.genericError("Mock error")
        }
    }
    
    override func skipCurrentNode() async {
        skipCurrentNodeCallCount += 1
    }
    
    override func generateInsights() -> PersonalityInsights {
        return mockInsights
    }
    
    func simulateProgressUpdate(_ progress: Double) {
        self.progress = progress
    }
}

@MainActor
final class MockConversationPersistence: ConversationPersistence {
    var mockSession: ConversationSession?
    var shouldThrowError = false
    
    override func fetchActiveSession(for userId: UUID) throws -> ConversationSession? {
        if shouldThrowError {
            throw AppError.databaseError("Mock persistence error")
        }
        return mockSession
    }
}

@MainActor
final class MockConversationAnalytics: ConversationAnalytics {
    var trackedEvents: [ConversationEvent] = []
    
    override func track(_ event: ConversationEvent) async {
        trackedEvents.append(event)
    }
}

// MARK: - Test Helpers

extension ConversationNode {
    static var mock: ConversationNode {
        ConversationNode(
            id: UUID(),
            question: "Test question?",
            type: .openText,
            category: .lifestyle,
            isRequired: true,
            nextNodeId: nil,
            metadata: [:]
        )
    }
}

extension PersonalityInsights {
    static var mock: PersonalityInsights {
        PersonalityInsights(
            communicationTone: .friendly,
            motivationStyle: .encouraging,
            detailLevel: .balanced,
            preferredTiming: .morning,
            responseToSuccess: .enthusiastic,
            responseToStruggle: .supportive,
            humorLevel: .moderate,
            formalityLevel: .casual
        )
    }
}

extension ResponseValue: Equatable {
    public static func == (lhs: ResponseValue, rhs: ResponseValue) -> Bool {
        switch (lhs, rhs) {
        case (.text(let l), .text(let r)): return l == r
        case (.number(let l), .number(let r)): return l == r
        case (.selection(let l), .selection(let r)): return l == r
        case (.multiSelection(let l), .multiSelection(let r)): return l == r
        case (.scale(let l), .scale(let r)): return l == r
        default: return false
        }
    }
}