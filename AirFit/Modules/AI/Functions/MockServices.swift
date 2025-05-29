import Foundation

// MARK: - Mock Workout Service

actor MockWorkoutService: WorkoutServiceProtocol {

    func generatePlan(
        for user: User,
        goal: String,
        duration: Int,
        intensity: String,
        targetMuscles: [String],
        equipment: [String],
        constraints: String?,
        style: String
    ) async throws -> WorkoutPlanResult {

        // Simulate processing time
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let exercises = generateExercises(
            goal: goal,
            duration: duration,
            targetMuscles: targetMuscles,
            equipment: equipment,
            style: style
        )

        let estimatedCalories = calculateEstimatedCalories(
            exercises: exercises,
            duration: duration,
            intensity: intensity
        )

        return WorkoutPlanResult(
            id: UUID(),
            exercises: exercises,
            estimatedCalories: estimatedCalories,
            estimatedDuration: duration,
            summary: generateWorkoutSummary(goal: goal, exercises: exercises, duration: duration)
        )
    }

    private func generateExercises(
        goal: String,
        duration: Int,
        targetMuscles: [String],
        equipment: [String],
        style: String
    ) -> [WorkoutPlanResult.ExerciseInfo] {

        let exerciseCount = min(max(duration / 8, 3), 8) // 3-8 exercises based on duration
        var exercises: [WorkoutPlanResult.ExerciseInfo] = []

        let exerciseDatabase = getExerciseDatabase(equipment: equipment)
        let filteredExercises = exerciseDatabase.filter { exercise in
            targetMuscles.contains("full_body") ||
                !Set(exercise.muscleGroups).isDisjoint(with: Set(targetMuscles))
        }

        for i in 0..<exerciseCount {
            let exercise = filteredExercises[i % filteredExercises.count]
            let (sets, reps) = getSetsAndReps(goal: goal, style: style, exerciseIndex: i)
            let restSeconds = getRestTime(goal: goal, style: style)

            exercises.append(WorkoutPlanResult.ExerciseInfo(
                name: exercise.name,
                sets: sets,
                reps: reps,
                restSeconds: restSeconds,
                muscleGroups: exercise.muscleGroups
            ))
        }

        return exercises
    }

    private func getExerciseDatabase(equipment: [String]) -> [(name: String, muscleGroups: [String])] {
        let bodyweightExercises = [
            ("Push-ups", ["chest", "triceps", "shoulders"]),
            ("Squats", ["quadriceps", "glutes", "core"]),
            ("Lunges", ["quadriceps", "glutes", "hamstrings"]),
            ("Plank", ["core", "shoulders"]),
            ("Burpees", ["full_body"]),
            ("Mountain Climbers", ["core", "shoulders", "legs"]),
            ("Jumping Jacks", ["full_body"]),
            ("Pull-ups", ["back", "biceps"])
        ]

        let dumbbellExercises = [
            ("Dumbbell Bench Press", ["chest", "triceps", "shoulders"]),
            ("Dumbbell Rows", ["back", "biceps"]),
            ("Dumbbell Squats", ["quadriceps", "glutes"]),
            ("Dumbbell Shoulder Press", ["shoulders", "triceps"]),
            ("Dumbbell Deadlifts", ["hamstrings", "glutes", "back"]),
            ("Dumbbell Bicep Curls", ["biceps"]),
            ("Dumbbell Lunges", ["quadriceps", "glutes"])
        ]

        let barbellExercises = [
            ("Barbell Squats", ["quadriceps", "glutes", "core"]),
            ("Deadlifts", ["hamstrings", "glutes", "back", "core"]),
            ("Bench Press", ["chest", "triceps", "shoulders"]),
            ("Barbell Rows", ["back", "biceps"]),
            ("Overhead Press", ["shoulders", "triceps", "core"])
        ]

        var availableExercises = bodyweightExercises

        if equipment.contains("dumbbells") || equipment.contains("full_gym") {
            availableExercises.append(contentsOf: dumbbellExercises)
        }

        if equipment.contains("barbell") || equipment.contains("full_gym") {
            availableExercises.append(contentsOf: barbellExercises)
        }

        return availableExercises
    }

    private func getSetsAndReps(goal: String, style: String, exerciseIndex: Int) -> (sets: Int, reps: String) {
        switch goal {
        case "strength":
            return (4, "3-5")
        case "hypertrophy":
            return (3, "8-12")
        case "endurance":
            return (3, "15-20")
        case "power":
            return (4, "3-6")
        case "mobility":
            return (2, "10-15")
        case "active_recovery":
            return (2, "8-10")
        default:
            return (3, "8-12")
        }
    }

    private func getRestTime(goal: String, style: String) -> Int {
        if style == "circuit" || style == "hiit" {
            return 30
        }

        switch goal {
        case "strength", "power":
            return 120
        case "hypertrophy":
            return 90
        case "endurance", "active_recovery":
            return 60
        default:
            return 75
        }
    }

    private func calculateEstimatedCalories(
        exercises: [WorkoutPlanResult.ExerciseInfo],
        duration: Int,
        intensity: String
    ) -> Int {
        let baseCaloriesPerMinute: Double = switch intensity {
        case "light": 4.0
        case "moderate": 6.0
        case "high": 8.0
        default: 6.0
        }

        return Int(Double(duration) * baseCaloriesPerMinute)
    }

    private func generateWorkoutSummary(
        goal: String,
        exercises: [WorkoutPlanResult.ExerciseInfo],
        duration: Int
    ) -> String {
        let primaryMuscles = Set(exercises.flatMap { $0.muscleGroups }).prefix(3).joined(separator: ", ")
        return "A \(duration)-minute \(goal) workout targeting \(primaryMuscles) with \(exercises.count) exercises."
    }
}

