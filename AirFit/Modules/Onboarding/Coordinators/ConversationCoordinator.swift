import SwiftUI
import SwiftData

@MainActor
final class ConversationCoordinator: ObservableObject {
    enum CoordinatorView {
        case conversation(ConversationView)
        case synthesis(PersonaSynthesisView)
    }
    
    @Published var isActive = false
    @Published var currentView: CoordinatorView?
    
    private let modelContext: ModelContext
    private let userId: UUID
    private let apiKeyManager: APIKeyManagerProtocol
    private let onCompletion: (PersonaProfile) -> Void
    
    private var insights: PersonalityInsights?
    private var conversationData: ConversationData?
    
    init(
        modelContext: ModelContext,
        userId: UUID,
        apiKeyManager: APIKeyManagerProtocol,
        onCompletion: @escaping (PersonaProfile) -> Void
    ) {
        self.modelContext = modelContext
        self.userId = userId
        self.apiKeyManager = apiKeyManager
        self.onCompletion = onCompletion
    }
    
    func start() {
        isActive = true
        currentView = .conversation(createConversationView())
    }
    
    func handleConversationComplete(insights: PersonalityInsights, data: ConversationData) {
        self.insights = insights
        self.conversationData = data
        
        // Transition to synthesis
        let synthesisView = createSynthesisView(insights: insights, data: data)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentView = .synthesis(synthesisView)
        }
    }
    
    func handleSynthesisComplete(personaProfile: PersonaProfile) {
        isActive = false
        onCompletion(personaProfile)
    }
    
    private func createConversationView() -> ConversationView {
        let flowData = ConversationFlowData.defaultFlow()
        let flowManager = ConversationFlowManager(
            flowDefinition: flowData,
            modelContext: modelContext,
            responseAnalyzer: ResponseAnalyzerImpl()
        )
        
        let viewModel = ConversationViewModel(
            flowManager: flowManager,
            persistence: ConversationPersistence(modelContext: modelContext),
            analytics: ConversationAnalytics(),
            userId: userId
        )
        
        viewModel.onCompletion = { [weak self] insights in
            guard let self = self,
                  let session = flowManager.session else { return }
            
            // Extract conversation data
            let data = self.extractConversationData(from: session)
            self.handleConversationComplete(insights: insights, data: data)
        }
        
        return ConversationView(viewModel: viewModel)
    }
    
    private func createSynthesisView(insights: PersonalityInsights, data: ConversationData) -> PersonaSynthesisView {
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        let synthesizer = PersonaSynthesizer(llm: llmOrchestrator)
        
        return PersonaSynthesisView(
            synthesizer: synthesizer,
            insights: insights,
            conversationData: data,
            onCompletion: { [weak self] persona in
                self?.handleSynthesisComplete(personaProfile: persona)
            }
        )
    }
    
    private func extractConversationData(from session: ConversationSession) -> ConversationData {
        var responses: [String: Any] = [:]
        
        // Extract responses by node ID
        for response in session.responses {
            if let responseValue = try? JSONDecoder().decode(ResponseValue.self, from: response.responseData) {
                switch responseValue {
                case .text(let text):
                    responses[response.nodeId] = text
                case .choice(let choice):
                    responses[response.nodeId] = choice
                case .multiChoice(let choices):
                    responses[response.nodeId] = choices
                case .slider(let value):
                    responses[response.nodeId] = value
                case .voice(let transcription, _):
                    responses[response.nodeId] = transcription
                }
            }
        }
        
        return ConversationData(
            userName: responses["opening"] as? String ?? "Friend",
            primaryGoal: responses["goals-primary"] as? String ?? "Get fit",
            responses: responses
        )
    }
}