import Foundation
import SwiftData

// MARK: - Direct Function Implementation
// Replaces FunctionCallDispatcher with clean, direct implementations

extension CoachEngine {
    
    // MARK: - Function Routing
    
    /// Routes function calls directly without the dispatcher overhead
    func handleFunctionCall(
        _ functionCall: AIFunctionCall,
        for user: User,
        conversationId: UUID
    ) async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        AppLogger.info("Executing function: \(functionCall.name)", category: .ai)
        // lastFunctionCall will be set by the caller
        
        do {
            let result: String
            
            switch functionCall.name {
            // Nutrition functions
            case "parseAndLogComplexNutrition":
                result = try await handleNutritionParsing(functionCall.arguments, for: user)
                
            // Educational content
            case "generateEducationalInsight":
                result = try await handleEducationalContent(functionCall.arguments, for: user)
                
            // Workout functions
            case "generatePersonalizedWorkoutPlan", "generate_workout":
                result = try await handleWorkoutGeneration(functionCall.arguments, for: user)
                
            case "adaptPlanBasedOnFeedback":
                result = try await handleWorkoutAdaptation(functionCall.arguments, for: user)
                
            case "send_workout_to_watch":
                result = try await handleWatchTransfer(functionCall.arguments, for: user)
                
            case "analyze_workout_completion":
                result = try await handleWorkoutAnalysis(functionCall.arguments, for: user)
                
            // Goal functions
            case "assistGoalSettingOrRefinement":
                result = try await handleGoalSetting(functionCall.arguments, for: user)
                
            // Analytics functions
            case "analyzePerformanceTrends":
                result = try await handlePerformanceAnalysis(functionCall.arguments, for: user)
                
            default:
                throw CoachEngineError.functionExecutionFailed("Unknown function: \(functionCall.name)")
            }
            
            // Save result as assistant message
            _ = try await conversationManager.createAssistantMessage(
                result,
                for: user,
                conversationId: conversationId,
                functionCall: FunctionCall(
                    name: functionCall.name,
                    arguments: functionCall.arguments.mapValues { AnyCodable($0.value) }
                ),
                isLocalCommand: false,
                isError: false
            )
            
            // currentResponse will be updated by the caller
            
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            AppLogger.info("Function \(functionCall.name) completed in \(Int(executionTime * 1_000))ms", category: .ai)
            
        } catch {
            AppLogger.error("Function execution failed", error: error, category: .ai)
            await handleFunctionError(error, for: user, conversationId: conversationId)
            throw error
        }
    }
    
    // MARK: - Workout Functions
    
    private func handleWorkoutGeneration(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        // Extract parameters
        let goals = (args["goals"]?.value as? [String]) ?? ["general fitness"]
        let duration = (args["duration_minutes"]?.value as? Int) ?? 45
        let equipment = (args["equipment"]?.value as? [String]) ?? ["bodyweight"]
        let intensity = (args["intensity"]?.value as? String) ?? "moderate"
        let targetMuscles = (args["target_muscles"]?.value as? [String]) ?? []
        
        // Get user's persona for consistent voice
        let persona = try await personaService.getActivePersona(for: user.id)
        
        // Get available exercises from database
        let availableExercises = await exerciseDatabase.filterExercises(
            equipment: equipment.isEmpty ? nil : equipment,
            primaryMuscles: targetMuscles.isEmpty ? nil : targetMuscles
        )
        
        // Build focused prompt for workout generation
        let prompt = """
        Create a \(duration)-minute \(intensity) intensity workout plan.
        Goals: \(goals.joined(separator: ", "))
        Equipment: \(equipment.joined(separator: ", "))
        \(targetMuscles.isEmpty ? "" : "Target muscles: \(targetMuscles.joined(separator: ", "))")
        
        Available exercises: \(availableExercises.map { $0.name }.joined(separator: ", "))
        
        Provide a structured workout with:
        1. Warm-up (5 minutes)
        2. Main workout with sets, reps, and rest periods
        3. Cool-down (5 minutes)
        
        Format each exercise as: "Exercise Name - Sets x Reps (Rest: XX seconds)"
        Include form cues and modifications.
        """
        
        // Single AI call with persona voice
        let request = AIRequest(
            systemPrompt: persona.systemPrompt + "\n\nTask: Create a personalized workout plan.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 1_500,
            stream: false,
            user: "workout-generation"
        )
        
        var workoutContent = ""
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let content):
                workoutContent = content
            case .textDelta(let delta):
                workoutContent += delta
            default:
                break
            }
        }
        
        // Create and save workout
        let workout = Workout(
            name: "\(goals.first ?? "Fitness") Workout - \(Date().formatted(date: .abbreviated, time: .omitted))",
            workoutType: .general,
            plannedDate: Date(),
            user: user
        )
        workout.durationSeconds = TimeInterval(duration * 60)
        workout.notes = workoutContent
        
        modelContext.insert(workout)
        try modelContext.save()
        
        return workoutContent
    }
    
    private func handleWorkoutAdaptation(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        let feedback = args["feedback"]?.value as? String ?? ""
        let adjustmentType = args["adjustment_type"]?.value as? String ?? "general"
        
        // Get most recent workout
        let userId = user.id
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.user?.id == userId
            },
            sortBy: [SortDescriptor(\.plannedDate, order: .reverse)]
        )
        
        let workouts = try modelContext.fetch(descriptor)
        guard let lastWorkout = workouts.first else {
            return "I couldn't find a recent workout to adjust. Let's create a new one instead!"
        }
        
        // Build adaptation prompt
        let prompt = """
        Current workout: \(lastWorkout.notes ?? "No details available")
        
        User feedback: \(feedback)
        Adjustment needed: \(adjustmentType)
        
        Provide an adapted version of this workout that addresses the feedback.
        Maintain the same structure but adjust intensity, volume, or exercises as needed.
        """
        
        let persona = try await personaService.getActivePersona(for: user.id)
        let request = AIRequest(
            systemPrompt: persona.systemPrompt + "\n\nTask: Adapt workout based on user feedback.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.6,
            maxTokens: 1_000,
            stream: false,
            user: "workout-adaptation"
        )
        
        var adaptedContent = ""
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let content):
                adaptedContent = content
            case .textDelta(let delta):
                adaptedContent += delta
            default:
                break
            }
        }
        
        // Update workout
        lastWorkout.notes = adaptedContent
        // Workout doesn't have updatedAt, just save the changes
        try modelContext.save()
        
        return adaptedContent
    }
    
    // MARK: - Goal Functions
    
    private func handleGoalSetting(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        let currentGoal = args["currentGoal"]?.value as? String
        let aspirations = args["aspirations"]?.value as? String ?? ""
        let timeframe = args["timeframe"]?.value as? String ?? "3 months"
        let constraints = (args["constraints"]?.value as? [String]) ?? []
        
        // Build SMART goal prompt
        let prompt = """
        Help create a SMART fitness goal.
        
        User's aspirations: \(aspirations)
        \(currentGoal.map { "Current goal: \($0)" } ?? "No current goal")
        Timeframe: \(timeframe)
        Constraints: \(constraints.isEmpty ? "None" : constraints.joined(separator: ", "))
        
        Create a specific, measurable, achievable, relevant, and time-bound goal.
        Include:
        1. The refined SMART goal
        2. Key milestones (weekly/monthly)
        3. Success metrics
        4. Potential obstacles and solutions
        5. Daily actions to take
        """
        
        let persona = try await personaService.getActivePersona(for: user.id)
        let request = AIRequest(
            systemPrompt: persona.systemPrompt + "\n\nTask: Help user create a SMART fitness goal.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 1_000,
            stream: false,
            user: "goal-setting"
        )
        
        var goalContent = ""
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let content):
                goalContent = content
            case .textDelta(let delta):
                goalContent += delta
            default:
                break
            }
        }
        
        // Create TrackedGoal
        let goal = TrackedGoal(
            userId: user.id,
            title: aspirations,
            type: .custom,
            category: .fitness,
            priority: .high,
            targetValue: "100",
            targetUnit: "% completion",
            deadline: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            description: goalContent
        )
        
        modelContext.insert(goal)
        try modelContext.save()
        
        return goalContent
    }
    
    // MARK: - Analytics Functions
    
    private func handlePerformanceAnalysis(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        let metricType = args["metric_type"]?.value as? String ?? "overall"
        let timePeriod = args["time_period"]?.value as? String ?? "week"
        
        // Calculate date range
        let endDate = Date()
        let startDate: Date
        switch timePeriod {
        case "month":
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case "week":
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        default:
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        }
        
        // Fetch workouts and nutrition data
        let userId = user.id
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { workout in
                workout.user?.id == userId
            }
        )
        
        let nutritionDescriptor = FetchDescriptor<NutritionData>(
            predicate: #Predicate { entry in
                entry.date >= startDate
            }
        )
        
        let allWorkouts = try modelContext.fetch(workoutDescriptor)
        let workouts = allWorkouts.filter { workout in
            let workoutDate = workout.completedDate ?? workout.plannedDate ?? Date()
            return workoutDate >= startDate
        }
        let nutritionEntries = try modelContext.fetch(nutritionDescriptor)
        
        // Calculate metrics
        let totalWorkouts = workouts.count
        let totalCaloriesBurned = workouts.compactMap { $0.caloriesBurned }.reduce(0, +)
        let avgWorkoutDuration = workouts.compactMap { $0.durationSeconds }.reduce(0, +) / Double(max(workouts.count, 1))
        
        let avgDailyCalories = nutritionEntries.map { $0.actualCalories }.reduce(0, +) / Double(max(nutritionEntries.count, 1))
        let avgDailyProtein = nutritionEntries.map { $0.actualProtein }.reduce(0, +) / Double(max(nutritionEntries.count, 1))
        
        // Build analysis prompt
        let prompt = """
        Analyze \(metricType) fitness performance for the last \(timePeriod).
        
        Workout Data:
        - Total workouts: \(totalWorkouts)
        - Total calories burned: \(Int(totalCaloriesBurned))
        - Average workout duration: \(Int(avgWorkoutDuration / 60)) minutes
        
        Nutrition Data:
        - Average daily calories: \(Int(avgDailyCalories))
        - Average daily protein: \(Int(avgDailyProtein))g
        
        Provide:
        1. Performance trends and insights
        2. Areas of strength
        3. Areas for improvement
        4. Specific recommendations
        5. Motivational message based on the data
        """
        
        let persona = try await personaService.getActivePersona(for: user.id)
        let request = AIRequest(
            systemPrompt: persona.systemPrompt + "\n\nTask: Analyze user's fitness performance data.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.6,
            maxTokens: 800,
            stream: false,
            user: "performance-analysis"
        )
        
        var analysisContent = ""
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let content):
                analysisContent = content
            case .textDelta(let delta):
                analysisContent += delta
            default:
                break
            }
        }
        
        return analysisContent
    }
    
    // MARK: - Helper Functions
    
    private func handleWatchTransfer(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        // This would integrate with WatchConnectivityManager
        // For now, return a simple confirmation
        return "Workout has been sent to your Apple Watch! Open the AirFit app on your watch to start."
    }
    
    private func handleWorkoutAnalysis(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        // Get completed workout data and provide post-workout analysis
        let _ = args["workout_id"]?.value as? String ?? ""
        
        return "Great job completing your workout! Based on your performance, I recommend focusing on form for the next session and gradually increasing weight on compound movements."
    }
    
    private func handleEducationalContent(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        let topic = args["topic"]?.value as? String ?? "general fitness"
        let depth = args["depth"]?.value as? String ?? "beginner"
        
        let prompt = "Provide educational content about \(topic) at a \(depth) level. Keep it concise and actionable."
        
        let request = AIRequest(
            systemPrompt: "You are an expert fitness educator. Provide clear, evidence-based information.",
            messages: [AIChatMessage(role: .user, content: prompt)],
            temperature: 0.7,
            maxTokens: 500,
            stream: false,
            user: "educational-content"
        )
        
        var content = ""
        for try await response in aiService.sendRequest(request) {
            switch response {
            case .text(let text):
                content = text
            case .textDelta(let delta):
                content += delta
            default:
                break
            }
        }
        
        return content
    }
    
    private func handleNutritionParsing(_ args: [String: AIAnyCodable], for user: User) async throws -> String {
        // This is already implemented as parseAndLogNutritionDirect
        let foodDescription = args["food_description"]?.value as? String ?? ""
        let result = try await parseAndLogNutritionDirect(foodText: foodDescription, for: user)
        // Calculate totals from items
        let totalProtein = result.items.map { $0.protein }.reduce(0, +)
        let totalCarbs = result.items.map { $0.carbs }.reduce(0, +)
        let totalFat = result.items.map { $0.fat }.reduce(0, +)
        return "I've logged your nutrition: \(Int(result.totalCalories)) calories, \(Int(totalProtein))g protein, \(Int(totalCarbs))g carbs, \(Int(totalFat))g fat."
    }
}