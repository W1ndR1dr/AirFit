import SwiftUI
import SwiftData
import Observation

// MARK: - Workout View with DI
struct WorkoutView: View {
    let user: User
    @State private var viewModel: WorkoutViewModel?
    @Environment(\.diContainer) private var container

    var body: some View {
        Group {
            if let viewModel = viewModel {
                WorkoutListView(viewModel: viewModel)
            } else {
                ProgressView()
                    .task {
                        let factory = DIViewModelFactory(container: container)
                        viewModel = try? await factory.makeWorkoutViewModel(user: user)
                    }
            }
        }
    }
}

/// Main list view showing weekly workout summary, recent workouts, and quick actions.
struct WorkoutListView: View {
    // MARK: - State
    @State private var viewModel: WorkoutViewModel
    @State private var coordinator: WorkoutCoordinator
    @State private var searchText = ""
    @State private var hasLoaded = false
    @State private var animateIn = false
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(NavigationState.self) private var navigationState
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initializers
    init(viewModel: WorkoutViewModel, coordinator: WorkoutCoordinator = WorkoutCoordinator()) {
        _viewModel = State(initialValue: viewModel)
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            BaseScreen {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header
                        CascadeText("Workouts")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : -20)

                        WeeklySummaryCard(stats: viewModel.weeklyStats)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.sm)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)

                        quickActionsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)

                        if filteredWorkouts.isEmpty {
                            emptyStateView
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
                        } else {
                            recentWorkoutsSection
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)
                        }
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .refreshable {
                HapticService.impact(.light)
                await viewModel.loadWorkouts()
            }
            .navigationDestination(for: WorkoutCoordinator.WorkoutDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(item: $coordinator.presentedSheet) { sheet in
                sheetView(for: sheet)
                    .environmentObject(gradientManager)
            }
            .onAppear {
                withAnimation(MotionToken.standardSpring) {
                    animateIn = true
                }
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await viewModel.loadWorkouts()
        }
    }

    // MARK: - Filtered Workouts
    private var filteredWorkouts: [Workout] {
        guard !searchText.isEmpty else { return viewModel.workouts }
        return viewModel.workouts.filter { workout in
            workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.workoutTypeEnum?.displayName.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    // MARK: - Sections
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                CascadeText("Quick Actions")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.md) {
                QuickActionCard(title: "Start Workout", icon: "mic.fill", index: 0) {
                    HapticService.impact(.medium)
                    // Navigate to chat with workout context
                    coordinator.showSheet(.voiceWorkoutInput)
                }
                .environmentObject(gradientManager)

                QuickActionCard(title: "Exercise Library", icon: "books.vertical.fill", index: 1) {
                    HapticService.impact(.medium)
                    coordinator.navigateTo(.exerciseLibrary)
                }
                .environmentObject(gradientManager)
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                CascadeText("Recent Workouts")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Button(action: {
                    HapticService.impact(.light)
                    coordinator.navigateTo(.allWorkouts)
                }, label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                })
            }
            .padding(.horizontal, AppSpacing.md)

            ForEach(Array(filteredWorkouts.prefix(5).enumerated()), id: \.element.id) { index, workout in
                WorkoutRow(workout: workout, index: index) {
                    HapticService.impact(.light)
                    coordinator.navigateTo(.workoutDetail(workout))
                }
                .environmentObject(gradientManager)
                .padding(.horizontal, AppSpacing.md)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(MotionToken.standardSpring.delay(0.4 + Double(index) * 0.1), value: animateIn)
            }
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "mic.fill",
            title: "No Workouts Yet",
            message: "Tell me what kind of workout you want to do",
            action: { coordinator.showSheet(.voiceWorkoutInput) },
            actionTitle: "Start Workout"
        )
    }

    // MARK: - Navigation Destinations
    @ViewBuilder
    private func destinationView(for destination: WorkoutCoordinator.WorkoutDestination) -> some View {
        switch destination {
        case .workoutDetail(let workout):
            WorkoutDetailView(workout: workout, viewModel: viewModel)
        case .exerciseLibrary:
            ExerciseLibraryView()
        case .allWorkouts:
            Text("All Workouts")
        case .statistics:
            Text("Statistics")
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: WorkoutCoordinator.WorkoutSheet) -> some View {
        switch sheet {
        case .voiceWorkoutInput:
            // For now, show a placeholder that directs to chat
            // In a real implementation, this would navigate to the chat interface
            VoiceWorkoutInputPlaceholder(coordinator: coordinator)
                .environmentObject(gradientManager)
        case .newTemplate:
            Text("New Template")
        case .exerciseDetail(let exercise):
            Text(exercise.name)
        }
    }
}

