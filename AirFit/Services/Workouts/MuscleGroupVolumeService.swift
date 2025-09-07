import Foundation
import SwiftData

// MARK: - Muscle Group Volume Service Protocol
protocol MuscleGroupVolumeServiceProtocol: Actor, ServiceProtocol {
    func getWeeklyVolumes(for user: User) async throws -> [MuscleGroupVolume]
    func getHardSetsForMuscleGroup(_ muscleGroup: String, user: User, days: Int) async throws -> Int
    func updateTargets(_ targets: [String: Int], for user: User) async throws
    func getRecommendedVolumes(goals: [String], currentFitness: String, experience: String) async throws -> [String: Int]
}

// MARK: - Implementation
actor MuscleGroupVolumeService: MuscleGroupVolumeServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated var isConfigured: Bool { true }
    nonisolated var serviceIdentifier: String { "muscle-group-volume-service" }

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
    func getWeeklyVolumes(for user: User) async throws -> [MuscleGroupVolume] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentWorkouts = user.workouts.filter { workout in
            guard let completedDate = workout.completedDate else { return false }
            return completedDate >= sevenDaysAgo
        }

        // Count sets by muscle group
        var muscleGroupSets: [String: Int] = [:]

        for workout in recentWorkouts {
            for exercise in workout.exercises {
                // Count only completed sets (hard sets)
                let hardSets = exercise.sets.filter { $0.isCompleted }.count

                // Add to each muscle group this exercise targets
                for muscleGroup in exercise.muscleGroups {
                    muscleGroupSets[muscleGroup, default: 0] += hardSets
                }
            }
        }

        // Get user's targets
        let targets = user.getMuscleGroupTargets()

        // Build volume objects for each muscle group
        return targets.compactMap { (groupName, target) -> MuscleGroupVolume? in
            let sets = muscleGroupSets[groupName] ?? 0

            // Only include muscle groups that have targets or completed sets
            guard target > 0 || sets > 0 else { return nil }

            // Map to color based on muscle group
            let color = switch groupName {
            case "Chest": "blue"
            case "Back": "green"
            case "Shoulders": "orange"
            case "Biceps": "purple"
            case "Triceps": "pink"
            case "Quads": "red"
            case "Hamstrings": "orange"
            case "Glutes": "pink"
            case "Calves": "indigo"
            case "Core": "yellow"
            default: "gray"
            }

            return MuscleGroupVolume(
                name: groupName,
                sets: sets,
                target: target,
                color: color
            )
        }
    }

    func getHardSetsForMuscleGroup(_ muscleGroup: String, user: User, days: Int) async throws -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentWorkouts = user.workouts.filter { workout in
            guard let completedDate = workout.completedDate else { return false }
            return completedDate >= cutoffDate
        }

        var totalSets = 0

        for workout in recentWorkouts {
            for exercise in workout.exercises {
                if exercise.muscleGroups.contains(muscleGroup) {
                    totalSets += exercise.sets.filter { $0.isCompleted }.count
                }
            }
        }

        return totalSets
    }

    // MARK: - AI Configuration Methods

    func updateTargets(_ targets: [String: Int], for user: User) async throws {
        // Update user's muscle group targets
        user.muscleGroupTargets = targets

        AppLogger.info(
            "Updated muscle group targets for user: \(targets)",
            category: .data
        )
    }

    func getRecommendedVolumes(goals: [String], currentFitness: String, experience: String) async throws -> [String: Int] {
        // Base recommendations based on experience level
        let baseVolumes: [String: Int]

        switch experience.lowercased() {
        case "beginner":
            baseVolumes = [
                "Chest": 8,
                "Back": 8,
                "Shoulders": 6,
                "Biceps": 4,
                "Triceps": 4,
                "Quads": 8,
                "Hamstrings": 6,
                "Glutes": 6,
                "Calves": 4,
                "Core": 6
            ]
        case "intermediate":
            baseVolumes = [
                "Chest": 12,
                "Back": 14,
                "Shoulders": 10,
                "Biceps": 8,
                "Triceps": 8,
                "Quads": 10,
                "Hamstrings": 8,
                "Glutes": 8,
                "Calves": 6,
                "Core": 8
            ]
        case "advanced":
            baseVolumes = [
                "Chest": 16,
                "Back": 18,
                "Shoulders": 14,
                "Biceps": 12,
                "Triceps": 12,
                "Quads": 14,
                "Hamstrings": 10,
                "Glutes": 10,
                "Calves": 8,
                "Core": 10
            ]
        default:
            // Default to intermediate
            baseVolumes = [
                "Chest": 12,
                "Back": 14,
                "Shoulders": 10,
                "Biceps": 8,
                "Triceps": 8,
                "Quads": 10,
                "Hamstrings": 8,
                "Glutes": 8,
                "Calves": 6,
                "Core": 8
            ]
        }

        // Adjust based on goals
        var adjustedVolumes = baseVolumes

        for goal in goals {
            switch goal.lowercased() {
            case let g where g.contains("strength"):
                // Lower volume, higher intensity for strength
                adjustedVolumes = adjustedVolumes.mapValues { Int(Double($0) * 0.8) }

            case let g where g.contains("hypertrophy") || g.contains("muscle"):
                // Higher volume for muscle building
                adjustedVolumes = adjustedVolumes.mapValues { Int(Double($0) * 1.2) }

            case let g where g.contains("upper"):
                // Emphasize upper body
                adjustedVolumes["Chest"] = Int(Double(adjustedVolumes["Chest"] ?? 0) * 1.3)
                adjustedVolumes["Back"] = Int(Double(adjustedVolumes["Back"] ?? 0) * 1.3)
                adjustedVolumes["Shoulders"] = Int(Double(adjustedVolumes["Shoulders"] ?? 0) * 1.2)
                adjustedVolumes["Biceps"] = Int(Double(adjustedVolumes["Biceps"] ?? 0) * 1.2)
                adjustedVolumes["Triceps"] = Int(Double(adjustedVolumes["Triceps"] ?? 0) * 1.2)

            case let g where g.contains("lower") || g.contains("legs"):
                // Emphasize lower body
                adjustedVolumes["Quads"] = Int(Double(adjustedVolumes["Quads"] ?? 0) * 1.3)
                adjustedVolumes["Hamstrings"] = Int(Double(adjustedVolumes["Hamstrings"] ?? 0) * 1.3)
                adjustedVolumes["Glutes"] = Int(Double(adjustedVolumes["Glutes"] ?? 0) * 1.3)
                adjustedVolumes["Calves"] = Int(Double(adjustedVolumes["Calves"] ?? 0) * 1.2)

            case let g where g.contains("athletic") || g.contains("performance"):
                // Balanced with emphasis on functional muscles
                adjustedVolumes["Core"] = Int(Double(adjustedVolumes["Core"] ?? 0) * 1.5)
                adjustedVolumes["Glutes"] = Int(Double(adjustedVolumes["Glutes"] ?? 0) * 1.3)
                adjustedVolumes["Back"] = Int(Double(adjustedVolumes["Back"] ?? 0) * 1.2)

            default:
                break
            }
        }

        // Ensure minimum volumes (at least 4 sets per week)
        adjustedVolumes = adjustedVolumes.mapValues { max($0, 4) }

        return adjustedVolumes
    }
}
