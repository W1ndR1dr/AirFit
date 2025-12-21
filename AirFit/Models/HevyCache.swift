import Foundation
import SwiftData

// MARK: - Cached Workout

/// Cached workout from Hevy API with full exercise/set data.
///
/// Stores workouts locally so training data is available offline
/// and can be used for rich context in AI coaching.
@Model
final class CachedWorkout {
    @Attribute(.unique)
    var id: String

    var title: String
    var workoutDate: Date
    var daysAgo: Int
    var durationMinutes: Int
    var totalVolumeLbs: Double
    var workoutDescription: String?

    /// Exercise names (stored as JSON array) - for quick access
    var exercisesData: Data?

    /// Full exercise details with sets (stored as JSON)
    var fullExercisesData: Data?

    /// When this cache entry was created/updated
    var cachedAt: Date

    var exercises: [String] {
        get {
            guard let data = exercisesData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            exercisesData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Full exercise details with all sets
    var fullExercises: [CachedExercise] {
        get {
            guard let data = fullExercisesData else { return [] }
            return (try? JSONDecoder().decode([CachedExercise].self, from: data)) ?? []
        }
        set {
            fullExercisesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        id: String,
        title: String,
        workoutDate: Date,
        daysAgo: Int,
        durationMinutes: Int,
        totalVolumeLbs: Double,
        exercises: [String],
        fullExercises: [CachedExercise] = [],
        description: String? = nil
    ) {
        self.id = id
        self.title = title
        self.workoutDate = workoutDate
        self.daysAgo = daysAgo
        self.durationMinutes = durationMinutes
        self.totalVolumeLbs = totalVolumeLbs
        self.workoutDescription = description
        self.exercisesData = try? JSONEncoder().encode(exercises)
        self.fullExercisesData = try? JSONEncoder().encode(fullExercises)
        self.cachedAt = Date()
    }

    /// Create from API response
    convenience init(from summary: APIClient.WorkoutSummary) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let workoutDate = dateFormatter.date(from: summary.date) ?? Date()

        self.init(
            id: summary.id,
            title: summary.title,
            workoutDate: workoutDate,
            daysAgo: summary.days_ago,
            durationMinutes: summary.duration_minutes,
            totalVolumeLbs: summary.total_volume_lbs,
            exercises: summary.exercises
        )
    }

    /// Generate a detailed context string for AI prompts
    var detailedContext: String {
        var lines: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        lines.append("\(dateFormatter.string(from: workoutDate)): \(title) (\(durationMinutes)min)")

        // Include workout-level notes/description if present
        if let description = workoutDescription, !description.isEmpty {
            lines.append("  Notes: \"\(description)\"")
        }

        for exercise in fullExercises {
            let bestSet = exercise.sets.max { a, b in
                (a.weightLbs ?? 0) * Double(a.reps ?? 0) < (b.weightLbs ?? 0) * Double(b.reps ?? 0)
            }
            if let best = bestSet, let weight = best.weightLbs, let reps = best.reps {
                lines.append("  - \(exercise.name): \(Int(weight))lbs × \(reps) (best of \(exercise.sets.count) sets)")
            } else {
                lines.append("  - \(exercise.name): \(exercise.sets.count) sets")
            }

            // Include exercise-level notes if present (valuable for coach feedback!)
            if let notes = exercise.notes, !notes.isEmpty {
                lines.append("      📝 \"\(notes)\"")
            }
        }

        return lines.joined(separator: "\n")
    }
}

/// Cached exercise with all set details
struct CachedExercise: Codable {
    let name: String
    let sets: [CachedSet]
    let notes: String?

    var totalVolumeLbs: Double {
        sets.reduce(0) { $0 + ($1.weightLbs ?? 0) * Double($1.reps ?? 0) }
    }
}

/// Cached set with weight, reps, and type
struct CachedSet: Codable {
    let reps: Int?
    let weightLbs: Double?
    let type: String?  // "normal", "warmup", "drop", "failure"
    let rpe: Double?
}

// MARK: - Cached Lift Progress

/// Cached PR and history for a lift (e.g., Bench Press).
///
/// Enables sparkline charts and PR tracking without server dependency.
@Model
final class CachedLiftProgress {
    @Attribute(.unique)
    var exerciseName: String

    // Current PR
    var currentPRWeightLbs: Double
    var currentPRReps: Int
    var currentPRDate: Date

    // Workout volume
    var workoutCount: Int

    /// History points for sparkline (stored as JSON)
    var historyData: Data?

    /// When this cache entry was created/updated
    var cachedAt: Date

    /// Decoded history points for charting
    var history: [HistoryPoint] {
        get {
            guard let data = historyData else { return [] }
            return (try? JSONDecoder().decode([HistoryPoint].self, from: data)) ?? []
        }
        set {
            historyData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        exerciseName: String,
        currentPRWeightLbs: Double,
        currentPRReps: Int,
        currentPRDate: Date,
        workoutCount: Int,
        history: [HistoryPoint]
    ) {
        self.exerciseName = exerciseName
        self.currentPRWeightLbs = currentPRWeightLbs
        self.currentPRReps = currentPRReps
        self.currentPRDate = currentPRDate
        self.workoutCount = workoutCount
        self.historyData = try? JSONEncoder().encode(history)
        self.cachedAt = Date()
    }

    /// Create from API response
    convenience init(from liftData: APIClient.LiftData) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let prDate = dateFormatter.date(from: liftData.current_pr.date) ?? Date()

        let historyPoints = liftData.history.map { point -> HistoryPoint in
            let date = dateFormatter.date(from: point.date) ?? Date()
            return HistoryPoint(date: date, weightLbs: point.weight_lbs)
        }

        self.init(
            exerciseName: liftData.name,
            currentPRWeightLbs: liftData.current_pr.weight_lbs,
            currentPRReps: liftData.current_pr.reps,
            currentPRDate: prDate,
            workoutCount: liftData.workout_count,
            history: historyPoints
        )
    }

    /// History point for sparkline charts
    struct HistoryPoint: Codable, Identifiable {
        var id: Date { date }
        let date: Date
        let weightLbs: Double
    }
}

// MARK: - Cached Set Tracker

/// Cached weekly set volume by muscle group.
///
/// Tracks whether user is hitting optimal volume (in zone, below, above).
@Model
final class CachedSetTracker {
    @Attribute(.unique)
    var muscleGroup: String

    /// Current set count in the window
    var currentSets: Int

    /// Optimal range bounds
    var optimalMin: Int
    var optimalMax: Int

    /// Volume status: "in_zone", "below", "at_floor", "above"
    var status: String

    /// When this cache entry was created/updated
    var cachedAt: Date

    init(
        muscleGroup: String,
        currentSets: Int,
        optimalMin: Int,
        optimalMax: Int,
        status: String
    ) {
        self.muscleGroup = muscleGroup
        self.currentSets = currentSets
        self.optimalMin = optimalMin
        self.optimalMax = optimalMax
        self.status = status
        self.cachedAt = Date()
    }

    /// Create from API response entry
    convenience init(muscleGroup: String, from data: APIClient.MuscleGroupData) {
        self.init(
            muscleGroup: muscleGroup,
            currentSets: data.current,
            optimalMin: data.min,
            optimalMax: data.max,
            status: data.status
        )
    }

    /// Whether volume is in optimal zone
    var isInZone: Bool {
        status == "in_zone"
    }

    /// Percentage of minimum target achieved
    var completionPercentage: Double {
        guard optimalMin > 0 else { return 0 }
        return min(1.0, Double(currentSets) / Double(optimalMin))
    }

    /// Volume status for display
    enum VolumeStatus: String {
        case inZone = "in_zone"
        case below = "below"
        case atFloor = "at_floor"
        case above = "above"

        var displayText: String {
            switch self {
            case .inZone: return "Optimal"
            case .below: return "Below Target"
            case .atFloor: return "At Minimum"
            case .above: return "Above Target"
            }
        }

        var iconName: String {
            switch self {
            case .inZone: return "checkmark.circle.fill"
            case .below: return "arrow.down.circle.fill"
            case .atFloor: return "exclamationmark.circle.fill"
            case .above: return "arrow.up.circle.fill"
            }
        }
    }

    var volumeStatus: VolumeStatus {
        VolumeStatus(rawValue: status) ?? .below
    }
}

// MARK: - Hevy Cache Metadata

/// Tracks when the Hevy cache was last refreshed.
///
/// Used to determine if cached data is stale and needs refresh.
@Model
final class HevyCacheMetadata {
    @Attribute(.unique)
    var id: String = "singleton"

    var lastRefresh: Date?
    var windowDays: Int = 7
    var lastSyncTimestamp: String?  // From server response

    /// Date of the most recent workout in cache (for incremental sync)
    var newestWorkoutDate: Date?

    /// Total workouts cached
    var cachedWorkoutCount: Int = 0

    init() {
        self.id = "singleton"
    }

    /// Check if cache is stale (older than threshold)
    func isStale(thresholdMinutes: Int = 60) -> Bool {
        guard let lastRefresh = lastRefresh else { return true }
        let age = Date().timeIntervalSince(lastRefresh)
        return age > Double(thresholdMinutes * 60)
    }

    /// Check if cache is stale for active chatting (shorter threshold)
    func isStaleForChat(thresholdMinutes: Int = 5) -> Bool {
        guard let lastRefresh = lastRefresh else { return true }
        let age = Date().timeIntervalSince(lastRefresh)
        return age > Double(thresholdMinutes * 60)
    }

    /// Human-readable cache age
    var ageDescription: String {
        guard let lastRefresh = lastRefresh else { return "never" }
        let age = Date().timeIntervalSince(lastRefresh)

        if age < 60 {
            return "just now"
        } else if age < 3600 {
            let minutes = Int(age / 60)
            return "\(minutes)m ago"
        } else if age < 86400 {
            let hours = Int(age / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(age / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Query Helpers

extension CachedWorkout {
    /// Get recent workouts sorted by date
    static var recentFirst: SortDescriptor<CachedWorkout> {
        SortDescriptor(\CachedWorkout.workoutDate, order: .reverse)
    }
}

extension CachedLiftProgress {
    /// Get lifts sorted by PR weight
    static var byPRWeight: SortDescriptor<CachedLiftProgress> {
        SortDescriptor(\CachedLiftProgress.currentPRWeightLbs, order: .reverse)
    }

    /// Get lifts sorted by workout count (most practiced first)
    static var byWorkoutCount: SortDescriptor<CachedLiftProgress> {
        SortDescriptor(\CachedLiftProgress.workoutCount, order: .reverse)
    }
}

extension CachedSetTracker {
    /// Get muscle groups sorted alphabetically
    static var alphabetical: SortDescriptor<CachedSetTracker> {
        SortDescriptor(\CachedSetTracker.muscleGroup)
    }

    /// Predicate for muscle groups below target
    static var belowTarget: Predicate<CachedSetTracker> {
        #Predicate<CachedSetTracker> { $0.status == "below" || $0.status == "at_floor" }
    }
}
