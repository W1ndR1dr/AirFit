import SwiftUI
import Observation

@MainActor
@Observable
final class DashboardViewModel: ErrorHandling {
    // MARK: - State Properties
    private(set) var isLoading = true
    var error: AppError?
    var isShowingError = false

    // Morning Greeting
    private(set) var morningGreeting = "Good morning!"
    private(set) var greetingContext: GreetingContext?

    // Energy Logging
    private(set) var currentEnergyLevel: Int?
    private(set) var isLoggingEnergy = false

    // Nutrition Data
    private(set) var nutritionSummary = NutritionSummary()
    private(set) var nutritionTargets = NutritionTargets.default

    // Health Insights
    private(set) var recoveryScore: RecoveryScore?
    private(set) var performanceInsight: PerformanceInsight?

    // Quick Actions
    private(set) var suggestedActions: [QuickAction] = []

    // AI Dashboard Content
    private(set) var aiDashboardContent: AIDashboardContent?

    // MARK: - Dependencies
    private let user: User
    private let dashboardRepository: DashboardRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let aiCoachService: AICoachServiceProtocol
    private let nutritionService: DashboardNutritionServiceProtocol

    // MARK: - Private State
    private var refreshTask: Task<Void, Never>?
    private var lastGreetingDate: Date?
    #if DEBUG
    private var forceGreetingRefresh = false
    #endif

    // MARK: - Initialization
    init(
        user: User,
        dashboardRepository: DashboardRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol,
        aiCoachService: AICoachServiceProtocol,
        nutritionService: DashboardNutritionServiceProtocol
    ) {
        self.user = user
        self.dashboardRepository = dashboardRepository
        self.healthKitService = healthKitService
        self.aiCoachService = aiCoachService
        self.nutritionService = nutritionService
    }

    // MARK: - Public Methods
    func onAppear() {
        refreshDashboard()
    }

    func onDisappear() {
        refreshTask?.cancel()
    }

    func refreshDashboard() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.loadDashboardData()
        }
    }

    func loadDashboardData() async {
        await _loadDashboardData()
    }

    func logEnergyLevel(_ level: Int) async {
        guard !isLoggingEnergy else { return }

        isLoggingEnergy = true
        defer { isLoggingEnergy = false }

        do {
            // Use repository to log energy level
            _ = try dashboardRepository.logEnergyLevel(level, for: user)

            // Update local state
            currentEnergyLevel = level

            // Haptic feedback
            HapticService.play(.dataUpdated)
            // Log analytics
            AppLogger.info("Energy level logged: \(level)", category: .data)

        } catch {
            handleError(error)
        }
    }

    // MARK: - Test Support
    #if DEBUG
    func resetGreetingState() {
        forceGreetingRefresh = true
    }
    #endif

    // MARK: - Private Methods
    private func _loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        // Load AI dashboard content first
        await loadAIDashboardContent()

        // Load other data in parallel for backward compatibility
        async let energyTask: Void = loadEnergyLevel()
        async let nutritionTask: Void = loadNutritionData()
        async let healthTask: Void = loadHealthInsights()

        // Wait for all parallel tasks to complete
        _ = await (energyTask, nutritionTask, healthTask)

        // Load quick actions after nutrition data is available (has dependency)
        await loadQuickActions(for: Date())
    }

    private func loadAIDashboardContent() async {
        do {
            aiDashboardContent = try await aiCoachService.generateDashboardContent(for: user)
            // Also update morning greeting from the content if available
            if let content = aiDashboardContent {
                morningGreeting = content.primaryInsight
            }
        } catch {
            AppLogger.error("Failed to generate AI dashboard content", error: error, category: .ai)
            // Fall back to basic greeting
            morningGreeting = generateFallbackGreeting()
        }
    }

    private func loadMorningGreeting() async {
        #if DEBUG
        // Always execute during testing - no guard
        #else
        // Always refresh if no previous greeting date, or if it's a new day
        let shouldRefresh = lastGreetingDate.map { date in
            !Calendar.current.isDateInToday(date)
        } ?? true

        guard shouldRefresh else { return }
        #endif

        do {
            let healthContext = try await healthKitService.getCurrentContext()
            let context = GreetingContext(
                userName: user.name ?? "there",
                sleepHours: healthContext.lastNightSleepDurationHours,
                sleepQuality: healthContext.sleepQuality.map { String($0) },
                weather: healthContext.currentWeatherCondition,
                temperature: healthContext.currentTemperatureCelsius,
                energyYesterday: healthContext.yesterdayEnergyLevel.map { String($0) },
                dayOfWeek: Date().formatted(.dateTime.weekday(.wide))
            )

            let greeting = try await aiCoachService.generateMorningGreeting(
                for: user,
                context: context
            )

            self.morningGreeting = greeting
            self.greetingContext = context
            self.lastGreetingDate = Date()

        } catch {
            self.morningGreeting = generateFallbackGreeting()
            AppLogger.error("Failed to generate AI greeting", error: error, category: .ai)
        }
    }

    private func loadEnergyLevel() async {
        do {
            currentEnergyLevel = try dashboardRepository.getCurrentEnergyLevel(for: user)
        } catch {
            AppLogger.error("Failed to load energy level", error: error, category: .data)
        }
    }

    private func loadNutritionData() async {
        do {
            let summary = try await nutritionService.getTodaysSummary(for: user)
            self.nutritionSummary = summary

            // Extract targets from summary
            self.nutritionTargets = NutritionTargets(
                calories: summary.caloriesTarget,
                protein: summary.proteinTarget,
                carbs: summary.carbsTarget,
                fat: summary.fatTarget,
                fiber: summary.fiberTarget
            )

        } catch {
            AppLogger.error("Failed to load nutrition data", error: error, category: .data)
        }
    }

    private func loadHealthInsights() async {
        do {
            let recovery = try await healthKitService.calculateRecoveryScore(for: user)
            self.recoveryScore = recovery

            let performance = try await healthKitService.getPerformanceInsight(
                for: user,
                days: 7
            )
            self.performanceInsight = performance

        } catch {
            AppLogger.error("Failed to load health insights", error: error, category: .health)
        }
    }

    func loadQuickActions(for date: Date = Date()) async {
        var actions: [QuickAction] = []

        let hour = Calendar.current.component(.hour, from: date)
        // Add lunch logging if it's lunch time
        if (11...13).contains(hour) {
            actions.append(QuickAction(
                title: "Log Lunch",
                subtitle: "Track your midday meal",
                systemImage: "sun.max.fill",
                color: "orange",
                action: .logMeal(type: .lunch)
            ))
        }

        if !hasWorkoutToday() {
            actions.append(QuickAction(
                title: "Start Workout",
                subtitle: "Begin your training session",
                systemImage: "figure.strengthtraining.traditional",
                color: "blue",
                action: .startWorkout
            ))
        }


        self.suggestedActions = actions
    }

    private func generateFallbackGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = user.name ?? "there"

        switch hour {
        case 5..<12:
            return "Good morning, \(name)! Ready to make today count?"
        case 12..<17:
            return "Good afternoon, \(name)! How's your day going?"
        case 17..<22:
            return "Good evening, \(name)! Time to wind down."
        default:
            return "Hello, \(name)! Still up?"
        }
    }

    private func hasWorkoutToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return user.workouts.contains { workout in
            if let completed = workout.completedDate {
                return Calendar.current.isDate(completed, inSameDayAs: today)
            }
            return false
        }
    }
}
