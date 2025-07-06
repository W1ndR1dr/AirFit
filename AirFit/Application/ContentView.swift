import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.diContainer)
    private var diContainer
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject
    private var gradientManager: GradientManager

    @State private var appState: AppState?
    @State private var isRecreatingContainer = false

    // Store the container we receive to ensure consistency
    @State private var activeContainer: DIContainer?

    var body: some View {
        BaseScreen {
            if isRecreatingContainer {
                LoadingView()
            } else if let appState = appState {
                if appState.isLoading {
                    LoadingView()
                } else if appState.shouldShowAPISetup {
                    APISetupView(apiKeyManager: appState.apiKeyManager) {
                        // Completion handler - only called when user explicitly continues
                        appState.completeAPISetup()
                        // Need to recreate the DI container with the new API key
                        isRecreatingContainer = true
                        Task {
                            await recreateContainer()
                        }
                    }
                } else if appState.shouldCreateUser {
                    WelcomeView(appState: appState)
                } else if appState.shouldShowOnboarding {
                    // Use the new 3-file onboarding flow from the manifesto
                    OnboardingContainerView()
                        .withDIContainer(activeContainer ?? diContainer)
                        .onAppear {
                            AppLogger.info("ContentView: Using manifesto onboarding with container ID: \(ObjectIdentifier(activeContainer ?? diContainer))", category: .app)
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                            Task {
                                await appState.completeOnboarding()
                            }
                        }
                } else if appState.shouldShowDashboard, let user = appState.currentUser {
                    MainTabView(user: user)
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
            AppLogger.info("ContentView.onAppear: Called", category: .app)
            // Capture the container from environment
            if activeContainer == nil {
                activeContainer = diContainer
                AppLogger.info("ContentView: Captured container ID: \(ObjectIdentifier(diContainer))", category: .app)
            }

            if appState == nil {
                AppLogger.info("ContentView.onAppear: appState is nil, creating it", category: .app)
                Task {
                    await createAppState()
                }
            } else {
                AppLogger.info("ContentView.onAppear: appState already exists", category: .app)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appResetForTesting)) { _ in
            AppLogger.info("ContentView: Received app reset notification", category: .app)
            // Reset app state and reload
            appState = nil
            Task {
                await createAppState()
            }
        }
        .accessibilityIdentifier("app.content")
    }

    private func createAppState() async {
        AppLogger.info("ContentView.createAppState: Starting", category: .app)
        do {
            // Use the container from environment
            let containerToUse = activeContainer ?? diContainer
            AppLogger.info("ContentView.createAppState: Using container ID: \(ObjectIdentifier(containerToUse))", category: .app)

            AppLogger.info("ContentView.createAppState: Resolving dependencies", category: .app)
            // Resolve dependencies in parallel for better performance
            async let apiKeyManager = containerToUse.resolve(APIKeyManagementProtocol.self)
            async let healthKitAuthManager = containerToUse.resolve(HealthKitAuthManager.self)

            appState = try await AppState(
                modelContext: modelContext,
                healthKitAuthManager: healthKitAuthManager,
                apiKeyManager: apiKeyManager
            )
            AppLogger.info("ContentView.createAppState: AppState created successfully", category: .app)
        } catch {
            AppLogger.error("ContentView.createAppState: Failed to resolve APIKeyManager", error: error, category: .app)
            // Create with minimal dependencies for error case
            // This is not ideal but allows the app to at least show an error screen
            AppLogger.warning("Creating AppState without full dependencies due to error", category: .app)
            AppLogger.info("ContentView.createAppState: Created AppState without APIKeyManager", category: .app)
        }
    }

    private func recreateContainer() async {
        // Recreate the container with updated API keys
        AppLogger.info("ContentView: Recreating DI container after API setup", category: .app)

        do {
            // Get the model container from current environment
            let modelContainer = try await diContainer.resolve(ModelContainer.self)

            // Create new container with API keys now available
            let newContainer = DIBootstrapper.createAppContainer(modelContainer: modelContainer)
            
            // Validate that AI services are properly initialized in the new container
            do {
                let aiService = try await newContainer.resolve(AIServiceProtocol.self)
                AppLogger.info("ContentView: Successfully resolved AI service in new container", category: .app)
            } catch {
                AppLogger.error("ContentView: Failed to resolve AI service in new container", error: error, category: .app)
                // Continue anyway - the error will be caught during onboarding
            }

            // Update our local reference
            activeContainer = newContainer

            // Recreate AppState with new container
            await createAppState()
        } catch {
            AppLogger.error("ContentView: Failed to recreate container", error: error, category: .app)
            // The error will be caught when trying to load onboarding
        }

        isRecreatingContainer = false
        await appState?.loadUserState()
    }
}

// MARK: - Supporting Views
private struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Custom gradient progress indicator
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 48, height: 48)

                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: gradientManager.active.colors(for: colorScheme)[0]))
            }

            HStack(spacing: 0) {
                Text("Loading ")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary)

                Text("AirFit")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("app.loading")
    }
}

private struct WelcomeView: View {
    let appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.lg) {
                Text("Welcome to")
                    .font(.system(size: 24, weight: .ultraLight, design: .rounded))
                    .foregroundStyle(.secondary)
                    .cascadeIn()

                // Use CascadeText for the hero title
                CascadeText("AirFit")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)

                Text("Your personalized AI fitness coach")
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .cascadeIn(delay: 0.2)
                    .padding(.horizontal, 48)
            }

            Spacer()

            // Beautiful gradient button
            Button {
                HapticService.impact(.light)
                Task {
                    do {
                        try await appState.createNewUser()
                    } catch {
                        AppLogger.error("Failed to create user", error: error, category: .app)
                    }
                }
            } label: {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("app.welcome")
    }
}

private struct ErrorView: View {
    let error: Error?
    let onRetry: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // Gradient error icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Something went wrong")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)

            if let error = error {
                Text(error.localizedDescription)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            Button {
                HapticService.impact(.light)
                onRetry()
            } label: {
                Text("Try Again")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: gradientManager.active.colors(for: colorScheme)[0].opacity(0.3), radius: 12, y: 4)
            }
            .padding(.top, AppSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("app.error")
    }
}

// MARK: - Previews
#Preview("Loading") {
    LoadingView()
}

#Preview("Welcome") {
    // Create a mock AppState for preview
    let context = ModelContext(ModelContainer.preview)
    let mockHealthKitManager = HealthKitManager()
    let mockAuthManager = HealthKitAuthManager(healthKitManager: mockHealthKitManager)
    return WelcomeView(appState: AppState(
        modelContext: context,
        healthKitAuthManager: mockAuthManager
    ))
}

#Preview("Dashboard") {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
