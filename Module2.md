Understood! "Vibe-coding" it is – I like that term! My apologies for any lingering "human developer" assumptions. I'll ensure the instructions are geared towards you directing AI agents.

Let's proceed with Modular Sub-Document 2: **Data Layer (SwiftData Schema & Managers).** This builds directly on the foundation set by Sub-Document 1.

---

**Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers)**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:** Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To define and implement the complete data persistence schema for the AirFit application using SwiftData. This module establishes the single source of truth for all application data.
*   **Responsibilities:**
    *   Defining all SwiftData `@Model` classes according to the application's requirements.
    *   Specifying attributes, relationships (including cascade rules), and constraints for each model.
    *   Implementing any necessary custom initializers, computed properties, or helper methods within the models.
    *   (Future consideration, not for initial AI tasking) Establishing a strategy and initial implementation for data migrations if the schema evolves.
*   **Key Components within this Module:**
    *   SwiftData Model files (e.g., `User.swift`, `OnboardingProfile.swift`, `Workout.swift`, etc.) located within `AirFit/Data/Models/`.
    *   (Potentially, in the future) `DataMigrationManager.swift` or similar, located in `AirFit/Data/Managers/`.

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) – specifically sections referencing data captured or displayed (e.g., Persona Blueprint Flow, Dashboard elements).
    *   AirFit App - Master Architecture Specification (v1.2) – particularly Section 9 (Data Layer) from the original combined spec (v1.1/v1.2) for schema details.
    *   Modular Sub-Document 1: Core Project Setup & Configuration – for the project structure and core utilities.
*   **Outputs:**
    *   A complete set of SwiftData model classes integrated into the project.
    *   The application's data schema is ready for other modules to interact with (create, read, update, delete data).

**3. Detailed Component Specifications & Agent Tasks**

*(AI Agent Tasks: These tasks involve creating specific Swift files and defining classes with properties and methods. The agent should be instructed to place these files in the `AirFit/Data/Models/` directory created in Sub-Document 1.)*

---

**Task 2.0: Prepare SwiftData Environment**
    *   **Agent Task 2.0.1:**
        *   Instruction: "Ensure the main application struct `AirFitApp.swift` (and `AirFitWatchApp.swift` if creating models shared with watch) is configured to set up the SwiftData `ModelContainer`."
        *   Details:
            *   In `AirFit/Application/AirFitApp.swift`, import SwiftData.
            *   Modify the `AirFitApp` struct to include the `.modelContainer()` view modifier, listing all the model types that will be created in this module. For now, list the primary ones like `User.self`, `Workout.self`, `FoodEntry.self`, `CoachMessage.self`, `OnboardingProfile.self`, `DailyLog.self`. *This list will be expanded as each model is defined.*
            ```swift
            // AirFit/Application/AirFitApp.swift
            import SwiftUI
            import SwiftData // Import SwiftData

            @main
            struct AirFitApp: App {
                // Define the shared model container
                // Initially list key models, expand as they are created in this sub-document.
                let sharedModelContainer: ModelContainer = {
                    let schema = Schema([
                        User.self,
                        OnboardingProfile.self,
                        Workout.self,
                        Exercise.self,
                        ExerciseSet.self,
                        FoodEntry.self,
                        FoodItem.self,
                        DailyLog.self,
                        CoachMessage.self
                        // Add other models here as they are defined
                    ])
                    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false) // Set to true for UI Previews or specific testing if needed

                    do {
                        return try ModelContainer(for: schema, configurations: [modelConfiguration])
                    } catch {
                        fatalError("Could not create ModelContainer: \(error)") // Or use AppLogger.error
                    }
                }() // Immediately execute the closure

                var body: some Scene {
                    WindowGroup {
                        ContentView() // Placeholder - to be replaced by Onboarding or Dashboard later
                    }
                    .modelContainer(sharedModelContainer) // Apply the model container
                }
            }
            ```            *   Similarly, for `AirFit/Application/WatchApp/AirFitWatchApp.swift` if any models are directly used/synced to the watch via SwiftData's iCloud capabilities (if enabled later). For now, assume watch might access data via iOS app or have its own minimal subset if independent. If sharing via iCloud, its `.modelContainer` needs to reference the same schema.
        *   Acceptance Criteria: The `.modelContainer` is correctly set up in `AirFitApp.swift` (and `AirFitWatchApp.swift` if applicable) and the app compiles.

