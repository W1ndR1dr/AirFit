import SwiftData
import Foundation

// MARK: - Schema Version 1
enum SchemaV1: VersionedSchema {
    nonisolated(unsafe) static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
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
        ]
    }
}

// MARK: - Migration Plan
enum AirFitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
