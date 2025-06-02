import SwiftUI
import Observation

@MainActor
@Observable
final class ConversationViewModel {
    // MARK: - Published State
    var currentNode: ConversationNode?
    var isLoading = false
    var error: Error?
    var completionPercentage: Double = 0
    var showSkipOption = false
    
    // MARK: - Dependencies
    private let flowManager: ConversationFlowManager
    private let persistence: ConversationPersistence
    private let analytics: ConversationAnalytics
    private let userId: UUID
    
    // MARK: - Callbacks
    var onCompletion: ((PersonalityInsights) -> Void)?
    
    // MARK: - Private State
    private var hasStarted = false
    
    // MARK: - Initialization
    init(
        flowManager: ConversationFlowManager,
        persistence: ConversationPersistence,
        analytics: ConversationAnalytics,
        userId: UUID
    ) {
        self.flowManager = flowManager
        self.persistence = persistence
        self.analytics = analytics
        self.userId = userId
        
        // Observe flow manager state
        setupObservers()
    }
    
    // MARK: - Public Methods
    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        
        await analytics.track(.sessionStarted(userId: userId))
        
        // Check for existing session
        do {
            if let existingSession = try persistence.fetchActiveSession(for: userId) {
                // Resume existing session
                await analytics.track(.sessionResumed(
                    userId: userId,
                    nodeId: existingSession.currentNodeId
                ))
                await flowManager.resumeSession(existingSession)
            } else {
                // Start new session
                await flowManager.startNewSession(userId: userId)
            }
        } catch {
            self.error = error
            await analytics.track(.errorOccurred(nodeId: nil, error: error))
        }
    }
    
    func submitResponse(_ response: ResponseValue) async {
        guard let node = currentNode else { return }
        
        let startTime = Date()
        isLoading = true
        
        do {
            try await flowManager.submitResponse(response)
            
            let processingTime = Date().timeIntervalSince(startTime)
            await analytics.track(.responseSubmitted(
                nodeId: node.id.uuidString,
                responseType: String(describing: response),
                processingTime: processingTime
            ))
            
            // Check if conversation is complete
            if flowManager.currentNode == nil {
                await handleCompletion()
            }
        } catch {
            self.error = error
            await analytics.track(.errorOccurred(
                nodeId: node.id.uuidString,
                error: error
            ))
        }
        
        isLoading = false
    }
    
    func skipCurrentQuestion() async {
        guard let node = currentNode else { return }
        
        do {
            await analytics.track(.nodeSkipped(nodeId: node.id.uuidString))
            try await flowManager.skipCurrentNode()
        } catch {
            self.error = error
        }
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe flow manager changes
        Task {
            for await _ in flowManager.$currentNode.values {
                updateFromFlowManager()
            }
        }
        
        Task {
            for await _ in flowManager.$session.values {
                updateProgress()
            }
        }
    }
    
    private func updateFromFlowManager() {
        currentNode = flowManager.currentNode
        showSkipOption = currentNode?.validationRules.required == false
        
        if let node = currentNode {
            Task {
                await analytics.track(.nodeViewed(
                    nodeId: node.id.uuidString,
                    nodeType: node.nodeType
                ))
            }
        }
    }
    
    private func updateProgress() {
        completionPercentage = flowManager.session?.completionPercentage ?? 0
    }
    
    private func handleCompletion() async {
        guard let session = flowManager.session else { return }
        
        let duration = Date().timeIntervalSince(session.startedAt)
        await analytics.track(.sessionCompleted(
            userId: userId,
            duration: duration,
            completionPercentage: 1.0
        ))
        
        // Extract final insights
        if let insightsData = session.extractedInsights,
           let insights = try? JSONDecoder().decode(PersonalityInsights.self, from: insightsData) {
            onCompletion?(insights)
        }
        
        // Clean up
        do {
            try persistence.saveSession(session)
        } catch {
            print("Failed to save completed session: \(error)")
        }
    }
}

// MARK: - View State Helpers
extension ConversationViewModel {
    var currentNodeType: ConversationNode.NodeType? {
        currentNode?.nodeType
    }
    
    var currentQuestion: String {
        currentNode?.question.primary ?? ""
    }
    
    var currentClarifications: [String] {
        currentNode?.question.clarifications ?? []
    }
    
    var currentInputType: InputType? {
        currentNode?.inputType
    }
    
    var progressText: String {
        "\(Int(completionPercentage * 100))% Complete"
    }
}