import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var coordinator: OnboardingFlowCoordinator
    @State private var showingError = false
    @Environment(\.dismiss) private var dismiss
    
    init(
        conversationManager: ConversationFlowManager,
        personaService: PersonaService,
        userService: UserServiceProtocol,
        modelContext: ModelContext
    ) {
        _coordinator = State(initialValue: OnboardingFlowCoordinator(
            conversationManager: conversationManager,
            personaService: personaService,
            userService: userService,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color("BackgroundPrimary")
                .ignoresSafeArea()
            
            // Main content with transitions
            Group {
                switch coordinator.currentView {
                case .welcome:
                    WelcomeView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                case .conversation:
                    ConversationFlowView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                case .generatingPersona:
                    GeneratingPersonaView(coordinator: coordinator)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    
                case .personaPreview:
                    PersonaPreviewView(
                        persona: coordinator.generatedPersona!,
                        coordinator: coordinator
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.1).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                    
                case .complete:
                    ContainerCompletionView(coordinator: coordinator)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(.smooth(duration: 0.5), value: coordinator.currentView)
            
            // Loading overlay
            if coordinator.isLoading {
                ContainerLoadingOverlay()
                    .transition(.opacity)
                    .zIndex(10)
            }
            
            // Progress indicator
            VStack {
                ContainerProgressBar(progress: coordinator.progress)
                    .padding(.horizontal)
                    .padding(.top, 8)
                Spacer()
            }
            .zIndex(5)
        }
        .alert("Error", isPresented: .constant(coordinator.error != nil)) {
            Button("Retry") {
                Task {
                    await coordinator.retryLastAction()
                }
            }
            Button("Cancel", role: .cancel) {
                coordinator.clearError()
            }
        } message: {
            if let error = coordinator.error {
                Text(error.localizedDescription)
                if let recovery = (error as? OnboardingError)?.recoverySuggestion {
                    Text(recovery)
                        .font(.caption)
                }
            }
        }
        .task {
            coordinator.start()
        }
    }
}

// MARK: - Sub Views

private struct WelcomeView: View {
    let coordinator: OnboardingFlowCoordinator
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo or illustration
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.accentColor)
                .symbolEffect(.pulse)
            
            VStack(spacing: 16) {
                Text("Welcome to AirFit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let's create your personalized AI fitness coach")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await coordinator.beginConversation()
                }
            }) {
                HStack {
                    Text("Get Started")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

private struct ConversationFlowView: View {
    let coordinator: OnboardingFlowCoordinator
    
    var body: some View {
        // This wraps the existing ConversationView
        if let session = coordinator.conversationSession {
            // TODO: Fix ConversationView integration
            Text("Conversation in progress...")
                .onAppear {
                    Task {
                        await coordinator.completeConversation()
                    }
                }
        } else {
            ContentUnavailableView(
                "Starting Conversation",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Setting up your conversation...")
            )
        }
    }
}

private struct GeneratingPersonaView: View {
    let coordinator: OnboardingFlowCoordinator
    @State private var dots = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentColor, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.variableColor.iterative.reversing)
            
            VStack(spacing: 16) {
                Text("Creating Your Coach")
                    .font(.title)
                    .fontWeight(.semibold)
                
                HStack(spacing: 4) {
                    Text("Synthesizing personality")
                    ForEach(0..<3) { i in
                        Text(".")
                            .opacity(i < dots ? 1 : 0)
                    }
                }
                .font(.headline)
                .foregroundStyle(.secondary)
                .onAppear {
                    animateDots()
                }
            }
            
            // Progress messages
            VStack(spacing: 8) {
                ProgressMessage(text: "Analyzing your responses", isComplete: true)
                ProgressMessage(text: "Extracting personality insights", isComplete: true)
                ProgressMessage(text: "Generating unique coach identity", isComplete: false)
                ProgressMessage(text: "Crafting communication style", isComplete: false)
            }
            .padding(.top, 20)
            
            Spacer()
            
            Text("This usually takes 3-5 seconds")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
        }
        .padding()
    }
    
    private func animateDots() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
            dots = (dots + 1) % 4
        }
    }
}

private struct ProgressMessage: View {
    let text: String
    let isComplete: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? .green : .secondary)
                .font(.caption)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(isComplete ? .primary : .secondary)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

private struct ContainerCompletionView: View {
    let coordinator: OnboardingFlowCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personalized coach is ready to help you achieve your fitness goals")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Start Training")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Supporting Views

private struct ContainerLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .frame(width: 120, height: 120)
                .overlay {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.accentColor)
                }
        }
    }
}

private struct ContainerProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.smooth, value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Preview

// MARK: - Preview Support

private final class PreviewUserService: UserServiceProtocol, @unchecked Sendable {
    func getCurrentUser() -> User? {
        nil
    }
    
    func createUser(from profile: OnboardingProfile) async throws -> User {
        User(email: "preview@test.com", name: "Preview User")
    }
    
    func updateProfile(_ updates: ProfileUpdate) async throws {
        // No-op for preview
    }
    
    func getCurrentUserId() async -> UUID? {
        nil
    }
    
    func deleteUser(_ user: User) async throws {
        // No-op for preview
    }
    
    func completeOnboarding() async throws {
        // No-op for preview
    }
    
    func setCoachPersona(_ persona: CoachPersona) async throws {
        // No-op for preview
    }
}

private final class PreviewAPIKeyManager: APIKeyManagementProtocol, @unchecked Sendable {
    func getAPIKey(for provider: AIProvider) async throws -> String {
        return "preview-key"
    }
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        // No-op for preview
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        // No-op for preview
    }
    
    func hasAPIKey(for provider: AIProvider) async -> Bool {
        return true
    }
    
    func getAllConfiguredProviders() async -> [AIProvider] {
        return [.openAI, .anthropic, .gemini]
    }
}

#Preview {
    OnboardingContainerView(
        conversationManager: ConversationFlowManager(
            flowDefinition: [:],
            modelContext: DataManager.previewContainer.mainContext
        ),
        personaService: PersonaService(
            personaSynthesizer: OptimizedPersonaSynthesizer(
                llmOrchestrator: LLMOrchestrator(apiKeyManager: PreviewAPIKeyManager()),
                cache: AIResponseCache()
            ),
            llmOrchestrator: LLMOrchestrator(apiKeyManager: PreviewAPIKeyManager()),
            modelContext: DataManager.previewContainer.mainContext
        ),
        userService: PreviewUserService(),
        modelContext: DataManager.previewContainer.mainContext
    )
}