import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class WorkoutViewModel: ErrorHandling {
    // MARK: - State
    private(set) var workouts: [Workout] = []
    private(set) var weeklyStats = WeeklyWorkoutStats()
    private(set) var isLoading = false
    private(set) var aiWorkoutSummary: String?
    private(set) var isGeneratingAnalysis = false
    var activeWorkout: Workout?
    var error: AppError?
    var isShowingError = false
    
    // Live Activity state
    private(set) var isLiveActivityActive = false
    private var workoutStartTime: Date?
    private var workoutTimer: Timer?
    private var currentCalories: Int = 0
    private var currentActiveMinutes: Int = 0
    private var currentHeartRate: Int?

    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let user: User
    private let coachEngine: CoachEngineProtocol
    private let healthKitManager: HealthKitManaging
    private let contextAssembler: ContextAssembler
    let exerciseDatabase: ExerciseDatabase
    private let workoutSyncService: WorkoutSyncService
    private let liveActivityManager: LiveActivityManager

    // MARK: - Init
    init(
        modelContext: ModelContext,
        user: User,
        coachEngine: CoachEngineProtocol,
        healthKitManager: HealthKitManaging,
        exerciseDatabase: ExerciseDatabase,
        workoutSyncService: WorkoutSyncService,
        liveActivityManager: LiveActivityManager
    ) {
        self.modelContext = modelContext
        self.user = user
        self.coachEngine = coachEngine
        self.healthKitManager = healthKitManager
        self.contextAssembler = ContextAssembler(healthKitManager: healthKitManager)
        self.exerciseDatabase = exerciseDatabase
        self.workoutSyncService = workoutSyncService
        self.liveActivityManager = liveActivityManager

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWorkoutDataReceived(_:)),
            name: .workoutDataReceived,
            object: nil
        )
        
        // Listen for Live Activity notifications
        NotificationCenter.default.addObserver(
            forName: .workoutPaused,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.pauseCurrentWorkout() }
        }
        
        NotificationCenter.default.addObserver(
            forName: .workoutEnded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.endCurrentWorkout() }
        }
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
                sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
            )
            descriptor.fetchLimit = 0
            workouts = try modelContext.fetch(descriptor)
            await calculateWeeklyStats()
        } catch {
            handleError(error)
            AppLogger.error("Failed to load workouts", error: error, category: .data)
        }
    }

    // MARK: - Exercise Library
    func loadExerciseLibrary() async {
        // Trigger exercise database initialization if needed
        _ = try? await exerciseDatabase.getAllExercises()
    }

    // MARK: - Processing
    func processReceivedWorkout(data: WorkoutBuilderData) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await workoutSyncService.processReceivedWorkout(data, modelContext: modelContext)
            await loadWorkouts()
            if let workout = workouts.first(where: { $0.id == data.id }) {
                await generateAIAnalysis(for: workout)
            }
        } catch {
            handleError(error)
            AppLogger.error("Failed to process workout", error: error, category: .data)
        }
    }

    // MARK: - AI Analysis
    func generateAIAnalysis(for workout: Workout) async {
        isGeneratingAnalysis = true
        defer { isGeneratingAnalysis = false }
        do {
            // Assemble context snapshot for AI analysis
            _ = await contextAssembler.assembleContext()

            let request = PostWorkoutAnalysisRequest(
                workout: workout,
                recentWorkouts: Array(workouts.prefix(5)),
                userGoals: nil,
                recoveryData: nil
            )
            let analysis = try await coachEngine.generatePostWorkoutAnalysis(request)
            aiWorkoutSummary = analysis

            // Save analysis to workout
            workout.aiAnalysis = analysis
            try modelContext.save()
        } catch {
            handleError(error)
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

        // Calculate muscle group distribution
        var muscleGroupCounts: [String: Int] = [:]
        for workout in recent {
            for exercise in workout.exercises {
                for muscleGroup in exercise.muscleGroups {
                    muscleGroupCounts[muscleGroup, default: 0] += 1
                }
            }
        }

        weeklyStats = WeeklyWorkoutStats(
            totalWorkouts: recent.count,
            totalDuration: recent.reduce(0) { $0 + ($1.durationSeconds ?? 0) },
            totalCalories: recent.reduce(0) { $0 + ($1.caloriesBurned ?? 0) },
            muscleGroupDistribution: muscleGroupCounts
        )
    }

    // MARK: - Notifications
    @objc private func handleWorkoutDataReceived(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? WorkoutBuilderData else { return }
        Task { await processReceivedWorkout(data: data) }
    }
    
    // MARK: - Live Activity Integration
    
    /// Starts a workout and its corresponding Live Activity
    func startWorkout(type: String, goalCalories: Int? = nil, estimatedDuration: TimeInterval? = nil) async {
        // Set up workout state
        workoutStartTime = Date()
        currentCalories = 0
        currentActiveMinutes = 0
        currentHeartRate = nil
        
        // Start the Live Activity
        do {
            try await liveActivityManager.startWorkoutActivity(
                workoutType: type,
                goalCalories: goalCalories,
                estimatedDuration: estimatedDuration
            )
            isLiveActivityActive = true
            
            // Start periodic updates
            startWorkoutTimer()
            
            AppLogger.info("Started workout with Live Activity: \(type)", category: .health)
        } catch {
            AppLogger.error("Failed to start workout Live Activity", error: error, category: .health)
            handleError(error)
        }
    }
    
    /// Updates the current workout Live Activity with new metrics
    func updateWorkoutMetrics(
        calories: Int? = nil,
        activeMinutes: Int? = nil,
        heartRate: Int? = nil,
        currentExercise: String? = nil,
        intensity: WorkoutIntensity = .moderate
    ) async {
        guard isLiveActivityActive else { return }
        
        // Update local state
        if let calories = calories { self.currentCalories = calories }
        if let activeMinutes = activeMinutes { self.currentActiveMinutes = activeMinutes }
        if let heartRate = heartRate { self.currentHeartRate = heartRate }
        
        // Calculate elapsed time
        let elapsedSeconds = workoutStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
        
        // Determine heart rate zone
        let zone = calculateHeartRateZone(heartRate: heartRate)
        
        // Update Live Activity
        await liveActivityManager.updateWorkoutActivity(
            calories: self.currentCalories,
            activeMinutes: self.currentActiveMinutes,
            heartRate: self.currentHeartRate,
            currentActivity: currentExercise ?? "In Progress",
            currentExercise: currentExercise,
            elapsedSeconds: elapsedSeconds,
            intensity: intensity,
            zone: zone
        )
    }
    
    /// Pauses the current workout
    private func pauseCurrentWorkout() async {
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        await updateWorkoutMetrics(
            currentExercise: "Paused"
        )
        
        AppLogger.info("Workout paused via Live Activity", category: .health)
    }
    
    /// Ends the current workout and Live Activity
    private func endCurrentWorkout() async {
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        await liveActivityManager.endWorkoutActivity()
        isLiveActivityActive = false
        workoutStartTime = nil
        
        AppLogger.info("Workout ended via Live Activity", category: .health)
    }
    
    /// Manually ends the workout (called from UI)
    func completeWorkout() async {
        await endCurrentWorkout()
    }
    
    // MARK: - Private Helpers
    
    private func startWorkoutTimer() {
        workoutTimer?.invalidate()
        
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { await self?.fetchLatestHealthData() }
        }
    }
    
    private func fetchLatestHealthData() async {
        // Fetch latest heart rate and activity data from HealthKit
        do {
            let today = Date()
            let activityMetrics = try await healthKitManager.fetchTodayActivityMetrics()
            let heartMetrics = try await healthKitManager.fetchHeartHealthMetrics()
            
            // Extract current heart rate (simplified - in real implementation, 
            // you'd want to fetch the most recent heart rate sample)
            let heartRate = heartMetrics.restingHeartRate.map { $0 + 20 } // Rough estimate during exercise
            
            // Update calories and active minutes from HealthKit
            let calories = Int(activityMetrics.activeEnergyBurned?.converted(to: .kilocalories).value ?? 0)
            let activeMinutes = activityMetrics.exerciseMinutes
            
            await updateWorkoutMetrics(
                calories: max(calories, currentCalories),
                activeMinutes: max(activeMinutes, currentActiveMinutes),
                heartRate: heartRate,
                intensity: determineIntensity(heartRate: heartRate)
            )
        } catch {
            AppLogger.error("Failed to fetch latest health data", error: error, category: .health)
        }
    }
    
    private func calculateHeartRateZone(heartRate: Int?) -> HeartRateZone? {
        guard let hr = heartRate else { return nil }
        
        // Simplified zone calculation (in real app, use user's max HR)
        let estimatedMaxHR = 220 - (user.profile?.age ?? 30)
        let percentage = Double(hr) / Double(estimatedMaxHR)
        
        switch percentage {
        case 0.0..<0.6: return .zone1
        case 0.6..<0.7: return .zone2
        case 0.7..<0.8: return .zone3
        case 0.8..<0.9: return .zone4
        default: return .zone5
        }
    }
    
    private func determineIntensity(heartRate: Int?) -> WorkoutIntensity {
        guard let hr = heartRate else { return .light }
        
        let estimatedMaxHR = 220 - (user.profile?.age ?? 30)
        let percentage = Double(hr) / Double(estimatedMaxHR)
        
        switch percentage {
        case 0.0..<0.6: return .light
        case 0.6..<0.8: return .moderate
        case 0.8..<0.9: return .vigorous
        default: return .peak
        }
    }
}

// MARK: - Protocol Extension
