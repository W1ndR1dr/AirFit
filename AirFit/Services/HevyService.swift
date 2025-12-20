import Foundation

/// Direct Hevy API integration for workout sync.
///
/// Enables device-first workout data access without server dependency.
/// API key stored securely in Keychain via KeychainManager.
///
/// API Reference: https://api.hevyapp.com/v1
actor HevyService {
    static let shared = HevyService()

    private let baseURL = URL(string: "https://api.hevyapp.com/v1")!
    private let keychainManager = KeychainManager.shared

    // MARK: - API Types

    /// Hevy workout from API response
    struct HevyWorkout: Codable, Identifiable {
        let id: String
        let title: String
        let startTime: Date
        let endTime: Date?
        let exercises: [HevyExercise]
        let description: String?

        var durationMinutes: Int {
            guard let end = endTime else { return 0 }
            return Int(end.timeIntervalSince(startTime) / 60)
        }

        var totalVolumeKg: Double {
            exercises.reduce(0) { $0 + $1.volumeKg }
        }

        var totalVolumeLbs: Double {
            totalVolumeKg * 2.20462
        }

        var exerciseNames: [String] {
            exercises.map { $0.title }
        }

        enum CodingKeys: String, CodingKey {
            case id, title, exercises
            case startTime = "start_time"
            case endTime = "end_time"
            case description
        }
    }

    struct HevyExercise: Codable {
        let title: String
        let sets: [HevySet]
        let notes: String?
        let exerciseTemplateId: String?

        var volumeKg: Double {
            sets.reduce(0) { $0 + ($1.weightKg ?? 0) * Double($1.reps ?? 0) }
        }

        /// Best set (highest weight × reps)
        var bestSet: HevySet? {
            sets.max { ($0.weightKg ?? 0) * Double($0.reps ?? 0) < ($1.weightKg ?? 0) * Double($1.reps ?? 0) }
        }

        enum CodingKeys: String, CodingKey {
            case title, sets, notes
            case exerciseTemplateId = "exercise_template_id"
        }
    }

    struct HevySet: Codable {
        let reps: Int?
        let weightKg: Double?
        let type: String?  // "normal", "warmup", "drop", "failure"
        let rpe: Double?

        enum CodingKeys: String, CodingKey {
            case reps
            case weightKg = "weight_kg"
            case type, rpe
        }
    }

    // MARK: - API Response Wrappers

    private struct WorkoutsResponse: Codable {
        let page: Int
        let page_count: Int
        let workouts: [HevyWorkout]
    }

    // MARK: - Public API

    /// Check if Hevy API key is configured
    func isConfigured() async -> Bool {
        await keychainManager.hasHevyAPIKey()
    }

    /// Test the API connection with the current key.
    ///
    /// Returns true if we can successfully fetch workouts.
    func testConnection() async -> Bool {
        do {
            _ = try await fetchWorkouts(page: 1, pageSize: 1)
            return true
        } catch {
            print("[HevyService] Connection test failed: \(error)")
            return false
        }
    }

    /// Fetch recent workouts from Hevy.
    ///
    /// - Parameters:
    ///   - page: Page number (1-indexed)
    ///   - pageSize: Number of workouts per page (max 10)
    /// - Returns: Array of workouts
    func fetchWorkouts(page: Int = 1, pageSize: Int = 10) async throws -> [HevyWorkout] {
        guard let apiKey = await keychainManager.getHevyAPIKey() else {
            throw HevyError.noAPIKey
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("workouts"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(min(pageSize, 10))")  // API max is 10
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HevyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw HevyError.unauthorized
        case 429:
            throw HevyError.rateLimited
        default:
            throw HevyError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let wrapper = try decoder.decode(WorkoutsResponse.self, from: data)
        return wrapper.workouts
    }

    /// Fetch all workouts within a date range (paginated).
    ///
    /// - Parameters:
    ///   - days: Number of days to fetch (default 30)
    ///   - maxPages: Maximum pages to fetch (default 5)
    /// - Returns: All workouts within the date range
    func fetchWorkoutsInRange(days: Int = 30, maxPages: Int = 5) async throws -> [HevyWorkout] {
        var allWorkouts: [HevyWorkout] = []
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        for page in 1...maxPages {
            let workouts = try await fetchWorkouts(page: page, pageSize: 10)

            // Filter to date range
            let inRange = workouts.filter { $0.startTime >= cutoffDate }
            allWorkouts.append(contentsOf: inRange)

            // Stop if we've gone past the date range or reached end
            if workouts.count < 10 || workouts.last.map({ $0.startTime < cutoffDate }) == true {
                break
            }
        }

        return allWorkouts.sorted { $0.startTime > $1.startTime }
    }

    /// Get computed workout summaries for caching.
    ///
    /// Transforms raw Hevy workouts into the format expected by CachedWorkout.
    func getWorkoutSummaries(days: Int = 30) async throws -> [WorkoutSummary] {
        let workouts = try await fetchWorkoutsInRange(days: days)

        return workouts.map { workout in
            let daysAgo = Calendar.current.dateComponents([.day], from: workout.startTime, to: Date()).day ?? 0

            return WorkoutSummary(
                id: workout.id,
                title: workout.title,
                date: workout.startTime,
                daysAgo: daysAgo,
                durationMinutes: workout.durationMinutes,
                totalVolumeLbs: workout.totalVolumeLbs,
                exercises: workout.exerciseNames
            )
        }
    }

    // MARK: - Full Workout Data (for rich caching)

    /// Get full workout data including all exercises and sets.
    ///
    /// Returns `FullWorkoutData` with complete set/rep information for rich AI context.
    func getFullWorkouts(days: Int = 30) async throws -> [FullWorkoutData] {
        let workouts = try await fetchWorkoutsInRange(days: days)

        return workouts.map { workout in
            let daysAgo = Calendar.current.dateComponents([.day], from: workout.startTime, to: Date()).day ?? 0

            let exercises = workout.exercises.map { exercise in
                let sets = exercise.sets.map { set in
                    FullSetData(
                        reps: set.reps,
                        weightLbs: set.weightKg.map { $0 * 2.20462 },
                        type: set.type,
                        rpe: set.rpe
                    )
                }
                return FullExerciseData(
                    name: exercise.title,
                    sets: sets,
                    notes: exercise.notes
                )
            }

            return FullWorkoutData(
                id: workout.id,
                title: workout.title,
                date: workout.startTime,
                daysAgo: daysAgo,
                durationMinutes: workout.durationMinutes,
                totalVolumeLbs: workout.totalVolumeLbs,
                exercises: exercises,
                description: workout.description
            )
        }
    }

    /// Fetch only workouts newer than a given date (for incremental sync).
    ///
    /// - Parameter since: Only fetch workouts after this date
    /// - Returns: New workouts sorted by date (newest first)
    func getWorkoutsSince(_ since: Date) async throws -> [FullWorkoutData] {
        var allWorkouts: [HevyWorkout] = []

        // Fetch pages until we hit workouts older than `since`
        for page in 1...10 {
            let workouts = try await fetchWorkouts(page: page, pageSize: 10)

            let newWorkouts = workouts.filter { $0.startTime > since }
            allWorkouts.append(contentsOf: newWorkouts)

            // Stop if we've gone past the since date or reached end
            if workouts.count < 10 || newWorkouts.count < workouts.count {
                break
            }
        }

        return allWorkouts.sorted { $0.startTime > $1.startTime }.map { workout in
            let daysAgo = Calendar.current.dateComponents([.day], from: workout.startTime, to: Date()).day ?? 0

            let exercises = workout.exercises.map { exercise in
                let sets = exercise.sets.map { set in
                    FullSetData(
                        reps: set.reps,
                        weightLbs: set.weightKg.map { $0 * 2.20462 },
                        type: set.type,
                        rpe: set.rpe
                    )
                }
                return FullExerciseData(
                    name: exercise.title,
                    sets: sets,
                    notes: exercise.notes
                )
            }

            return FullWorkoutData(
                id: workout.id,
                title: workout.title,
                date: workout.startTime,
                daysAgo: daysAgo,
                durationMinutes: workout.durationMinutes,
                totalVolumeLbs: workout.totalVolumeLbs,
                exercises: exercises,
                description: workout.description
            )
        }
    }

    // MARK: - Full Data Types

    /// Full workout data with all exercise and set details
    struct FullWorkoutData {
        let id: String
        let title: String
        let date: Date
        let daysAgo: Int
        let durationMinutes: Int
        let totalVolumeLbs: Double
        let exercises: [FullExerciseData]
        let description: String?
    }

    /// Full exercise data with sets
    struct FullExerciseData {
        let name: String
        let sets: [FullSetData]
        let notes: String?
    }

    /// Full set data
    struct FullSetData {
        let reps: Int?
        let weightLbs: Double?
        let type: String?
        let rpe: Double?
    }

    /// Get lift progress (PRs) for key exercises.
    ///
    /// Analyzes workout history to find personal records.
    func getLiftProgress(days: Int = 90) async throws -> [LiftProgress] {
        let workouts = try await fetchWorkoutsInRange(days: days, maxPages: 10)

        // Group all sets by exercise
        var exerciseData: [String: [(date: Date, weight: Double, reps: Int)]] = [:]

        for workout in workouts {
            for exercise in workout.exercises {
                for set in exercise.sets {
                    guard let weight = set.weightKg, weight > 0,
                          let reps = set.reps, reps > 0 else { continue }

                    let key = exercise.title
                    var data = exerciseData[key] ?? []
                    data.append((date: workout.startTime, weight: weight * 2.20462, reps: reps))
                    exerciseData[key] = data
                }
            }
        }

        // Calculate PRs for each exercise
        var liftProgress: [LiftProgress] = []

        for (name, sets) in exerciseData {
            guard !sets.isEmpty else { continue }

            // Find PR (highest weight)
            let sortedByWeight = sets.sorted { $0.weight > $1.weight }
            let pr = sortedByWeight.first!

            // Get history for sparkline (max weight per day)
            let groupedByDay = Dictionary(grouping: sets) { set in
                Calendar.current.startOfDay(for: set.date)
            }
            let history = groupedByDay.map { (date, daySets) -> LiftProgress.HistoryPoint in
                let maxWeight = daySets.max { $0.weight < $1.weight }!.weight
                return LiftProgress.HistoryPoint(date: date, weightLbs: maxWeight)
            }.sorted { $0.date < $1.date }

            // Count unique workout days
            let workoutCount = groupedByDay.count

            liftProgress.append(LiftProgress(
                name: name,
                currentPRWeightLbs: pr.weight,
                currentPRReps: pr.reps,
                currentPRDate: pr.date,
                workoutCount: workoutCount,
                history: history
            ))
        }

        // Sort by workout count (most practiced first)
        return liftProgress.sorted { $0.workoutCount > $1.workoutCount }
    }

    /// Get set tracker (volume by muscle group).
    ///
    /// Estimates muscle group volume based on exercise names.
    /// Uses heuristic matching since Hevy API doesn't expose muscle groups directly.
    func getSetTracker(windowDays: Int = 7) async throws -> SetTrackerData {
        let workouts = try await fetchWorkoutsInRange(days: windowDays, maxPages: 3)

        // Count sets by inferred muscle group
        var muscleGroupSets: [String: Int] = [:]

        for workout in workouts {
            for exercise in workout.exercises {
                let muscleGroup = inferMuscleGroup(from: exercise.title)
                let setCount = exercise.sets.filter { $0.type != "warmup" }.count
                muscleGroupSets[muscleGroup, default: 0] += setCount
            }
        }

        // Build set tracker with optimal ranges
        var muscleGroups: [String: MuscleGroupVolume] = [:]

        for (muscle, sets) in muscleGroupSets {
            let (min, max) = optimalSetRange(for: muscle)
            let status: String
            if sets >= min && sets <= max {
                status = "in_zone"
            } else if sets < min {
                status = sets == 0 ? "at_floor" : "below"
            } else {
                status = "above"
            }

            muscleGroups[muscle] = MuscleGroupVolume(
                current: sets,
                min: min,
                max: max,
                status: status
            )
        }

        return SetTrackerData(
            windowDays: windowDays,
            muscleGroups: muscleGroups
        )
    }

    // MARK: - Data Types for Caching

    struct WorkoutSummary {
        let id: String
        let title: String
        let date: Date
        let daysAgo: Int
        let durationMinutes: Int
        let totalVolumeLbs: Double
        let exercises: [String]
    }

    struct LiftProgress {
        let name: String
        let currentPRWeightLbs: Double
        let currentPRReps: Int
        let currentPRDate: Date
        let workoutCount: Int
        let history: [HistoryPoint]

        struct HistoryPoint {
            let date: Date
            let weightLbs: Double
        }
    }

    struct SetTrackerData {
        let windowDays: Int
        let muscleGroups: [String: MuscleGroupVolume]
    }

    struct MuscleGroupVolume {
        let current: Int
        let min: Int
        let max: Int
        let status: String
    }

    // MARK: - Muscle Group Inference

    /// Infer muscle group from exercise name (heuristic).
    private func inferMuscleGroup(from exerciseName: String) -> String {
        let name = exerciseName.lowercased()

        // Chest
        if name.contains("bench") || name.contains("chest") || name.contains("fly") || name.contains("pec") {
            return "Chest"
        }
        // Back
        if name.contains("row") || name.contains("pull") || name.contains("lat") || name.contains("back") || name.contains("deadlift") {
            return "Back"
        }
        // Shoulders
        if name.contains("shoulder") || name.contains("press") && name.contains("overhead") || name.contains("lateral raise") || name.contains("delt") {
            return "Shoulders"
        }
        // Biceps
        if name.contains("bicep") || name.contains("curl") && !name.contains("leg") {
            return "Biceps"
        }
        // Triceps
        if name.contains("tricep") || name.contains("pushdown") || name.contains("skull") || name.contains("dip") {
            return "Triceps"
        }
        // Quads
        if name.contains("squat") || name.contains("leg press") || name.contains("extension") || name.contains("quad") || name.contains("lunge") {
            return "Quads"
        }
        // Hamstrings
        if name.contains("hamstring") || name.contains("leg curl") || name.contains("rdl") || name.contains("romanian") {
            return "Hamstrings"
        }
        // Glutes
        if name.contains("glute") || name.contains("hip thrust") {
            return "Glutes"
        }
        // Calves
        if name.contains("calf") || name.contains("calves") {
            return "Calves"
        }
        // Abs
        if name.contains("ab") || name.contains("crunch") || name.contains("plank") || name.contains("core") {
            return "Abs"
        }

        return "Other"
    }

    /// Get optimal set range for a muscle group per week.
    private func optimalSetRange(for muscle: String) -> (min: Int, max: Int) {
        switch muscle {
        case "Chest": return (10, 20)
        case "Back": return (12, 22)
        case "Shoulders": return (12, 20)
        case "Biceps": return (8, 14)
        case "Triceps": return (8, 14)
        case "Quads": return (10, 20)
        case "Hamstrings": return (8, 16)
        case "Glutes": return (6, 12)
        case "Calves": return (8, 14)
        case "Abs": return (6, 12)
        default: return (6, 12)
        }
    }
}

// MARK: - Errors

enum HevyError: LocalizedError {
    case noAPIKey
    case unauthorized
    case rateLimited
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Hevy API key configured. Add your key in Settings."
        case .unauthorized:
            return "Hevy API key is invalid. Please check your key in Settings."
        case .rateLimited:
            return "Hevy API rate limit reached. Try again later."
        case .invalidResponse:
            return "Invalid response from Hevy API"
        case .apiError(let message):
            return "Hevy API error: \(message)"
        }
    }
}
