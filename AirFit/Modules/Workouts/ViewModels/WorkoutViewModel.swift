import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class WorkoutViewModel {
    // MARK: - State
    private(set) var workouts: [Workout] = []
    private(set) var weeklyStats = WeeklyWorkoutStats()
    private(set) var isLoading = false
    private(set) var aiWorkoutSummary: String?
    private(set) var isGeneratingAnalysis = false

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let user: User
    private let coachEngine: CoachEngineProtocol
    private let healthKitManager: HealthKitManaging
    private let contextAssembler: ContextAssembler

    // MARK: - Init
    init(
        modelContext: ModelContext,
        user: User,
        coachEngine: CoachEngineProtocol,
        healthKitManager: HealthKitManaging
    ) {
        self.modelContext = modelContext
        self.user = user
        self.coachEngine = coachEngine
        self.healthKitManager = healthKitManager
        self.contextAssembler = ContextAssembler(healthKitManager: healthKitManager)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWorkoutDataReceived(_:)),
            name: .workoutDataReceived,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Loading
    func loadWorkouts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var descriptor = FetchDescriptor<Workout>(
                predicate: #Predicate { workout in
                    workout.user?.id == user.id
                },
                sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
            )
            descriptor.fetchLimit = 0
            workouts = try modelContext.fetch(descriptor)
            await calculateWeeklyStats()
        } catch {
            AppLogger.error("Failed to load workouts", error: error, category: .data)
        }
    }

    // MARK: - Processing
    func processReceivedWorkout(data: WorkoutBuilderData) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await WorkoutSyncService.shared.processReceivedWorkout(data, modelContext: modelContext)
            await loadWorkouts()
            if let workout = workouts.first(where: { $0.id == data.id }) {
                await generateAIAnalysis(for: workout)
            }
        } catch {
            AppLogger.error("Failed to process workout", error: error, category: .data)
        }
    }

    // MARK: - AI Analysis
    func generateAIAnalysis(for workout: Workout) async {
        isGeneratingAnalysis = true
        defer { isGeneratingAnalysis = false }
        do {
            let snapshot = await contextAssembler.assembleSnapshot(modelContext: modelContext)
            let request = PostWorkoutAnalysisRequest(
                workout: workout,
                recentWorkouts: Array(workouts.prefix(5)),
                healthContext: snapshot
            )
            aiWorkoutSummary = try await coachEngine.generatePostWorkoutAnalysis(request)
        } catch {
            AppLogger.error("Failed to generate AI analysis", error: error, category: .ai)
        }
    }

    // MARK: - Stats
    func calculateWeeklyStats() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        let recent = workouts.filter { workout in
            let date = workout.completedDate ?? workout.plannedDate ?? .distantPast
            return date >= startDate && date <= endDate
        }
        weeklyStats = WeeklyWorkoutStats(
            totalWorkouts: recent.count,
            totalDuration: recent.reduce(0) { $0 + ($1.durationSeconds ?? 0) },
            totalCalories: recent.reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
        )
    }

    // MARK: - Notifications
    @objc private func handleWorkoutDataReceived(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? WorkoutBuilderData else { return }
        Task { await processReceivedWorkout(data: data) }
    }
}

// MARK: - Protocols
protocol CoachEngineProtocol: AnyObject {
    func generatePostWorkoutAnalysis(_ request: PostWorkoutAnalysisRequest) async throws -> String
}

extension CoachEngine: CoachEngineProtocol {}

// MARK: - Supporting Types
struct WeeklyWorkoutStats {
    var totalWorkouts: Int = 0
    var totalDuration: TimeInterval = 0
    var totalCalories: Double = 0
}

struct PostWorkoutAnalysisRequest {
    let workout: Workout
    let recentWorkouts: [Workout]
    let healthContext: HealthContextSnapshot
}
