import Foundation
import SwiftData

/// AI Goal Service - Wraps the base GoalServiceProtocol and adds AI-specific functionality
@MainActor
final class AIGoalService: AIGoalServiceProtocol, ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "ai-goal-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For @MainActor classes, we need to return a simple value
        // The actual state is tracked in _isConfigured
        true
    }
    
    private let goalService: GoalServiceProtocol
    private let aiService: AIServiceProtocol
    private let personaService: PersonaService
    
    init(
        goalService: GoalServiceProtocol, 
        aiService: AIServiceProtocol,
        personaService: PersonaService
    ) {
        self.goalService = goalService
        self.aiService = aiService
        self.personaService = personaService
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: _isConfigured ? .healthy : .unhealthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: _isConfigured ? nil : "Service not configured",
            metadata: ["hasGoalService": "true"]
        )
    }
    
    // MARK: - AI-specific methods
    
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
        // Build AI prompt for goal refinement
        let prompt = buildGoalRefinementPrompt(
            current: current,
            aspirations: aspirations,
            timeframe: timeframe,
            fitnessLevel: fitnessLevel,
            constraints: constraints,
            motivations: motivations,
            goalType: goalType
        )
        
        // Get user's persona for consistent coaching voice
        let persona = try await personaService.getActivePersona(for: user.id)
        
        // Create AI request with persona's system prompt
        let request = AIRequest(
            systemPrompt: persona.systemPrompt,
            messages: [
                AIChatMessage(
                    role: .system,
                    content: "Task context: Helping refine fitness goals using SMART criteria. Focus on specific, measurable, achievable, relevant, and time-bound objectives."
                ),
                AIChatMessage(
                    role: .user,
                    content: prompt
                )
            ],
            temperature: 0.7,
            stream: false,
            user: user.id.uuidString
        )
        
        // Send request and collect response
        var fullResponse = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                fullResponse = text
            case .textDelta(let delta):
                fullResponse += delta
            case .done:
                break
            default:
                continue
            }
        }
        
        // Parse the AI response into a structured goal
        return try parseGoalResponse(fullResponse, deadline: calculateDeadline(from: timeframe))
    }
    
    func suggestGoalAdjustments(
        for goal: TrackedGoal,
        user: User
    ) async throws -> [GoalAdjustment] {
        // Build AI prompt for goal adjustment analysis
        let prompt = buildGoalAdjustmentPrompt(goal: goal)
        
        // Get user's persona for consistent coaching voice
        let persona = try await personaService.getActivePersona(for: user.id)
        
        // Create AI request with persona's system prompt
        let request = AIRequest(
            systemPrompt: persona.systemPrompt,
            messages: [
                AIChatMessage(
                    role: .system,
                    content: "Task context: Analyzing goal progress and providing actionable adjustments. Be encouraging and practical."
                ),
                AIChatMessage(
                    role: .user,
                    content: prompt
                )
            ],
            temperature: 0.7,
            stream: false,
            user: user.id.uuidString
        )
        
        // Send request and collect response
        var fullResponse = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                fullResponse = text
            case .textDelta(let delta):
                fullResponse += delta
            case .done:
                break
            default:
                continue
            }
        }
        
        // Parse the AI response into structured adjustments
        return try parseAdjustmentsResponse(fullResponse)
    }
    
    // MARK: - GoalServiceProtocol forwarding
    
    func createGoal(_ goal: TrackedGoal) async throws {
        try await goalService.createGoal(goal)
    }
    
    func updateGoal(_ goal: TrackedGoal) async throws {
        try await goalService.updateGoal(goal)
    }
    
    func deleteGoal(_ goal: TrackedGoal) async throws {
        try await goalService.deleteGoal(goal)
    }
    
    func completeGoal(_ goal: TrackedGoal) async throws {
        try await goalService.completeGoal(goal)
    }
    
    func getActiveGoals(for userId: UUID) async throws -> [TrackedGoal] {
        try await goalService.getActiveGoals(for: userId)
    }
    
    func getAllGoals(for userId: UUID) async throws -> [TrackedGoal] {
        try await goalService.getAllGoals(for: userId)
    }
    
    func getGoal(by id: UUID) async throws -> TrackedGoal? {
        try await goalService.getGoal(by: id)
    }
    
    func updateProgress(for goalId: UUID, progress: Double) async throws {
        try await goalService.updateProgress(for: goalId, progress: progress)
    }
    
    func recordMilestone(for goalId: UUID, milestone: TrackedGoalMilestone) async throws {
        try await goalService.recordMilestone(for: goalId, milestone: milestone)
    }
    
    func getGoalsContext(for userId: UUID) async throws -> GoalsContext {
        try await goalService.getGoalsContext(for: userId)
    }
    
    func getGoalStatistics(for userId: UUID) async throws -> GoalStatistics {
        try await goalService.getGoalStatistics(for: userId)
    }
    
    // MARK: - Private Helpers
    
    private func mapGoalTypeToCategory(_ goalType: String?) -> TrackedGoalCategory {
        guard let goalType = goalType else { return .fitness }
        
        switch goalType.lowercased() {
        case "nutrition", "diet":
            return .nutrition
        case "wellness", "health":
            return .wellness
        case "recovery", "rest":
            return .recovery
        case "mindfulness", "mental":
            return .mindfulness
        default:
            return .fitness
        }
    }
    
    private func calculateDeadline(from timeframe: String?) -> Date? {
        guard let timeframe = timeframe else {
            return Date().addingTimeInterval(30 * 24 * 60 * 60) // Default 30 days
        }
        
        // Parse timeframe string (e.g., "30 days", "3 months", "1 year")
        let components = timeframe.lowercased().split(separator: " ")
        guard components.count >= 2,
              let value = Int(components[0]) else {
            return Date().addingTimeInterval(30 * 24 * 60 * 60)
        }
        
        let unit = String(components[1])
        let calendar = Calendar.current
        
        switch unit {
        case "day", "days":
            return calendar.date(byAdding: .day, value: value, to: Date())
        case "week", "weeks":
            return calendar.date(byAdding: .weekOfYear, value: value, to: Date())
        case "month", "months":
            return calendar.date(byAdding: .month, value: value, to: Date())
        case "year", "years":
            return calendar.date(byAdding: .year, value: value, to: Date())
        default:
            return Date().addingTimeInterval(30 * 24 * 60 * 60)
        }
    }
    
    private func generateMetrics(for aspirations: String, goalType: String?) -> [GoalMetric] {
        // Generate relevant metrics based on goal type
        var metrics: [GoalMetric] = []
        
        if aspirations.lowercased().contains("weight") {
            metrics.append(GoalMetric(
                name: "Body Weight",
                currentValue: 0,
                targetValue: 0,
                unit: "lbs"
            ))
        }
        
        if aspirations.lowercased().contains("strength") {
            metrics.append(GoalMetric(
                name: "Total Weight Lifted",
                currentValue: 0,
                targetValue: 0,
                unit: "lbs/week"
            ))
        }
        
        if aspirations.lowercased().contains("run") || aspirations.lowercased().contains("cardio") {
            metrics.append(GoalMetric(
                name: "Weekly Distance",
                currentValue: 0,
                targetValue: 0,
                unit: "miles"
            ))
        }
        
        return metrics
    }
    
    private func generateMilestones(for aspirations: String, deadline: Date?) -> [GoalMilestone] {
        guard let deadline = deadline else { return [] }
        
        let totalDays = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 30
        var milestones: [GoalMilestone] = []
        
        // Create 3 milestones at 25%, 50%, and 75% of timeline
        let intervals = [0.25, 0.5, 0.75]
        
        for (index, interval) in intervals.enumerated() {
            let daysToMilestone = Int(Double(totalDays) * interval)
            let milestoneDate = Calendar.current.date(byAdding: .day, value: daysToMilestone, to: Date()) ?? Date()
            
            milestones.append(GoalMilestone(
                title: "Milestone \(index + 1)",
                targetDate: milestoneDate,
                criteria: "\(Int(interval * 100))% progress achieved",
                reward: nil
            ))
        }
        
        return milestones
    }
    
    // MARK: - AI Helper Methods
    
    private func buildGoalRefinementPrompt(
        current: String?,
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        constraints: [String],
        motivations: [String],
        goalType: String?
    ) -> String {
        var prompt = """
        Help me create a SMART fitness goal based on the following information:
        
        Aspiration: \(aspirations)
        """
        
        if let current = current {
            prompt += "\nCurrent goal: \(current)"
        }
        
        if let timeframe = timeframe {
            prompt += "\nTimeframe: \(timeframe)"
        }
        
        if let fitnessLevel = fitnessLevel {
            prompt += "\nFitness level: \(fitnessLevel)"
        }
        
        if !constraints.isEmpty {
            prompt += "\nConstraints: \(constraints.joined(separator: ", "))"
        }
        
        if !motivations.isEmpty {
            prompt += "\nMotivations: \(motivations.joined(separator: ", "))"
        }
        
        if let goalType = goalType {
            prompt += "\nGoal type: \(goalType)"
        }
        
        prompt += """
        
        
        Please create a refined SMART goal with the following structure in JSON format:
        {
            "title": "Clear, concise goal title",
            "description": "Detailed description of what success looks like",
            "metrics": [
                {
                    "name": "Metric name",
                    "targetValue": 100,
                    "unit": "unit of measurement",
                    "currentValue": 0
                }
            ],
            "milestones": [
                {
                    "title": "Milestone title",
                    "daysFromNow": 7,
                    "criteria": "What must be achieved",
                    "reward": "Optional reward"
                }
            ],
            "smartCriteria": {
                "specific": "What exactly will be accomplished",
                "measurable": "How progress will be measured",
                "achievable": "Why this is realistic given constraints",
                "relevant": "How this aligns with motivations",
                "timeBound": "Clear timeline with deadlines"
            }
        }
        """
        
        return prompt
    }
    
    private func buildGoalAdjustmentPrompt(goal: TrackedGoal) -> String {
        let progress = goal.progressPercentage
        let daysRemaining = goal.daysRemaining ?? 0
        let isOnTrack = goal.isOnTrack
        
        return """
        Analyze this fitness goal and suggest adjustments:
        
        Goal: \(goal.title)
        Target: \(goal.targetValue ?? "0") \(goal.targetUnit ?? "")
        Current: \(String(format: "%.1f", goal.currentProgress)) \(goal.progressUnit ?? "")
        Progress: \(progress)%
        Days remaining: \(daysRemaining)
        On track: \(isOnTrack)
        
        Based on the current progress trajectory, provide 0-3 adjustments in JSON format:
        [
            {
                "type": "timeline|target|approach|intensity",
                "reason": "Clear explanation of why this adjustment is needed",
                "suggestedChange": "Specific change to make",
                "impact": "Expected outcome of this adjustment"
            }
        ]
        
        Only suggest adjustments if they would significantly improve the user's chances of success or help them optimize their efforts.
        """
    }
    
    private func parseGoalResponse(_ response: String, deadline: Date?) throws -> GoalResult {
        // Try to extract JSON from the response
        let jsonPattern = #"\{[\s\S]*\}"#
        guard let range = response.range(of: jsonPattern, options: .regularExpression),
              let data = String(response[range]).data(using: .utf8) else {
            throw AppError.decodingError(underlying: NSError(domain: "AIGoalService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find JSON in AI response"]))
        }
        
        // Parse JSON
        struct GoalJSON: Codable {
            let title: String
            let description: String
            let metrics: [MetricJSON]
            let milestones: [MilestoneJSON]
            let smartCriteria: SMARTCriteriaJSON
            
            struct MetricJSON: Codable {
                let name: String
                let targetValue: Double
                let unit: String
                let currentValue: Double
            }
            
            struct MilestoneJSON: Codable {
                let title: String
                let daysFromNow: Int
                let criteria: String
                let reward: String?
            }
            
            struct SMARTCriteriaJSON: Codable {
                let specific: String
                let measurable: String
                let achievable: String
                let relevant: String
                let timeBound: String
            }
        }
        
        let goalData = try JSONDecoder().decode(GoalJSON.self, from: data)
        
        // Convert to GoalResult
        let metrics = goalData.metrics.map { metric in
            GoalMetric(
                name: metric.name,
                currentValue: metric.currentValue,
                targetValue: metric.targetValue,
                unit: metric.unit
            )
        }
        
        let milestones = goalData.milestones.map { milestone in
            let milestoneDate = Calendar.current.date(
                byAdding: .day,
                value: milestone.daysFromNow,
                to: Date()
            ) ?? Date()
            
            return GoalMilestone(
                title: milestone.title,
                targetDate: milestoneDate,
                criteria: milestone.criteria,
                reward: milestone.reward
            )
        }
        
        return GoalResult(
            id: UUID(),
            title: goalData.title,
            description: goalData.description,
            targetDate: deadline,
            metrics: metrics,
            milestones: milestones,
            smartCriteria: GoalResult.SMARTCriteria(
                specific: goalData.smartCriteria.specific,
                measurable: goalData.smartCriteria.measurable,
                achievable: goalData.smartCriteria.achievable,
                relevant: goalData.smartCriteria.relevant,
                timeBound: goalData.smartCriteria.timeBound
            )
        )
    }
    
    private func parseAdjustmentsResponse(_ response: String) throws -> [GoalAdjustment] {
        // Try to extract JSON array from the response
        let jsonPattern = #"\[[\s\S]*\]"#
        guard let range = response.range(of: jsonPattern, options: .regularExpression),
              let data = String(response[range]).data(using: .utf8) else {
            // If no adjustments needed, return empty array
            return []
        }
        
        // Parse JSON
        struct AdjustmentJSON: Codable {
            let type: String
            let reason: String
            let suggestedChange: String
            let impact: String
        }
        
        let adjustments = try JSONDecoder().decode([AdjustmentJSON].self, from: data)
        
        // Convert to GoalAdjustment
        return adjustments.compactMap { json in
            guard let adjustmentType = GoalAdjustment.AdjustmentType(rawValue: json.type) else {
                AppLogger.warning("Unknown adjustment type: \(json.type)", category: .ai)
                return nil
            }
            
            return GoalAdjustment(
                type: adjustmentType,
                reason: json.reason,
                suggestedChange: json.suggestedChange,
                impact: json.impact
            )
        }
    }
}