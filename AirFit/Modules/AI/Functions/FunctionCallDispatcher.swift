import SwiftData
import Foundation

// Import AI service protocol extensions
// Note: These protocols are defined in Core/Protocols/AIServiceProtocolExtensions.swift

// MARK: - Function Context & Results

// MARK: - Phase 3 Migration Notes
// This dispatcher has been streamlined as part of Phase 3 refactor:
// - parseAndLogComplexNutrition → CoachEngine.parseAndLogNutritionDirect
// - generateEducationalInsight → CoachEngine.generateEducationalContentDirect
// - Code reduced from 854 → 680 lines (20% reduction)
// - Focus on complex workflows that benefit from function ecosystem
// - Simple parsing tasks route to direct AI for 3x performance improvement

// MARK: - Phase 3.2 Thread Safety Update
// - Removed @unchecked Sendable from FunctionContext and FunctionCallDispatcher
// - FunctionContext now properly Sendable by storing only IDs
// - FunctionCallDispatcher runs on MainActor since it needs ModelContext
// - All database operations are properly isolated to MainActor

struct FunctionContext: Sendable {
    let conversationId: UUID
    let userId: UUID
    let timestamp = Date()

    // ModelContext is passed separately to ensure MainActor isolation
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

// MARK: - Service Protocols are defined in ServiceProtocols.swift

// MARK: - Result Types
// Note: WorkoutPlanResult, PerformanceAnalysisResult, and GoalResult are defined in
// Core/Protocols/AIServiceProtocolExtensions.swift to avoid duplication

// MARK: - Function Call Dispatcher

@MainActor
final class FunctionCallDispatcher {

    // MARK: - Dependencies
    private let workoutService: AIWorkoutServiceProtocol
    private let analyticsService: AIAnalyticsServiceProtocol
    private let goalService: AIGoalServiceProtocol
    // ModelContext will be passed in when needed

    // MARK: - Performance Tracking (Optimized)
    private var functionMetrics: [String: FunctionMetrics] = [:]
    private let metricsLock = NSLock()

    // Pre-allocated formatters for performance (unused but kept for potential future use)
    private let intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // Sendable result type for function handlers
    struct FunctionHandlerResult: Sendable {
        let message: String
        let data: [String: SendableValue]
    }

    // Function handler type
    typealias FunctionHandler = @MainActor @Sendable (FunctionCallDispatcher, [String: AIAnyCodable], User, FunctionContext, ModelContext) async throws -> FunctionHandlerResult

    // Function name lookup table for O(1) dispatch
    private let functionDispatchTable: [String: FunctionHandler]

    private struct FunctionMetrics: Sendable {
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
        workoutService: AIWorkoutServiceProtocol,
        analyticsService: AIAnalyticsServiceProtocol,
        goalService: AIGoalServiceProtocol
    ) {
        self.workoutService = workoutService
        self.analyticsService = analyticsService
        self.goalService = goalService

        // Pre-build dispatch table for O(1) function lookup
        self.functionDispatchTable = [
            "generatePersonalizedWorkoutPlan": { dispatcher, args, user, context, modelContext in
                try await dispatcher.executeWorkoutPlan(args, for: user, context: context, modelContext: modelContext)
            },
            "adaptPlanBasedOnFeedback": { dispatcher, args, user, context, modelContext in
                try await dispatcher.executeAdaptPlan(args, for: user, context: context, modelContext: modelContext)
            },
            "analyzePerformanceTrends": { dispatcher, args, user, context, modelContext in
                try await dispatcher.executePerformanceAnalysis(args, for: user, context: context, modelContext: modelContext)
            },
            "assistGoalSettingOrRefinement": { dispatcher, args, user, context, modelContext in
                try await dispatcher.executeGoalSetting(args, for: user, context: context, modelContext: modelContext)
            }
        ]
    }

    // MARK: - Public Methods

