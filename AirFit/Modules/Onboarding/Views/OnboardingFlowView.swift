import SwiftUI
import SwiftData
import Observation

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel

    init(
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol
    ) {
        let context = ModelContext(AirFitApp.sharedModelContainer)
        _viewModel = State(initialValue: OnboardingViewModel(
            aiService: aiService,
            onboardingService: onboardingService,
            modelContext: context
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.currentScreen != .openingScreen &&
                viewModel.currentScreen != .generatingCoach &&
                viewModel.currentScreen != .coachProfileReady {
                StepProgressBar(progress: viewModel.currentScreen.progress)
                    .padding(.horizontal)
                    .padding(.top)
            }

            Group {
                switch viewModel.currentScreen {
                case .openingScreen:
                    OpeningScreenView(viewModel: viewModel)
                case .lifeSnapshot:
                    LifeSnapshotView(viewModel: viewModel)
                case .coreAspiration:
                    CoreAspirationView(viewModel: viewModel)
                case .coachingStyle:
                    CoachingStyleView(viewModel: viewModel)
                case .engagementPreferences:
                    EngagementPreferencesView(viewModel: viewModel)
                case .sleepAndBoundaries:
                    SleepAndBoundariesView(viewModel: viewModel)
                case .motivationalAccents:
                    MotivationalAccentsView(viewModel: viewModel)
                case .generatingCoach:
                    GeneratingCoachView(viewModel: viewModel)
                case .coachProfileReady:
                    CoachProfileReadyView(viewModel: viewModel)
                }
            }
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .animation(.easeInOut(duration: AppConstants.Animation.defaultDuration), value: viewModel.currentScreen)

            if viewModel.currentScreen != .generatingCoach &&
                viewModel.currentScreen != .coachProfileReady {
                PrivacyFooter()
                    .padding(.bottom)
            }
        }
        .background(AppColors.backgroundPrimary)
        .loadingOverlay(isLoading: viewModel.isLoading)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? NSLocalizedString("error.generic", comment: ""))
        }
        .accessibilityIdentifier("onboarding.flow")
    }
}

// MARK: - Progress Bar
private struct StepProgressBar: View {
    let progress: Double
    private let segments = 7

    var body: some View {
        GeometryReader { geometry in
            let segmentWidth = geometry.size.width / CGFloat(segments)
            HStack(spacing: 2) {
                ForEach(0..<segments, id: \..self) { index in
                    Capsule()
                        .fill(progress >= Double(index) / Double(segments - 1) ? AppColors.accentColor : AppColors.dividerColor)
                        .frame(width: segmentWidth - 2, height: 4)
                }
            }
        }
        .frame(height: 4)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityValue("\(Int(progress * 100))% complete")
    }
}

// MARK: - Privacy Footer
private struct PrivacyFooter: View {
    var body: some View {
        Button(action: {
            AppLogger.info("Privacy policy tapped", category: .onboarding)
        }) {
            Text("Privacy & Data")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .accessibilityIdentifier("onboarding.privacy")
    }
}

// MARK: - Placeholder Views

private struct CoachingStyleView: View {
    @Bindable var viewModel: OnboardingViewModel
    var body: some View { Text("Coaching Style") }
}

private struct EngagementPreferencesView: View {
    @Bindable var viewModel: OnboardingViewModel
    var body: some View { Text("Engagement Preferences") }
}

private struct SleepAndBoundariesView: View {
    @Bindable var viewModel: OnboardingViewModel
    var body: some View { Text("Sleep & Boundaries") }
}

private struct MotivationalAccentsView: View {
    @Bindable var viewModel: OnboardingViewModel
    var body: some View { Text("Motivational Accents") }
}

private struct GeneratingCoachView: View {
    @Bindable var viewModel: OnboardingViewModel
    var body: some View { Text("Generating Coach...") }
}

private struct CoachProfileReadyView: View {
    @Bindable var viewModel: OnboardingViewModel
    var body: some View { Text("Coach Profile Ready") }
}

