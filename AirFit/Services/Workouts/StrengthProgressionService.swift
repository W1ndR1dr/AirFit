import Foundation
import SwiftData

// MARK: - Protocol
protocol StrengthProgressionServiceProtocol: Actor, ServiceProtocol {
    func recordStrengthProgress(from workout: Workout, for user: User) async throws
    func getCurrentOneRepMax(exercise: String, user: User) async throws -> Double?
    func getStrengthHistory(exercise: String, user: User, days: Int) async throws -> [StrengthRecord]
    func getTopProgressingExercises(user: User, limit: Int) async throws -> [(exercise: String, improvement: Double)]
    func getStrengthTrend(exercise: String, user: User) async throws -> StrengthTrend
    func getAllCurrentPRs(user: User) async throws -> [String: Double]
}

// MARK: - Implementation
actor StrengthProgressionService: StrengthProgressionServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated var isConfigured: Bool { true }
    nonisolated var serviceIdentifier: String { "strength-progression-service" }

    func configure() async throws {
        // No configuration needed
    }

    func reset() async {
        // No state to reset
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [:]
        )
    }

    // MARK: - Public Methods

    /// Records strength progress from a completed workout
    func recordStrengthProgress(from workout: Workout, for user: User) async throws {
        guard workout.isCompleted else { return }

        // Process each exercise in the workout
        for exercise in workout.exercises {
            // Find the best set (highest calculated 1RM)
            var bestOneRM: Double = 0
            var bestSet: ExerciseSet?

            for set in exercise.completedSets {
                if let oneRM = set.oneRepMax, oneRM > bestOneRM {
                    bestOneRM = oneRM
                    bestSet = set
                }
            }

            // If we found a valid 1RM, check if it's a PR
            if let set = bestSet, bestOneRM > 0 {
                let currentPR = try await getCurrentOneRepMax(exercise: exercise.name, user: user)

                // Only record if it's a new PR or first record
                if currentPR == nil || bestOneRM > (currentPR ?? 0) {
                    let record = StrengthRecord(
                        exerciseName: exercise.name,
                        oneRepMax: bestOneRM,
                        recordedDate: workout.completedDate ?? Date(),
                        actualWeight: set.completedWeightKg,
                        actualReps: set.completedReps,
                        isEstimated: true,
                        formula: "Epley"
                    )

                    user.strengthRecords.append(record)
                    record.user = user

                    AppLogger.info(
                        "New PR recorded: \(exercise.name) - \(Int(bestOneRM))kg",
                        category: .data
                    )
                }
            }
        }
    }

    /// Gets the current 1RM for an exercise
    func getCurrentOneRepMax(exercise: String, user: User) async throws -> Double? {
        let records = user.strengthRecords
            .filter { $0.exerciseName.lowercased() == exercise.lowercased() }
            .sorted { $0.recordedDate > $1.recordedDate }

        return records.first?.oneRepMax
    }

    /// Gets strength history for an exercise over specified days
    func getStrengthHistory(exercise: String, user: User, days: Int) async throws -> [StrengthRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return user.strengthRecords
            .filter {
                $0.exerciseName.lowercased() == exercise.lowercased() &&
                    $0.recordedDate >= cutoffDate
            }
            .sorted { $0.recordedDate < $1.recordedDate }
    }

    /// Gets top progressing exercises by improvement percentage
    func getTopProgressingExercises(user: User, limit: Int) async throws -> [(exercise: String, improvement: Double)] {
        var exerciseProgress: [(exercise: String, improvement: Double)] = []

        // Group records by exercise
        let exerciseGroups = Dictionary(grouping: user.strengthRecords) { $0.exerciseName }

        for (exercise, records) in exerciseGroups {
            let sortedRecords = records.sorted { $0.recordedDate < $1.recordedDate }

            // Need at least 2 records to calculate improvement
            guard sortedRecords.count >= 2,
                  let firstRecord = sortedRecords.first,
                  let latestRecord = sortedRecords.last else { continue }

            // Calculate improvement percentage
            let improvement = ((latestRecord.oneRepMax - firstRecord.oneRepMax) / firstRecord.oneRepMax) * 100

            exerciseProgress.append((exercise, improvement))
        }

        // Sort by improvement and take top N
        return exerciseProgress
            .sorted { $0.improvement > $1.improvement }
            .prefix(limit)
            .map { $0 }
    }

    /// Calculates strength trend for an exercise
    func getStrengthTrend(exercise: String, user: User) async throws -> StrengthTrend {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let records = user.strengthRecords
            .filter {
                $0.exerciseName.lowercased() == exercise.lowercased() &&
                    $0.recordedDate >= thirtyDaysAgo
            }
            .sorted { $0.recordedDate < $1.recordedDate }

        // Need at least 3 records for meaningful trend
        guard records.count >= 3 else { return .insufficient }

        // Simple linear regression to determine trend
        let recentRecords = Array(records.suffix(5)) // Last 5 records

        // Calculate average change between consecutive records
        var changes: [Double] = []
        for i in 1..<recentRecords.count {
            let change = recentRecords[i].oneRepMax - recentRecords[i - 1].oneRepMax
            changes.append(change)
        }

        let averageChange = changes.reduce(0, +) / Double(changes.count)

        // Determine trend based on average change
        if averageChange > 0.5 { // More than 0.5kg average increase
            return .increasing
        } else if averageChange < -0.5 { // More than 0.5kg average decrease
            return .decreasing
        } else {
            return .stable
        }
    }

    /// Gets all current PRs for a user
    func getAllCurrentPRs(user: User) async throws -> [String: Double] {
        var currentPRs: [String: Double] = [:]

        // Group by exercise and find max
        let exerciseGroups = Dictionary(grouping: user.strengthRecords) { $0.exerciseName }

        for (exercise, records) in exerciseGroups {
            if let maxRecord = records.max(by: { $0.oneRepMax < $1.oneRepMax }) {
                currentPRs[exercise] = maxRecord.oneRepMax
            }
        }

        return currentPRs
    }
}

// MARK: - 1RM Calculation Extensions
extension StrengthProgressionService {
    /// Alternative 1RM formulas for future use
    enum OneRMFormula {
        case epley
        case brzycki
        case lander
        case lombardi
        case mayhew
        case oconner
        case wathen

        func calculate(weight: Double, reps: Int) -> Double {
            let r = Double(reps)

            switch self {
            case .epley:
                return weight * (1 + r / 30)
            case .brzycki:
                return weight * (36 / (37 - r))
            case .lander:
                return (100 * weight) / (101.3 - 2.67123 * r)
            case .lombardi:
                return weight * pow(r, 0.10)
            case .mayhew:
                return (100 * weight) / (52.2 + 41.9 * exp(-0.055 * r))
            case .oconner:
                return weight * (1 + 0.025 * r)
            case .wathen:
                return (100 * weight) / (48.8 + 53.8 * exp(-0.075 * r))
            }
        }
    }
}
