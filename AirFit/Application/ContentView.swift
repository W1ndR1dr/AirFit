import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @State private var appState: AppState?

    var body: some View {
        Group {
            if let appState = appState {
                if appState.isLoading {
                    LoadingView()
                } else if appState.shouldCreateUser {
                    WelcomeView(appState: appState)
                } else if appState.shouldShowOnboarding {
                    OnboardingFlowView(
                        aiService: MockAIService(),
                        onboardingService: OnboardingService(modelContext: modelContext),
                        onCompletion: {
                            Task {
                                await appState.completeOnboarding()
                            }
                        }
                    )
                } else if appState.shouldShowDashboard {
                    DashboardView()
                } else {
                    ErrorView(error: appState.error, onRetry: {
                        appState.clearError()
                        Task {
                            await appState.loadUserState()
                        }
                    })
                }
            } else {
                LoadingView()
            }
        }
        .onAppear {
            if appState == nil {
                appState = AppState(modelContext: modelContext)
            }
        }
        .accessibilityIdentifier("app.content")
    }
}

// MARK: - Supporting Views
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: AppConstants.Spacing.large) {
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
        VStack(spacing: AppConstants.Spacing.xlarge) {
            Spacer()

            VStack(spacing: AppConstants.Spacing.large) {
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

            Button(action: {
                Task {
                    try await appState.createNewUser()
                }
            }) {
                Text("Get Started")
                    .font(AppFonts.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentColor)
                    .cornerRadius(AppConstants.CornerRadius.medium)
            }
            .padding(.horizontal, AppConstants.Spacing.large)
            .padding(.bottom, AppConstants.Spacing.xlarge)
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
        VStack(spacing: AppConstants.Spacing.large) {
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
                .padding(.horizontal, AppConstants.Spacing.large)
                .padding(.vertical, AppConstants.Spacing.medium)
                .background(AppColors.accentColor)
                .cornerRadius(AppConstants.CornerRadius.medium)
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