---

**Task 2.1: Define User & Onboarding Models**
    *   **Agent Task 2.1.1:**
        *   Instruction: "Create a new Swift file named `User.swift` in `AirFit/Data/Models/`. Define the `User` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/User.swift
            import SwiftData
            import Foundation

            @Model
            final class User {
                @Attribute(.unique) var id: UUID
                var createdAt: Date
                var lastActiveAt: Date // For tracking lapses
                var preferredUnits: String // e.g., "imperial", "metric"

                // Relationships with cascading delete rules
                @Relationship(deleteRule: .cascade, inverse: \OnboardingProfile.user)
                var onboardingProfile: OnboardingProfile?

                @Relationship(deleteRule: .cascade, inverse: \FoodEntry.user)
                var foodEntries: [FoodEntry]? = [] // Initialize as empty array

                @Relationship(deleteRule: .cascade, inverse: \Workout.user)
                var workouts: [Workout]? = []

                @Relationship(deleteRule: .cascade, inverse: \DailyLog.user)
                var dailyLogs: [DailyLog]? = []

                @Relationship(deleteRule: .cascade, inverse: \CoachMessage.user) // Assuming CoachMessages are linked to a user
                var coachMessages: [CoachMessage]? = []

                init(id: UUID = UUID(),
                     createdAt: Date = Date(),
                     lastActiveAt: Date = Date(),
                     preferredUnits: String = "imperial", // Default to imperial
                     onboardingProfile: OnboardingProfile? = nil) {
                    self.id = id
                    self.createdAt = createdAt
                    self.lastActiveAt = lastActiveAt
                    self.preferredUnits = preferredUnits
                    self.onboardingProfile = onboardingProfile
                    // Initialize relationship arrays if you want them non-optional from the start
                    self.foodEntries = []
                    self.workouts = []
                    self.dailyLogs = []
                    self.coachMessages = []
                }
            }
            ```
        *   Acceptance Criteria: `User.swift` is created, compiles, and matches the specification.
    *   **Agent Task 2.1.2:**
        *   Instruction: "Create a new Swift file named `OnboardingProfile.swift` in `AirFit/Data/Models/`. Define the `OnboardingProfile` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/OnboardingProfile.swift
            import SwiftData
            import Foundation

            @Model
            final class OnboardingProfile {
                var id: UUID
                var personaPromptData: Data // Stores the persona_profile.json (which is used to build the dynamic system prompt)
                var communicationPreferencesData: Data // Stores CommunicationPreferences struct as JSON
                @Attribute(.externalStorage) var rawFullProfileData: Data // The complete JSON from onboarding v3.1 for audit/reconstruction

                var user: User? // Inverse relationship

                init(id: UUID = UUID(),
                     personaPromptData: Data,
                     communicationPreferencesData: Data,
                     rawFullProfileData: Data,
                     user: User? = nil) {
                    self.id = id
                    self.personaPromptData = personaPromptData
                    self.communicationPreferencesData = communicationPreferencesData
                    self.rawFullProfileData = rawFullProfileData
                    self.user = user
                }
            }

            // Supporting struct to be encoded/decoded from communicationPreferencesData
            // This struct definition should be placed in a shared location like Core/Models or Core/Enums
            // For now, the agent can define it here, and we can task it to move it later.
            struct CommunicationPreferences: Codable {
                var absenceResponse: String // e.g., "gentle_nudge", "respect_space"
                var celebrationStyle: String // e.g., "subtle_affirming", "enthusiastic_celebratory"
                // Add any other preferences from Onboarding Flow v3.1 Screen 8
            }
            ```
        *   Acceptance Criteria: `OnboardingProfile.swift` is created, compiles, and matches specification. `CommunicationPreferences` struct is defined.
    *   **Agent Task 2.1.3 (Update Schema):**
        *   Instruction: "Update `AirFitApp.swift`'s `ModelContainer` schema to include `User.self` and `OnboardingProfile.self` if not already present from Task 2.0.1."
        *   Acceptance Criteria: `AirFitApp.swift` compiles with the updated schema.

