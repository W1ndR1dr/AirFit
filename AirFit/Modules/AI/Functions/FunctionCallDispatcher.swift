import SwiftData
import Foundation

// MARK: - Function Context & Results

struct FunctionContext: @unchecked Sendable {
    let modelContext: ModelContext
    let conversationId: UUID
    let userId: UUID
    let timestamp = Date()
}

struct FunctionExecutionResult: Sendable {
    let success: Bool
    let message: String
    let data: [String: SendableValue]?
    let executionTimeMs: Int
    let functionName: String

    init(success: Bool, message: String, data: [String: Any]? = nil, executionTimeMs: Int, functionName: String) {
        self.success = success
        self.message = message
        self.data = data?.mapValues { SendableValue($0) }
        self.executionTimeMs = executionTimeMs
        self.functionName = functionName
    }
}

// Sendable wrapper for Any values
enum SendableValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([SendableValue])
    case dictionary([String: SendableValue])
    case null

    init(_ value: Any) {
        switch value {
        case let str as String:
            self = .string(str)
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
        case let bool as Bool:
            self = .bool(bool)
        case let array as [Any]:
            self = .array(array.map { SendableValue($0) })
        case let dict as [String: Any]:
            self = .dictionary(dict.mapValues { SendableValue($0) })
        default:
            self = .null
        }
    }

    var anyValue: Any {
        switch self {
        case .string(let str): return str
        case .int(let int): return int
        case .double(let double): return double
        case .bool(let bool): return bool
        case .array(let array): return array.map { $0.anyValue }
        case .dictionary(let dict): return dict.mapValues { $0.anyValue }
        case .null: return NSNull()
        }
    }
}

// MARK: - Service Protocols (Mock Implementations)

protocol WorkoutServiceProtocol: Sendable {
    func generatePlan(
        for user: User,
        goal: String,
        duration: Int,
        intensity: String,
        targetMuscles: [String],
        equipment: [String],
        constraints: String?,
        style: String
    ) async throws -> WorkoutPlanResult
}

protocol AIFunctionNutritionServiceProtocol: Sendable {
    func parseAndLogMeal(
        _ input: String,
        type: String,
        date: Date,
        confidenceThreshold: Double,
        includeAlternatives: Bool,
        for user: User
    ) async throws -> NutritionLogResult
}

protocol AnalyticsServiceProtocol: Sendable {
    func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult
}

protocol GoalServiceProtocol: Sendable {
    func createOrRefineGoal(
        current: String?,
        aspirations: String,
        timeframe: String?,
        fitnessLevel: String?,
        constraints: [String],
        motivations: [String],
        goalType: String?,
        for user: User
    ) async throws -> GoalResult
}

protocol EducationServiceProtocol: Sendable {
    func generateEducationalContent(
        topic: String,
        userContext: String,
        knowledgeLevel: String,
        contentDepth: String,
        outputFormat: String,
        includeActionItems: Bool,
        relateToUserData: Bool,
        for user: User
    ) async throws -> EducationalContentResult
}

// MARK: - Result Types

struct WorkoutPlanResult {
    let id: UUID
    let exercises: [ExerciseInfo]
    let estimatedCalories: Int
    let estimatedDuration: Int
    let summary: String

    struct ExerciseInfo {
        let name: String
        let sets: Int
        let reps: String
        let restSeconds: Int
        let muscleGroups: [String]
    }
}

struct NutritionLogResult {
    let id: UUID
    let items: [FoodItemInfo]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let confidence: Double
    let alternatives: [String]?

    struct FoodItemInfo {
        let name: String
        let quantity: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
    }
}

struct PerformanceAnalysisResult {
    let summary: String
    let insights: [String]
    let trends: [TrendInfo]
    let recommendations: [String]
    let dataPoints: Int

    struct TrendInfo {
        let metric: String
        let direction: String
        let magnitude: Double
        let significance: String
    }
}

struct GoalResult {
    let id: UUID
    let title: String
    let description: String
    let targetDate: Date?
    let metrics: [String]
    let milestones: [String]
    let smartCriteria: SMARTCriteria

