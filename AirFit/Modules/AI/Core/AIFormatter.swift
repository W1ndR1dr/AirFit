import Foundation

/// Pure formatting helpers. No side effects.
struct AIFormatter {

    // MARK: Workout - REMOVED
    
    // WORKOUT TRACKING REMOVED - Analysis moved to external apps
    /*
    func workoutAnalysisPrompt(_ request: PostWorkoutAnalysisRequest) -> String {
        let workout = request.workout
        let recent = request.recentWorkouts

        var prompt = "Analyze this workout:\n\n"
        prompt += "Workout: \(workout.workoutTypeEnum?.displayName ?? workout.workoutType)\n"
        prompt += "Duration: \(workout.formattedDuration ?? "Unknown")\n"
        prompt += "Exercises: \(workout.exercises.count)\n"

        if let calories = workout.caloriesBurned, calories > 0 {
            prompt += "Calories: \(Int(calories))\n"
        }

        prompt += "\nExercises performed:\n"
        for ex in workout.exercises {
            prompt += "- \(ex.name): \(ex.sets.count) sets\n"
        }

        if recent.count > 1 {
            prompt += "\nRecent workout history (\(recent.count - 1) previous):\n"
            for r in recent.dropFirst() {
                prompt += "- \(r.workoutTypeEnum?.displayName ?? r.workoutType): \(r.formattedDuration ?? "Unknown")\n"
            }
        }

        prompt += """
        
        Provide encouraging analysis focusing on progress, form tips, and next steps. Keep it under 150 words.
        """
        return prompt
    }
    */

    // MARK: Nutrition

    func nutritionParsingResponse(_ result: NutritionParseResult) -> String {
        let items = result.items
            .map { item in
                "\(item.name) (\(item.quantity)): \(Int(item.calories)) cal, \(String(format: "%.1f", item.protein))g protein"
            }
            .joined(separator: "\n")

        return """
        I've logged your nutrition data:

        \(items)

        Total: \(Int(result.totalCalories)) calories
        Confidence: \(String(format: "%.0f", result.confidence * 100))%
        """
    }

    // MARK: Notifications

    enum NotificationContentType {
        case morningGreeting
        case workoutReminder
        case mealReminder(MealType)
        case achievement
    }

    func notificationPrompt(type: NotificationContentType, context: Any) -> String {
        switch type {
        case .morningGreeting:
            if let c = context as? MorningContext {
                var p = "Generate a personalized morning greeting for \(c.userName). "
                p += "Requirements: 1-2 sentences, warm and encouraging tone. "
                var ctx = "Context: "
                if let q = c.sleepQuality { ctx += "Sleep quality was \(q). " }
                if let d = c.sleepDuration { ctx += "Slept \(Int(d/3600)) hours. " }
                if let w = c.plannedWorkout { ctx += "Has \(w.name) workout scheduled today. " }
                if c.currentStreak > 0 { ctx += "On a \(c.currentStreak)-day activity streak. " }
                if let w = c.weather { ctx += "Weather: \(w.temperature)°F, \(w.condition). " }
                p += ctx
                p += "Create a unique message that acknowledges their specific situation."
                return p
            }
        case .workoutReminder:
            if let c = context as? WorkoutReminderContext {
                var p = "Generate a motivating workout reminder for \(c.userName). "
                p += "Workout type: \(c.workoutType). "
                p += "Requirements: 1-2 sentences, energetic but not pushy. "
                if c.streak > 0 { p += "They're on day \(c.streak + 1) of their streak - acknowledge this. " }
                else if c.lastWorkoutDays > 3 { p += "It's been \(c.lastWorkoutDays) days since last workout - be encouraging. " }
                else if c.lastWorkoutDays == 1 { p += "They worked out yesterday - encourage consistency. " }
                p += "Match their motivational style: \(c.motivationalStyle.styles.first?.rawValue ?? "encouraging")."
                return p
            }
        case .mealReminder(let mealType):
            if let c = context as? MealReminderContext {
                var p = "Generate a \(mealType.displayName) reminder for \(c.userName). "
                p += "Requirements: 1 sentence, friendly and practical. "
                if let last = c.lastMealLogged {
                    let hours = Date().timeIntervalSince(last)/3600
                    if hours < 2 { p += "They recently logged a meal - acknowledge consistency. " }
                    else if hours > 6 { p += "They haven't logged in a while - gently encourage. " }
                }
                if !c.favoritesFoods.isEmpty {
                    p += "Their favorites include: \(c.favoritesFoods.prefix(3).joined(separator: ", ")). "
                }
                return p
            }
        case .achievement:
            if let c = context as? AchievementContext {
                var p = "Celebrate \(c.userName) earning: \(c.achievementName)."
                if c.personalBest { p += " This is a personal best." }
                return p
            }
        }
        return "Generate a brief, motivational fitness notification."
    }
}