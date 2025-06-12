# Phase 2.3 Data Layer Improvements - Required Reading List

## Core Context Files
- /Users/Brian/Coding Projects/AirFit/CLAUDE.md
- /Users/Brian/Coding Projects/AirFit/Manual.md

## Progress & Planning Documents
- /Users/Brian/Coding Projects/AirFit/Docs/CODEBASE_RECOVERY_PLAN.md
- /Users/Brian/Coding Projects/AirFit/Docs/PHASE_1_PROGRESS.md
- /Users/Brian/Coding Projects/AirFit/Docs/PHASE_2_PROGRESS.md
- /Users/Brian/Coding Projects/AirFit/Docs/PHASE_2_3_ModelContainer_Migration_Implementation.md
- /Users/Brian/Coding Projects/AirFit/Docs/ModelContainer_Error_Fix.md

## Essential Research Reports
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/Data_Layer_Analysis.md
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/Architecture_Overview_Analysis.md
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/Architecture_Dependencies_Analysis.md
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/DI_System_Complete_Analysis.md
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/Service_Layer_Complete_Catalog.md
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/App_Lifecycle_Analysis.md

## Development Standards
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/DI_STANDARDS.md
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/DI_LAZY_RESOLUTION_STANDARDS.md
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/ERROR_HANDLING_STANDARDS.md
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/CONCURRENCY_STANDARDS.md
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/NAMING_STANDARDS.md
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/PROJECT_FILE_MANAGEMENT.md

## Migration Guides
- /Users/Brian/Coding Projects/AirFit/Docs/ERROR_MIGRATION_GUIDE.md
- /Users/Brian/Coding Projects/AirFit/Docs/Migration_Strategy.md

## Data Layer Source Files

### Core Data Management
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Managers/DataManager.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Migrations/SchemaV1.swift

### Data Extensions
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Extensions/FetchDescriptor+Convenience.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Extensions/ModelContainer+Test.swift

### SwiftData Models
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/User.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/Goal.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/DailyLog.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/FoodEntry.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/FoodItem.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/FoodItemTemplate.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/MealTemplate.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/NutritionData.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/Workout.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/Exercise.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ExerciseSet.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ExerciseTemplate.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/WorkoutTemplate.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/SetTemplate.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/HealthKitSyncRecord.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ChatSession.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ChatMessage.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ChatAttachment.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/CoachMessage.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ConversationSession.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/ConversationResponse.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Data/Models/OnboardingProfile.swift

### Related Source Files
- /Users/Brian/Coding Projects/AirFit/AirFit/Core/Views/ModelContainerErrorView.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Application/AirFitApp.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Core/DI/DIBootstrapper.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Core/DI/DIContainer.swift

### Services Using Data Layer
- /Users/Brian/Coding Projects/AirFit/AirFit/Services/User/UserService.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Services/Goals/GoalService.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Workouts/Services/WorkoutService.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Modules/FoodTracking/Services/NutritionService.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/OnboardingService.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Onboarding/Services/PersonaService.swift
- /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Chat/Services/ChatHistoryManager.swift

## Related Module Documentation
- /Users/Brian/Coding Projects/AirFit/AirFit/Modules/Module_Services_Analysis.md
- /Users/Brian/Coding Projects/AirFit/Docs/Research Reports/HealthKit_Integration_Analysis.md

## Testing References
- /Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Data/UserModelTests.swift
- /Users/Brian/Coding Projects/AirFit/Docs/Development-Standards/TEST_STANDARDS.md

## Additional Context
- /Users/Brian/Coding Projects/AirFit/Docs/Filetree 6-8-25-10am.md
- /Users/Brian/Coding Projects/AirFit/project.yml

## Codex Documentation (if delegating)
- /Users/Brian/Coding Projects/AirFit/AGENTS.md
- /Users/Brian/Coding Projects/AirFit/Docs/CODEX_EXECUTION_GUIDE.md
- /Users/Brian/Coding Projects/AirFit/Docs/Archive/Codex-Analysis/CODEX_AGENT_TEMPLATE.md
- /Users/Brian/Coding Projects/AirFit/Docs/Archive/Codex-Analysis/CODEX_ANALYSIS_SUMMARY.md