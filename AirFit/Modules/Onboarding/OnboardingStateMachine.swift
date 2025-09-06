import Foundation
import SwiftUI

/// Onboarding state machine with proper state management, transitions, and error recovery
@MainActor
final class OnboardingStateMachine: ObservableObject {
    // MARK: - State Definition
    
    indirect enum State: Equatable {
        case healthPermission
        case healthDataLoading(progress: Double, status: String)
        case whisperSetup
        case profileSetup
        case conversation(turnCount: Int, contextQuality: Double)
        case insightsConfirmation
        case generating(progress: PersonaSynthesisProgress?)
        case confirmation
        case watchSetup
        case completed
        case error(AppError, fromState: State)
        
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.healthPermission, .healthPermission),
                 (.whisperSetup, .whisperSetup),
                 (.profileSetup, .profileSetup),
                 (.insightsConfirmation, .insightsConfirmation),
                 (.confirmation, .confirmation),
                 (.watchSetup, .watchSetup),
                 (.completed, .completed):
                return true
            case let (.healthDataLoading(p1, s1), .healthDataLoading(p2, s2)):
                return p1 == p2 && s1 == s2
            case let (.conversation(t1, q1), .conversation(t2, q2)):
                return t1 == t2 && q1 == q2
            case let (.generating(p1), .generating(p2)):
                return p1?.phase == p2?.phase
            case let (.error(e1, s1), .error(e2, s2)):
                return e1.localizedDescription == e2.localizedDescription && s1 == s2
            default:
                return false
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var currentState: State = .healthPermission
    @Published private(set) var isTransitioning = false
    @Published private(set) var stateHistory: [State] = []
    @Published private(set) var conversationHistory: [(text: String, isUser: Bool)] = []
    
    // MARK: - Private Properties
    
    private var intelligence: OnboardingIntelligence?
    private var userInput: String = ""
    private var lastValidState: State = .healthPermission
    private var transitionTask: Task<Void, Never>?
    
    // Configuration
    private let minConversationTurns = 3
    private let maxConversationTurns = 10
    private let sufficientContextQuality = 0.8
    
    // MARK: - Events
    
    enum Event {
        case acceptHealthPermission
        case skipHealthPermission
        case healthDataLoaded
        case skipHealthData
        case whisperSetupComplete
        case skipWhisperSetup
        case profileComplete(birthDate: Date?, biologicalSex: String?)
        case skipProfile
        case submitConversation(String)
        case confirmInsights
        case refineInsights
        case generationComplete
        case acceptPlan
        case refinePlan
        case watchSetupComplete
        case skipWatchSetup
        case retry
        case reset
    }
    
    // MARK: - Initialization
    
    init() {
        stateHistory.append(currentState)
    }
    
    func configure(with intelligence: OnboardingIntelligence) {
        self.intelligence = intelligence
    }
    
    // MARK: - State Transitions
    
    func send(_ event: Event) {
        guard !isTransitioning else {
            AppLogger.warning("Attempted to send event \(event) while transitioning", category: .onboarding)
            return
        }
        
        // Cancel any ongoing transition
        transitionTask?.cancel()
        
        transitionTask = Task { @MainActor in
            isTransitioning = true
            defer { isTransitioning = false }
            
            do {
                let nextState = try await processEvent(event, from: currentState)
                if nextState != currentState {
                    transition(to: nextState)
                }
            } catch {
                let appError = error.asAppError
                transition(to: .error(appError, fromState: currentState))
            }
        }
    }
    
    private func processEvent(_ event: Event, from state: State) async throws -> State {
        guard let intelligence = intelligence else {
            throw AppError.configuration("OnboardingIntelligence not configured")
        }
        
        switch (state, event) {
        // Health Permission transitions
        case (.healthPermission, .acceptHealthPermission):
            // Start health analysis in background
            Task {
                await intelligence.startHealthAnalysis()
            }
            return .healthDataLoading(progress: 0.0, status: "Initializing...")
            
        case (.healthPermission, .skipHealthPermission):
            return .whisperSetup
            
        // Health Data Loading transitions
        case (.healthDataLoading, .healthDataLoaded):
            return .whisperSetup
            
        case (.healthDataLoading, .skipHealthData):
            return .whisperSetup
            
        // Whisper Setup transitions
        case (.whisperSetup, .whisperSetupComplete):
            return .profileSetup
            
        case (.whisperSetup, .skipWhisperSetup):
            return .profileSetup
            
        // Profile Setup transitions
        case (.profileSetup, .profileComplete(let birthDate, let biologicalSex)):
            if let birthDate = birthDate, let biologicalSex = biologicalSex {
                intelligence.addProfileData(birthDate: birthDate, biologicalSex: biologicalSex)
            }
            return .conversation(turnCount: 0, contextQuality: 0.0)
            
        case (.profileSetup, .skipProfile):
            return .conversation(turnCount: 0, contextQuality: 0.0)
            
        // Conversation transitions
        case (.conversation(let turnCount, _), .submitConversation(let input)):
            // Add to history
            conversationHistory.append((text: intelligence.currentPrompt, isUser: false))
            conversationHistory.append((text: input, isUser: true))
            
            // Analyze conversation
            await intelligence.analyzeConversation(input)
            
            let newTurnCount = turnCount + 1
            let contextQuality = intelligence.contextQuality.overall
            
            // Determine next state based on conversation progress
            if newTurnCount >= maxConversationTurns {
                return .insightsConfirmation
            } else if newTurnCount >= minConversationTurns && contextQuality >= sufficientContextQuality {
                return .insightsConfirmation
            } else {
                // Continue conversation
                if let followUp = intelligence.followUpQuestion {
                    intelligence.currentPrompt = followUp
                } else if newTurnCount < minConversationTurns {
                    intelligence.currentPrompt = "What else should I know about your fitness journey?"
                } else {
                    // No follow-up but haven't hit minimum turns
                    return .insightsConfirmation
                }
                return .conversation(turnCount: newTurnCount, contextQuality: contextQuality)
            }
            
        // Insights Confirmation transitions
        case (.insightsConfirmation, .confirmInsights):
            return .generating(progress: nil)
            
        case (.insightsConfirmation, .refineInsights):
            intelligence.currentPrompt = "Thanks for clarifying! What else should I know about your fitness goals and preferences?"
            if case .conversation(let turnCount, let quality) = state {
                return .conversation(turnCount: turnCount, contextQuality: quality)
            }
            return .conversation(turnCount: conversationHistory.count / 2, contextQuality: intelligence.contextQuality.overall)
            
        // Generation transitions
        case (.generating, .generationComplete):
            if intelligence.coachingPlan != nil {
                return .confirmation
            } else {
                throw AppError.llm("Failed to generate coaching plan")
            }
            
        // Confirmation transitions
        case (.confirmation, .acceptPlan):
            return .watchSetup
            
        case (.confirmation, .refinePlan):
            intelligence.currentPrompt = "Is there anything else you'd like me to know? Any specific concerns, preferences, or goals I should consider?"
            let turnCount = conversationHistory.count / 2
            return .conversation(turnCount: turnCount, contextQuality: intelligence.contextQuality.overall)
            
        // Watch Setup transitions
        case (.watchSetup, .watchSetupComplete), (.watchSetup, .skipWatchSetup):
            return .completed
            
        // Error recovery
        case (.error(_, let fromState), .retry):
            return fromState
            
        case (_, .reset):
            resetState()
            return .healthPermission
            
        // Invalid transitions
        default:
            AppLogger.warning("Invalid transition: \(event) from \(state)", category: .onboarding)
            return state
        }
    }
    
