import SwiftUI
import SwiftData
import Observation

/// DI-based version of OnboardingFlowView
struct OnboardingFlowViewDI: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: OnboardingViewModel?
    @State private var isLoading = true
    @State private var loadError: Error?
    
    let onCompletion: (() -> Void)?
    
    init(onCompletion: (() -> Void)? = nil) {
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                VStack(spacing: 0) {
                    if shouldShowProgressBar(for: viewModel.currentScreen) {
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
                    
                    if shouldShowPrivacyFooter(for: viewModel.currentScreen) {
                        PrivacyFooter()
                            .padding(.bottom)
                    }
                }
                .background(AppColors.backgroundPrimary)
                .loadingOverlay(isLoading: viewModel.isLoading)
                .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                    Button("OK") { viewModel.error = nil }
                } message: {
                    if let error = viewModel.error {
                        Text(error.localizedDescription)
                    }
                }
            } else if isLoading {
                VStack(spacing: AppSpacing.large) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppColors.accentColor)
                    
                    Text("Setting up...")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundPrimary)
            } else if let error = loadError {
                VStack(spacing: AppSpacing.large) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.errorColor)
                    
                    Text("Failed to initialize onboarding")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(error.localizedDescription)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await loadViewModel()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.backgroundPrimary)
            }
        }
        .task {
            await loadViewModel()
        }
    }
    
    private func loadViewModel() async {
        isLoading = true
        loadError = nil
        
        do {
            let factory = DIViewModelFactory(container: diContainer)
            viewModel = try await factory.makeOnboardingViewModel()
            
            // Update the view model's model context to use the one from the environment
            viewModel?.updateModelContext(modelContext)
            
            // Set the completion callback
            viewModel?.onCompletionCallback = onCompletion
            
            isLoading = false
        } catch {
            loadError = error
            isLoading = false
            AppLogger.error("Failed to create onboarding view model", error: error, category: .onboarding)
        }
    }
    
    private func shouldShowProgressBar(for screen: OnboardingScreen) -> Bool {
        switch screen {
        case .openingScreen, .generatingCoach, .coachProfileReady:
            return false
        default:
            return true
        }
    }
    
    private func shouldShowPrivacyFooter(for screen: OnboardingScreen) -> Bool {
        switch screen {
        case .openingScreen, .generatingCoach, .coachProfileReady:
            return false
        default:
            return true
        }
    }
}

// MARK: - Step Progress Bar

private struct StepProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.backgroundTertiary)
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.accentColor)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.smooth, value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Privacy Footer

private struct PrivacyFooter: View {
    var body: some View {
        Text("Your information is secure and will only be used to personalize your fitness experience.")
            .font(AppFonts.caption)
            .foregroundColor(AppColors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, AppSpacing.small)
    }
}