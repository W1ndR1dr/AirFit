import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.diContainer)
    private var diContainer
    @State private var appState: AppState?
    @State private var isRecreatingContainer = false
    
    // Store the container we receive to ensure consistency
    @State private var activeContainer: DIContainer?

    var body: some View {
        VStack {
            if isRecreatingContainer {
                LoadingView()
            } else if let appState = appState {
                if appState.isLoading {
                    LoadingView()
                } else if appState.shouldShowAPISetup {
                    InitialAPISetupView { configured in
                        appState.completeAPISetup(usingDemoMode: !configured)
                        if configured {
                            // Need to recreate the DI container with the new API key
                            isRecreatingContainer = true
                            Task {
                                await recreateContainer()
                            }
                        }
                    }
                } else if appState.shouldCreateUser {
                    WelcomeView(appState: appState)
                } else if appState.shouldShowOnboarding {
                    // Use the new DI-based onboarding flow
                    OnboardingFlowViewDI(onCompletion: {
                        Task {
                            await appState.completeOnboarding()
                        }
                    })
                    .onAppear {
                        AppLogger.info("ContentView: Container from environment ID: \(ObjectIdentifier(diContainer))", category: .app)
                    }
                } else if appState.shouldShowDashboard, let user = appState.currentUser {
                    DashboardView(user: user)
                } else {
                    ErrorView(
                        error: appState.error,
                        onRetry: {
                            appState.clearError()
                            Task {
                                await appState.loadUserState()
                            }
                        }
                    )
                }
            } else {
                LoadingView()
            }
        }
        .onAppear {
            // Capture the container from environment
            if activeContainer == nil {
                activeContainer = diContainer
                AppLogger.info("ContentView: Captured container ID: \(ObjectIdentifier(diContainer))", category: .app)
            }
            
            if appState == nil {
                Task {
                    await createAppState()
                }
            }
        }
        .accessibilityIdentifier("app.content")
    }
    
    private func createAppState() async {
        do {
            // Use shared container during initialization
            let containerToUse = DIContainer.shared ?? diContainer
            AppLogger.info("ContentView.createAppState: Using container ID: \(ObjectIdentifier(containerToUse))", category: .app)
            let apiKeyManager = try await containerToUse.resolve(APIKeyManagementProtocol.self)
            appState = AppState(
                modelContext: modelContext,
                apiKeyManager: apiKeyManager
            )
        } catch {
            AppLogger.error("ContentView.createAppState: Failed to resolve APIKeyManager", error: error, category: .app)
            // Create without API key manager for error case
            appState = AppState(modelContext: modelContext)
        }
    }
    
    private func recreateContainer() async {
        // This will be called from the parent app to recreate the container
        // For now, just reload the app state
        isRecreatingContainer = false
        await appState?.loadUserState()
    }
}

// MARK: - Supporting Views
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.accentColor)

            Text("Loading AirFit...")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
        .accessibilityIdentifier("app.loading")
    }
}

private struct WelcomeView: View {
    let appState: AppState

    var body: some View {
        VStack(spacing: AppSpacing.xLarge) {
            Spacer()

            VStack(spacing: AppSpacing.large) {
                Text("Welcome to")
                    .font(AppFonts.title)
                    .foregroundColor(AppColors.textSecondary)

                Text("AirFit")
                    .font(AppFonts.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentColor)

                Text("Your personalized AI fitness coach")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                Task {
                    do {
                        try await appState.createNewUser()
                    } catch {
                        AppLogger.error("Failed to create user", error: error, category: .app)
                    }
                }
            } label: {
                Text("Get Started")
                    .font(AppFonts.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentColor)
                    .cornerRadius(AppConstants.Layout.defaultCornerRadius)
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
        .accessibilityIdentifier("app.welcome")
    }
}

private struct ErrorView: View {
    let error: Error?
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.errorColor)

            Text("Something went wrong")
                .font(AppFonts.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)

            if let error = error {
                Text(error.localizedDescription)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Try Again", action: onRetry)
                .font(AppFonts.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textOnAccent)
                .padding(.horizontal, AppSpacing.large)
                .padding(.vertical, AppSpacing.medium)
                .background(AppColors.accentColor)
                .cornerRadius(AppConstants.Layout.defaultCornerRadius)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundPrimary)
        .accessibilityIdentifier("app.error")
    }
}

// MARK: - Previews
#Preview("Loading") {
    LoadingView()
}

#Preview("Welcome") {
    WelcomeView(appState: AppState(modelContext: ModelContext(ModelContainer.preview)))
}

#Preview("Dashboard") {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