    private func transition(to newState: State) {
        let oldState = currentState
        
        // Store last valid state for error recovery
        if case .error = newState {
            // Don't update last valid state when entering error
        } else {
            lastValidState = currentState
        }
        
        // Update state
        currentState = newState
        stateHistory.append(newState)
        
        // Limit history size
        if stateHistory.count > 20 {
            stateHistory.removeFirst()
        }
        
        AppLogger.info("State transition: \(oldState) -> \(newState)", category: .onboarding)
        
        // Handle automatic transitions
        if case .generating = newState {
            Task {
                await generatePersona()
            }
        }
    }
    
    // MARK: - State Queries
    
    var canGoBack: Bool {
        switch currentState {
        case .healthPermission, .completed:
            return false
        case .error:
            return true
        default:
            return stateHistory.count > 1
        }
    }
    
    var progressPercentage: Double {
        switch currentState {
        case .healthPermission:
            return 0.1
        case .healthDataLoading:
            return 0.2
        case .whisperSetup:
            return 0.3
        case .profileSetup:
            return 0.4
        case .conversation(let turnCount, _):
            let conversationProgress = Double(turnCount) / Double(maxConversationTurns)
            return 0.4 + (0.2 * conversationProgress)
        case .insightsConfirmation:
            return 0.6
        case .generating:
            return 0.7
        case .confirmation:
            return 0.8
        case .watchSetup:
            return 0.9
        case .completed:
            return 1.0
        case .error:
            return progressPercentage(for: lastValidState)
        }
    }
    
    private func progressPercentage(for state: State) -> Double {
        // Recursive helper to get progress for any state
        switch state {
        case .healthPermission: return 0.1
        case .healthDataLoading: return 0.2
        case .whisperSetup: return 0.3
        case .profileSetup: return 0.4
        case .conversation: return 0.5
        case .insightsConfirmation: return 0.6
        case .generating: return 0.7
        case .confirmation: return 0.8
        case .watchSetup: return 0.9
        case .completed: return 1.0
        case .error(_, let fromState): return progressPercentage(for: fromState)
        }
    }
    
    // MARK: - Private Methods
    
    private func generatePersona() async {
        guard let intelligence = intelligence else { return }
        
        await intelligence.generatePersona()
        
        // Send completion event
        send(.generationComplete)
    }
    
    private func resetState() {
        currentState = .healthPermission
        stateHistory = [.healthPermission]
        conversationHistory = []
        userInput = ""
        lastValidState = .healthPermission
        // Reset conversation in intelligence
        intelligence?.conversationHistory.removeAll()
        intelligence?.currentPrompt = "What's your main\nfitness goal?"
    }
    
    // MARK: - Public Methods
    
    func getCurrentPrompt() -> String {
        intelligence?.currentPrompt ?? "What's your main fitness goal?"
    }
    
    func getSuggestions() -> [String] {
        intelligence?.contextualSuggestions ?? []
    }
    
    func getInsights() -> ExtractedInsights? {
        intelligence?.extractedInsights
    }
    
    func getCoachingPlan() -> CoachingPlan? {
        intelligence?.coachingPlan
    }
    
    func getPersonaSynthesisProgress() -> PersonaSynthesisProgress? {
        intelligence?.personaSynthesisProgress
    }
}

// MARK: - State Extensions

extension OnboardingStateMachine.State {
    var isErrorState: Bool {
        if case .error = self { return true }
        return false
    }
    
    var isLoadingState: Bool {
        switch self {
        case .healthDataLoading, .generating:
            return true
        default:
            return false
        }
    }
    
    var requiresUserInput: Bool {
        switch self {
        case .conversation, .profileSetup:
            return true
        default:
            return false
        }
    }
}