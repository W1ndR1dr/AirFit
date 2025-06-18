import SwiftUI

/// Container view that manages the onboarding flow with gradient transitions
struct OnboardingContainerView: View {
    let viewModel: OnboardingViewModel
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var navigationPath = NavigationPath()
    
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            currentScreen
                .navigationBarHidden(true)
                .onChange(of: viewModel.currentScreen) { oldScreen, newScreen in
                    handleScreenTransition(from: oldScreen, to: newScreen)
                }
        }
        .onAppear {
            // Set initial gradient for opening screen (pre-dawn darkness)
            gradientManager.setGradient(.nightSky, animated: false)
        }
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch viewModel.currentScreen {
        case .opening:
            OpeningScreenView(viewModel: viewModel)
        case .healthKit:
            HealthKitAuthorizationView(viewModel: viewModel)
        case .lifeContext:
            LifeContextView(viewModel: viewModel)
        case .goals:
            GoalsProgressiveView(viewModel: viewModel)
        case .communicationStyle:
            CommunicationStyleView(viewModel: viewModel)
        case .synthesis:
            LLMSynthesisView(viewModel: viewModel)
        case .coachReady:
            CoachReadyView(viewModel: viewModel)
        }
    }
    
    private func handleScreenTransition(from oldScreen: OnboardingViewModel.OnboardingScreen, to newScreen: OnboardingViewModel.OnboardingScreen) {
        // Map screens to specific gradients for sunrise journey
        let gradientMap: [OnboardingViewModel.OnboardingScreen: GradientToken] = [
            .opening: .nightSky,              // Pre-dawn darkness
            .healthKit: .earlyTwilight,       // First hint of light
            .lifeContext: .morningTwilight,   // Purple twilight
            .goals: .firstLight,              // Dawn breaking
            .communicationStyle: .sunrise,    // Actual sunrise
            .synthesis: .morningGlow,         // Golden hour (will cycle)
            .coachReady: .brightMorning       // Late morning - user's "home" gradient
        ]
        
        // Only advance gradient when moving forward
        if newScreen.rawValue > oldScreen.rawValue {
            if let targetGradient = gradientMap[newScreen] {
                gradientManager.setGradient(targetGradient)
            } else {
                gradientManager.advance()
            }
        }
    }
}

// MARK: - Chapter Transition (o3-inspired)
struct ChapterTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .scaleEffect(isPresented ? 1 : 0.94)
            .blur(radius: isPresented ? 0 : 4)
            .animation(.easeInOut(duration: 0.55), value: isPresented)
    }
}

extension View {
    func chapterTransition(isPresented: Bool) -> some View {
        modifier(ChapterTransition(isPresented: isPresented))
    }
}