    struct SMARTCriteria {
        let specific: String
        let measurable: String
        let achievable: String
        let relevant: String
        let timeBound: String
    }
}

struct EducationalContentResult {
    let topic: String
    let content: String
    let keyPoints: [String]
    let actionItems: [String]
    let relatedTopics: [String]
    let sources: [String]
}

// MARK: - Function Call Dispatcher

final class FunctionCallDispatcher: @unchecked Sendable {

    // MARK: - Dependencies
    private let workoutService: WorkoutServiceProtocol
    private let nutritionService: AIFunctionNutritionServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let goalService: GoalServiceProtocol
    private let educationService: EducationServiceProtocol

    // MARK: - Performance Tracking (Optimized)
    private let metricsQueue = DispatchQueue(label: "com.airfit.function-metrics", attributes: .concurrent)
    private var _functionMetrics: [String: FunctionMetrics] = [:]

    // Pre-allocated formatters for performance
    private let intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // Function name lookup table for O(1) dispatch
    private let functionDispatchTable: [String: @Sendable (FunctionCallDispatcher, [String: AIAnyCodable], User, FunctionContext) async throws -> (message: String, data: [String: Any])]

    private struct FunctionMetrics {
        var totalCalls: Int = 0
        var totalExecutionTime: TimeInterval = 0
        var successCount: Int = 0
        var errorCount: Int = 0

        var averageExecutionTime: TimeInterval {
            totalCalls > 0 ? totalExecutionTime / Double(totalCalls) : 0
        }

        var successRate: Double {
            totalCalls > 0 ? Double(successCount) / Double(totalCalls) : 0
        }
    }

    // MARK: - Initialization
    init(
        workoutService: WorkoutServiceProtocol = MockWorkoutService(),
        nutritionService: AIFunctionNutritionServiceProtocol = MockNutritionService(),
        analyticsService: AnalyticsServiceProtocol = MockAnalyticsService(),
        goalService: GoalServiceProtocol = MockGoalService(),
        educationService: EducationServiceProtocol = MockEducationService()
    ) {
        self.workoutService = workoutService
        self.nutritionService = nutritionService
        self.analyticsService = analyticsService
        self.goalService = goalService
        self.educationService = educationService

        // Pre-build dispatch table for O(1) function lookup
        self.functionDispatchTable = [
            "generatePersonalizedWorkoutPlan": { dispatcher, args, user, context in
                try await dispatcher.executeWorkoutPlan(args, for: user, context: context)
            },
            "adaptPlanBasedOnFeedback": { dispatcher, args, user, context in
                try await dispatcher.executeAdaptPlan(args, for: user, context: context)
            },
            "parseAndLogComplexNutrition": { dispatcher, args, user, context in
                try await dispatcher.executeNutritionLogging(args, for: user, context: context)
            },
            "analyzePerformanceTrends": { dispatcher, args, user, context in
                try await dispatcher.executePerformanceAnalysis(args, for: user, context: context)
            },
            "assistGoalSettingOrRefinement": { dispatcher, args, user, context in
                try await dispatcher.executeGoalSetting(args, for: user, context: context)
            },
            "generateEducationalInsight": { dispatcher, args, user, context in
                try await dispatcher.executeEducationalContent(args, for: user, context: context)
            }
        ]
    }

    // MARK: - Public Methods

    func execute(
        _ call: AIFunctionCall,
        for user: User,
        context: FunctionContext
    ) async throws -> FunctionExecutionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        AppLogger.info("Executing function: \(call.name)", category: .ai)

