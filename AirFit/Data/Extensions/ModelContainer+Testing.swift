import SwiftData
import Foundation

extension ModelContainer {
    /// Creates an in-memory ModelContainer for testing
    static func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            DailyLog.self,
            FoodEntry.self,
            FoodItem.self,
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            CoachMessage.self,
            ChatSession.self,
            ChatMessage.self,
            ChatAttachment.self,
            NutritionData.self,
            HealthKitSyncRecord.self,
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            SetTemplate.self,
            MealTemplate.self,
            FoodItemTemplate.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Creates a test container with sample data
    @MainActor
    static func createTestContainerWithSampleData() throws -> ModelContainer {
        let container = try createTestContainer()
        let context = container.mainContext

        // Create test user
        let user = User(
            id: UUID(),
            createdAt: Date(),
            lastActiveAt: Date(),
            email: "test@example.com",
            name: "Test User",
            preferredUnits: "metric"
        )
        context.insert(user)

        // Create today's log
        let todayLog = DailyLog(date: Date(), user: user)
        todayLog.checkIn(energy: 4, sleep: 5, stress: 2, mood: "Good")
        context.insert(todayLog)

        // Create sample meal
        let breakfast = FoodEntry(
            mealType: .breakfast,
            user: user
        )

        let eggs = FoodItem(
            name: "Scrambled Eggs",
            quantity: 2,
            unit: "large",
            calories: 140,
            proteinGrams: 12,
            carbGrams: 2,
            fatGrams: 10
        )
        breakfast.addItem(eggs)
        context.insert(breakfast)

        // Create sample workout
        let workout = Workout(
            name: "Morning Workout",
            workoutType: .strength,
            user: user
        )

        let benchPress = Exercise(
            name: "Bench Press",
            muscleGroups: ["Chest", "Triceps"]
        )

        for i in 1...3 {
            let set = ExerciseSet(
                setNumber: i,
                targetReps: 10,
                targetWeightKg: 60
            )
            benchPress.addSet(set)
        }

        workout.addExercise(benchPress)
        context.insert(workout)

        // Save context
        try context.save()

        return container
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension ModelContainer {
    @MainActor
    static var preview: ModelContainer {
        do {
            return try .createTestContainerWithSampleData()
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
#endif
