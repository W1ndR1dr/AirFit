import SwiftUI
import SwiftData
import Observation
import Charts

/// ViewModel for workout history view with real data
@MainActor
@Observable
final class WorkoutHistoryViewModel {
    // MARK: - State Properties
    private(set) var isLoading = true
    private(set) var error: AppError?

    // Volume data
    private(set) var volumeData: [VolumeDataPoint] = []
    private(set) var totalVolume: Double = 0
    private(set) var weeklyAverage: Double = 0
    private(set) var volumeProgress: Double = 0

    // Frequency data
    private(set) var frequencyData: [FrequencyDataPoint] = []
    private(set) var currentWeekFrequency: Int = 0

    // Recent workouts
    private(set) var recentWorkouts: [Workout] = []

    // Personal records
    private(set) var recentPRs: [PersonalRecord] = []

    // MARK: - Dependencies
    private let user: User
    private let modelContext: ModelContext
    private let muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol
    private let strengthProgressionService: StrengthProgressionServiceProtocol

    // MARK: - Filter State
    var selectedTimeframe: TimeframeOption {
        didSet {
            Task {
                await loadData()
            }
        }
    }

    var selectedMuscleGroup: MuscleGroup {
        didSet {
            Task {
                await loadData()
            }
        }
    }

    // MARK: - Types
    enum TimeframeOption: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }

    enum MuscleGroup: String, CaseIterable {
        case all = "All"
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case biceps = "Biceps"
        case triceps = "Triceps"
        case quads = "Quads"
        case hamstrings = "Hamstrings"
        case glutes = "Glutes"
        case calves = "Calves"
        case core = "Core"
    }

    struct VolumeDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let volume: Double
    }

    struct FrequencyDataPoint: Identifiable {
        let id = UUID()
        let weekday: String
        let count: Int
        let isToday: Bool
    }

    struct PersonalRecord: Identifiable {
        let id = UUID()
        let exercise: String
        let weight: Double
        let improvement: Double
        let date: Date
    }

    // MARK: - Initialization
    init(
        user: User,
        modelContext: ModelContext,
        muscleGroupVolumeService: MuscleGroupVolumeServiceProtocol,
        strengthProgressionService: StrengthProgressionServiceProtocol
    ) {
        self.user = user
        self.modelContext = modelContext
        self.muscleGroupVolumeService = muscleGroupVolumeService
        self.strengthProgressionService = strengthProgressionService
        self.selectedTimeframe = .month
        self.selectedMuscleGroup = .all
    }

    // MARK: - Public Methods
    func onAppear() {
        Task {
            await loadData()
        }
    }

    // MARK: - Private Methods
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load all data concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadVolumeData()
            }
            group.addTask {
                await self.loadFrequencyData()
            }
            group.addTask {
                await self.loadRecentWorkouts()
            }
            group.addTask {
                await self.loadPersonalRecords()
            }
        }
    }

    private func loadVolumeData() async {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeframe.days, to: endDate) ?? endDate

        // Get workouts in timeframe
        let workouts = user.workouts.filter { workout in
            guard let completedDate = workout.completedDate else { return false }
            return completedDate >= startDate && completedDate <= endDate
        }

        // Filter by muscle group if needed
        let filteredWorkouts = filterWorkoutsByMuscleGroup(workouts)

        // Calculate daily volumes
        var dailyVolumes: [Date: Double] = [:]

        for workout in filteredWorkouts {
            guard let date = workout.completedDate else { continue }
            let dayStart = calendar.startOfDay(for: date)

            let workoutVolume = calculateWorkoutVolume(workout)
            dailyVolumes[dayStart, default: 0] += workoutVolume
        }

        // Create data points for every day in range
        var dataPoints: [VolumeDataPoint] = []
        var currentDate = startDate
        var totalVol: Double = 0

        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let volume = dailyVolumes[dayStart] ?? 0
            dataPoints.append(VolumeDataPoint(date: dayStart, volume: volume))
            totalVol += volume
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }

        self.volumeData = dataPoints
        self.totalVolume = totalVol

        // Calculate weekly average
        let weeks = Double(selectedTimeframe.days) / 7.0
        self.weeklyAverage = totalVol / weeks

        // Calculate progress vs previous period
        let previousStartDate = calendar.date(byAdding: .day, value: -selectedTimeframe.days, to: startDate) ?? startDate
        let previousWorkouts = user.workouts.filter { workout in
            guard let completedDate = workout.completedDate else { return false }
            return completedDate >= previousStartDate && completedDate < startDate
        }

        let previousVolume = filterWorkoutsByMuscleGroup(previousWorkouts)
            .reduce(0) { $0 + calculateWorkoutVolume($1) }

        if previousVolume > 0 {
            self.volumeProgress = ((totalVol - previousVolume) / previousVolume) * 100
        } else {
            self.volumeProgress = 0
        }
    }

    private func loadFrequencyData() async {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())

        // Initialize frequency array for 7 days
        var weekdayFrequency = Array(repeating: 0, count: 7)

        // Count workouts for each weekday in the selected timeframe
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeframe.days, to: endDate) ?? endDate

        let workouts = user.workouts.filter { workout in
            guard let completedDate = workout.completedDate else { return false }
            return completedDate >= startDate && completedDate <= endDate
        }

        let filteredWorkouts = filterWorkoutsByMuscleGroup(workouts)

        for workout in filteredWorkouts {
            guard let date = workout.completedDate else { continue }
            let weekday = calendar.component(.weekday, from: date)
            weekdayFrequency[weekday - 1] += 1
        }

        // Create frequency data points
        let weekdaySymbols = DateFormatter().shortWeekdaySymbols ?? []
        var dataPoints: [FrequencyDataPoint] = []

        for (index, count) in weekdayFrequency.enumerated() {
            let weekdayName = index < weekdaySymbols.count ? weekdaySymbols[index] : "Day \(index + 1)"
            let isToday = (index + 1) == today
            dataPoints.append(FrequencyDataPoint(
                weekday: weekdayName,
                count: count,
                isToday: isToday
            ))
        }

        self.frequencyData = dataPoints

        // Calculate current week frequency
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        self.currentWeekFrequency = filteredWorkouts.filter { workout in
            guard let date = workout.completedDate else { return false }
            return date >= currentWeekStart
        }.count
    }

    private func loadRecentWorkouts() async {
        let workouts = user.workouts
            .filter { $0.completedDate != nil }
            .sorted { ($0.completedDate ?? Date.distantPast) > ($1.completedDate ?? Date.distantPast) }

        self.recentWorkouts = filterWorkoutsByMuscleGroup(Array(workouts.prefix(10)))
    }

    private func loadPersonalRecords() async {
        do {
            // Get recent PRs
            let strengthRecords = user.strengthRecords
                .sorted { $0.recordedDate > $1.recordedDate }
                .prefix(5)

            var records: [PersonalRecord] = []

            for record in strengthRecords {
                // Calculate improvement
                let history = try await strengthProgressionService.getStrengthHistory(
                    exercise: record.exerciseName,
                    user: user,
                    days: 90
                )

                var improvement: Double = 0
                if history.count >= 2 {
                    let previousPR = history[history.count - 2].oneRepMax
                    improvement = ((record.oneRepMax - previousPR) / previousPR) * 100
                }

                // Filter by muscle group if needed
                if selectedMuscleGroup != .all {
                    // Check if exercise works the selected muscle group
                    let exerciseMuscles = getMusclGroupsForExercise(record.exerciseName)
                    if !exerciseMuscles.contains(selectedMuscleGroup.rawValue) {
                        continue
                    }
                }

                records.append(PersonalRecord(
                    exercise: record.exerciseName,
                    weight: record.oneRepMax,
                    improvement: improvement,
                    date: record.recordedDate
                ))
            }

            self.recentPRs = records

        } catch {
            AppLogger.error("Failed to load personal records", error: error, category: .data)
            self.recentPRs = []
        }
    }

    private func calculateWorkoutVolume(_ workout: Workout) -> Double {
        var volume: Double = 0

        for exercise in workout.exercises {
            for set in exercise.sets where set.isCompleted {
                let weight = set.completedWeightKg ?? 0
                let reps = Double(set.completedReps ?? 0)
                volume += weight * reps
            }
        }

        return volume
    }

    private func filterWorkoutsByMuscleGroup(_ workouts: [Workout]) -> [Workout] {
        guard selectedMuscleGroup != .all else { return workouts }

        return workouts.filter { workout in
            workout.exercises.contains { exercise in
                exercise.muscleGroups.contains(selectedMuscleGroup.rawValue)
            }
        }
    }

    private func getMusclGroupsForExercise(_ exerciseName: String) -> [String] {
        // Simple mapping - in a real app this would come from exercise database
        let exerciseLower = exerciseName.lowercased()

        if exerciseLower.contains("bench") || exerciseLower.contains("chest") {
            return ["Chest", "Triceps"]
        } else if exerciseLower.contains("squat") {
            return ["Quads", "Glutes", "Hamstrings"]
        } else if exerciseLower.contains("deadlift") {
            return ["Back", "Hamstrings", "Glutes"]
        } else if exerciseLower.contains("row") || exerciseLower.contains("pull") {
            return ["Back", "Biceps"]
        } else if exerciseLower.contains("press") && exerciseLower.contains("shoulder") {
            return ["Shoulders", "Triceps"]
        } else if exerciseLower.contains("curl") {
            return ["Biceps"]
        } else if exerciseLower.contains("tricep") || exerciseLower.contains("dip") {
            return ["Triceps"]
        } else if exerciseLower.contains("calf") {
            return ["Calves"]
        } else if exerciseLower.contains("abs") || exerciseLower.contains("plank") {
            return ["Core"]
        }

        return []
    }
}
