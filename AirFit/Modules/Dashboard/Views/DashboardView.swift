import SwiftUI
import SwiftData

/// Dashboard content view that displays the actual dashboard UI
struct DashboardContent: View {
    @Environment(\.modelContext)
    private var modelContext
    @EnvironmentObject private var gradientManager: GradientManager

    let viewModel: DashboardViewModel

    @State private var coordinator = DashboardCoordinator()

    @State private var hasAppeared = false
    
    let user: User

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 180), spacing: AppSpacing.sm)
    ]

    var body: some View {
        BaseScreen {
            NavigationStack(path: $coordinator.path) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Beautiful cascade title
                        CascadeText("Daily Dashboard")
                            .font(.system(size: 34, weight: .thin, design: .rounded))
                            .padding(.horizontal, AppSpacing.screenPadding)
                            .padding(.top, AppSpacing.md)
                            .padding(.bottom, AppSpacing.lg)
                        
                        if viewModel.isLoading {
                            loadingView
                        } else if let error = viewModel.error {
                            errorView(error)
                        } else {
                            dashboardContent
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable { viewModel.refreshDashboard() }
                .navigationDestination(for: DashboardDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
        }
        .task {
            guard !hasAppeared else { return }
            hasAppeared = true
            viewModel.onAppear()
        }
        .onDisappear { viewModel.onDisappear() }
        .accessibilityIdentifier("dashboard.main")
    }

    // MARK: - Subviews
    private var loadingView: some View {
        VStack(spacing: AppSpacing.large) {
            ProgressView()
                .controlSize(.large)
                .tint(AppColors.accentColor)

            Text("Loading dashboard…")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("dashboard.loading")
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(AppColors.errorColor)

            Text(error.localizedDescription)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            StandardButton("Retry", style: .primary) { viewModel.refreshDashboard() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("dashboard.error")
    }

    private var dashboardContent: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            GlassCard {
                MorningGreetingCard(
                    greeting: viewModel.morningGreeting,
                    context: viewModel.greetingContext,
                    currentEnergy: viewModel.currentEnergyLevel,
                    onEnergyLog: { level in
                        Task { await viewModel.logEnergyLevel(level) }
                    }
                )
            }
            
            GlassCard {
                NutritionCard(
                    summary: viewModel.nutritionSummary,
                    targets: viewModel.nutritionTargets
                )
            }
            
            GlassCard {
                RecoveryCard(recoveryScore: viewModel.recoveryScore)
            }
            
            GlassCard {
                PerformanceCard(insight: viewModel.performanceInsight)
            }
            
            GlassCard {
                QuickActionsCard(
                    suggestedActions: viewModel.suggestedActions,
                    onActionTap: handleQuickAction
                )
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.bottom, AppSpacing.xl)
        .animation(MotionToken.standardSpring, value: viewModel.morningGreeting)
    }

    @ViewBuilder
    private func destinationView(for destination: DashboardDestination) -> some View {
        switch destination {
        case .placeholder:
            Text("Destination")
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        coordinator.navigate(to: .nutritionDetail)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: User.self) // swiftlint:disable:this force_try
    let user = User(name: "Preview")
    container.mainContext.insert(user)
    
    return DashboardView(user: user)
        .withDIContainer(DIContainer()) // Empty container for preview
        .modelContainer(container)
}

// MARK: - Placeholder Destination
enum DashboardDestination: Hashable {
    case placeholder
}

// MARK: - Placeholder Services
actor PlaceholderHealthKitService: HealthKitServiceProtocol {
    func getCurrentContext() async throws -> HealthContext {
        HealthContext(
            lastNightSleepDurationHours: nil,
            sleepQuality: nil,
            currentWeatherCondition: nil,
            currentTemperatureCelsius: nil,
            yesterdayEnergyLevel: nil,
            currentHeartRate: nil,
            hrv: nil,
            steps: nil
        )
    }

    func calculateRecoveryScore(for user: User) async throws -> RecoveryScore {
        RecoveryScore(score: 0, status: .moderate, factors: [])
    }

    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
        PerformanceInsight(trend: .stable, metric: "", value: "", insight: "")
    }
}

actor PlaceholderAICoachService: AICoachServiceProtocol {
    func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String {
        "Good morning, \(user.name ?? "there")!"
    }
}

actor PlaceholderNutritionService: DashboardNutritionServiceProtocol {
    func getTodaysSummary(for user: User) async throws -> NutritionSummary {
        NutritionSummary()
    }

    func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets {
        .default
    }
}

// MARK: - Main Dashboard View with DI
struct DashboardView: View {
    let user: User
    @State private var viewModel: DashboardViewModel?
    @Environment(\.diContainer) private var container
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                DashboardContent(viewModel: viewModel, user: user)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeDashboardViewModel(user: user)
                    }
            }
        }
    }
}

// MARK: - Placeholder Quick Actions Card
