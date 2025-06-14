import SwiftData
import Foundation

// MARK: - Schema Version 1 (Current - AI-Native, No Templates)
enum SchemaV1: VersionedSchema {
    nonisolated(unsafe) static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            // Core Models
            User.self,
            OnboardingProfile.self,
            DailyLog.self,
            
            // Food Tracking
            FoodEntry.self,
            FoodItem.self,
            NutritionData.self,
            
            // Workout Models
            Workout.self,
            Exercise.self,
            ExerciseSet.self,
            
            // Goals
            TrackedGoal.self,
            
            // Chat/AI Models
            CoachMessage.self,
            ChatSession.self,
            ChatMessage.self,
            ChatAttachment.self,
            ConversationSession.self,
            ConversationResponse.self,
            
            // Sync Records
            HealthKitSyncRecord.self
            
            // NOTE: No template models - AI-native generation only
        ]
    }
}

// MARK: - Migration Plan (Single Schema for MVP)
enum AirFitMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        [
            // No migrations needed for MVP - single schema
        ]
    }
}
