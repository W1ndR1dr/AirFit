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
    /// Note: Now stubbed - workout tracking moved to external apps (HEVY/Apple Workouts)
    func recordStrengthProgress(from workout: Workout, for user: User) async throws {
        // No-op: Local workout models removed, strength tracking now via HealthKit
        AppLogger.info("Strength progress recording disabled - use HealthKit integration", category: .data)
    }

    /// Gets the current 1RM for an exercise
    /// Note: Stubbed - strength tracking now via HealthKit
    func getCurrentOneRepMax(exercise: String, user: User) async throws -> Double? {
        // Return nil - no local strength records stored
        return nil
    }

    /// Gets strength history for an exercise over specified days
    /// Note: Stubbed - strength tracking now via HealthKit
    func getStrengthHistory(exercise: String, user: User, days: Int) async throws -> [StrengthRecord] {
        // Return empty array - no local strength records stored
        return []
    }

    /// Gets top progressing exercises by improvement percentage
    /// Note: Stubbed - strength tracking now via HealthKit
    func getTopProgressingExercises(user: User, limit: Int) async throws -> [(exercise: String, improvement: Double)] {
        // Return empty array - no local strength records stored
        return []
    }

    /// Calculates strength trend for an exercise
    /// Note: Stubbed - strength tracking now via HealthKit
    func getStrengthTrend(exercise: String, user: User) async throws -> StrengthTrend {
        // Return insufficient data - no local strength records stored
        return .insufficient
    }

    /// Gets all current PRs for a user
    /// Note: Stubbed - strength tracking now via HealthKit
    func getAllCurrentPRs(user: User) async throws -> [String: Double] {
        // Return empty dictionary - no local strength records stored
        return [:]
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
