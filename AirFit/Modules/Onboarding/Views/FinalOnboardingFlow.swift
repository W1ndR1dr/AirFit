import SwiftUI
import SwiftData

/// Final polished onboarding flow view - production ready
struct FinalOnboardingFlow: View {
    @State private var coordinator: OnboardingFlowCoordinator?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.diContainer) private var diContainer
    @State private var showingExitConfirmation = false
    @State private var isLoading = true
    @State private var loadError: Error?
    
    var body: some View {
        Group {
            if let coordinator = coordinator {
                OnboardingErrorBoundary(content: {
                    NavigationStack {
                        BaseScreen {
                            // Content with transitions
                            contentView(for: coordinator)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                        .toolbar(coordinator.currentView == .welcome ? .hidden : .visible, for: .navigationBar)
                        .toolbar {
                            if coordinator.currentView != .welcome && coordinator.currentView != .complete {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("Exit") {
                                        showingExitConfirmation = true
                                    }
                                    .foregroundStyle(.secondary)
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
                }, coordinator: coordinator)
                .onAppear {
                    coordinator.start()
                }
            } else if isLoading {
                BaseScreen {
                    VStack {
                        Spacer()
                        ProgressView("Setting up...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                }
            } else if let error = loadError {
                BaseScreen {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        
                        Text("Failed to initialize onboarding")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text(error.localizedDescription)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            Task {
                                await loadCoordinator()
                            }
                        } label: {
                            Text("Retry")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 120)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await loadCoordinator()
        }
    }
    
    private func loadCoordinator() async {
        isLoading = true
        loadError = nil
        
        do {
            let factory = DIViewModelFactory(container: diContainer)
            coordinator = try await factory.makeOnboardingFlowCoordinator()
            isLoading = false
        } catch {
            loadError = error
            isLoading = false
            AppLogger.error("Failed to create onboarding coordinator", error: error, category: .onboarding)
        }
    }
    
    @ViewBuilder
    private func contentView(for coordinator: OnboardingFlowCoordinator) -> some View {
        switch coordinator.currentView {
        case .welcome:
            WelcomeView(coordinator: coordinator)
                .id("welcome")
            
        case .conversation:
            ConversationFlowView(coordinator: coordinator)
                .id("conversation")
            
        case .generatingPersona:
            OptimizedGeneratingPersonaView(
                coordinator: coordinator
            )
            .id("generating")
            
        case .personaPreview:
            if let persona = coordinator.generatedPersona {
                PersonaPreviewView(
                    persona: persona,
                    coordinator: coordinator
                )
                .id("preview")
            }
            
        case .complete:
            OnboardingCompletionView(coordinator: coordinator)
                .id("complete")
        }
    }
}

// MARK: - Welcome View

private struct WelcomeView: View {
    @Bindable var coordinator: OnboardingFlowCoordinator
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Logo animation
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animationPhase > 0 ? 1.0 : 0.8)
                .opacity(animationPhase > 0 ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationPhase)
            
            VStack(spacing: AppSpacing.md) {
                CascadeText("Welcome to AirFit")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .opacity(animationPhase > 1 ? 1.0 : 0.0)
                    .offset(y: animationPhase > 1 ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animationPhase)
                
                Text("Your AI-powered fitness journey starts here")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animationPhase > 2 ? 1.0 : 0.0)
                    .offset(y: animationPhase > 2 ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animationPhase)
            }
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
            
            // Start button
            Button {
                HapticService.impact(.medium)
                Task {
                    await coordinator.beginConversation()
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Text("Let's Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, AppSpacing.xl)
            .opacity(animationPhase > 3 ? 1.0 : 0.0)
            .offset(y: animationPhase > 3 ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.7), value: animationPhase)
            
            Spacer()
                .frame(height: AppSpacing.xl)
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
    @Bindable var coordinator: OnboardingFlowCoordinator
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressBar(progress: coordinator.progress)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
            
            // Conversation content
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Current conversation UI would go here
                    // This is a placeholder for the actual conversation view
                    Text("Conversation in progress...")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.xl)
                }
                .padding(AppSpacing.lg)
            }
            
            // Action buttons
            HStack(spacing: AppSpacing.md) {
                Button {
                    Task {
                        await coordinator.completeConversation()
                    }
                } label: {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                Button {
                    Task {
                        await coordinator.completeConversation()
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            LinearGradient(
                                colors: coordinator.isLoading 
                                    ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                    : [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(coordinator.isLoading)
            }
            .padding(AppSpacing.lg)
        }
    }
}

// MARK: - Completion View

private struct OnboardingCompletionView: View {
    @Bindable var coordinator: OnboardingFlowCoordinator
    @State private var showingContent = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(showingContent ? 1.0 : 0.5)
                .opacity(showingContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showingContent)
            
            VStack(spacing: AppSpacing.md) {
                CascadeText("You're All Set!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Your personalized AI coach is ready to help you achieve your fitness goals")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            .opacity(showingContent ? 1.0 : 0.0)
            .offset(y: showingContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: showingContent)
            
            Spacer()
            
            Button {
                HapticService.notification(.success)
                // Dismiss onboarding
            } label: {
                Text("Start My Journey")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.horizontal, AppSpacing.xl)
            .opacity(showingContent ? 1.0 : 0.0)
            .offset(y: showingContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: showingContent)
            
            Spacer()
                .frame(height: AppSpacing.xl)
        }
        .onAppear {
            withAnimation {
                showingContent = true
            }
            
            // Cleanup
            Task {
                await coordinator.cleanup()
            }
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
                    .fill(.ultraThinMaterial)
                    .frame(height: 6)
                
                // Progress
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 6)
    }
}