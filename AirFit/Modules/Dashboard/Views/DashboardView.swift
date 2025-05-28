import SwiftUI
import SwiftData

/// Main dashboard container view using adaptive grid layout.
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel
    @StateObject private var coordinator: DashboardCoordinator
    @State private var hasAppeared = false

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 180), spacing: AppSpacing.medium)
    ]

    // MARK: - Initializers
    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
        _coordinator = StateObject(wrappedValue: DashboardCoordinator())
    }

    init(user: User) {
        let context = DependencyContainer.shared.makeModelContext() ?? {
            do {
                let container = try ModelContainer(
                    for: User.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
                return ModelContext(container)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }()
        let vm = DashboardViewModel(
            user: user,
            modelContext: context,
            healthKitService: PlaceholderHealthKitService(),
            aiCoachService: PlaceholderAICoachService(),
            nutritionService: PlaceholderNutritionService()
        )
        _viewModel = State(initialValue: vm)
        _coordinator = StateObject(wrappedValue: DashboardCoordinator())
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ScrollView {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    dashboardContent
                }
            }
            .contentMargins(.horizontal, AppSpacing.medium)
            .navigationTitle("Dashboard")
            .refreshable { viewModel.refreshDashboard() }
            .navigationDestination(for: DashboardDestination.self) { destination in
                destinationView(for: destination)
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

            Button("Retry") { viewModel.refreshDashboard() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityIdentifier("dashboard.error")
    }

    private var dashboardContent: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.medium) {
            MorningGreetingCard(
                greeting: viewModel.morningGreeting,
                context: viewModel.greetingContext,
                currentEnergy: viewModel.currentEnergyLevel,
                onEnergyLog: { level in
                    Task { await viewModel.logEnergyLevel(level) }
                }
            )
            NutritionCard(
                summary: viewModel.nutritionSummary,
                targets: viewModel.nutritionTargets
            )
            RecoveryCard(recoveryScore: viewModel.recoveryScore)
            PerformanceCard(insight: viewModel.performanceInsight)
            QuickActionsCard(
                suggestedActions: viewModel.suggestedActions,
                onActionTap: handleQuickAction
            )
        }
        .animation(.bouncy, value: viewModel.morningGreeting)
    }

    @ViewBuilder
    private func destinationView(for destination: DashboardDestination) -> some View {
        switch destination {
        case .placeholder:
            Text("Destination")
        }
    }

    private func handleQuickAction(_ action: QuickAction) {
        coordinator.navigate(to: .placeholder)
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: User.self) // swiftlint:disable:this force_try
    let context = container.mainContext
    let user = User(name: "Preview")
    context.insert(user)
    let vm = DashboardViewModel(
        user: user,
        modelContext: context,
        healthKitService: PlaceholderHealthKitService(),
        aiCoachService: PlaceholderAICoachService(),
        nutritionService: PlaceholderNutritionService()
    )
    return DashboardView(viewModel: vm)
        .modelContainer(container)
}

// MARK: - Placeholder Coordinator & Destinations
@MainActor
final class DashboardCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func navigate(to destination: DashboardDestination) {
        path.append(destination)
    }

    func navigateBack() {
        if !path.isEmpty { path.removeLast() }
    }
}

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
        RecoveryScore(score: 0, components: [])
    }

    func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight {
        PerformanceInsight(summary: "", trend: .steady, keyMetric: "", value: 0)
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

// MARK: - Placeholder Quick Actions Card
