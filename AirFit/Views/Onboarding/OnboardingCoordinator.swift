import SwiftUI

// MARK: - Onboarding Coordinator

struct OnboardingCoordinator: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboardingStep") private var savedStep = 0

    @State private var currentStep: OnboardingStep = .splash

    enum OnboardingStep: Int, CaseIterable {
        case splash = 0
        case welcome = 1
        case permissions = 2
        case serverCheck = 3
        case interview = 4
        case complete = 5
    }

    var body: some View {
        Group {
            switch currentStep {
            case .splash:
                SplashView(onComplete: { advanceTo(.welcome) })
                    .transition(.opacity)

            case .welcome:
                WelcomeView(
                    onContinue: { advanceTo(.permissions) },
                    onReturningUser: { advanceTo(.serverCheck) }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .permissions:
                PermissionFlowView(onComplete: { advanceTo(.serverCheck) })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .serverCheck:
                ServerCheckView(
                    onSuccess: { advanceTo(.interview) },
                    onSkip: { advanceTo(.interview) }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            case .interview:
                OnboardingInterviewView(
                    onComplete: { completeOnboarding() },
                    onSkip: { skipOnboarding() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))

            case .complete:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
        .onAppear {
            // Resume from saved step if app was killed mid-onboarding
            if savedStep > 0 && savedStep < OnboardingStep.complete.rawValue {
                currentStep = OnboardingStep(rawValue: savedStep) ?? .splash
            }
        }
    }

    private func advanceTo(_ step: OnboardingStep) {
        currentStep = step
        savedStep = step.rawValue
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        savedStep = OnboardingStep.complete.rawValue
    }

    private func skipOnboarding() {
        hasCompletedOnboarding = true
        savedStep = OnboardingStep.complete.rawValue
    }
}

#Preview {
    OnboardingCoordinator()
}