// MARK: - Mock Nutrition Service

actor MockNutritionService: AIFunctionNutritionServiceProtocol {

    func parseAndLogMeal(
        _ input: String,
        type: String,
        date: Date,
        confidenceThreshold: Double,
        includeAlternatives: Bool,
        for user: User
    ) async throws -> NutritionLogResult {

        // Simulate AI processing time
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        let items = parseFoodItems(from: input)
        let alternatives = includeAlternatives ? generateAlternatives(for: input) : nil

        let totalCalories = items.reduce(0) { $0 + $1.calories }
        let totalProtein = items.reduce(0) { $0 + $1.protein }
        let totalCarbs = items.reduce(0) { $0 + $1.carbs }
        let totalFat = items.reduce(0) { $0 + $1.fat }

        return NutritionLogResult(
            id: UUID(),
            items: items,
            totalCalories: totalCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            confidence: 0.85,
            alternatives: alternatives
        )
    }

    private func parseFoodItems(from input: String) -> [NutritionLogResult.FoodItemInfo] {
        let lowercaseInput = input.lowercased()
        var items: [NutritionLogResult.FoodItemInfo] = []

        // Simple pattern matching for common foods
        let foodPatterns: [(pattern: String, name: String, calories: Double, protein: Double, carbs: Double, fat: Double)] = [
            ("chicken", "Grilled Chicken Breast", 165, 31, 0, 3.6),
            ("rice", "Brown Rice", 112, 2.6, 23, 0.9),
            ("egg", "Large Egg", 70, 6, 0.6, 5),
            ("banana", "Medium Banana", 105, 1.3, 27, 0.4),
            ("apple", "Medium Apple", 95, 0.5, 25, 0.3),
            ("salmon", "Grilled Salmon", 206, 22, 0, 12),
            ("broccoli", "Steamed Broccoli", 25, 3, 5, 0.3),
            ("oatmeal", "Oatmeal", 150, 5, 27, 3),
            ("yogurt", "Greek Yogurt", 100, 17, 6, 0.7),
            ("avocado", "Half Avocado", 160, 2, 8.5, 15),
            ("bread", "Whole Wheat Bread", 80, 4, 14, 1.1),
            ("pasta", "Whole Wheat Pasta", 174, 7.5, 37, 0.8)
        ]

        for (pattern, name, calories, protein, carbs, fat) in foodPatterns where lowercaseInput.contains(pattern) {
            let quantity = extractQuantity(from: input, for: pattern)
            items.append(NutritionLogResult.FoodItemInfo(
                name: name,
                quantity: quantity,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            ))
        }

        // If no matches found, create a generic item
        if items.isEmpty {
            items.append(NutritionLogResult.FoodItemInfo(
                name: "Mixed Meal",
                quantity: "1 serving",
                calories: 350,
                protein: 20,
                carbs: 35,
                fat: 12
            ))
        }

        return items
    }

    private func extractQuantity(from input: String, for food: String) -> String {
        // Simple quantity extraction
        if input.contains("2") || input.contains("two") {
            return "2 servings"
        } else if input.contains("large") {
            return "1 large serving"
        } else if input.contains("small") {
            return "1 small serving"
        }
        return "1 serving"
    }

    private func generateAlternatives(for input: String) -> [String] {
        return [
            "Alternative interpretation: \(input) with different portion sizes",
            "Could also be: Similar meal with different cooking method",
            "Possible variation: \(input) with additional sides"
        ]
    }
}

