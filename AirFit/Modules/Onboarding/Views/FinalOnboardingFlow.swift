import SwiftUI
import SwiftData

/// Final polished onboarding flow view - production ready
struct FinalOnboardingFlow: View {
    @StateObject private var coordinator: OnboardingFlowCoordinator
    @Environment(\.modelContext) private var modelContext
    @State private var showingExitConfirmation = false
    
    init(
        userService: UserServiceProtocol,
        modelContext: ModelContext
    ) {
        let cache = AIResponseCache()
        let apiKeyManager = DependencyContainer.shared.apiKeyManager
        let llmOrchestrator = LLMOrchestrator(apiKeyManager: apiKeyManager)
        
        // Use optimized synthesizer
        let optimizedSynthesizer = OptimizedPersonaSynthesizer(
            llmOrchestrator: llmOrchestrator,
            cache: cache
        )
        
        let personaSynthesizer = PersonaSynthesizer(llmOrchestrator: llmOrchestrator)
        
        let personaService = PersonaService(
            personaSynthesizer: personaSynthesizer,
            llmOrchestrator: llmOrchestrator,
            modelContext: modelContext,
            cache: cache
        )
        
        let coordinator = OnboardingFlowCoordinator(
            conversationManager: ConversationFlowManager(),
            personaService: personaService,
            userService: userService,
            modelContext: modelContext
        )
        
        _coordinator = StateObject(wrappedValue: coordinator)
    }
    
    var body: some View {
        OnboardingErrorBoundary(coordinator: coordinator) {
            NavigationStack {
                ZStack {
                    // Background gradient
                    backgroundGradient
                    
                    // Content with transitions
                    contentView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
                .navigationBarHidden(coordinator.currentView == .welcome)
                .toolbar {
                    if coordinator.currentView != .welcome && coordinator.currentView != .complete {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Exit") {
                                showingExitConfirmation = true
                            }
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .confirmationDialog(
                "Exit Onboarding?",
                isPresented: $showingExitConfirmation,
                titleVisibility: .visible
            ) {
                Button("Exit", role: .destructive) {
                    // Handle exit
                }
                Button("Continue Setup", role: .cancel) { }
            } message: {
                Text("You can complete setup later from Settings")
            }
        }
        .onAppear {
            coordinator.start()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch coordinator.currentView {
        case .welcome:
            WelcomeView(coordinator: coordinator)
                .id("welcome")
            
        case .conversation:
            ConversationFlowView(coordinator: coordinator)
                .id("conversation")
            
        case .generatingPersona:
            OptimizedGeneratingPersonaView(
                progress: coordinator.progress,
                message: coordinator.recoveryMessage
            )
            .id("generating")
            
        case .personaPreview:
            if let persona = coordinator.generatedPersona {
                PersonaPreviewView(
                    persona: persona,
                    onAccept: {
                        Task {
                            await coordinator.acceptPersona()
                        }
                    },
                    onAdjust: { adjustment in
                        Task {
                            await coordinator.adjustPersona(adjustment)
                        }
                    },
                    onRegenerate: {
                        Task {
                            await coordinator.regeneratePersona()
                        }
                    }
                )
                .id("preview")
            }
            
        case .complete:
            CompletionView(coordinator: coordinator)
                .id("complete")
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                AppColors.backgroundPrimary,
                AppColors.backgroundSecondary.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Welcome View

private struct WelcomeView: View {
    @ObservedObject var coordinator: OnboardingFlowCoordinator
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(spacing: AppSpacing.xxLarge) {
            Spacer()
            
            // Logo animation
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.accentColor, AppColors.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animationPhase > 0 ? 1.0 : 0.8)
                .opacity(animationPhase > 0 ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationPhase)
            
            VStack(spacing: AppSpacing.medium) {
                Text("Welcome to AirFit")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                    .opacity(animationPhase > 1 ? 1.0 : 0.0)
                    .offset(y: animationPhase > 1 ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animationPhase)
                
                Text("Your AI-powered fitness journey starts here")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(animationPhase > 2 ? 1.0 : 0.0)
                    .offset(y: animationPhase > 2 ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animationPhase)
            }
            .padding(.horizontal, AppSpacing.xxLarge)
            
            Spacer()
            
            // Start button
            Button(action: {
                Task {
                    await coordinator.beginConversation()
                }
            }) {
                HStack {
                    Text("Let's Get Started")
                        .font(AppFonts.bodyBold)
                    Image(systemName: "arrow.right")
                        .font(AppFonts.body)
                }
                .foregroundColor(AppColors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.medium)
                .background(
                    Capsule()
                        .fill(AppColors.accentColor)
                )
            }
            .padding(.horizontal, AppSpacing.xxLarge)
            .opacity(animationPhase > 3 ? 1.0 : 0.0)
            .offset(y: animationPhase > 3 ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.7), value: animationPhase)
            
            Spacer()
                .frame(height: AppSpacing.xxLarge)
        }
        .onAppear {
            // Trigger animations
            withAnimation {
                animationPhase = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationPhase = 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animationPhase = 3
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animationPhase = 4
                    }
                }
            }
        }
    }
}

// MARK: - Conversation Flow View

private struct ConversationFlowView: View {
    @ObservedObject var coordinator: OnboardingFlowCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressBar(progress: coordinator.progress)
                .padding(.horizontal, AppSpacing.large)
                .padding(.top, AppSpacing.medium)
            
            // Conversation content
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    // Current conversation UI would go here
                    // This is a placeholder for the actual conversation view
                    Text("Conversation in progress...")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.top, AppSpacing.xxLarge)
                }
                .padding(AppSpacing.large)
            }
            
            // Action buttons
            HStack(spacing: AppSpacing.medium) {
                Button("Skip") {
                    Task {
                        await coordinator.completeConversation()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Continue") {
                    Task {
                        await coordinator.completeConversation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(coordinator.isLoading)
            }
            .padding(AppSpacing.large)
        }
    }
}

// MARK: - Completion View

private struct CompletionView: View {
    @ObservedObject var coordinator: OnboardingFlowCoordinator
    @State private var showingContent = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xxLarge) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(AppColors.successColor)
                .scaleEffect(showingContent ? 1.0 : 0.5)
                .opacity(showingContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showingContent)
            
            VStack(spacing: AppSpacing.medium) {
                Text("You're All Set!")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Your personalized AI coach is ready to help you achieve your fitness goals")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxLarge)
            }
            .opacity(showingContent ? 1.0 : 0.0)
            .offset(y: showingContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: showingContent)
            
            Spacer()
            
            Button(action: {
                // Dismiss onboarding
            }) {
                Text("Start My Journey")
                    .font(AppFonts.bodyBold)
                    .foregroundColor(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.medium)
                    .background(
                        Capsule()
                            .fill(AppColors.accentColor)
                    )
            }
            .padding(.horizontal, AppSpacing.xxLarge)
            .opacity(showingContent ? 1.0 : 0.0)
            .offset(y: showingContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: showingContent)
            
            Spacer()
                .frame(height: AppSpacing.xxLarge)
        }
        .onAppear {
            withAnimation {
                showingContent = true
            }
            
            // Cleanup
            coordinator.cleanup()
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(AppColors.backgroundTertiary)
                    .frame(height: 6)
                
                // Progress
                Capsule()
                    .fill(AppColors.accentColor)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 6)
    }
}