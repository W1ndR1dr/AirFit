import Foundation
import SwiftData

@MainActor
final class ConversationFlowManager: ObservableObject {
    // MARK: - Properties
    private let flowDefinition: [String: ConversationNode]
    private let modelContext: ModelContext
    private let responseAnalyzer: ResponseAnalyzer?
    
    @Published private(set) var currentNode: ConversationNode?
    @Published private(set) var session: ConversationSession?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Initialization
    init(
        flowDefinition: [String: ConversationNode],
        modelContext: ModelContext,
        responseAnalyzer: ResponseAnalyzer? = nil
    ) {
        self.flowDefinition = flowDefinition
        self.modelContext = modelContext
        self.responseAnalyzer = responseAnalyzer
    }
    
    // MARK: - Public Methods
    func startNewSession(userId: UUID) async {
        session = ConversationSession(userId: userId)
        modelContext.insert(session!)
        
        // Start with opening node
        await navigateToNode(nodeId: "opening")
    }
    
    func resumeSession(_ existingSession: ConversationSession) async {
        session = existingSession
        await navigateToNode(nodeId: existingSession.currentNodeId)
    }
    
    func submitResponse(_ response: ResponseValue) async throws {
        guard let currentNode = currentNode,
              let session = session else {
            throw ConversationError.noActiveSession
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Validate response
        try validateResponse(response, for: currentNode)
        
        // Store response
        let responseData = try JSONEncoder().encode(response)
        let conversationResponse = ConversationResponse(
            nodeId: currentNode.id.uuidString,
            responseType: String(describing: response),
            responseData: responseData
        )
        
        session.responses.append(conversationResponse)
        
        // Analyze response if analyzer available
        if let analyzer = responseAnalyzer {
            let snapshots = session.responses.map { ResponseSnapshot(from: $0) }
            let insights = try await analyzer.analyzeResponse(
                response: response,
                node: currentNode,
                previousResponses: snapshots
            )
            
            // Update session insights
            session.extractedInsights = try JSONEncoder().encode(insights)
        }
        
        // Update progress
        updateProgress()
        
        // Determine next node
        let nextNodeId = determineNextNode(
            from: currentNode,
            with: response,
            session: session
        )
        
        if let nextNodeId = nextNodeId {
            await navigateToNode(nodeId: nextNodeId)
        } else {
            // Conversation complete
            await completeSession()
        }
        
        try modelContext.save()
    }
    
    func skipCurrentNode() async throws {
        guard let currentNode = currentNode else { return }
        
        // Only allow skipping non-required nodes
        guard !currentNode.validationRules.required else {
            throw ConversationError.cannotSkipRequired
        }
        
        // Find next node with "always" branching
        if let alwaysBranch = currentNode.branchingRules.first(where: { 
            if case .always = $0.condition { return true }
            return false
        }) {
            await navigateToNode(nodeId: alwaysBranch.nextNodeId)
        }
    }
    
    // MARK: - Private Methods
    private func navigateToNode(nodeId: String) async {
        guard let node = flowDefinition[nodeId] else {
            error = ConversationError.nodeNotFound(nodeId)
            return
        }
        
        currentNode = node
        session?.currentNodeId = nodeId
        
        // Track analytics event if specified
        if let event = node.analyticsEvent {
            // Analytics tracking would go here
            print("Analytics event: \(event)")
        }
    }
    
    private func validateResponse(_ response: ResponseValue, for node: ConversationNode) throws {
        switch (response, node.inputType) {
        case (.text(let text), .text(let minLength, let maxLength, _)):
            guard text.count >= minLength && text.count <= maxLength else {
                throw ConversationError.invalidTextLength(min: minLength, max: maxLength)
            }
            
        case (.choice(let choice), .singleChoice(let options)):
            guard options.contains(where: { $0.id == choice }) else {
                throw ConversationError.invalidChoice
            }
            
        case (.multiChoice(let choices), .multiChoice(let options, let min, let max)):
            let validChoices = choices.filter { choice in
                options.contains(where: { $0.id == choice })
            }
            guard validChoices.count >= min && validChoices.count <= max else {
                throw ConversationError.invalidMultiChoice(min: min, max: max)
            }
            
        case (.slider(let value), .slider(let min, let max, _, _)):
            guard value >= min && value <= max else {
                throw ConversationError.sliderOutOfRange
            }
            
        default:
            // Type mismatch or unsupported combination
            throw ConversationError.responseTypeMismatch
        }
    }
    
    private func determineNextNode(
        from node: ConversationNode,
        with response: ResponseValue,
        session: ConversationSession
    ) -> String? {
        // Evaluate branching rules in order
        for rule in node.branchingRules {
            if evaluateBranchCondition(rule.condition, response: response, session: session) {
                return rule.nextNodeId
            }
        }
        
        // No matching rule found
        return nil
    }
    
    private func evaluateBranchCondition(
        _ condition: BranchCondition,
        response: ResponseValue,
        session: ConversationSession
    ) -> Bool {
        switch condition {
        case .always:
            return true
            
        case .responseContains(let text):
            switch response {
            case .text(let value), .voice(let value, _):
                return value.localizedCaseInsensitiveContains(text)
            default:
                return false
            }
            
        case .traitAbove(let trait, let threshold), .traitBelow(let trait, let threshold):
            // Extract insights from session
            guard let insightsData = session.extractedInsights,
                  let insights = try? JSONDecoder().decode(PersonalityInsights.self, from: insightsData),
                  let dimension = PersonalityDimension(rawValue: trait),
                  let value = insights.traits[dimension] else {
                return false
            }
            
            if case .traitAbove = condition {
                return value > threshold
            } else {
                return value < threshold
            }
            
        case .hasResponse(let nodeId):
            return session.responses.contains(where: { $0.nodeId == nodeId })
        }
    }
    
    private func updateProgress() {
        guard let session = session else { return }
        
        let totalNodes = flowDefinition.count
        let completedNodes = session.responses.count
        session.completionPercentage = Double(completedNodes) / Double(totalNodes)
    }
    
    private func completeSession() async {
        guard let session = session else { return }
        
        session.completedAt = Date()
        session.completionPercentage = 1.0
        
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Errors
enum ConversationError: LocalizedError {
    case noActiveSession
    case nodeNotFound(String)
    case invalidTextLength(min: Int, max: Int)
    case invalidChoice
    case invalidMultiChoice(min: Int, max: Int)
    case sliderOutOfRange
    case responseTypeMismatch
    case cannotSkipRequired
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active conversation session"
        case .nodeNotFound(let id):
            return "Conversation node not found: \(id)"
        case .invalidTextLength(let min, let max):
            return "Text must be between \(min) and \(max) characters"
        case .invalidChoice:
            return "Invalid choice selected"
        case .invalidMultiChoice(let min, let max):
            return "Please select between \(min) and \(max) options"
        case .sliderOutOfRange:
            return "Value is out of range"
        case .responseTypeMismatch:
            return "Response type doesn't match expected input"
        case .cannotSkipRequired:
            return "This question is required"
        }
    }
}

// MARK: - Response Analyzer Protocol
protocol ResponseAnalyzer {
    func analyzeResponse(
        response: ResponseValue,
        node: ConversationNode,
        previousResponses: [ResponseSnapshot]
    ) async throws -> PersonalityInsights
}

// MARK: - Response Snapshot (Sendable version)
struct ResponseSnapshot: Sendable {
    let nodeId: String
    let responseType: String
    let responseData: Data
    let timestamp: Date
    
    init(from response: ConversationResponse) {
        self.nodeId = response.nodeId
        self.responseType = response.responseType
        self.responseData = response.responseData
        self.timestamp = response.timestamp
    }
}