---

**Task 2.2: Define Daily Logging Models**
    *   **Agent Task 2.2.1:**
        *   Instruction: "Create a new Swift file named `DailyLog.swift` in `AirFit/Data/Models/`. Define the `DailyLog` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/DailyLog.swift
            import SwiftData
            import Foundation

            @Model
            final class DailyLog {
                @Attribute(.unique) var date: Date // Store as YYYY-MM-DD, ensuring uniqueness for a given day. Time component should be ignored or zeroed out for unique constraint.
                var subjectiveEnergyLevel: Int? // 1-5 scale, optional
                // Potentially add other daily metrics here later (e.g., mood, stress, subjectiveSleepQuality)

                var user: User? // Inverse relationship

                init(date: Date, subjectiveEnergyLevel: Int? = nil, user: User? = nil) {
                    // Normalize date to start of day to ensure uniqueness for the date component
                    self.date = Calendar.current.startOfDay(for: date)
                    self.subjectiveEnergyLevel = subjectiveEnergyLevel
                    self.user = user
                }
            }
            ```        *   Acceptance Criteria: `DailyLog.swift` is created, compiles, and matches specification.
    *   **Agent Task 2.2.2:**
        *   Instruction: "Create a new Swift file named `FoodEntry.swift` in `AirFit/Data/Models/`. Define the `FoodEntry` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/FoodEntry.swift
            import SwiftData
            import Foundation

            @Model
            final class FoodEntry {
                var id: UUID
                var loggedAt: Date
                var mealType: String // Raw value from MealType enum
                var rawTranscript: String? // Optional, if logged via voice

                // AI Parsing Metadata for traceability (if parsed by LLM)
                var parsingModelUsed: String?
                var parsingConfidence: Double?

                @Relationship(deleteRule: .cascade, inverse: \FoodItem.foodEntry)
                var items: [FoodItem]? = []

                var user: User? // Inverse relationship

                init(id: UUID = UUID(),
                     loggedAt: Date = Date(),
                     mealType: MealType = .snack, // Use the enum for default
                     rawTranscript: String? = nil,
                     parsingModelUsed: String? = nil,
                     parsingConfidence: Double? = nil,
                     user: User? = nil) {
                    self.id = id
                    self.loggedAt = loggedAt
                    self.mealType = mealType.rawValue
                    self.rawTranscript = rawTranscript
                    self.parsingModelUsed = parsingModelUsed
                    self.parsingConfidence = parsingConfidence
                    self.items = []
                    self.user = user
                }
            }
            ```
        *   Acceptance Criteria: `FoodEntry.swift` is created, compiles, and matches specification.
    *   **Agent Task 2.2.3:**
        *   Instruction: "Create a new Swift file named `FoodItem.swift` in `AirFit/Data/Models/`. Define the `FoodItem` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/FoodItem.swift
            import SwiftData
            import Foundation

            @Model
            final class FoodItem {
                var id: UUID
                var name: String
                var quantity: Double?
                var unit: String? // e.g., "g", "oz", "cup", "item"
                var calories: Double?
                var proteinGrams: Double?
                var carbGrams: Double?
                var fatGrams: Double?
                // Add other micronutrients if detailed tracking is a future goal

                var foodEntry: FoodEntry? // Inverse relationship

                init(id: UUID = UUID(),
                     name: String,
                     quantity: Double? = nil,
                     unit: String? = nil,
                     calories: Double? = nil,
                     proteinGrams: Double? = nil,
                     carbGrams: Double? = nil,
                     fatGrams: Double? = nil,
                     foodEntry: FoodEntry? = nil) {
                    self.id = id
                    self.name = name
                    self.quantity = quantity
                    self.unit = unit
                    self.calories = calories
                    self.proteinGrams = proteinGrams
                    self.carbGrams = carbGrams
                    self.fatGrams = fatGrams
                    self.foodEntry = foodEntry
                }
            }
            ```
        *   Acceptance Criteria: `FoodItem.swift` is created, compiles, and matches specification.
    *   **Agent Task 2.2.4:**
        *   Instruction: "Create a new Swift file named `SupportingEnums.swift` in `AirFit/Core/Enums/` (or add to existing `GlobalEnums.swift`). Define the `MealType` enum."
        *   Details:
            ```swift
            // In AirFit/Core/Enums/SupportingEnums.swift (or GlobalEnums.swift)
            import Foundation

            enum MealType: String, Codable, CaseIterable {
                case breakfast = "Breakfast"
                case lunch = "Lunch"
                case dinner = "Dinner"
                case snack = "Snack"
                case preWorkout = "Pre-Workout"
                case postWorkout = "Post-Workout"
                // Add other types if necessary
            }
            ```
        *   Acceptance Criteria: `MealType` enum is defined and accessible.
    *   **Agent Task 2.2.5 (Update Schema):**
        *   Instruction: "Update `AirFitApp.swift`'s `ModelContainer` schema to include `DailyLog.self`, `FoodEntry.self`, and `FoodItem.self`."
        *   Acceptance Criteria: `AirFitApp.swift` compiles with the updated schema.

---

**Task 2.3: Define Workout Models**
    *   **Agent Task 2.3.1:**
        *   Instruction: "Create a new Swift file named `Workout.swift` in `AirFit/Data/Models/`. Define the `Workout` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/Workout.swift
            import SwiftData
            import Foundation

            @Model
            final class Workout {
                var id: UUID
                var name: String // e.g., "Upper Body Strength", "Morning Run"
                var plannedDate: Date? // If the workout was planned for a specific time
                var completedDate: Date? // When the workout was actually completed
                var durationSeconds: TimeInterval? // Total duration of the workout
                var notes: String? // User's notes about the workout

                // HealthKit sync metadata to prevent duplicates if syncing from HK
                var healthKitWorkoutID: String?
                var healthKitSyncedDate: Date?

                @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
                var exercises: [Exercise]? = []

                var user: User? // Inverse relationship

                init(id: UUID = UUID(),
                     name: String,
                     plannedDate: Date? = nil,
                     completedDate: Date? = nil,
                     durationSeconds: TimeInterval? = nil,
                     notes: String? = nil,
                     healthKitWorkoutID: String? = nil,
                     healthKitSyncedDate: Date? = nil,
                     user: User? = nil) {
                    self.id = id
                    self.name = name
                    self.plannedDate = plannedDate
                    self.completedDate = completedDate
                    self.durationSeconds = durationSeconds
                    self.notes = notes
                    self.healthKitWorkoutID = healthKitWorkoutID
                    self.healthKitSyncedDate = healthKitSyncedDate
                    self.exercises = []
                    self.user = user
                }
            }
            ```
        *   Acceptance Criteria: `Workout.swift` is created, compiles, and matches specification.
    *   **Agent Task 2.3.2:**
        *   Instruction: "Create a new Swift file named `Exercise.swift` in `AirFit/Data/Models/`. Define the `Exercise` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/Exercise.swift
            import SwiftData
            import Foundation

            @Model
            final class Exercise {
                var id: UUID
                var name: String // e.g., "Barbell Squat", "Push-ups"
                var muscleGroupsData: Data? // JSON encoded array of strings, e.g., ["Chest", "Triceps"]
                var notes: String?

                @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
                var sets: [ExerciseSet]? = []

                var workout: Workout? // Inverse relationship

                // Computed property for muscleGroups
                var muscleGroups: [String] {
                    get {
                        guard let data = muscleGroupsData else { return [] }
                        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
                    }
                    set {
                        muscleGroupsData = try? JSONEncoder().encode(newValue)
                    }
                }

                init(id: UUID = UUID(),
                     name: String,
                     muscleGroups: [String] = [],
                     notes: String? = nil,
                     workout: Workout? = nil) {
                    self.id = id
                    self.name = name
                    self.setMuscleGroups(muscleGroups) // Use helper to set
                    self.notes = notes
                    self.sets = []
                    self.workout = workout
                }

                // Helper method to set muscleGroups to handle encoding
                func setMuscleGroups(_ groups: [String]) {
                    self.muscleGroupsData = try? JSONEncoder().encode(groups)
                }
            }
            ```
        *   Acceptance Criteria: `Exercise.swift` is created, compiles, and matches specification.
    *   **Agent Task 2.3.3:**
        *   Instruction: "Create a new Swift file named `ExerciseSet.swift` in `AirFit/Data/Models/`. Define the `ExerciseSet` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/ExerciseSet.swift
            import SwiftData
            import Foundation

            @Model
            final class ExerciseSet {
                var id: UUID
                var setNumber: Int // e.g., 1, 2, 3
                var targetReps: Int?
                var completedReps: Int?
                var targetWeightKg: Double? // Store in a consistent unit (kg)
                var completedWeightKg: Double?
                var targetDurationSeconds: TimeInterval? // For timed sets like planks
                var completedDurationSeconds: TimeInterval?
                var rateOfPerceivedExertionRPE: Double? // Optional RPE logging (e.g., 1-10)
                var restDurationSeconds: TimeInterval? // Rest taken AFTER this set
                var notes: String?

                var exercise: Exercise? // Inverse relationship

                init(id: UUID = UUID(),
                     setNumber: Int,
                     targetReps: Int? = nil,
                     completedReps: Int? = nil,
                     targetWeightKg: Double? = nil,
                     completedWeightKg: Double? = nil,
                     targetDurationSeconds: TimeInterval? = nil,
                     completedDurationSeconds: TimeInterval? = nil,
                     rateOfPerceivedExertionRPE: Double? = nil,
                     restDurationSeconds: TimeInterval? = nil,
                     notes: String? = nil,
                     exercise: Exercise? = nil) {
                    self.id = id
                    self.setNumber = setNumber
                    self.targetReps = targetReps
                    self.completedReps = completedReps
                    self.targetWeightKg = targetWeightKg
                    self.completedWeightKg = completedWeightKg
                    self.targetDurationSeconds = targetDurationSeconds
                    self.completedDurationSeconds = completedDurationSeconds
                    self.rateOfPerceivedExertionRPE = rateOfPerceivedExertionRPE
                    self.restDurationSeconds = restDurationSeconds
                    self.notes = notes
                    self.exercise = exercise
                }
            }
            ```
        *   Acceptance Criteria: `ExerciseSet.swift` is created, compiles, and matches specification.
    *   **Agent Task 2.3.4 (Update Schema):**
        *   Instruction: "Update `AirFitApp.swift`'s `ModelContainer` schema to include `Workout.self`, `Exercise.self`, and `ExerciseSet.self`."
        *   Acceptance Criteria: `AirFitApp.swift` compiles with the updated schema.