// MARK: - Supporting Views
private struct WeeklySummaryCard: View {
    let stats: WeeklyWorkoutStats
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateStats = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        CascadeText("This Week")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }

                    Spacer()

                    NavigationLink(value: WorkoutCoordinator.WorkoutDestination.statistics) {
                        HStack(spacing: 4) {
                            Text("View Stats")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradientManager.active.colors(for: colorScheme),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }

                // Gradient divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                gradientManager.active.colors(for: colorScheme).first?.opacity(0.2) ?? Color.clear,
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, AppSpacing.xs)

                HStack(spacing: AppSpacing.lg) {
                    StatItem(
                        value: "\(stats.totalWorkouts)",
                        label: "Workouts",
                        icon: "figure.strengthtraining.traditional",
                        index: 0,
                        animate: animateStats
                    )
                    StatItem(
                        value: stats.totalDuration.formattedDuration(),
                        label: "Duration",
                        icon: "timer",
                        index: 1,
                        animate: animateStats
                    )
                    StatItem(
                        value: "\(Int(stats.totalCalories))",
                        label: "Calories",
                        icon: "flame.fill",
                        index: 2,
                        animate: animateStats
                    )
                }
            }
            .padding(AppSpacing.md)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.2)) {
                animateStats = true
            }
        }
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let index: Int
    let animate: Bool
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        switch index {
        case 0: return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        case 1: return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case 2: return [Color(hex: "#F8961E"), Color(hex: "#F3722C")]
        default: return gradientManager.active.colors(for: colorScheme)
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animate ? 1 : 0.8)
                    .opacity(animate ? 1 : 0)
                    .animation(MotionToken.standardSpring.delay(Double(index) * 0.1), value: animate)

                GradientNumber(value: Double(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 10)
                    .animation(MotionToken.standardSpring.delay(Double(index) * 0.1 + 0.1), value: animate)
            }

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .opacity(animate ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(Double(index) * 0.1 + 0.2), value: animate)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WorkoutRow: View {
    let workout: Workout
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var dateText: String {
        (workout.completedDate ?? workout.plannedDate ?? Date())
            .formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        Button(action: action) {
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(workout.workoutTypeEnum?.displayName ?? workout.workoutType)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.primary)
                        }

                        Text(dateText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.secondary.opacity(0.8))

                        HStack(spacing: AppSpacing.md) {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 11))
                                Text(workout.formattedDuration ?? "0m")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color.secondary.opacity(0.7))

                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 11))
                                Text("\(workout.exercises.count) exercises")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color.secondary.opacity(0.7))

                            if let calories = workout.caloriesBurned, calories > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 11))
                                    Text("\(Int(calories)) cal")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#F8961E"), Color(hex: "#F3722C")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                }
                .padding(AppSpacing.sm)
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(MotionToken.microAnimation, value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.microAnimation) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

private struct QuickActionCard: View {
    let title: String
    let icon: String
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var animateIn = false

    private var gradientColors: [Color] {
        switch icon {
        case "play.fill": return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case "books.vertical.fill": return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        default: return gradientManager.active.colors(for: colorScheme)
        }
    }

