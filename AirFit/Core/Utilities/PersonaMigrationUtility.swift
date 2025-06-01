import Foundation

/// Utility for migrating legacy Blend system to discrete PersonaMode system
/// Part of Phase 4 Persona System Refactor
struct PersonaMigrationUtility {
    
    /// Migrate legacy Blend to PersonaMode by finding dominant trait
    static func migrateBlendToPersonaMode(_ blend: Blend) -> PersonaMode {
        // Find the dominant persona trait
        let traits = [
            ("supportive", blend.encouragingEmpathetic),
            ("direct", blend.authoritativeDirect),
            ("analytical", blend.analyticalInsightful),
            ("motivational", blend.playfullyProvocative)
        ]
        
        let dominantTrait = traits.max { $0.1 < $1.1 }?.0 ?? "supportive"
        
        switch dominantTrait {
        case "direct": return .directTrainer
        case "analytical": return .analyticalAdvisor
        case "motivational": return .motivationalBuddy
        default: return .supportiveCoach
        }
    }
    
    /// Migrate user profile with legacy blend to new PersonaMode system
    static func migrateUserProfile(_ profile: UserProfileJsonBlob) -> UserProfileJsonBlob {
        // If profile already has PersonaMode and no blend, return as-is
        if profile.blend == nil {
            return profile
        }
        
        // If it has legacy Blend, convert it to PersonaMode
        guard let blend = profile.blend else {
            return profile
        }
        
        let migratedPersonaMode = migrateBlendToPersonaMode(blend)
        
        return UserProfileJsonBlob(
            lifeContext: profile.lifeContext,
            goal: profile.goal,
            personaMode: migratedPersonaMode,
            engagementPreferences: profile.engagementPreferences,
            sleepWindow: profile.sleepWindow,
            motivationalStyle: profile.motivationalStyle,
            timezone: profile.timezone,
            baselineModeEnabled: profile.baselineModeEnabled
        )
    }
    
    /// Check if a user profile needs migration
    static func needsMigration(_ profile: UserProfileJsonBlob) -> Bool {
        return profile.blend != nil
    }
    
    /// Create a new profile with PersonaMode (for new users)
    static func createNewProfile(
        lifeContext: LifeContext,
        goal: Goal,
        selectedPersonaMode: PersonaMode,
        engagementPreferences: EngagementPreferences,
        sleepWindow: SleepWindow,
        motivationalStyle: MotivationalStyle,
        timezone: String = TimeZone.current.identifier
    ) -> UserProfileJsonBlob {
        return UserProfileJsonBlob(
            lifeContext: lifeContext,
            goal: goal,
            personaMode: selectedPersonaMode,
            engagementPreferences: engagementPreferences,
            sleepWindow: sleepWindow,
            motivationalStyle: motivationalStyle,
            timezone: timezone,
            baselineModeEnabled: true
        )
    }
} 