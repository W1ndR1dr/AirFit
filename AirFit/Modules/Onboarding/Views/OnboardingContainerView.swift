import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @State private var coordinator: OnboardingFlowCoordinator?
    @State private var showingError = false
    @State private var isLoading = true
    @State private var loadError: Error?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.diContainer) private var diContainer
    
    var body: some View {
        Group {
            if let coordinator = coordinator {
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
                .onAppear {
                    coordinator.start()
                }
            } else if isLoading {
                ProgressView("Initializing...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("BackgroundPrimary"))
            } else if let error = loadError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text("Failed to initialize onboarding")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    StandardButton("Retry", style: .primary) {
                        Task {
                            await loadCoordinator()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundPrimary"))
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
}

// MARK: - Welcome View

private struct WelcomeView: View {
    @Bindable var coordinator: OnboardingFlowCoordinator
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon/logo
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AccentColor"), Color("AccentSecondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .animation(.spring(response: 0.8, dampingFraction: 0.5), value: isAnimating)
            
            VStack(spacing: 16) {
                Text("Welcome to AirFit")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("Let's create your personalized AI fitness coach")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Get started button
            Button(action: {
                Task {
                    await coordinator.beginConversation()
                }
            }) {
                HStack {
                    Text("Get Started")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("AccentColor"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Conversation Flow View

private struct ConversationFlowView: View {
    @Bindable var coordinator: OnboardingFlowCoordinator
    
    var body: some View {
        VStack {
            // Conversation content would go here
            Text("Conversation in progress...")
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Complete button for testing
            StandardButton("Complete Conversation", style: .primary) {
                Task {
                    await coordinator.completeConversation()
                }
            }
            .padding()
        }
    }
}

// MARK: - Generating Persona View

private struct GeneratingPersonaView: View {
    @Bindable var coordinator: OnboardingFlowCoordinator
    @State private var dots = ""
    @State private var animationTask: Task<Void, Never>?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated loading icon
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentColor")))
            
            VStack(spacing: 8) {
                Text("Creating Your Coach\(dots)")
                    .font(.title2.bold())
                
                Text("This will take just a moment")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            animateDots()
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private func animateDots() {
        animationTask = Task {
            while !Task.isCancelled {
                if coordinator.currentView != .generatingPersona {
                    break
                }
                
                switch dots.count {
                case 0: dots = "."
                case 1: dots = ".."
                case 2: dots = "..."
                default: dots = ""
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }
}

// MARK: - Completion View

private struct ContainerCompletionView: View {
    @Bindable var coordinator: OnboardingFlowCoordinator
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("All Set!")
                    .font(.largeTitle.bold())
                
                Text("Your AI coach is ready to help you achieve your fitness goals")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button("Start Training") {
                // Complete onboarding by accepting the persona
                Task {
                    await coordinator.acceptPersona()
                }
            }
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Progress Bar

private struct ContainerProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("AccentColor"))
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.smooth, value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Loading Overlay

private struct ContainerLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
}