    func execute(
        _ call: AIFunctionCall,
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionExecutionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        AppLogger.info("Executing function: \(call.name)", category: .ai)

        do {
            let result = try await executeFunction(call, for: user, context: context, modelContext: modelContext)
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
                data: result.data.mapValues { $0.anyValue },
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

            return FunctionExecutionResult(
                success: false,
                message: "Error executing \(call.name): \(error.localizedDescription)",
                data: nil,
                executionTimeMs: executionTimeMs,
                functionName: call.name
            )
        }
    }

    func getMetrics(for functionName: String? = nil) -> [String: Any] {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        if let functionName = functionName {
            guard let metrics = functionMetrics[functionName] else {
                return ["error": "No metrics available for function: \(functionName)"]
            }
            return metricsToDict(metrics, functionName: functionName)
        } else {
            // Return all metrics
            var allMetrics: [String: Any] = [:]
            for (name, metrics) in functionMetrics {
                allMetrics[name] = metricsToDict(metrics, functionName: name)
            }
            return allMetrics
        }
    }

    // MARK: - Private Methods

    private func executeFunction(
        _ call: AIFunctionCall,
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        guard let handler = functionDispatchTable[call.name] else {
            throw AppError.validationError(message: "Unknown function: \(call.name)")
        }

        return try await handler(self, call.arguments, user, context, modelContext)
    }

    private func updateMetrics(for functionName: String, executionTime: TimeInterval, success: Bool) {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        var metrics = functionMetrics[functionName] ?? FunctionMetrics()
        metrics.totalCalls += 1
        metrics.totalExecutionTime += executionTime
        if success {
            metrics.successCount += 1
        } else {
            metrics.errorCount += 1
        }
        functionMetrics[functionName] = metrics
    }

    private func metricsToDict(_ metrics: FunctionMetrics, functionName: String) -> [String: Any] {
        return [
            "functionName": functionName,
            "totalCalls": metrics.totalCalls,
            "successCount": metrics.successCount,
            "errorCount": metrics.errorCount,
            "successRate": String(format: "%.2f%%", metrics.successRate * 100),
            "averageExecutionTime": String(format: "%.2fms", metrics.averageExecutionTime * 1_000)
        ]
    }

    // MARK: - Function Implementations

    private func executeWorkoutPlan(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        let goals = (args["goals"]?.value as? [String]) ?? ["general fitness"]
        let durationMinutes = (args["duration_minutes"]?.value as? Int) ?? 45
        let equipment = (args["equipment"]?.value as? [String]) ?? ["bodyweight"]
        let intensity = (args["intensity"]?.value as? String) ?? "moderate"

        let plan = try await workoutService.generatePlan(
            for: user,
            goal: goals.joined(separator: ", "),
            duration: durationMinutes,
            intensity: intensity,
            targetMuscles: [], // Could extract from goals
            equipment: equipment,
            constraints: nil,
            style: "balanced"
        )

        // Save the workout plan to the database
        let workout = Workout(
            name: plan.summary,
            workoutType: .general,
            plannedDate: Date(),
            user: user
        )
        workout.durationSeconds = TimeInterval(plan.estimatedDuration * 60)
        workout.caloriesBurned = Double(plan.estimatedCalories)

        // Create exercises
        for (index, exercise) in plan.exercises.enumerated() {
            let exerciseModel = Exercise(
                name: exercise.name,
                muscleGroups: [], // PlannedExercise doesn't have muscle groups
                equipment: [], // PlannedExercise doesn't have equipment
                orderIndex: index
            )

            // Add default sets based on the planned exercise
            for setNum in 1...exercise.sets {
                // Parse reps from string (e.g., "8-12" -> 10)
                let targetReps = parseRepsFromString(exercise.reps)
                let set = ExerciseSet(
                    setNumber: setNum,
                    targetReps: targetReps,
                    targetWeightKg: nil, // Would need to be determined
                    targetDurationSeconds: nil
                )
                exerciseModel.addSet(set)
            }

            exerciseModel.restSeconds = TimeInterval(exercise.restSeconds)
            workout.exercises.append(exerciseModel)
        }

        modelContext.insert(workout)
        try modelContext.save()

        let exerciseData: [SendableValue] = plan.exercises.map { exercise in
            SendableValue.dictionary([
                "name": .string(exercise.name),
                "sets": .int(exercise.sets),
                "reps": .string(exercise.reps),
                "restSeconds": .int(exercise.restSeconds)
            ])
        }

        let result: [String: SendableValue] = [
            "workoutId": .string(workout.id.uuidString),
            "planName": .string(plan.summary),
            "exercises": .array(exerciseData),
            "estimatedCalories": .int(plan.estimatedCalories),
            "totalDuration": .int(plan.estimatedDuration)
        ]

        return FunctionHandlerResult(
            message: "Created workout plan: \(plan.summary)",
            data: result
        )
    }

