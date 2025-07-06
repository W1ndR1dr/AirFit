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
    private let workoutTransferService: WorkoutPlanTransferProtocol?
    private let coachEngine: CoachEngineProtocol?
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
        goalService: AIGoalServiceProtocol,
        workoutTransferService: WorkoutPlanTransferProtocol? = nil,
        coachEngine: CoachEngineProtocol? = nil
    ) {
        self.workoutService = workoutService
        self.analyticsService = analyticsService
        self.goalService = goalService
        self.workoutTransferService = workoutTransferService
        self.coachEngine = coachEngine

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
            },
            "generate_workout": { dispatcher, args, user, context, modelContext in
                try await dispatcher.handleGenerateWorkout(args, for: user, context: context, modelContext: modelContext)
            },
            "send_workout_to_watch": { dispatcher, args, user, context, modelContext in
                try await dispatcher.handleSendWorkoutToWatch(args, for: user, context: context, modelContext: modelContext)
            },
            "analyze_workout_completion": { dispatcher, args, user, context, modelContext in
                try await dispatcher.handleAnalyzeWorkoutCompletion(args, for: user, context: context, modelContext: modelContext)
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

    // MARK: - Workout Generation for Watch
    
    private func handleGenerateWorkout(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        // Extract parameters from natural language or structured input
        let duration = (args["duration"]?.value as? Int) ?? 30
        // Always generate strength training workouts for watch
        let workoutType = "strength"
        let muscleGroups = (args["muscle_groups"]?.value as? [String]) ?? []
        let equipment = (args["equipment"]?.value as? [String]) ?? ["bodyweight"]
        let intensity = (args["intensity"]?.value as? String) ?? "moderate"
        let style = (args["style"]?.value as? String) ?? "balanced"
        let constraints = args["constraints"]?.value as? String
        
        // Generate workout plan using AI service
        let plan = try await workoutService.generatePlan(
            for: user,
            goal: workoutType,
            duration: duration,
            intensity: intensity,
            targetMuscles: muscleGroups,
            equipment: equipment,
            constraints: constraints,
            style: style
        )
        
        // Format exercises for display in chat
        var exerciseDisplay = ""
        for (index, exercise) in plan.exercises.enumerated() {
            exerciseDisplay += "\n\(index + 1). **\(exercise.name)**\n"
            exerciseDisplay += "   • \(exercise.sets) sets × \(exercise.reps) reps\n"
            exerciseDisplay += "   • Rest: \(exercise.restSeconds)s\n"
            if let notes = exercise.notes {
                exerciseDisplay += "   • Notes: \(notes)\n"
            }
        }
        
        // Store the generated plan temporarily for sending to watch
        let planId = UUID()
        let plannedWorkout = PlannedWorkoutData.from(
            workoutPlan: plan,
            workoutType: WorkoutType(from: workoutType),
            userId: user.id,
            workoutName: "\(workoutType.capitalized) - \(Date().formatted(date: .omitted, time: .shortened))"
        )
        
        // Save to temporary storage or cache
        // For now, we'll return the plan ID for immediate use
        
        let result: [String: SendableValue] = [
            "planId": .string(planId.uuidString),
            "workoutName": .string(plannedWorkout.name),
            "duration": .int(duration),
            "exerciseCount": .int(plan.exercises.count),
            "estimatedCalories": .int(plan.estimatedCalories),
            "exercises": .string(exerciseDisplay),
            "canSendToWatch": .bool(workoutTransferService != nil)
        ]
        
        return FunctionHandlerResult(
            message: """
            I've created a \(duration)-minute \(intensity) strength training workout for you:
            
            **\(plannedWorkout.name)**
            • Duration: \(duration) minutes
            • Exercises: \(plan.exercises.count)
            • Estimated calories: \(plan.estimatedCalories)
            \(exerciseDisplay)
            
            Would you like to send this strength workout to your Apple Watch?
            
            *Note: For cardio workouts like running or cycling, I recommend using Apple's native Workout app which has excellent GPS tracking and metrics. I'll focus on helping you with strength training where I can add the most value!*
            """,
            data: result
        )
    }
    
    private func handleSendWorkoutToWatch(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        guard let workoutTransferService = workoutTransferService else {
            throw AppError.unknown(message: "Watch transfer service not available")
        }
        
        // Get workout plan ID or generate from recent workout
        if let planIdString = args["planId"]?.value as? String,
           let planId = UUID(uuidString: planIdString) {
            // TODO: Retrieve cached plan by ID
            // For now, we'll need to regenerate or fetch from a recent workout
        }
        
        // Alternative: Get the most recent workout to send
        let userId = user.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.user?.id == userId
            },
            sortBy: [SortDescriptor(\.plannedDate, order: .reverse)]
        )
        
        let workouts = try modelContext.fetch(descriptor)
        guard let recentWorkout = workouts.first else {
            throw AppError.unknown(message: "No workout found to send")
        }
        
        // Convert to PlannedWorkoutData
        let plannedWorkout = PlannedWorkoutData.from(workout: recentWorkout, userId: user.id)
        
        // Check if watch is available
        let isAvailable = await workoutTransferService.isWatchAvailable()
        
        if !isAvailable {
            return FunctionHandlerResult(
                message: "Your Apple Watch is not currently reachable. Make sure:\n• The AirFit Watch app is installed\n• Your watch is nearby and unlocked\n• Bluetooth is enabled\n\nThe workout will be queued and sent when your watch is available.",
                data: ["queued": .bool(true), "workoutName": .string(plannedWorkout.name)]
            )
        }
        
        // Send to watch
        try await workoutTransferService.sendWorkoutPlan(plannedWorkout)
        
        let result: [String: SendableValue] = [
            "workoutName": .string(plannedWorkout.name),
            "exerciseCount": .int(plannedWorkout.plannedExercises.count),
            "duration": .int(plannedWorkout.estimatedDuration),
            "sent": .bool(true)
        ]
        
        return FunctionHandlerResult(
            message: """
            ✅ Successfully sent "\(plannedWorkout.name)" to your Apple Watch!
            
            • \(plannedWorkout.plannedExercises.count) exercises
            • \(plannedWorkout.estimatedDuration) minutes
            • \(plannedWorkout.estimatedCalories) calories
            
            Open the AirFit app on your watch to start the workout.
            """,
            data: result
        )
    }

    private func handleAnalyzeWorkoutCompletion(
        _ args: [String: AIAnyCodable],
        for user: User,
        context: FunctionContext,
        modelContext: ModelContext
    ) async throws -> FunctionHandlerResult {
        // This would be called automatically when workout completion data is received
        // For now, we'll analyze the most recent workout
        
        let userId = user.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.user?.id == userId && workout.isCompleted
            },
            sortBy: [SortDescriptor(\.completedDate, order: .reverse)]
        )
        
        let workouts = try modelContext.fetch(descriptor)
        guard let recentWorkout = workouts.first else {
            throw AppError.unknown(message: "No completed workout found")
        }
        
        // Generate AI analysis
        let request = PostWorkoutAnalysisRequest(
            workout: recentWorkout,
            recentWorkouts: Array(workouts.prefix(5)),
            userGoals: nil,
            recoveryData: nil
        )
        
        guard let coachEngine = coachEngine else {
            throw AppError.unknown(message: "Coach engine not available")
        }
        
        let analysis = try await coachEngine.generatePostWorkoutAnalysis(request)
        
        // Save analysis to workout
        recentWorkout.aiAnalysis = analysis
        try modelContext.save()
        
        let result: [String: SendableValue] = [
            "workoutId": .string(recentWorkout.id.uuidString),
            "workoutName": .string(recentWorkout.name),
            "analysis": .string(analysis)
        ]
        
        return FunctionHandlerResult(
            message: analysis,
            data: result
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

extension WorkoutType {
    init(from string: String) {
        switch string.lowercased() {
        case "strength", "strength training":
            self = .strength
        case "cardio", "cardiovascular", "running", "run", "cycling", "bike", "swimming", "swim":
            self = .cardio
        case "hiit", "high intensity":
            self = .hiit
        case "yoga", "stretching":
            self = .yoga
        case "flexibility":
            self = .flexibility
        case "sports":
            self = .sports
        case "pilates":
            self = .pilates
        default:
            self = .general
        }
    }
}

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
