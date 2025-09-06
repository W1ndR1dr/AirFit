import SwiftUI
import SwiftData

/// Dashboard content view that displays the actual dashboard UI
struct DashboardContent: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.colorScheme)
    private var colorScheme
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.diContainer) private var diContainer

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
                .navigationBarHidden(true)
                .toolbar(.hidden, for: .navigationBar)
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

                TextLoadingView(message: "Loading dashboard", style: .standard)
            }

            Text("Loading dashboard…")
                .font(AppFonts.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("dashboard.loading")
    }

    private func errorView(_ error: Error) -> some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(error.localizedDescription)
                .font(AppFonts.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                HapticService.impact(.light)
                viewModel.refreshDashboard()
            } label: {
                Text("Retry")
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
            .padding(.horizontal, AppSpacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("dashboard.error")
    }

    private var dashboardContent: some View {
        VStack(alignment: .leading, spacing: 40) {
            // Primary AI insight - directly on gradient
            if let content = viewModel.aiDashboardContent {
                CascadeText(content.primaryInsight)
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .lineSpacing(4)

                // Nutrition rings if we have data
                if let nutrition = content.nutritionData {
                    NutritionRingsView(nutrition: nutrition)
                        .padding(.vertical, 8)
                }

                // Muscle volume if user trains
                if let volumes = content.muscleGroupVolumes, !volumes.isEmpty {
                    MuscleVolumeView(volumes: volumes)
                        .padding(.vertical, 8)
                }

                // AI guidance
                if let guidance = content.guidance {
                    Text(guidance)
                        .font(.system(size: 20, weight: .light))
                        .opacity(0.9)
                        .lineSpacing(2)
                }

                // Celebration
                if let celebration = content.celebration {
                    Text(celebration)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.top, 8)
                }
            } else {
                // Fallback while loading
                CascadeText(viewModel.morningGreeting)
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.bottom, AppSpacing.xl)
        .animation(MotionToken.standardSpring, value: viewModel.aiDashboardContent)
    }

    @ViewBuilder
    private func destinationView(for destination: DashboardDestination) -> some View {
        switch destination {
        case .nutritionDetail:
            NutritionDetailView(user: user)
        case .workoutHistory:
            // Create WorkoutHistoryView with proper dependencies
            WorkoutHistoryViewWrapper(user: user, container: diContainer)
        case .recoveryDetail:
            RecoveryDetailView(user: user, container: diContainer)
        case .settings:
            SettingsView(user: user)
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        switch action.action {
        case .logMeal:
            // Navigate to nutrition/food logging
            coordinator.navigate(to: .nutritionDetail)
        case .startWorkout:
            // Navigate to workout view
            coordinator.navigate(to: .workoutHistory)
        case .checkIn:
            // Navigate to recovery/check-in view
            coordinator.navigate(to: .recoveryDetail)
        }
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

// MARK: - Dashboard Destinations
enum DashboardDestination: Hashable {
    case nutritionDetail
    case workoutHistory
    case recoveryDetail
    case settings
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

    func generateDashboardContent(for user: User) async throws -> AIDashboardContent {
        AIDashboardContent(
            primaryInsight: "Welcome back! Ready to make today count?",
            nutritionData: nil,
            muscleGroupVolumes: nil,
            guidance: nil,
            celebration: nil
        )
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
                TextLoadingView.preparingData()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeDashboardViewModel(user: user)
                    }
            }
        }
    }
}

// MARK: - WorkoutHistoryView Wrapper
struct WorkoutHistoryViewWrapper: View {
    let user: User
    let container: DIContainer

    @State private var muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol?
    @State private var strengthProgressionService: StrengthProgressionServiceProtocol?
    @State private var isLoading = true
    @State private var loadError = false

    var body: some View {
        ZStack {
            if isLoading {
                TextLoadingView(message: "Loading workout analytics", style: .standard)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task {
                        do {
                            // Resolve services asynchronously
                            async let volumeService = container.resolve(MuscleGroupVolumeServiceProtocol.self)
                            async let strengthService = container.resolve(StrengthProgressionServiceProtocol.self)

                            let (volume, strength) = try await (volumeService, strengthService)

                            muscleGroupVolumeService = volume
                            strengthProgressionService = strength
                            isLoading = false
                        } catch {
                            AppLogger.error("Failed to resolve workout services", error: error, category: .services)
                            loadError = true
                            isLoading = false
                        }
                    }
            } else if loadError || muscleGroupVolumeService == nil || strengthProgressionService == nil {
                VStack(spacing: AppSpacing.lg) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Unable to load workout history")
                        .font(AppFonts.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                WorkoutHistoryView(
                    user: user,
                    muscleGroupVolumeService: muscleGroupVolumeService!,
                    strengthProgressionService: strengthProgressionService!
                )
            }
        }
    }
}

// MARK: - Placeholder Quick Actions Card