    private func executeAdaptPlan(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        let workoutId = args["workout_id"]?.value as? String ?? ""
        let feedback = args["feedback"]?.value as? String ?? ""
        let performanceDataRaw = args["performance_data"]?.value as? [String: Any] ?? [:]

        // Convert to Sendable format
        let performanceData = performanceDataRaw.mapValues { value in
            String(describing: value)
        }

        // Validate workout exists
        guard let workoutUUID = UUID(uuidString: workoutId) else {
            throw AppError.validationError(message: "Invalid workout ID")
        }

        // Fetch workout from database
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.id == workoutUUID }
        )
        guard let workout = try modelContext.fetch(descriptor).first else {
            throw AppError.unknown(message: "Workout not found")
        }

        // Create a WorkoutPlanResult from the existing workout
        let currentPlan = WorkoutPlanResult(
            id: workout.id,
            exercises: [], // Would need to convert from workout.exercises
            estimatedCalories: Int(workout.caloriesBurned ?? 0),
            estimatedDuration: Int((workout.durationSeconds ?? 0) / 60),
            summary: workout.name,
            difficulty: .intermediate,
            focusAreas: []
        )

        // Adapt the plan based on feedback
        let adaptedPlan = try await workoutService.adaptPlan(
            currentPlan,
            feedback: feedback,
            adjustments: performanceData as [String: Any],
            for: user
        )

        // Update the workout in database
        // Update workout properties
        workout.name = adaptedPlan.summary
        workout.durationSeconds = TimeInterval(adaptedPlan.estimatedDuration * 60)
        workout.caloriesBurned = Double(adaptedPlan.estimatedCalories)

        // Update exercises
        workout.exercises.removeAll()
        for (index, exercise) in adaptedPlan.exercises.enumerated() {
            let exerciseModel = Exercise(
                name: exercise.name,
                muscleGroups: [], // PlannedExercise doesn't have muscle groups
                equipment: [], // PlannedExercise doesn't have equipment
                orderIndex: index
            )

            // Add default sets based on the planned exercise
            for setNum in 1...exercise.sets {
                let targetReps = parseRepsFromString(exercise.reps)
                let set = ExerciseSet(
                    setNumber: setNum,
                    targetReps: targetReps,
                    targetWeightKg: nil,
                    targetDurationSeconds: nil
                )
                exerciseModel.addSet(set)
            }

            exerciseModel.restSeconds = TimeInterval(exercise.restSeconds)
            workout.exercises.append(exerciseModel)
        }

        try modelContext.save()

        let result: [String: SendableValue] = [
            "workoutId": .string(workout.id.uuidString),
            "summary": .string(adaptedPlan.summary),
            "exercises": .int(adaptedPlan.exercises.count),
            "estimatedCalories": .int(adaptedPlan.estimatedCalories)
        ]

