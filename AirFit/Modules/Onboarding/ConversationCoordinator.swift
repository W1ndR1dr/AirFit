import SwiftUI
import SwiftData

@MainActor
final class ConversationCoordinator: ObservableObject {
    @Published var isActive = false
    @Published var currentView: ConversationView?
    
    private let modelContext: ModelContext
    private let userId: UUID
    private let onCompletion: (PersonaProfile) -> Void
    
    init(
        modelContext: ModelContext,
        userId: UUID,
        onCompletion: @escaping (PersonaProfile) -> Void
    ) {
        self.modelContext = modelContext
        self.userId = userId
        self.onCompletion = onCompletion
    }
    
    func start() {
        isActive = true
        currentView = createConversationView()
    }
    
    func handleCompletion(personaProfile: PersonaProfile) {
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
            // In Phase 2, this will generate a full PersonaProfile via AI
            // For now, create a basic profile
            let profile = PersonaProfile(
                name: "Coach",
                archetype: "Balanced Guide",
                personalityPrompt: "A supportive fitness coach",
                voiceCharacteristics: VoiceCharacteristics(
                    pace: .moderate,
                    energy: .balanced,
                    warmth: .friendly
                ),
                interactionStyle: InteractionStyle(
                    greetingStyle: "Hey there!",
                    signoffStyle: "Keep pushing forward!",
                    encouragementPhrases: ["You've got this!", "Great work!", "Keep it up!"],
                    correctionStyle: "Let's adjust that slightly",
                    humorLevel: .occasional
                ),
                sourceInsights: insights
            )
            
            self?.handleCompletion(personaProfile: profile)
        }
        
        return ConversationView(viewModel: viewModel)
    }
}