---

**Task 2.4: Define AI Conversation Model**
    *   **Agent Task 2.4.1:**
        *   Instruction: "Create a new Swift file named `CoachMessage.swift` in `AirFit/Data/Models/`. Define the `CoachMessage` SwiftData model class as specified."
        *   Details:
            ```swift
            // AirFit/Data/Models/CoachMessage.swift
            import SwiftData
            import Foundation

            @Model
            final class CoachMessage {
                var id: UUID
                var timestamp: Date
                var role: String // "user" or "assistant" (or a Role enum)
                @Attribute(.externalStorage) var content: String // Can be long, so external storage is good

                // AI Metadata for assistant messages
                var modelUsed: String?
                var tokenCountInput: Int?
                var tokenCountOutput: Int?
                var requestedFunctionCallData: Data? // JSON string of the function call requested by AI
                var functionCallResultData: Data? // JSON string of the result of the function call executed by app

                var user: User? // Inverse relationship, assuming messages are per user

                init(id: UUID = UUID(),
                     timestamp: Date = Date(),
                     role: String, // Consider defining an enum for role
                     content: String,
                     modelUsed: String? = nil,
                     tokenCountInput: Int? = nil,
                     tokenCountOutput: Int? = nil,
                     requestedFunctionCallData: Data? = nil,
                     functionCallResultData: Data? = nil,
                     user: User? = nil) {
                    self.id = id
                    self.timestamp = timestamp
                    self.role = role
                    self.content = content
                    self.modelUsed = modelUsed
                    self.tokenCountInput = tokenCountInput
                    self.tokenCountOutput = tokenCountOutput
                    self.requestedFunctionCallData = requestedFunctionCallData
                    self.functionCallResultData = functionCallResultData
                    self.user = user
                }
            }

            // Consider adding this enum to SupportingEnums.swift or GlobalEnums.swift
            enum MessageRole: String, Codable {
                case user = "user"
                case assistant = "assistant"
                case system = "system" // If you ever store system messages in the history
                case tool = "tool"     // If you store tool/function call results as separate messages
            }
            ```
        *   Acceptance Criteria: `CoachMessage.swift` is created, compiles, and matches specification. `MessageRole` enum considered/defined.
    *   **Agent Task 2.4.2 (Update Schema):**
        *   Instruction: "Update `AirFitApp.swift`'s `ModelContainer` schema to include `CoachMessage.self`."
        *   Acceptance Criteria: `AirFitApp.swift` compiles with the updated schema.