// MARK: - Mock Analytics Service

actor MockAnalyticsService: AnalyticsServiceProtocol {

    func analyzePerformance(
        query: String,
        metrics: [String],
        days: Int,
        depth: String,
        includeRecommendations: Bool,
        for user: User
    ) async throws -> PerformanceAnalysisResult {

        // Simulate analysis processing time
        try await Task.sleep(nanoseconds: 400_000_000) // 400ms

        let insights = generateInsights(for: metrics, days: days)
        let trends = generateTrends(for: metrics)
        let recommendations = includeRecommendations ? generateRecommendations(for: metrics) : []
        let summary = generateAnalysisSummary(query: query, insights: insights, trends: trends)

        return PerformanceAnalysisResult(
            summary: summary,
            insights: insights,
            trends: trends,
            recommendations: recommendations,
            dataPoints: days * metrics.count
        )
    }

    private func generateInsights(for metrics: [String], days: Int) -> [String] {
        var insights: [String] = []

        for metric in metrics.prefix(3) {
            switch metric {
            case "workout_volume":
                insights.append("Your workout volume has increased by 15% over the past \(days) days")
            case "energy_levels":
                insights.append("Energy levels show a positive correlation with sleep quality")
            case "sleep_quality":
                insights.append("Sleep quality has been consistently above average this period")
            case "strength_progression":
                insights.append("Strength gains are tracking well with your current program")
            case "recovery_metrics":
                insights.append("Recovery time has improved by 20% since starting the program")
            default:
                insights.append("\(metric.replacingOccurrences(of: "_", with: " ")) shows positive trends")
            }
        }

        return insights
    }

    private func generateTrends(for metrics: [String]) -> [PerformanceAnalysisResult.TrendInfo] {
        return metrics.prefix(3).map { metric in
            PerformanceAnalysisResult.TrendInfo(
                metric: metric,
                direction: ["improving", "stable", "declining"].randomElement() ?? "stable",
                magnitude: Double.random(in: 0.1...0.8),
                significance: ["high", "medium", "low"].randomElement() ?? "medium"
            )
        }
    }

    private func generateRecommendations(for metrics: [String]) -> [String] {
        var recommendations: [String] = []

        if metrics.contains("sleep_quality") {
            recommendations.append("Consider maintaining your current sleep schedule for optimal recovery")
        }

        if metrics.contains("workout_volume") {
            recommendations.append("Your current training volume is well-suited to your goals")
        }

        if metrics.contains("energy_levels") {
            recommendations.append("Focus on pre-workout nutrition to maintain energy levels")
        }

        recommendations.append("Continue tracking these metrics to identify long-term patterns")

        return recommendations
    }

    private func generateAnalysisSummary(
        query: String,
        insights: [String],
        trends: [PerformanceAnalysisResult.TrendInfo]
    ) -> String {
        let positiveCount = trends.filter { $0.direction == "improving" }.count
        let stableCount = trends.filter { $0.direction == "stable" }.count

        if positiveCount > stableCount {
            return "Your performance metrics show strong positive trends with \(insights.count) key insights identified."
        } else {
            return "Your performance is stable with \(insights.count) areas showing consistent progress."
        }
    }
}

// MARK: - Mock Goal Service

