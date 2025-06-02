import Foundation
import SwiftData

@MainActor
final class DataManager {
    static let shared = DataManager()
    private init() {}

    // MARK: - Initial Setup
    func performInitialSetup(with container: ModelContainer) async {
        do {
            let context = container.mainContext
            let descriptor = FetchDescriptor<User>()
            let existing = try context.fetch(descriptor)

            if existing.isEmpty {
                print("No existing user found, waiting for onboarding")
            } else {
                print("Found \(existing.count) existing users")
                await createSystemTemplatesIfNeeded(context: context)
            }
        } catch {
            print("Failed to perform initial setup: \(error)")
        }
    }

    // MARK: - System Templates
    private func createSystemTemplatesIfNeeded(context: ModelContext) async {
        do {
            var descriptor = FetchDescriptor<WorkoutTemplate>()
            descriptor.predicate = #Predicate { $0.isSystemTemplate == true }
            let existingTemplates = try context.fetch(descriptor)

            if existingTemplates.isEmpty {
                print("Creating system workout templates")
                createDefaultWorkoutTemplates(context: context)
                try context.save()
            }

            var mealDescriptor = FetchDescriptor<MealTemplate>()
            mealDescriptor.predicate = #Predicate { $0.isSystemTemplate == true }
            let existingMealTemplates = try context.fetch(mealDescriptor)

            if existingMealTemplates.isEmpty {
                print("Creating system meal templates")
                createDefaultMealTemplates(context: context)
                try context.save()
            }
        } catch {
            print("Failed to create system templates: \(error)")
        }
    }

    private func createDefaultWorkoutTemplates(context: ModelContext) {
        let upperBody = WorkoutTemplate(
            name: "Upper Body Strength",
            workoutType: .strength,
            isSystemTemplate: true
        )
        upperBody.estimatedDuration = 45 * 60
        upperBody.difficulty = "intermediate"

        let benchPress = ExerciseTemplate(name: "Bench Press", orderIndex: 0)
        benchPress.muscleGroups = ["Chest", "Triceps", "Shoulders"]
        for i in 1...4 {
            benchPress.sets.append(SetTemplate(setNumber: i, targetReps: 10))
        }
        upperBody.exercises.append(benchPress)

        let pullups = ExerciseTemplate(name: "Pull-ups", orderIndex: 1)
        pullups.muscleGroups = ["Back", "Biceps"]
        for i in 1...3 {
            pullups.sets.append(SetTemplate(setNumber: i, targetReps: 8))
        }
        upperBody.exercises.append(pullups)

        context.insert(upperBody)

        let hiit = WorkoutTemplate(
            name: "20-Minute HIIT",
            workoutType: .hiit,
            isSystemTemplate: true
        )
        hiit.estimatedDuration = 20 * 60
        hiit.difficulty = "intermediate"

        let burpees = ExerciseTemplate(name: "Burpees", orderIndex: 0)
        burpees.sets.append(SetTemplate(setNumber: 1, targetDurationSeconds: 45))
        hiit.exercises.append(burpees)

        context.insert(hiit)
    }

    private func createDefaultMealTemplates(context: ModelContext) {
        let breakfast = MealTemplate(
            name: "Protein Power Breakfast",
            mealType: .breakfast,
            isSystemTemplate: true
        )
        breakfast.estimatedCalories = 450
        breakfast.estimatedProtein = 35
        breakfast.estimatedCarbs = 40
        breakfast.estimatedFat = 15

        let eggs = FoodItemTemplate(name: "Scrambled Eggs")
        eggs.quantity = 2
        eggs.unit = "large"
        eggs.calories = 140
        eggs.proteinGrams = 12
        eggs.carbGrams = 2
        eggs.fatGrams = 10
        breakfast.items.append(eggs)

        let toast = FoodItemTemplate(name: "Whole Wheat Toast")
        toast.quantity = 2
        toast.unit = "slices"
        toast.calories = 160
        toast.proteinGrams = 8
        toast.carbGrams = 30
        toast.fatGrams = 2
        breakfast.items.append(toast)

        context.insert(breakfast)
    }
}

// MARK: - ModelContext Helpers
extension ModelContext {
    func fetchFirst<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> T? {
        var descriptor = FetchDescriptor<T>()
        descriptor.fetchLimit = 1
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        return try fetch(descriptor).first
    }

    func count<T: PersistentModel>(_ type: T.Type, where predicate: Predicate<T>? = nil) throws -> Int {
        var descriptor = FetchDescriptor<T>()
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        return try fetchCount(descriptor)
    }
}

// MARK: - Preview Support
#if DEBUG
extension DataManager {
    static var preview: DataManager {
        let manager = DataManager()
        // Create in-memory container for previews
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self,
            CoachMessage.self,
            ChatSession.self,
            ConversationSession.self,
            ConversationResponse.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        if let container = try? ModelContainer(for: schema, configurations: [configuration]) {
            manager._previewContainer = container
        }
        return manager
    }
    
    static var previewContainer: ModelContainer {
        createMemoryContainer()
    }
    
    private var _previewContainer: ModelContainer? {
        get { nil }
        set { }
    }
    
    var modelContext: ModelContext {
        _previewContainer?.mainContext ?? ModelContainer.createMemoryContainer().mainContext
    }
}

extension ModelContainer {
    static func createMemoryContainer() -> ModelContainer {
        let schema = Schema([
            User.self,
            OnboardingProfile.self,
            FoodEntry.self,
            Workout.self,
            DailyLog.self,
            CoachMessage.self,
            ChatSession.self,
            ConversationSession.self,
            ConversationResponse.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
#endif
