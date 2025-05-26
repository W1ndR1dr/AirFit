import SwiftUI
import SwiftData
import Observation

struct OnboardingFlowView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var viewModel: OnboardingViewModel

    init(
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol
    ) {
        let context = ModelContext(AirFitApp.sharedModelContainer)
        _viewModel = State(
            initialValue: OnboardingViewModel(
                aiService: aiService,
                onboardingService: onboardingService,
                modelContext: context
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if shouldShowProgressBar {
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
            .animation(
                .easeInOut(duration: AppConstants.Animation.defaultDuration),
                value: viewModel.currentScreen
            )

            if shouldShowPrivacyFooter {
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

    // MARK: - Computed Properties
    private var shouldShowProgressBar: Bool {
        viewModel.currentScreen != .openingScreen &&
        viewModel.currentScreen != .generatingCoach &&
        viewModel.currentScreen != .coachProfileReady
    }

    private var shouldShowPrivacyFooter: Bool {
        viewModel.currentScreen != .generatingCoach &&
        viewModel.currentScreen != .coachProfileReady
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
                ForEach(0..<segments, id: \.self) { index in
                    Capsule()
                        .fill(segmentColor(for: index))
                        .frame(width: segmentWidth - 2, height: 4)
                }
            }
        }
        .frame(height: 4)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityValue("\(Int(progress * 100))% complete")
    }

    private func segmentColor(for index: Int) -> Color {
        progress >= Double(index) / Double(segments - 1) ? AppColors.accentColor : AppColors.dividerColor
    }
}

// MARK: - Privacy Footer
private struct PrivacyFooter: View {
    var body: some View {
        Button(
            action: {
                AppLogger.info("Privacy policy tapped", category: .onboarding)
            }
        ) {
            Text("Privacy & Data")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .accessibilityIdentifier("onboarding.privacy")
    }
}

// MARK: - Placeholder Views

private struct GeneratingCoachView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.accentColor)

            Text("Crafting Your AirFit Coach")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Analyzing your preferences and creating your personalized coaching experience...")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(AppSpacing.large)
        .accessibilityIdentifier("onboarding.generatingCoach")
        .onAppear {
            Task {
                try await viewModel.completeOnboarding()
                viewModel.navigateToNextScreen()
            }
        }
    }
}

private struct CoachProfileReadyView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.successColor)

            Text("Your AirFit Coach Is Ready!")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Your personalized coaching experience has been created. Let's begin your fitness journey!")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(
                action: {
                    // Navigate to main app
                    AppLogger.info("Onboarding completed, navigating to main app", category: .onboarding)
                }
            ) {
                Text("Get Started")
                    .font(AppFonts.bodyBold)
                    .foregroundColor(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentColor)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .accessibilityIdentifier("onboarding.getStarted.button")
        }
        .padding(AppSpacing.large)
        .accessibilityIdentifier("onboarding.coachProfileReady")
    }
}