actor MockGoalService: GoalServiceProtocol {

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

// MARK: - Mock Education Service

actor MockEducationService: EducationServiceProtocol {

    func generateEducationalContent(
        topic: String,
        userContext: String,
        knowledgeLevel: String,
        contentDepth: String,
        outputFormat: String,
        includeActionItems: Bool,
        relateToUserData: Bool,
        for user: User
    ) async throws -> EducationalContentResult {

        // Simulate content generation time
        try await Task.sleep(nanoseconds: 350_000_000) // 350ms

        let content = generateContent(
            topic: topic,
            knowledgeLevel: knowledgeLevel,
            contentDepth: contentDepth,
            outputFormat: outputFormat
        )

        let keyPoints = generateKeyPoints(for: topic, depth: contentDepth)
        let actionItems = includeActionItems ? generateActionItems(for: topic) : []
        let relatedTopics = generateRelatedTopics(for: topic)
        let sources = generateSources(for: topic)

        return EducationalContentResult(
            topic: topic,
            content: content,
            keyPoints: keyPoints,
            actionItems: actionItems,
            relatedTopics: relatedTopics,
            sources: sources
        )
    }

    private func generateContent(
        topic: String,
        knowledgeLevel: String,
        contentDepth: String,
        outputFormat: String
    ) -> String {

        let topicName = topic.replacingOccurrences(of: "_", with: " ").capitalized

        let baseContent = switch topic {
        case "progressive_overload":
            """
            Progressive overload is the fundamental principle of strength training that involves gradually
            increasing the demands on your muscles over time. This can be achieved by increasing weight,
            reps, sets, or decreasing rest time. Your body adapts to stress, so consistent progression
            is essential for continued improvement.
            """
        case "nutrition_timing":
            """
            Nutrition timing refers to when you eat in relation to your workouts and daily activities.
            While total daily intake matters most, strategic timing can optimize performance and recovery.
            Pre-workout nutrition provides energy, while post-workout nutrition supports muscle repair
            and glycogen replenishment.
            """
        case "sleep_optimization":
            """
            Quality sleep is crucial for fitness progress, affecting hormone production, muscle recovery,
            and cognitive function. Adults need 7-9 hours of sleep per night. Sleep hygiene practices
            include consistent sleep schedules, cool dark environments, and limiting screen time before bed.
            """
        case "recovery_science":
            """
            Recovery is when your body adapts to training stress and becomes stronger. Active recovery,
            proper nutrition, hydration, and sleep all play crucial roles. Understanding recovery helps
            prevent overtraining and maximizes the benefits of your workouts.
            """
        default:
            """
            \(topicName) is an important aspect of fitness and health. Understanding this concept will
            help you make better decisions about your training and lifestyle. The key is to apply these
            principles consistently and adapt them to your individual needs and circumstances.
            """
        }

        // Adjust content based on knowledge level
        if knowledgeLevel == "complete_beginner" {
            return "Let's start with the basics of \(topicName.lowercased()). " + baseContent
        } else if knowledgeLevel == "advanced" {
            return baseContent + " Advanced practitioners should consider individual variations and periodization strategies."
        }

        return baseContent
    }

    private func generateKeyPoints(for topic: String, depth: String) -> [String] {
        let basePoints = switch topic {
        case "progressive_overload":
            [
                "Gradually increase training demands over time",
                "Can progress through weight, reps, sets, or intensity",
                "Essential for continued muscle and strength gains"
            ]
        case "nutrition_timing":
            [
                "Total daily intake is most important",
                "Pre-workout: focus on easily digestible carbs",
                "Post-workout: combine protein and carbs within 2 hours"
            ]
        case "sleep_optimization":
            [
                "Aim for 7-9 hours of quality sleep nightly",
                "Maintain consistent sleep and wake times",
                "Create a cool, dark, quiet sleep environment"
            ]
        default:
            [
                "Understanding the fundamentals is crucial",
                "Consistency in application yields best results",
                "Individual adaptation may be necessary"
            ]
        }

        if depth == "scientific_deep_dive" {
            return basePoints + ["Research shows significant physiological adaptations", "Molecular mechanisms involve specific pathways"]
        }

        return basePoints
    }

    private func generateActionItems(for topic: String) -> [String] {
        switch topic {
        case "progressive_overload":
            return [
                "Track your workouts to monitor progression",
                "Increase weight by 2.5-5% when you can complete all sets with good form",
                "Focus on one progression method at a time"
            ]
        case "nutrition_timing":
            return [
                "Eat a balanced meal 2-3 hours before training",
                "Have a protein-rich snack within 30 minutes post-workout",
                "Stay hydrated throughout the day"
            ]
        case "sleep_optimization":
            return [
                "Set a consistent bedtime and wake time",
                "Avoid screens 1 hour before bed",
                "Keep your bedroom temperature between 65-68°F"
            ]
        default:
            return [
                "Start implementing one small change today",
                "Track your progress over the next week",
                "Adjust based on your individual response"
            ]
        }
    }

    private func generateRelatedTopics(for topic: String) -> [String] {
        switch topic {
        case "progressive_overload":
            return ["periodization", "strength_training_basics", "recovery_science"]
        case "nutrition_timing":
            return ["macronutrient_balance", "hydration_science", "metabolism_basics"]
        case "sleep_optimization":
            return ["recovery_science", "stress_management", "habit_formation"]
        default:
            return ["exercise_physiology", "habit_formation", "motivation_psychology"]
        }
    }

    private func generateSources(for topic: String) -> [String] {
        return [
            "American College of Sports Medicine Position Stands",
            "Journal of Strength and Conditioning Research",
            "International Society of Sports Nutrition",
            "National Sleep Foundation Guidelines"
        ]
    }
}