        return FunctionHandlerResult(
            message: "Adapted workout plan based on your feedback",
            data: result
        )
    }

    private func executePerformanceAnalysis(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        let metricType = args["metric_type"]?.value as? String ?? "overall"
        _ = args["time_period"]?.value as? String ?? "week"

        // Fetch recent workouts from database
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // Fetch all user's workouts and filter manually
        let userId = user.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.user?.id == userId
            }
        )
        let allWorkouts = try modelContext.fetch(descriptor)

        // Filter for recent workouts
        _ = allWorkouts.filter { workout in
            let workoutDate = workout.completedDate ?? workout.plannedDate ?? Date()
            return workoutDate >= startDate
        }

        let analysis = try await analyticsService.analyzePerformance(
            query: "Analyze \(metricType) performance",
            metrics: ["calories", "duration", "volume"],
            days: 7,
            depth: "detailed",
            includeRecommendations: true,
            for: user
        )

        let trendsData: [SendableValue] = analysis.trends.map { trend in
            SendableValue.dictionary([
                "metric": .string(trend.metric),
                "direction": .string(trend.direction.rawValue),
                "magnitude": .double(trend.magnitude),
                "timeframe": .string(trend.timeframe)
            ])
        }

        let result: [String: SendableValue] = [
            "trends": .array(trendsData),
            "insights": .array(analysis.insights.map { .string($0.finding) }),
            "recommendations": .array(analysis.recommendations.map { .string($0) }),
            "dataPoints": .int(analysis.dataPoints)
        ]

        return FunctionHandlerResult(
            message: analysis.summary,
            data: result
        )
    }

    private func executeGoalSetting(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        let goalType = args["goal_type"]?.value as? String ?? "fitness"
        let timeframe = args["timeframe"]?.value as? String ?? "3 months"
        let currentState = args["current_state"]?.value as? [String: Any] ?? [:]
        _ = args["preferences"]?.value as? [String: Any] ?? [:]

        let result = try await goalService.createOrRefineGoal(
            current: nil,
            aspirations: goalType,
            timeframe: timeframe,
            fitnessLevel: currentState["fitnessLevel"] as? String,
            constraints: [],
            motivations: [],
            goalType: goalType,
            for: user
        )

        // Save goal to database
        let targetDate = result.targetDate ?? Date().addingTimeInterval(TimeInterval(90 * 24 * 60 * 60)) // Default 90 days
        let goal = TrackedGoal(
            userId: user.id,
            title: result.title,
            type: .custom,
            category: .fitness,
            priority: .high,
            targetValue: result.metrics.first?.targetValue.description,
            targetUnit: result.metrics.first?.unit,
            deadline: targetDate,
            description: result.description
        )

        modelContext.insert(goal)
        try modelContext.save()

        let milestonesData: [SendableValue] = result.milestones.map { milestone in
            SendableValue.dictionary([
                "title": .string(milestone.title),
                "targetDate": .string(milestone.targetDate.ISO8601Format()),
                "criteria": .string(milestone.criteria)
            ])
        }

        let metricsData: [SendableValue] = result.metrics.map { metric in
            SendableValue.dictionary([
                "name": .string(metric.name),
                "currentValue": .double(metric.currentValue),
                "targetValue": .double(metric.targetValue),
                "unit": .string(metric.unit)
            ])
        }

        let savedGoal: [String: SendableValue] = [
            "goalId": .string(goal.id.uuidString),
            "title": .string(result.title),
            "milestones": .array(milestonesData),
            "metrics": .array(metricsData)
        ]

        return FunctionHandlerResult(
            message: "Created goal: \(result.title)",
            data: savedGoal
        )
    }

    // MARK: - Helper Methods

    /// Parse reps from string format (e.g., "8-12" -> 10, "15" -> 15)
    private func parseRepsFromString(_ repsString: String) -> Int {
        // Handle range format "8-12"
        if repsString.contains("-") {
            let components = repsString.split(separator: "-").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            if components.count == 2 {
                // Return the average
                return (components[0] + components[1]) / 2
            }
        }

        // Try to parse as single number
        return Int(repsString.trimmingCharacters(in: .whitespaces)) ?? 10
    }
}

// MARK: - Extensions

extension FunctionCallDispatcher {
    // Phase 3.2: Batch execution support for improved performance
    func executeBatch(
        _ calls: [AIFunctionCall],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async -> [FunctionExecutionResult] {
        // Execute sequentially to avoid data races with ModelContext
        var results: [FunctionExecutionResult] = []
        for call in calls {
            do {
                let result = try await self.execute(call, for: user, context: context, modelContext: modelContext)
                results.append(result)
            } catch {
                results.append(FunctionExecutionResult(
                    success: false,
                    message: "Error: \(error.localizedDescription)",
                    data: nil,
                    executionTimeMs: 0,
                    functionName: call.name
                ))
            }
        }
        return results
    }
}
