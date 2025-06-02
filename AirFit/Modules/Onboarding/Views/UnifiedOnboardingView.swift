import SwiftUI
import SwiftData

struct UnifiedOnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Dependencies
    let apiKeyManager: APIKeyManagerProtocol
    let userService: UserServiceProtocol
    let aiService: AIServiceProtocol
    let onboardingService: OnboardingServiceProtocol
    let onCompletion: () -> Void
    
    init(
        apiKeyManager: APIKeyManagerProtocol,
        userService: UserServiceProtocol,
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol,
        onCompletion: @escaping () -> Void
    ) {
        self.apiKeyManager = apiKeyManager
        self.userService = userService
        self.aiService = aiService
        self.onboardingService = onboardingService
        self.onCompletion = onCompletion
        
        // Initialize view model based on A/B test or user preference
        let mode: OnboardingViewModel.OnboardingMode = {
            // TODO: Check A/B test assignment when framework is ready
            // For now, default to conversational mode
            return .conversational
        }()
        
        self._viewModel = StateObject(wrappedValue: OnboardingViewModel(
            aiService: aiService,
            onboardingService: onboardingService,
            modelContext: modelContext,
            apiKeyManager: apiKeyManager,
            userService: userService,
            mode: mode
        ))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content based on mode
            Group {
                switch viewModel.mode {
                case .conversational:
                    conversationalFlowView
                case .legacy:
                    legacyFlowView
                }
            }
            
            // Mode switcher (for testing/debugging)
            if ProcessInfo.processInfo.environment["SHOW_MODE_SWITCHER"] == "1" {
                VStack {
                    HStack {
                        Spacer()
                        modeSwitcher
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.onCompletionCallback = onCompletion
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    // MARK: - Conversational Flow
    @ViewBuilder
    private var conversationalFlowView: some View {
        switch viewModel.orchestratorState {
        case .notStarted:
            ConversationalWelcomeView(
                onStart: {
                    Task {
                        // Get current user ID (would come from user service)
                        let userId = UUID() // Placeholder
                        try await viewModel.startConversationalOnboarding(userId: userId)
                    }
                }
            )
            
        case .conversationInProgress:
            // The conversation view is embedded within the orchestrator
            // Show progress or loading state
            VStack {
                OnboardingProgressBar(progress: viewModel.orchestratorProgress)
                    .padding()
                Spacer()
                ProgressView("Loading conversation...")
                    .progressViewStyle(.circular)
                Spacer()
            }
            
        case .synthesizingPersona:
            // This is handled within the conversation coordinator
            EmptyView()
            
        case .reviewingPersona(let persona):
            PersonaReviewView(
                persona: persona,
                onAccept: {
                    Task {
                        try await viewModel.completeConversationalOnboarding()
                    }
                },
                onAdjust: { adjustments in
                    Task {
                        try await viewModel.adjustPersona(adjustments)
                    }
                }
            )
            
        case .adjustingPersona:
            ProgressView("Adjusting your coach...")
                .progressViewStyle(.circular)
            
        case .saving:
            SavingProgressView()
            
        case .completed:
            CompletionView(onDismiss: onCompletion)
            
        case .paused:
            PausedView(
                onResume: {
                    Task {
                        try await viewModel.resumeConversation()
                    }
                },
                onRestart: {
                    // Restart logic
                }
            )
            
        case .cancelled:
            CancelledView(
                onRestart: {
                    viewModel.switchToConversationalMode()
                },
                onSwitchToLegacy: {
                    viewModel.switchToLegacyMode()
                }
            )
            
        case .error(let error):
            ErrorView(
                error: error,
                onRetry: {
                    // Retry logic based on error type
                },
                onSwitchToLegacy: {
                    viewModel.switchToLegacyMode()
                }
            )
        }
    }
    
    // MARK: - Legacy Flow
    @ViewBuilder
    private var legacyFlowView: some View {
        OnboardingFlowView(viewModel: viewModel)
    }
    
    // MARK: - Mode Switcher
    private var modeSwitcher: some View {
        Menu {
            Button("Conversational") {
                viewModel.switchToConversationalMode()
            }
            Button("Legacy Forms") {
                viewModel.switchToLegacyMode()
            }
        } label: {
            Label("Mode: \(viewModel.mode == .conversational ? "Chat" : "Forms")", systemImage: "gearshape")
                .font(.caption)
                .padding(8)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// MARK: - Supporting Views

struct ConversationalWelcomeView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)
            
            VStack(spacing: 16) {
                Text("Let's Create Your Perfect Coach")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Have a quick conversation with me, and I'll create a unique AI fitness coach just for you.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: onStart) {
                HStack {
                    Text("Start Conversation")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}


struct PersonaReviewView: View {
    let persona: PersonaProfile
    let onAccept: () -> Void
    let onAdjust: (PersonaAdjustments) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Meet \(persona.name)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(persona.archetype)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                // Preview message
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Introduction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(persona.interactionStyle.greetingStyle)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Characteristics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Coach Characteristics")
                        .font(.headline)
                    
                    CharacteristicRow(label: "Energy", value: persona.voiceCharacteristics.energy.rawValue)
                    CharacteristicRow(label: "Pace", value: persona.voiceCharacteristics.pace.rawValue)
                    CharacteristicRow(label: "Warmth", value: persona.voiceCharacteristics.warmth.rawValue)
                    CharacteristicRow(label: "Humor", value: persona.interactionStyle.humorLevel.rawValue)
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: onAccept) {
                        Text("Perfect! Let's Go")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Show adjustment options
                    }) {
                        Text("Adjust Personality")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

struct CharacteristicRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.capitalized)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct SavingProgressView: View {
    @State private var progress: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ProgressView(value: progress)
                .progressViewStyle(.circular)
                .scaleEffect(2)
            
            Text("Saving your coach...")
                .font(.headline)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 2)) {
                progress = 1.0
            }
        }
    }
}

struct CompletionView: View {
    let onDismiss: () -> Void
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your AI coach is ready to help you achieve your fitness goals.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Start Training")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                showContent = true
            }
        }
    }
}

struct PausedView: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "pause.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Conversation Paused")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your progress has been saved. You can continue where you left off.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: onResume) {
                    Text("Resume")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button(action: onRestart) {
                    Text("Start Over")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CancelledView: View {
    let onRestart: () -> Void
    let onSwitchToLegacy: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Onboarding Cancelled")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Button(action: onRestart) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button(action: onSwitchToLegacy) {
                    Text("Use Form-Based Setup")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ErrorView: View {
    let error: OnboardingOrchestratorError
    let onRetry: () -> Void
    let onSwitchToLegacy: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Something Went Wrong")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                
                Button(action: onSwitchToLegacy) {
                    Text("Use Form-Based Setup")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}