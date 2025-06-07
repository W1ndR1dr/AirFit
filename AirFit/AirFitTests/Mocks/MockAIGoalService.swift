import Foundation
@testable import AirFit

// MARK: - Mock AI Goal Service
// This is the AI-based goal creation and refinement service

actor MockAIGoalService: AIGoalServiceProtocol {
    
    // MARK: - GoalServiceProtocol (base protocol)
    
    func createGoal(_ goalData: GoalCreationData, for user: User) async throws -> ServiceGoal {
        return ServiceGoal(
            id: UUID(),
            type: goalData.type,
            target: goalData.target,
            currentValue: 0,
            deadline: goalData.deadline,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func updateGoal(_ goal: ServiceGoal, updates: GoalUpdate) async throws {
        // Mock implementation - just acknowledge
        print("Mock: Updated goal \(goal.id)")
    }
    
    func deleteGoal(_ goal: ServiceGoal) async throws {
        // Mock implementation - just acknowledge
        print("Mock: Deleted goal \(goal.id)")
    }
    
    func getActiveGoals(for user: User) async throws -> [ServiceGoal] {
        // Return some mock goals
        return [
            ServiceGoal(
                id: UUID(),
                type: .weightLoss,
                target: 10,
                currentValue: 3,
                deadline: Date().addingTimeInterval(90 * 24 * 60 * 60),
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                updatedAt: Date()
            ),
            ServiceGoal(
                id: UUID(),
                type: .workoutFrequency,
                target: 4,
                currentValue: 2.5,
                deadline: nil,
                createdAt: Date().addingTimeInterval(-14 * 24 * 60 * 60),
                updatedAt: Date()
            )
        ]
    }
    
    func trackProgress(for goal: ServiceGoal, value: Double) async throws {
        // Mock implementation - just acknowledge
        print("Mock: Tracked progress \(value) for goal \(goal.id)")
    }
    
    func checkGoalCompletion(_ goal: ServiceGoal) async -> Bool {
        // Simple check
        return goal.currentValue >= goal.target
    }
    
    // MARK: - AIGoalServiceProtocol methods

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

    private func generateMilestones(for title: String, timeframe: String?) -> [GoalMilestone] {
        let startDate = Date()
        
        var milestones: [GoalMilestone] = []
        
        // Create baseline milestones
        milestones.append(GoalMilestone(
            title: "Complete initial fitness assessment",
            targetDate: startDate.addingTimeInterval(TimeInterval(7 * 24 * 60 * 60)),
            criteria: "Complete all baseline measurements and tests",
            reward: "Unlock personalized workout plan"
        ))
        
        milestones.append(GoalMilestone(
            title: "Establish consistent workout routine",
            targetDate: startDate.addingTimeInterval(TimeInterval(30 * 24 * 60 * 60)),
            criteria: "Complete 3+ workouts per week for 4 weeks",
            reward: "Earn consistency badge"
        ))
        
        // Add goal-specific milestones
        if title.contains("Weight") {
            milestones.append(GoalMilestone(
                title: "Lose first 5% of target weight",
                targetDate: startDate.addingTimeInterval(TimeInterval(60 * 24 * 60 * 60)),
                criteria: "Achieve 5% reduction from starting weight",
                reward: "Unlock advanced nutrition features"
            ))
        } else if title.contains("Strength") {
            milestones.append(GoalMilestone(
                title: "Increase major lift by 10%",
                targetDate: startDate.addingTimeInterval(TimeInterval(45 * 24 * 60 * 60)),
                criteria: "10% improvement in squat, deadlift, or bench press",
                reward: "Unlock strength training insights"
            ))
        } else {
            milestones.append(GoalMilestone(
                title: "Achieve first measurable improvement",
                targetDate: startDate.addingTimeInterval(TimeInterval(30 * 24 * 60 * 60)),
                criteria: "Show improvement in primary metric",
                reward: "Celebrate progress milestone"
            ))
        }
        
        return milestones
    }

    private func generateMetrics(for goalType: String) -> [GoalMetric] {
        switch goalType {
        case "performance":
            return [
                GoalMetric(name: "Strength Gains", currentValue: 100, targetValue: 125, unit: "lbs"),
                GoalMetric(name: "Endurance", currentValue: 20, targetValue: 30, unit: "minutes"),
                GoalMetric(name: "Workout Frequency", currentValue: 2, targetValue: 4, unit: "per week")
            ]
        case "body_composition":
            return [
                GoalMetric(name: "Body Weight", currentValue: 180, targetValue: 165, unit: "lbs"),
                GoalMetric(name: "Body Fat", currentValue: 25, targetValue: 18, unit: "%"),
                GoalMetric(name: "Muscle Mass", currentValue: 135, targetValue: 145, unit: "lbs")
            ]
        case "health_markers":
            return [
                GoalMetric(name: "Resting Heart Rate", currentValue: 72, targetValue: 60, unit: "bpm"),
                GoalMetric(name: "Blood Pressure", currentValue: 130, targetValue: 120, unit: "systolic"),
                GoalMetric(name: "Sleep Quality", currentValue: 6, targetValue: 8, unit: "hours")
            ]
        case "lifestyle":
            return [
                GoalMetric(name: "Workout Frequency", currentValue: 2, targetValue: 4, unit: "per week"),
                GoalMetric(name: "Nutrition Score", currentValue: 60, targetValue: 85, unit: "%"),
                GoalMetric(name: "Energy Level", currentValue: 5, targetValue: 8, unit: "/10")
            ]
        default:
            return [
                GoalMetric(name: "Fitness Score", currentValue: 50, targetValue: 75, unit: "points"),
                GoalMetric(name: "Consistency", currentValue: 40, targetValue: 90, unit: "%"),
                GoalMetric(name: "Satisfaction", currentValue: 6, targetValue: 9, unit: "/10")
            ]
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
    
    func suggestGoalAdjustments(
        for goal: ServiceGoal,
        user: User
    ) async throws -> [GoalAdjustment] {
        // Generate mock adjustments based on goal progress
        var adjustments: [GoalAdjustment] = []
        
        let progressPercentage = (goal.currentValue / goal.target) * 100
        
        if progressPercentage < 25 && goal.deadline != nil {
            adjustments.append(GoalAdjustment(
                type: .timeline,
                reason: "Current progress rate suggests more time may be needed",
                suggestedChange: "Extend deadline by 30 days",
                impact: "Increases likelihood of sustainable success"
            ))
        }
        
        if progressPercentage > 80 {
            adjustments.append(GoalAdjustment(
                type: .target,
                reason: "You're close to achieving your goal ahead of schedule",
                suggestedChange: "Consider setting a more ambitious target",
                impact: "Continue challenging yourself for better results"
            ))
        }
        
        if goal.type == .workoutFrequency && goal.currentValue < goal.target * 0.5 {
            adjustments.append(GoalAdjustment(
                type: .approach,
                reason: "Current workout frequency is below target",
                suggestedChange: "Start with shorter, more frequent sessions",
                impact: "Build consistency before increasing intensity"
            ))
        }
        
        return adjustments
    }
    
    // MARK: - Reset
    
    func reset() {
        // This is an actor, so no state to reset
        // All methods return fresh data each time
    }
}