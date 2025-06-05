import Foundation
@testable import AirFit

// MARK: - Mock AI Goal Service
// This is the AI-based goal creation and refinement service

actor MockAIGoalService: GoalServiceProtocol {

    func createOrRefineGoal(
        current: String?,
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        constraints: [String],
        motivations: [String],
        goalType: String?,
        for user: User
    ) async throws -> GoalResult {

        // Simulate goal processing time
        try await Task.sleep(nanoseconds: 250_000_000) // 250ms

        let smartGoal = createSMARTGoal(
            aspirations: aspirations,
            timeframe: timeframe,
            fitnessLevel: fitnessLevel,
            goalType: goalType
        )

        let milestones = generateMilestones(for: smartGoal.title, timeframe: timeframe)
        let metrics = generateMetrics(for: goalType ?? "performance")

        return GoalResult(
            id: UUID(),
            title: smartGoal.title,
            description: smartGoal.description,
            targetDate: parseTargetDate(from: timeframe),
            metrics: metrics,
            milestones: milestones,
            smartCriteria: smartGoal.criteria
        )
    }

    private func createSMARTGoal(
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        goalType: String?
    ) -> (title: String, description: String, criteria: GoalResult.SMARTCriteria) {

        let title = refinedGoalTitle(from: aspirations, timeframe: timeframe)
        let description = generateGoalDescription(title: title, aspirations: aspirations)

        let criteria = GoalResult.SMARTCriteria(
            specific: "Clearly defined target: \(title)",
            measurable: "Progress tracked through specific metrics and milestones",
            achievable: "Realistic based on \(fitnessLevel ?? "current") fitness level",
            relevant: "Aligned with personal aspirations: \(aspirations)",
            timeBound: timeframe ?? "Flexible timeline with regular check-ins"
        )

        return (title, description, criteria)
    }

    private func refinedGoalTitle(from aspirations: String, timeframe: String?) -> String {
        let lowercaseAspirations = aspirations.lowercased()

        if lowercaseAspirations.contains("lose") && lowercaseAspirations.contains("weight") {
            return "Achieve Healthy Weight Loss"
        } else if lowercaseAspirations.contains("muscle") || lowercaseAspirations.contains("gain") {
            return "Build Lean Muscle Mass"
        } else if lowercaseAspirations.contains("strong") {
            return "Increase Overall Strength"
        } else if lowercaseAspirations.contains("run") || lowercaseAspirations.contains("marathon") {
            return "Improve Running Performance"
        } else if lowercaseAspirations.contains("fit") {
            return "Achieve Overall Fitness"
        } else {
            return "Personalized Fitness Goal"
        }
    }

    private func generateGoalDescription(title: String, aspirations: String) -> String {
        return """
        \(title) based on your aspiration: "\(aspirations)". This goal incorporates progressive
        training principles and sustainable lifestyle changes to ensure long-term success.
        """
    }

    private func generateMilestones(for title: String, timeframe: String?) -> [String] {
        let baselineMilestones = [
            "Complete initial fitness assessment",
            "Establish consistent workout routine",
            "Achieve first measurable improvement"
        ]

        if title.contains("Weight") {
            return baselineMilestones + [
                "Lose first 5% of target weight",
                "Establish sustainable eating habits",
                "Reach halfway point to target weight"
            ]
        } else if title.contains("Strength") {
            return baselineMilestones + [
                "Increase major lift by 10%",
                "Master proper form for all exercises",
                "Achieve 25% strength improvement"
            ]
        } else if title.contains("Running") {
            return baselineMilestones + [
                "Complete first 5K without stopping",
                "Improve pace by 30 seconds per mile",
                "Build up to target distance"
            ]
        }

        return baselineMilestones + [
            "Reach intermediate fitness level",
            "Maintain consistency for 30 days",
            "Achieve target performance metrics"
        ]
    }

    private func generateMetrics(for goalType: String) -> [String] {
        switch goalType {
        case "performance":
            return ["strength_gains", "endurance_improvement", "workout_consistency"]
        case "body_composition":
            return ["body_weight", "body_fat_percentage", "muscle_mass"]
        case "health_markers":
            return ["resting_heart_rate", "blood_pressure", "sleep_quality"]
        case "lifestyle":
            return ["workout_frequency", "nutrition_adherence", "energy_levels"]
        default:
            return ["overall_fitness", "workout_consistency", "progress_satisfaction"]
        }
    }

    private func parseTargetDate(from timeframe: String?) -> Date? {
        guard let timeframe = timeframe?.lowercased() else { return nil }

        let calendar = Calendar.current
        let now = Date()

        if timeframe.contains("week") {
            if let weeks = extractNumber(from: timeframe) {
                return calendar.date(byAdding: .weekOfYear, value: weeks, to: now)
            }
            return calendar.date(byAdding: .weekOfYear, value: 12, to: now) // Default 3 months
        } else if timeframe.contains("month") {
            if let months = extractNumber(from: timeframe) {
                return calendar.date(byAdding: .month, value: months, to: now)
            }
            return calendar.date(byAdding: .month, value: 6, to: now) // Default 6 months
        } else if timeframe.contains("year") {
            return calendar.date(byAdding: .year, value: 1, to: now)
        }

        return calendar.date(byAdding: .month, value: 3, to: now) // Default 3 months
    }

    private func extractNumber(from text: String) -> Int? {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        return numbers.compactMap { Int($0) }.first
    }
}