---

**Task 2.5: Final Review & Commit**
    *   **Agent Task 2.5.1:**
        *   Instruction: "Review all created SwiftData model files (`User.swift`, `OnboardingProfile.swift`, `DailyLog.swift`, `FoodEntry.swift`, `FoodItem.swift`, `Workout.swift`, `Exercise.swift`, `ExerciseSet.swift`, `CoachMessage.swift`) for correctness against specifications, including initializers, property types, relationships, and any helper methods or enums."
        *   Acceptance Criteria: All models compile without error and adhere to the detailed specifications provided in Tasks 2.1-2.4. Inverse relationships are correctly defined where specified.
    *   **Agent Task 2.5.2:**
        *   Instruction: "Ensure `AirFitApp.swift` (and `AirFitWatchApp.swift` if applicable) has the complete and correct list of all defined models in its `Schema` array for the `ModelContainer`."
        *   Acceptance Criteria: The `ModelContainer` setup is correct and the app compiles.
    *   **Agent Task 2.5.3:**
        *   Instruction: "Stage all new Swift files in the `AirFit/Data/Models/` directory and any modified files (like `AirFitApp.swift` and enum files)."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 2.5.4:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Define SwiftData models for core application schema".
        *   Acceptance Criteria: Git history shows the new commit. Project builds successfully.

