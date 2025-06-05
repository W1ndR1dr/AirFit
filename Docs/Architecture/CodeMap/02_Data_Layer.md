# 02_Data_Layer.md

The Data layer (`/AirFit/Data`) is responsible for data persistence, management, and migration, primarily using SwiftData.

## Key Subdirectories and Their Purpose:

*   **`/AirFit/Data/Extensions`**:
    *   `FetchDescriptor+Extensions.swift`: Provides convenient pre-defined `FetchDescriptor`s for common SwiftData queries.
    *   `ModelContainer+Testing.swift`: Utility extensions for setting up `ModelContainer` in testing environments.
*   **`/AirFit/Data/Managers`**:
    *   `DataManager.swift`: A singleton managing the SwiftData `ModelContainer` and `ModelContext`, and potentially handling initial data seeding.
*   **`/AirFit/Data/Migrations`**:
    *   `SchemaV1.swift`: Defines version 1 of the data schema and potentially migration plans.
*   **`/AirFit/Data/Models`**: This is the core of the data layer, defining all SwiftData `@Model` classes.

## Key SwiftData Models (from `/AirFit/Data/Models`):

*   **`User.swift`**: Represents the application user, holding profile information, preferences, and relationships to other data.
    *   *Key Properties*: `id`, `createdAt`, `lastActiveAt`, `email`, `name`, `preferredUnits`.
    *   *Relationships*: `onboardingProfile`, `foodEntries`, `workouts`, `dailyLogs`, `coachMessages`, `healthKitSyncRecords`, `chatSessions`.
*   **`OnboardingProfile.swift`**: Stores data collected during the onboarding process, specifically persona-related information.
    *   *Key Properties*: `personaPromptData`, `communicationPreferencesData`, `rawFullProfileData`.
    *   *Relationships*: `user`.
*   **`DailyLog.swift`**: Tracks daily subjective and objective health metrics.
    *   *Key Properties*: `date`, `subjectiveEnergyLevel`, `sleepQuality`, `stressLevel`, `weight`, `steps`.
    *   *Relationships*: `user`.
*   **`FoodEntry.swift`**: Represents a meal or food logging event.
    *   *Key Properties*: `loggedAt`, `mealType`, `rawTranscript`, `photoData`.
    *   *Relationships*: `items` (FoodItem), `nutritionData`, `user`.
*   **`FoodItem.swift`**: Details of an individual food item within a `FoodEntry`.
    *   *Key Properties*: `name`, `brand`, `quantity`, `unit`, `calories`, `proteinGrams`, `carbGrams`, `fatGrams`.
    *   *Relationships*: `foodEntry`.
*   **`NutritionData.swift`**: Aggregated nutrition data, likely per day. (Seems to be associated with FoodEntry, but might be a daily summary).
    *   *Key Properties*: `date`, `targetCalories`, `actualCalories`, `waterLiters`.
    *   *Relationships*: `foodEntries`.
*   **`Workout.swift`**: Represents a completed or planned workout session.
    *   *Key Properties*: `name`, `plannedDate`, `completedDate`, `durationSeconds`, `caloriesBurned`, `workoutType`.
    *   *Relationships*: `exercises`, `user`.
*   **`Exercise.swift`**: An exercise performed within a `Workout`.
    *   *Key Properties*: `name`, `muscleGroupsData`, `orderIndex`.
    *   *Relationships*: `sets`, `workout`.
*   **`ExerciseSet.swift`**: A single set of an `Exercise`.
    *   *Key Properties*: `setNumber`, `completedReps`, `completedWeightKg`, `completedDurationSeconds`.
    *   *Relationships*: `exercise`.
*   **`WorkoutTemplate.swift`**: A reusable template for creating workouts.
    *   *Key Properties*: `name`, `descriptionText`, `workoutType`, `isSystemTemplate`, `isFavorite`.
    *   *Relationships*: `exercises` (ExerciseTemplate).
*   **`ExerciseTemplate.swift`**: An exercise definition within a `WorkoutTemplate`.
    *   *Key Properties*: `name`, `muscleGroupsData`.
    *   *Relationships*: `sets` (SetTemplate), `workoutTemplate`.
*   **`SetTemplate.swift`**: A set definition within an `ExerciseTemplate`.
    *   *Key Properties*: `setNumber`, `targetReps`, `targetWeightKg`.
    *   *Relationships*: `exerciseTemplate`.
*   **`MealTemplate.swift`**: A reusable template for meals.
    *   *Key Properties*: `name`, `mealType`, `isSystemTemplate`, `isFavorite`.
    *   *Relationships*: `items` (FoodItemTemplate).
*   **`FoodItemTemplate.swift`**: A food item definition within a `MealTemplate`.
    *   *Key Properties*: `name`, `calories`, `proteinGrams`.
    *   *Relationships*: `mealTemplate`.
*   **`ChatMessage.swift`**: Represents a single message in a chat.
    *   *Key Properties*: `timestamp`, `role` (user/assistant), `content`.
    *   *Relationships*: `session`, `attachments`.
*   **`ChatSession.swift`**: Represents a conversation thread.
    *   *Key Properties*: `title`, `createdAt`, `lastMessageDate`.
    *   *Relationships*: `messages`, `user`.
*   **`ChatAttachment.swift`**: Represents an attachment to a `ChatMessage`.
    *   *Key Properties*: `type` (image/doc), `filename`, `data`.
    *   *Relationships*: `message`.
*   **`CoachMessage.swift`**: Stores messages exchanged with the AI coach, including metadata. (Potentially an evolution of/related to `ChatMessage`).
    *   *Key Properties*: `timestamp`, `role`, `content`, `userID`, `conversationID`, `modelUsed`, `tokenCount`.
    *   *Relationships*: `user`.
*   **`ConversationResponse.swift`**: Stores user responses during the (structured) onboarding conversation.
    *   *Key Properties*: `sessionId`, `nodeId`, `responseData`, `timestamp`.
    *   *Relationships*: `session` (ConversationSession).
*   **`ConversationSession.swift`**: Represents a single onboarding conversation flow session.
    *   *Key Properties*: `userId`, `startedAt`, `completedAt`, `currentNodeId`.
    *   *Relationships*: `responses`.
*   **`HealthKitSyncRecord.swift`**: Logs HealthKit data synchronization events.
    *   *Key Properties*: `dataType`, `lastSyncDate`, `success`.
    *   *Relationships*: `user`.

## Key Responsibilities:

*   Defining the application's data schema using SwiftData.
*   Providing a `DataManager` to access and manage the `ModelContainer` and `ModelContext`.
*   Handling data migrations.
*   Offering utility extensions for common data fetching operations.

## Key Dependencies:

*   **Consumed:**
    *   SwiftData (System Framework)
    *   Foundation (System Framework)
    *   Core Layer (for enums, simple models used in relationships, or utility functions if any).
*   **Provided:**
    *   Persistent data models and data access mechanisms for the Services and Modules layers.

## Tests:

Data layer components are tested in:
*   `/AirFit/AirFitTests/Data/UserModelTests.swift`: Tests the `User` model and its relationships.
*   Other model-specific tests might exist or be co-located with feature tests that use them.
*   Persistence tests for `ConversationManager` (e.g., `ConversationManagerPersistenceTests.swift`) indirectly test SwiftData interactions for `CoachMessage`.