import SwiftUI
import SwiftData
import Observation

// MARK: - Fallback API Key Manager
private final class PreviewAPIKeyManager: APIKeyManagementProtocol {
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {}
    func getAPIKey(for provider: AIProvider) async throws -> String { throw AppError.unauthorized }
    func deleteAPIKey(for provider: AIProvider) async throws {}
    func hasAPIKey(for provider: AIProvider) async -> Bool { false }
    func getAllConfiguredProviders() async -> [AIProvider] { [] }
}

/// DI-based version of OnboardingFlowView
struct OnboardingFlowViewDI: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.diContainer) private var diContainer
    @State private var viewModel: OnboardingViewModel?
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var retryCount = 0
    
    let onCompletion: (() -> Void)?
    
    init(onCompletion: (() -> Void)? = nil) {
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        BaseScreen {
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
                    .loadingOverlay(isLoading: viewModel.isLoading)
                    .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                        Button("OK") { viewModel.error = nil }
                    } message: {
                        if let error = viewModel.error {
                            Text(error.localizedDescription)
                        }
                    }
                } else if isLoading {
                    VStack(spacing: AppSpacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.accentColor)
                        
                        Text("Setting up...")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadError {
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
                                await loadViewModel()
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
            await loadViewModel()
        }
    }
    
    private func loadViewModel() async {
        isLoading = true
        loadError = nil
        retryCount += 1
        
        do {
            // Add a small delay to ensure the container is ready
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Use the injected container
            let containerToUse = diContainer
            AppLogger.info("OnboardingFlowViewDI: Attempt \(retryCount) using container ID: \(ObjectIdentifier(containerToUse))", category: .onboarding)
            
            // Check if we have API keys configured
            let apiKeyManager = try? await containerToUse.resolve(APIKeyManagementProtocol.self)
            let hasAPIKeys = await apiKeyManager?.getAllConfiguredProviders().isEmpty == false
            
            if !hasAPIKeys && AppConstants.Configuration.isUsingDemoMode == false {
                // If no API keys and not in demo mode, show error
                loadError = AppError.unknown(message: "API keys not configured. Please restart the app after setting up API keys.")
                isLoading = false
                return
            }
            
            // Try to create view model through DI, passing model context directly
            let factory = DIViewModelFactory(container: containerToUse)
            viewModel = try await factory.makeOnboardingViewModel(modelContext: modelContext)
            
            // Update the view model's model context to use the one from the environment
            viewModel?.updateModelContext(modelContext)
            
            // Set the completion callback
            viewModel?.onCompletionCallback = onCompletion
            
            isLoading = false
        } catch {
            AppLogger.error("Failed to create OnboardingViewModel: \(error)", category: .onboarding)
            
            // If DI fails, create a minimal view model directly
            if retryCount < 3 {
                // Retry a few times with increasing delay
                try? await Task.sleep(nanoseconds: UInt64(retryCount) * 500_000_000)
                await loadViewModel()
            } else {
                // After retries, create view model with minimal dependencies
                await createMinimalViewModel()
            }
        }
    }
    
    private func createMinimalViewModel() async {
        AppLogger.warning("Creating minimal OnboardingViewModel without full DI", category: .onboarding)
        
        // Create minimal services directly
        let onboardingService = OnboardingService(modelContext: modelContext)
        let healthKitManager = HealthKitManager()
        let healthKitAuthManager = HealthKitAuthManager(healthKitManager: healthKitManager)
        
        // Try to get services from container if possible, otherwise use defaults
        let aiService = (try? await diContainer.resolve(AIServiceProtocol.self)) ?? DemoAIService()
        let apiKeyManager = try? await diContainer.resolve(APIKeyManagementProtocol.self)
        let userService = (try? await diContainer.resolve(UserServiceProtocol.self)) ?? UserService(modelContext: modelContext)
        
        viewModel = OnboardingViewModel(
            aiService: aiService,
            onboardingService: onboardingService,
            modelContext: modelContext,
            apiKeyManager: apiKeyManager ?? PreviewAPIKeyManager(),
            userService: userService,
            healthKitAuthManager: healthKitAuthManager
        )
        
        viewModel?.onCompletionCallback = onCompletion
        isLoading = false
        loadError = nil
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
                    .fill(.ultraThinMaterial)
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, AppSpacing.sm)
    }
}