        do {
            let result = try await executeFunction(call, for: user, context: context)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime

            // Update metrics
            updateMetrics(for: call.name, executionTime: executionTime, success: true)

            let executionTimeMs = Int(executionTime * 1_000)
            AppLogger.info(
                "Function \(call.name) completed in \(executionTimeMs)ms",
                category: .ai
            )

            return FunctionExecutionResult(
                success: true,
                message: result.message,
                data: result.data,
                executionTimeMs: executionTimeMs,
                functionName: call.name
            )

        } catch {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime

            // Update metrics
            updateMetrics(for: call.name, executionTime: executionTime, success: false)

            let executionTimeMs = Int(executionTime * 1_000)
            AppLogger.error(
                "Function \(call.name) failed after \(executionTimeMs)ms",
                error: error,
                category: .ai
            )

            let errorMessage = handleError(error, functionName: call.name)

            return FunctionExecutionResult(
                success: false,
                message: errorMessage,
                data: ["error": error.localizedDescription],
                executionTimeMs: executionTimeMs,
                functionName: call.name
            )
        }
    }

    func getMetrics() -> [String: Any] {
        return metricsQueue.sync {
            return _functionMetrics.mapValues { metrics in
                [
                    "totalCalls": metrics.totalCalls,
                    "averageExecutionTimeMs": Int(metrics.averageExecutionTime * 1_000),
                    "successRate": metrics.successRate,
                    "errorCount": metrics.errorCount
                ]
            }
        }
    }

    // MARK: - Private Methods

    private func executeFunction(
        _ call: AIFunctionCall,
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        // O(1) function dispatch using lookup table
        guard let handler = functionDispatchTable[call.name] else {
            throw FunctionError.unknownFunction(call.name)
        }

        return try await handler(self, call.arguments, user, context)
    }

    // MARK: - Function Implementations

    private func executeWorkoutPlan(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        let goalFocus = extractString(from: args["goalFocus"]) ?? "general_fitness"
        let duration = extractInt(from: args["durationMinutes"]) ?? 45
        let intensity = extractString(from: args["intensityPreference"]) ?? "moderate"
        let muscleGroups = extractStringArray(from: args["targetMuscleGroups"]) ?? ["full_body"]
        let equipment = extractStringArray(from: args["availableEquipment"]) ?? ["bodyweight"]
        let constraints = extractString(from: args["constraints"])
        let style = extractString(from: args["workoutStyle"]) ?? "traditional_sets"

        let plan = try await workoutService.generatePlan(
            for: user,
            goal: goalFocus,
            duration: duration,
            intensity: intensity,
            targetMuscles: muscleGroups,
            equipment: equipment,
            constraints: constraints,
            style: style
        )

        // Optimized string building - avoid repeated interpolation
        let muscleGroupsText = muscleGroups.joined(separator: ", ")
        let exerciseCount = plan.exercises.count
        let calories = plan.estimatedCalories

        let message = "Created a personalized \(duration)-minute \(goalFocus) workout targeting \(muscleGroupsText). The workout includes \(exerciseCount) exercises and is estimated to burn \(calories) calories."

        // Pre-allocate exercise array capacity for better performance
        var exerciseData: [[String: Any]] = []
        exerciseData.reserveCapacity(exerciseCount)

        for exercise in plan.exercises {
            exerciseData.append([
                "name": exercise.name,
                "sets": exercise.sets,
                "reps": exercise.reps,
                "restSeconds": exercise.restSeconds,
                "muscleGroups": exercise.muscleGroups
            ])
        }

        let data: [String: Any] = [
            "planId": plan.id.uuidString,
            "exerciseCount": exerciseCount,
            "estimatedCalories": calories,
            "estimatedDuration": plan.estimatedDuration,
            "exercises": exerciseData,
            "summary": plan.summary
        ]

        return (message, data)
    }

    private func executeAdaptPlan(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        // Fix the nested AIAnyCodable extraction bug
        let feedback = extractString(from: args["userFeedback"]) ?? ""
        let adaptationType = extractString(from: args["adaptationType"]) ?? "moderate_adjustment"
        let concern = extractString(from: args["specificConcern"])
        let urgency = extractString(from: args["urgencyLevel"]) ?? "gradual"
        let maintainGoals = extractBool(from: args["maintainGoals"]) ?? true

        // Mock adaptation logic
        let adaptationSummary = generateAdaptationSummary(
            feedback: feedback,
            type: adaptationType,
            concern: concern,
            urgency: urgency
        )

        let message = """
        I've adapted your plan based on your feedback: "\(feedback)".
        \(adaptationSummary) The changes will be implemented \(urgency == "immediate" ? "in your next workout" : "gradually over the next few sessions").
        """

        let data: [String: Any] = [
            "adaptationType": adaptationType,
            "urgencyLevel": urgency,
            "maintainGoals": maintainGoals,
            "changes": [
                "intensity": adaptationType.contains("intensity") ? "adjusted" : "maintained",
                "focus": adaptationType.contains("focus") ? "shifted" : "maintained",
                "variety": adaptationType.contains("variety") ? "increased" : "maintained"
            ],
            "summary": adaptationSummary
        ]

        return (message, data)
    }

    private func executeNutritionLogging(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        let input = extractString(from: args["naturalLanguageInput"]) ?? ""
        let mealType = extractString(from: args["mealType"]) ?? "snack"
        let timestamp = extractString(from: args["timestamp"])
        let confidenceThreshold = extractDouble(from: args["confidenceThreshold"]) ?? 0.7
        let includeAlternatives = extractBool(from: args["includeAlternatives"]) ?? false

        let date = timestamp.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()

        let result = try await nutritionService.parseAndLogMeal(
            input,
            type: mealType,
            date: date,
            confidenceThreshold: confidenceThreshold,
            includeAlternatives: includeAlternatives,
            for: user
        )

        // Cache rounded values to avoid repeated Int() calls
        let itemCount = result.items.count
        let calories = Int(result.totalCalories)
        let protein = Int(result.totalProtein)
        let carbs = Int(result.totalCarbs)
        let fat = Int(result.totalFat)

        let message = "Successfully logged \(itemCount) food items for \(mealType): \(calories) calories, \(protein)g protein, \(carbs)g carbs, \(fat)g fat."

        // Pre-allocate items array
        var itemsData: [[String: Any]] = []
        itemsData.reserveCapacity(itemCount)

        for item in result.items {
            itemsData.append([
                "name": item.name,
                "quantity": item.quantity,
                "calories": item.calories,
                "protein": item.protein,
                "carbs": item.carbs,
                "fat": item.fat
            ])
        }

        var data: [String: Any] = [
            "entryId": result.id.uuidString,
            "itemCount": itemCount,
            "totalCalories": result.totalCalories,
            "totalProtein": result.totalProtein,
            "totalCarbs": result.totalCarbs,
            "totalFat": result.totalFat,
            "confidence": result.confidence,
            "items": itemsData
        ]

        if let alternatives = result.alternatives {
            data["alternatives"] = alternatives
        }

        return (message, data)
    }

    private func executePerformanceAnalysis(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        let query = extractString(from: args["analysisQuery"]) ?? ""
        let metrics = extractStringArray(from: args["metricsToAnalyze"]) ?? ["workout_volume", "energy_levels"]
        let days = extractInt(from: args["timePeriodDays"]) ?? 30
        let depth = extractString(from: args["analysisDepth"]) ?? "standard_analysis"
        let includeRecommendations = extractBool(from: args["includeRecommendations"]) ?? true

        let result = try await analyticsService.analyzePerformance(
            query: query,
            metrics: metrics,
            days: days,
            depth: depth,
            includeRecommendations: includeRecommendations,
            for: user
        )

        let message = """
        Analysis complete for the past \(days) days. \(result.summary)
        Found \(result.insights.count) key insights and \(result.trends.count) significant trends.
        """

        let data: [String: Any] = [
            "analysisQuery": query,
            "timePeriod": days,
            "dataPoints": result.dataPoints,
            "summary": result.summary,
            "insights": result.insights,
            "trends": result.trends.map { trend in
                [
                    "metric": trend.metric,
                    "direction": trend.direction,
                    "magnitude": trend.magnitude,
                    "significance": trend.significance
                ]
            },
            "recommendations": result.recommendations
        ]

        return (message, data)
    }

    private func executeGoalSetting(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        let currentGoal = extractString(from: args["currentGoal"])
        let aspirations = extractString(from: args["aspirations"]) ?? ""
        let timeframe = extractString(from: args["timeframe"])
        let fitnessLevel = extractString(from: args["currentFitnessLevel"])
        let constraints = extractStringArray(from: args["constraints"]) ?? []
        let motivations = extractStringArray(from: args["motivationFactors"]) ?? []
        let goalType = extractString(from: args["goalType"])

        let result = try await goalService.createOrRefineGoal(
            current: currentGoal,
            aspirations: aspirations,
            timeframe: timeframe,
            fitnessLevel: fitnessLevel,
            constraints: constraints,
            motivations: motivations,
            goalType: goalType,
            for: user
        )

        let message = """
        Created SMART goal: "\(result.title)".
        This goal is specific, measurable, and tailored to your \(fitnessLevel ?? "current") fitness level.
        I've identified \(result.milestones.count) key milestones to track your progress.
        """

        let data: [String: Any] = [
            "goalId": result.id.uuidString,
            "title": result.title,
            "description": result.description,
            "targetDate": result.targetDate?.ISO8601Format() ?? "",
            "metrics": result.metrics,
            "milestones": result.milestones,
            "smartCriteria": [
                "specific": result.smartCriteria.specific,
                "measurable": result.smartCriteria.measurable,
                "achievable": result.smartCriteria.achievable,
                "relevant": result.smartCriteria.relevant,
                "timeBound": result.smartCriteria.timeBound
            ]
        ]

        return (message, data)
    }

    private func executeEducationalContent(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext
    ) async throws -> (message: String, data: [String: Any]) {

        let topic = extractString(from: args["topic"]) ?? "general_fitness"
        let userContext = extractString(from: args["userContext"]) ?? ""
        let knowledgeLevel = extractString(from: args["knowledgeLevel"]) ?? "intermediate"
        let contentDepth = extractString(from: args["contentDepth"]) ?? "detailed_explanation"
        let outputFormat = extractString(from: args["outputFormat"]) ?? "conversational"
        let includeActionItems = extractBool(from: args["includeActionItems"]) ?? true
        let relateToUserData = extractBool(from: args["relateToUserData"]) ?? true

        let result = try await educationService.generateEducationalContent(
            topic: topic,
            userContext: userContext,
            knowledgeLevel: knowledgeLevel,
            contentDepth: contentDepth,
            outputFormat: outputFormat,
            includeActionItems: includeActionItems,
            relateToUserData: relateToUserData,
            for: user
        )

        let message = """
        Here's what you need to know about \(topic.replacingOccurrences(of: "_", with: " ")):
        \(result.content.prefix(200))...
        """

        let data: [String: Any] = [
            "topic": topic,
            "knowledgeLevel": knowledgeLevel,
            "contentDepth": contentDepth,
            "content": result.content,
            "keyPoints": result.keyPoints,
            "actionItems": result.actionItems,
            "relatedTopics": result.relatedTopics,
            "sources": result.sources
        ]

        return (message, data)
    }

    // MARK: - Helper Methods

    private func generateAdaptationSummary(
        feedback: String,
        type: String,
        concern: String?,
        urgency: String
    ) -> String {
        switch type {
        case "reduce_intensity":
            return "I've reduced the workout intensity to better match your current energy levels."
        case "increase_intensity":
            return "I've increased the challenge level to help you progress faster."
        case "change_focus":
            return "I've shifted the workout focus to address your specific needs."
        case "add_variety":
            return "I've added new exercises to keep your workouts engaging and prevent plateaus."
        case "recovery_focus":
            return "I've emphasized recovery and mobility work to help you feel better."
        case "time_adjustment":
            return "I've adjusted the workout duration to fit your schedule better."
        case "equipment_swap":
            return "I've modified exercises to work with your available equipment."
        case "injury_accommodation":
            return "I've adapted the plan to work around your injury while maintaining progress."
        default:
            return "I've made adjustments to better align with your feedback and goals."
        }
    }

    private func updateMetrics(for functionName: String, executionTime: TimeInterval, success: Bool) {
        metricsQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // Use modify-in-place pattern for better performance
            if self._functionMetrics[functionName] != nil {
                self._functionMetrics[functionName]!.totalCalls += 1
                self._functionMetrics[functionName]!.totalExecutionTime += executionTime

                if success {
                    self._functionMetrics[functionName]!.successCount += 1
                } else {
                    self._functionMetrics[functionName]!.errorCount += 1
                }
            } else {
                // First call for this function
                var newMetrics = FunctionMetrics()
                newMetrics.totalCalls = 1
                newMetrics.totalExecutionTime = executionTime

                if success {
                    newMetrics.successCount = 1
                } else {
                    newMetrics.errorCount = 1
                }

                self._functionMetrics[functionName] = newMetrics
            }
        }
    }

    private func handleError(_ error: Error, functionName: String) -> String {
        switch error {
        case FunctionError.unknownFunction(let name):
            return "I don't recognize the function '\(name)'. This might be a system error."

        case FunctionError.invalidArguments:
            return "The request had invalid parameters. Let me try a different approach."

        case FunctionError.serviceUnavailable:
            return "The service is temporarily unavailable. Please try again in a moment."

        case FunctionError.dataNotFound:
            return "I couldn't find the data needed for this analysis. Try asking about a different time period."

        case FunctionError.processingTimeout:
            return "This request is taking longer than expected. Let me try a simpler approach."

        default:
            return "I encountered an issue while processing your request. Let me try to help you in a different way."
        }
    }

    // MARK: - Helper Methods for AIAnyCodable Extraction

    private func extractString(from anyCodable: AIAnyCodable?) -> String? {
        guard let anyCodable = anyCodable else { return nil }

        // Handle nested AIAnyCodable
        if let nestedAnyCodable = anyCodable.value as? AIAnyCodable {
            return nestedAnyCodable.value as? String
        }

        // Handle direct value
        return anyCodable.value as? String
    }

    private func extractInt(from anyCodable: AIAnyCodable?) -> Int? {
        guard let anyCodable = anyCodable else { return nil }

        // Handle nested AIAnyCodable
        if let nestedAnyCodable = anyCodable.value as? AIAnyCodable {
            return nestedAnyCodable.value as? Int
        }

        // Handle direct value
        return anyCodable.value as? Int
    }

    private func extractDouble(from anyCodable: AIAnyCodable?) -> Double? {
        guard let anyCodable = anyCodable else { return nil }

        // Handle nested AIAnyCodable
        if let nestedAnyCodable = anyCodable.value as? AIAnyCodable {
            return nestedAnyCodable.value as? Double
        }

        // Handle direct value
        return anyCodable.value as? Double
    }

    private func extractBool(from anyCodable: AIAnyCodable?) -> Bool? {
        guard let anyCodable = anyCodable else { return nil }

        // Handle nested AIAnyCodable
        if let nestedAnyCodable = anyCodable.value as? AIAnyCodable {
            return nestedAnyCodable.value as? Bool
        }

        // Handle direct value
        return anyCodable.value as? Bool
    }

    private func extractStringArray(from anyCodable: AIAnyCodable?) -> [String]? {
        guard let anyCodable = anyCodable else { return nil }

        // Handle nested AIAnyCodable
        if let nestedAnyCodable = anyCodable.value as? AIAnyCodable {
            return nestedAnyCodable.value as? [String]
        }

        // Handle direct value
        return anyCodable.value as? [String]
    }
}

// MARK: - Errors

enum FunctionError: LocalizedError {
    case unknownFunction(String)
    case invalidArguments
    case serviceUnavailable
    case dataNotFound
    case processingTimeout

    var errorDescription: String? {
        switch self {
        case .unknownFunction(let name):
            return "Unknown function: \(name)"
        case .invalidArguments:
            return "Invalid function arguments"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .dataNotFound:
            return "Required data not found"
        case .processingTimeout:
            return "Processing timeout"
        }
    }
}
