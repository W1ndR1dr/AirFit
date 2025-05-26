import SwiftUI
import SwiftData
import Observation

struct OnboardingFlowView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var viewModel: OnboardingViewModel

    let onCompletion: (() -> Void)?

    init(
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol,
        onCompletion: (() -> Void)? = nil
    ) {
        // We'll initialize the viewModel in onAppear when we have access to modelContext
        _viewModel = State(initialValue: OnboardingViewModel(
            aiService: aiService,
            onboardingService: onboardingService,
            modelContext: try! ModelContext(.init(for: OnboardingProfile.self))
        ))
        self.onCompletion = onCompletion
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
        .onAppear {
            viewModel.onCompletionCallback = onCompletion
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
            },
            label: {
            Text("Privacy & Data")
                .font(AppFonts.caption)
                .foregroundColor(AppColors.textTertiary)
            }
        )
        .accessibilityIdentifier("onboarding.privacy")
    }
}