    var body: some View {
        Button(action: action) {
            GlassCard {
                VStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors.map { $0.opacity(0.15) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .blur(radius: 8)

                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .opacity(animateIn ? 1 : 0)
                    }

                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.primary)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                }
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(MotionToken.microAnimation, value: isPressed)
            .onAppear {
                withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.15)) {
                    animateIn = true
                }
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.microAnimation) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Voice Workout Input Placeholder
struct VoiceWorkoutInputPlaceholder: View {
    let coordinator: WorkoutCoordinator
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationState.self) private var navigationState
    @State private var animateIn = false

    var body: some View {
        NavigationStack {
            BaseScreen {
                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    // Icon with ripple effect
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(animateIn ? 1.0 : 0.8)
                            .opacity(animateIn ? 0.2 : 0)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: animateIn
                            )

                        Image(systemName: "mic.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(animateIn ? 1.0 : 0.9)
                    }
                    .padding(.bottom, AppSpacing.lg)

                    CascadeText("Chat with Your AI Coach")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("Type or speak your workout request:")
                        .font(.system(size: 18, weight: .light, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        WorkoutExampleText("\"I want to do a 30-minute upper body workout\"")
                        WorkoutExampleText("\"Let's do some cardio for 20 minutes\"")
                        WorkoutExampleText("\"I'm feeling sore, something light\"")
                        WorkoutExampleText("\"Surprise me with a full body circuit\"")
                    }
                    .padding(AppSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer()

                    Text("Go to Chat")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
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
                        .padding(.horizontal, AppSpacing.lg)
                        .onTapGesture {
                            HapticService.impact(.medium)
                            // Navigate to chat with workout context
                            navigationState.showChat(with: "I'd like you to create a personalized workout for me based on my current fitness level and recent activity.")
                            dismiss()
                        }

                    Text("The AI will create a personalized workout based on your fitness level, recent activity, and current energy.")
                        .font(.system(size: 14, weight: .light, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticService.impact(.light)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
}

struct WorkoutExampleText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack {
            Image(systemName: "quote.opening")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.system(size: 15, weight: .light, design: .rounded))
                .foregroundStyle(.primary.opacity(0.8))
                .italic()

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    let container = ModelContainer.preview
    let context = container.mainContext
    let user = try! context.fetch(FetchDescriptor<User>()).first! // swiftlint:disable:this force_try
    let vm = WorkoutViewModel(
        modelContext: context,
        user: user,
        coachEngine: WorkoutMockCoachEngine(),
        healthKitManager: PreviewHealthKitManager(),
        exerciseDatabase: ExerciseDatabase(container: container),
        workoutSyncService: WorkoutSyncService()
    )
    WorkoutListView(viewModel: vm)
        .modelContainer(container)
}

@MainActor
final class PreviewHealthKitManager: HealthKitManaging {
    var authorizationStatus: HealthKitManager.AuthorizationStatus = .authorized
    func refreshAuthorizationStatus() {}
    func requestAuthorization() async throws {}
    func fetchTodayActivityMetrics() async throws -> ActivityMetrics { ActivityMetrics() }
    func fetchHeartHealthMetrics() async throws -> HeartHealthMetrics { HeartHealthMetrics() }
    func fetchLatestBodyMetrics() async throws -> BodyMetrics { BodyMetrics() }
    func fetchLastNightSleep() async throws -> SleepAnalysis.SleepSession? { nil }

    // New HealthKit integration methods
    func getWorkoutData(from startDate: Date, to endDate: Date) async -> [WorkoutData] { [] }
    func saveFoodEntry(_ entry: FoodEntry) async throws -> [String] { [] }
    func getNutritionData(for date: Date) async throws -> HealthKitNutritionSummary {
        HealthKitNutritionSummary(
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            date: date
        )
    }
    func saveWorkout(_ workout: Workout) async throws -> String { "preview-workout-id" }
    func deleteWorkout(healthKitID: String) async throws {}
    func fetchRecentWorkouts(limit: Int) async throws -> [WorkoutData] { [] }

    // Body metrics methods
    func saveBodyMass(weightKg: Double, date: Date) async throws {}
    func saveBodyFatPercentage(percentage: Double, date: Date) async throws {}
    func saveLeanBodyMass(massKg: Double, date: Date) async throws {}
    func fetchBodyMetricsHistory(from startDate: Date, to endDate: Date) async throws -> [BodyMetrics] { [] }
    func observeBodyMetrics(handler: @escaping () -> Void) async throws {}
    func removeObserver(_ observer: Any) {}
}

@MainActor
final class WorkoutMockCoachEngine: CoachEngineProtocol {
    func processUserMessage(_ text: String, for user: User) async {
        // Mock implementation - no-op
    }

    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String {
        "Mock post-workout analysis"
    }
}