---

**4. Acceptance Criteria for Module Completion**

*   All specified SwiftData model classes are created in the `AirFit/Data/Models/` directory.
*   Each model class accurately reflects the attributes, relationships (with correct delete rules and inverse relationships), and initializers as detailed.
*   Supporting enums (like `MealType`, `MessageRole`) and structs (like `CommunicationPreferences`) are defined and correctly referenced or embedded.
*   The `ModelContainer` in `AirFitApp.swift` (and `AirFitWatchApp.swift` if applicable) is correctly configured with the complete schema of all defined models.
*   The entire project compiles successfully without errors or warnings related to the data models.
*   All changes are committed to the Git repository.

**5. Code Style Reminders for this Module**

*   Adhere strictly to SwiftData conventions (e.g., `@Model`, `@Attribute`, `@Relationship`).
*   Ensure all model properties are clearly named and typed.
*   Initialize relationship arrays (e.g., `var workouts: [Workout]? = []`) to avoid them being nil unexpectedly if they are conceptually lists that can be empty.
*   Use `UUID()` for IDs and `Date()` for timestamps as defaults in initializers where appropriate.
*   Ensure inverse relationships are correctly defined to maintain data integrity and enable efficient querying.
*   Code must pass SwiftLint checks.

---

This sub-document should provide the AI agent(s) with a clear "recipe" for constructing the data layer. The next step will be to build services and UI that interact with these models.
