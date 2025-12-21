import SwiftUI

// MARK: - Onboarding Coordinator

/// Manages the multi-step onboarding flow.
///
/// Flow:
/// 1. Splash - animated intro
/// 2. Welcome - new user vs returning
/// 3. Permissions - HealthKit access
/// 4. CoachSelection - pick AI mode (Claude/Gemini/Hybrid)
/// 5. ServerSetup - server URL (if Claude or Hybrid)
/// 6. GeminiSetup - API key (if Gemini or Hybrid)
/// 7. HevySetup - workout sync (right after LLM setup for data pipeline)
/// 8. Interview - conversational profile discovery (WHO you are)
/// 9. Calibration - coaching style preferences (HOW you want coaching)
/// 10. Complete
///
/// The Interview discovers user data through conversation.
/// The Calibration captures explicit coaching permissions (roast tolerance, advice style).
struct OnboardingCoordinator: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboardingStep") private var savedStep = 0
    @AppStorage("aiProvider") private var aiProvider: String = "claude"

    @State private var currentStep: OnboardingStep = .splash
    @State private var selectedCoachMode: CoachSelectionView.CoachMode = .claude

    enum OnboardingStep: Int, CaseIterable {
        case splash = 0
        case welcome = 1
        case permissions = 2
        case coachSelection = 3
        case serverSetup = 4
        case geminiSetup = 5
        case hevySetup = 6       // Moved up: data pipeline before personalization
        case interview = 7
        case calibration = 8
        case complete = 9
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
                    onReturningUser: { advanceTo(.coachSelection) }
                )
                .transition(.opacity)

            case .permissions:
                PermissionFlowView(onComplete: { advanceTo(.coachSelection) })
                    .transition(.opacity)

            case .coachSelection:
                CoachSelectionView { mode in
                    selectedCoachMode = mode
                    // Route based on selected mode
                    switch mode {
                    case .gemini:
                        // Gemini only - skip server setup
                        advanceTo(.geminiSetup)
                    case .hybrid, .claude:
                        // Need server for Claude
                        advanceTo(.serverSetup)
                    }
                }
                .transition(.opacity)

            case .serverSetup:
                ServerSetupView(
                    onComplete: {
                        // If hybrid, also need Gemini setup
                        if selectedCoachMode == .hybrid {
                            advanceTo(.geminiSetup)
                        } else {
                            advanceTo(.hevySetup)
                        }
                    },
                    onSkip: {
                        if selectedCoachMode == .hybrid {
                            advanceTo(.geminiSetup)
                        } else {
                            advanceTo(.hevySetup)
                        }
                    }
                )
                .transition(.opacity)

            case .geminiSetup:
                GeminiSetupView(
                    onComplete: { advanceTo(.hevySetup) },
                    onSkip: { advanceTo(.hevySetup) }
                )
                .transition(.opacity)

            case .interview:
                OnboardingInterviewView(
                    onComplete: { advanceTo(.calibration) },
                    onSkip: { advanceTo(.calibration) }
                )
                .transition(.opacity)

            case .hevySetup:
                HevySetupView(
                    onComplete: { advanceTo(.interview) },
                    onSkip: { advanceTo(.interview) }
                )
                .transition(.opacity)

            case .calibration:
                CoachingCalibrationView(
                    onComplete: { completeOnboarding() },
                    onSkip: { completeOnboarding() }
                )
                .transition(.opacity)

            case .complete:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentStep)
        .onAppear {
            // Resume from saved step if app was killed mid-onboarding
            if savedStep > 0 && savedStep < OnboardingStep.complete.rawValue {
                currentStep = OnboardingStep(rawValue: savedStep) ?? .splash
                // Restore coach mode from saved provider
                selectedCoachMode = CoachSelectionView.CoachMode(rawValue: aiProvider) ?? .claude
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
