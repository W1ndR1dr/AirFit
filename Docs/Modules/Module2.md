**Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:** Completion of Module 1: Core Project Setup & Configuration
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To define and implement the complete data persistence schema for the AirFit application using SwiftData with iOS 18 enhancements. This module establishes the single source of truth for all application data with proper concurrency safety and modern Swift 6 features.
*   **Responsibilities:**
    *   Defining all SwiftData `@Model` classes with proper Sendable conformance
    *   Implementing relationships with appropriate cascade rules and inverse specifications
    *   Creating thread-safe data managers with actor isolation
    *   Establishing migration strategies using VersionedSchema
    *   Implementing custom ModelContainer configuration for testing
    *   Creating data validation and transformation logic
    *   Setting up iCloud sync capabilities (CloudKit integration)
*   **Key Components:**
    *   SwiftData Models in `AirFit/Data/Models/`
    *   Data Managers in `AirFit/Data/Managers/`
    *   Migration schemas in `AirFit/Data/Migrations/`
    *   Model extensions in `AirFit/Data/Extensions/`

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Project structure, constants, and utilities
    *   Design Specification for data requirements
    *   Master Architecture Specification for schema details
*   **Outputs:**
    *   Complete SwiftData schema ready for all features
    *   Thread-safe data access patterns
    *   Testing-friendly model configuration

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 2.0: Configure SwiftData Environment**

**Agent Task 2.0.1: Update AirFitApp with ModelContainer**
- Instruction: "Configure main app with comprehensive SwiftData setup including error handling and migration support"
- File: `AirFit/Application/AirFitApp.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  
  @main
  struct AirFitApp: App {
      // MARK: - Properties
      @Environment(\.scenePhase) private var scenePhase
      @StateObject private var appState = AppState()
      
      // MARK: - Model Container
      static let sharedModelContainer: ModelContainer = {
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
          
          let modelConfiguration = ModelConfiguration(
              schema: schema,
              isStoredInMemoryOnly: false,
              allowsSave: true,
              cloudKitDatabase: .automatic
          )
          
          do {
              let container = try ModelContainer(
                  for: schema,
                  migrationPlan: AirFitMigrationPlan.self,
                  configurations: [modelConfiguration]
              )
              
              // Configure for better performance
              container.mainContext.autosaveEnabled = true
              container.mainContext.undoManager = nil // Disable undo for performance
              
              AppLogger.info("ModelContainer initialized successfully", category: .data)
              return container
          } catch {
              AppLogger.fault("Failed to create ModelContainer", error: error, category: .data)
              fatalError("Could not create ModelContainer: \(error)")
          }
      }()
      
      // MARK: - Body
      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environmentObject(appState)
                  .modelContainer(Self.sharedModelContainer)
                  .onAppear {
                      setupInitialData()
                  }
          }
          .onChange(of: scenePhase) { _, newPhase in
              handleScenePhaseChange(newPhase)
          }
      }
      
      // MARK: - Private Methods
      private func setupInitialData() {
          Task {
              await DataManager.shared.performInitialSetup()
          }
      }
      
      private func handleScenePhaseChange(_ phase: ScenePhase) {
          switch phase {
          case .background:
              // Save any pending changes
              try? Self.sharedModelContainer.mainContext.save()
          default:
              break
          }
      }
  }
  
  // MARK: - Migration Plan
  enum AirFitMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] {
          [SchemaV1.self] // Add future versions here
      }
      
      static var stages: [MigrationStage] {
          [] // Add migration stages as schema evolves
      }
  }
  
  // MARK: - Schema Versions
  enum SchemaV1: VersionedSchema {
      static var versionIdentifier = Schema.Version(1, 0, 0)
      static var models: [any PersistentModel.Type] {
          [User.self, OnboardingProfile.self, DailyLog.self, FoodEntry.self,
           FoodItem.self, Workout.self, Exercise.self, ExerciseSet.self,
           CoachMessage.self, ChatSession.self, ChatMessage.self, ChatAttachment.self,
           NutritionData.self, HealthKitSyncRecord.self,
           WorkoutTemplate.self, ExerciseTemplate.self, SetTemplate.self,
           MealTemplate.self, FoodItemTemplate.self]
      }
  }
  ```
- Acceptance Criteria:
  - ModelContainer properly configured with all models
  - CloudKit integration enabled
  - Migration plan structure in place
  - Error handling with proper logging
  - Autosave enabled for better UX

---

**Task 2.1: Define Core User Models**

**Agent Task 2.1.1: Create User Model**
- File: `AirFit/Data/Models/User.swift`
- Complete Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class User: Sendable {
      // MARK: - Properties
      @Attribute(.unique) var id: UUID
      var createdAt: Date
      var lastActiveAt: Date
      var email: String?
      var name: String?
      var preferredUnits: String // "imperial" or "metric"
      
      // MARK: - Computed Properties
      var isMetric: Bool {
          preferredUnits == "metric"
      }
      
      var daysActive: Int {
          Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
      }
      
      var isInactive: Bool {
          let daysSinceActive = Calendar.current.dateComponents([.day], from: lastActiveAt, to: Date()).day ?? 0
          return daysSinceActive > 7
      }
      
      // MARK: - Relationships
      @Relationship(deleteRule: .cascade, inverse: \OnboardingProfile.user)
      var onboardingProfile: OnboardingProfile?
      
      @Relationship(deleteRule: .cascade, inverse: \FoodEntry.user)
      var foodEntries: [FoodEntry] = []
      
      @Relationship(deleteRule: .cascade, inverse: \Workout.user)
      var workouts: [Workout] = []
      
      @Relationship(deleteRule: .cascade, inverse: \DailyLog.user)
      var dailyLogs: [DailyLog] = []
      
      @Relationship(deleteRule: .cascade, inverse: \CoachMessage.user)
      var coachMessages: [CoachMessage] = []
      
      @Relationship(deleteRule: .cascade, inverse: \HealthKitSyncRecord.user)
      var healthKitSyncRecords: [HealthKitSyncRecord] = []
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          createdAt: Date = Date(),
          lastActiveAt: Date = Date(),
          email: String? = nil,
          name: String? = nil,
          preferredUnits: String = "imperial"
      ) {
          self.id = id
          self.createdAt = createdAt
          self.lastActiveAt = lastActiveAt
          self.email = email
          self.name = name
          self.preferredUnits = preferredUnits
      }
      
      // MARK: - Methods
      func updateActivity() {
          lastActiveAt = Date()
      }
      
      func getTodaysLog() -> DailyLog? {
          let today = Calendar.current.startOfDay(for: Date())
          return dailyLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
      }
      
      func getRecentMeals(days: Int = 7) -> [FoodEntry] {
          let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
          return foodEntries
              .filter { $0.loggedAt > cutoffDate }
              .sorted { $0.loggedAt > $1.loggedAt }
      }
      
      func getRecentWorkouts(days: Int = 7) -> [Workout] {
          let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
          return workouts
              .compactMap { $0.completedDate != nil ? $0 : nil }
              .filter { $0.completedDate! > cutoffDate }
              .sorted { $0.completedDate! > $1.completedDate! }
      }
  }
  ```

**Agent Task 2.1.2: Create OnboardingProfile Model**
- File: `AirFit/Data/Models/OnboardingProfile.swift`
- Complete Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class OnboardingProfile: Sendable {
      // MARK: - Properties
      var id: UUID
      var createdAt: Date
      var personaPromptData: Data
      var communicationPreferencesData: Data
      @Attribute(.externalStorage) var rawFullProfileData: Data
      
      // MARK: - Relationships
      var user: User?
      
      // MARK: - Computed Properties
      var personaProfile: PersonaProfile? {
          try? JSONDecoder().decode(PersonaProfile.self, from: personaPromptData)
      }
      
      var communicationPreferences: CommunicationPreferences? {
          try? JSONDecoder().decode(CommunicationPreferences.self, from: communicationPreferencesData)
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          createdAt: Date = Date(),
          personaPromptData: Data,
          communicationPreferencesData: Data,
          rawFullProfileData: Data,
          user: User? = nil
      ) {
          self.id = id
          self.createdAt = createdAt
          self.personaPromptData = personaPromptData
          self.communicationPreferencesData = communicationPreferencesData
          self.rawFullProfileData = rawFullProfileData
          self.user = user
      }
      
      // MARK: - Convenience Initializer
      init(
          user: User,
          personaProfile: PersonaProfile,
          communicationPreferences: CommunicationPreferences
      ) throws {
          self.id = UUID()
          self.createdAt = Date()
          self.user = user
          
          let encoder = JSONEncoder()
          encoder.dateEncodingStrategy = .iso8601
          
          self.personaPromptData = try encoder.encode(personaProfile)
          self.communicationPreferencesData = try encoder.encode(communicationPreferences)
          self.rawFullProfileData = try encoder.encode(personaProfile) // Full profile for v1
      }
  }
  
  // MARK: - Supporting Types
  struct PersonaProfile: Codable, Sendable {
      let lifeContext: LifeSnapshotSelections
      let coreAspiration: String
      let structuredGoal: StructuredGoal?
      let coachingStyle: CoachingStylePreferences
      let engagementPreference: EngagementPreset
      let customEngagement: CustomEngagementSettings
      let availability: [WorkoutAvailabilityBlock]
      let sleepSchedule: SleepSchedule
      let motivationStyle: MotivationStyle
      let establishBaseline: Bool
  }
  
  struct CommunicationPreferences: Codable, Sendable {
      let coachingStyleBlend: CoachingStylePreferences
      let achievementAcknowledgement: AchievementStyle
      let inactivityResponse: InactivityResponseStyle
      let preferredCheckInTimes: [Date]?
      let quietHoursEnabled: Bool
      let quietHoursStart: Date?
      let quietHoursEnd: Date?
  }
  ```

---

**Task 2.2: Define Nutrition Models**

**Agent Task 2.2.1: Create FoodEntry Model**
- File: `AirFit/Data/Models/FoodEntry.swift`
- Complete Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class FoodEntry: Sendable {
      // MARK: - Properties
      var id: UUID
      var loggedAt: Date
      var mealType: String
      var rawTranscript: String?
      var photoData: Data?
      var notes: String?
      
      // AI Metadata
      var parsingModelUsed: String?
      var parsingConfidence: Double?
      var parsingTimestamp: Date?
      
      // MARK: - Relationships
      @Relationship(deleteRule: .cascade, inverse: \FoodItem.foodEntry)
      var items: [FoodItem] = []
      
      @Relationship(deleteRule: .nullify, inverse: \NutritionData.foodEntries)
      var nutritionData: NutritionData?
      
      var user: User?
      
      // MARK: - Computed Properties
      var totalCalories: Double {
          items.reduce(0) { $0 + ($1.calories ?? 0) }
      }
      
      var totalProtein: Double {
          items.reduce(0) { $0 + ($1.proteinGrams ?? 0) }
      }
      
      var totalCarbs: Double {
          items.reduce(0) { $0 + ($1.carbGrams ?? 0) }
      }
      
      var totalFat: Double {
          items.reduce(0) { $0 + ($1.fatGrams ?? 0) }
      }
      
      var mealTypeEnum: MealType? {
          MealType(rawValue: mealType)
      }
      
      var isComplete: Bool {
          !items.isEmpty && items.allSatisfy { item in
              item.calories != nil && item.proteinGrams != nil &&
              item.carbGrams != nil && item.fatGrams != nil
          }
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          loggedAt: Date = Date(),
          mealType: MealType = .snack,
          rawTranscript: String? = nil,
          photoData: Data? = nil,
          notes: String? = nil,
          user: User? = nil
      ) {
          self.id = id
          self.loggedAt = loggedAt
          self.mealType = mealType.rawValue
          self.rawTranscript = rawTranscript
          self.photoData = photoData
          self.notes = notes
          self.user = user
      }
      
      // MARK: - Methods
      func addItem(_ item: FoodItem) {
          items.append(item)
          item.foodEntry = self
      }
      
      func updateFromAIParsing(model: String, confidence: Double) {
          self.parsingModelUsed = model
          self.parsingConfidence = confidence
          self.parsingTimestamp = Date()
      }
  }
  
  // MARK: - MealType Enum
  enum MealType: String, Codable, CaseIterable, Sendable {
      case breakfast = "breakfast"
      case lunch = "lunch"
      case dinner = "dinner"
      case snack = "snack"
      case preWorkout = "pre_workout"
      case postWorkout = "post_workout"
      
      var displayName: String {
          switch self {
          case .breakfast: return "Breakfast"
          case .lunch: return "Lunch"
          case .dinner: return "Dinner"
          case .snack: return "Snack"
          case .preWorkout: return "Pre-Workout"
          case .postWorkout: return "Post-Workout"
          }
      }
      
      var defaultTime: DateComponents {
          switch self {
          case .breakfast: return DateComponents(hour: 8, minute: 0)
          case .lunch: return DateComponents(hour: 12, minute: 30)
          case .dinner: return DateComponents(hour: 18, minute: 30)
          case .snack: return DateComponents(hour: 15, minute: 0)
          case .preWorkout: return DateComponents(hour: 17, minute: 0)
          case .postWorkout: return DateComponents(hour: 19, minute: 0)
          }
      }
  }
  ```

**Agent Task 2.2.2: Create FoodItem Model**
- File: `AirFit/Data/Models/FoodItem.swift`
- Complete Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class FoodItem: Sendable {
      // MARK: - Properties
      var id: UUID
      var name: String
      var brand: String?
      var barcode: String?
      var quantity: Double?
      var unit: String?
      var calories: Double?
      var proteinGrams: Double?
      var carbGrams: Double?
      var fatGrams: Double?
      var fiberGrams: Double?
      var sugarGrams: Double?
      var sodiumMg: Double?
      var servingSize: String?
      var servingsConsumed: Double = 1.0
      
      // Data Source
      var dataSource: String? // "user", "database", "ai_parsed", "barcode"
      var databaseID: String? // External database reference
      var verificationStatus: String? // "verified", "unverified", "user_modified"
      
      // MARK: - Relationships
      var foodEntry: FoodEntry?
      
      // MARK: - Computed Properties
      var actualCalories: Double {
          (calories ?? 0) * servingsConsumed
      }
      
      var actualProtein: Double {
          (proteinGrams ?? 0) * servingsConsumed
      }
      
      var actualCarbs: Double {
          (carbGrams ?? 0) * servingsConsumed
      }
      
      var actualFat: Double {
          (fatGrams ?? 0) * servingsConsumed
      }
      
      var macroPercentages: (protein: Double, carbs: Double, fat: Double)? {
          guard let protein = proteinGrams,
                let carbs = carbGrams,
                let fat = fatGrams else { return nil }
          
          let totalCalories = (protein * 4) + (carbs * 4) + (fat * 9)
          guard totalCalories > 0 else { return (0, 0, 0) }
          
          return (
              protein: (protein * 4) / totalCalories,
              carbs: (carbs * 4) / totalCalories,
              fat: (fat * 9) / totalCalories
          )
      }
      
      var isValid: Bool {
          !name.isEmpty && calories != nil && calories! >= 0
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          name: String,
          brand: String? = nil,
          quantity: Double? = nil,
          unit: String? = nil,
          calories: Double? = nil,
          proteinGrams: Double? = nil,
          carbGrams: Double? = nil,
          fatGrams: Double? = nil
      ) {
          self.id = id
          self.name = name
          self.brand = brand
          self.quantity = quantity
          self.unit = unit
          self.calories = calories
          self.proteinGrams = proteinGrams
          self.carbGrams = carbGrams
          self.fatGrams = fatGrams
      }
      
      // MARK: - Methods
      func updateNutrition(
          calories: Double,
          protein: Double,
          carbs: Double,
          fat: Double,
          fiber: Double? = nil,
          sugar: Double? = nil,
          sodium: Double? = nil
      ) {
          self.calories = calories
          self.proteinGrams = protein
          self.carbGrams = carbs
          self.fatGrams = fat
          self.fiberGrams = fiber
          self.sugarGrams = sugar
          self.sodiumMg = sodium
          self.verificationStatus = "user_modified"
      }
  }
  ```

**Agent Task 2.2.3: Create NutritionData Model**
- File: `AirFit/Data/Models/NutritionData.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class NutritionData: Sendable {
      // MARK: - Properties
      var id: UUID
      var date: Date
      var targetCalories: Double?
      var targetProtein: Double?
      var targetCarbs: Double?
      var targetFat: Double?
      var actualCalories: Double = 0
      var actualProtein: Double = 0
      var actualCarbs: Double = 0
      var actualFat: Double = 0
      var waterLiters: Double = 0
      var notes: String?
      
      // MARK: - Relationships
      @Relationship(inverse: \FoodEntry.nutritionData)
      var foodEntries: [FoodEntry] = []
      
      // MARK: - Computed Properties
      var calorieDeficit: Double? {
          guard let target = targetCalories else { return nil }
          return target - actualCalories
      }
      
      var proteinProgress: Double {
          guard let target = targetProtein, target > 0 else { return 0 }
          return min(actualProtein / target, 1.0)
      }
      
      var carbsProgress: Double {
          guard let target = targetCarbs, target > 0 else { return 0 }
          return min(actualCarbs / target, 1.0)
      }
      
      var fatProgress: Double {
          guard let target = targetFat, target > 0 else { return 0 }
          return min(actualFat / target, 1.0)
      }
      
      var isComplete: Bool {
          targetCalories != nil && targetProtein != nil &&
          targetCarbs != nil && targetFat != nil
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          date: Date = Date(),
          targetCalories: Double? = nil,
          targetProtein: Double? = nil,
          targetCarbs: Double? = nil,
          targetFat: Double? = nil
      ) {
          self.id = id
          self.date = Calendar.current.startOfDay(for: date)
          self.targetCalories = targetCalories
          self.targetProtein = targetProtein
          self.targetCarbs = targetCarbs
          self.targetFat = targetFat
      }
      
      // MARK: - Methods
      func updateActuals() {
          actualCalories = foodEntries.reduce(0) { $0 + $1.totalCalories }
          actualProtein = foodEntries.reduce(0) { $0 + $1.totalProtein }
          actualCarbs = foodEntries.reduce(0) { $0 + $1.totalCarbs }
          actualFat = foodEntries.reduce(0) { $0 + $1.totalFat }
      }
  }
  ```

---

**Task 2.3: Define Workout Models**

**Agent Task 2.3.1: Create Workout Model**
- File: `AirFit/Data/Models/Workout.swift`
- Complete Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class Workout: Sendable {
      // MARK: - Properties
      var id: UUID
      var name: String
      var plannedDate: Date?
      var completedDate: Date?
      var durationSeconds: TimeInterval?
      var caloriesBurned: Double?
      var notes: String?
      var workoutType: String
      var intensity: String? // "low", "moderate", "high"
      
      // HealthKit Integration
      var healthKitWorkoutID: String?
      var healthKitSyncedDate: Date?
      
      // Template Reference
      var templateID: UUID?
      
      // MARK: - Relationships
      @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
      var exercises: [Exercise] = []
      
      var user: User?
      
      // MARK: - Computed Properties
      var isCompleted: Bool {
          completedDate != nil
      }
      
      var totalSets: Int {
          exercises.reduce(0) { $0 + $1.sets.count }
      }
      
      var totalVolume: Double {
          exercises.reduce(0) { total, exercise in
              total + exercise.sets.reduce(0) { setTotal, set in
                  setTotal + ((set.completedWeightKg ?? 0) * Double(set.completedReps ?? 0))
              }
          }
      }
      
      var workoutTypeEnum: WorkoutType? {
          WorkoutType(rawValue: workoutType)
      }
      
      var formattedDuration: String? {
          guard let duration = durationSeconds else { return nil }
          let hours = Int(duration) / 3600
          let minutes = (Int(duration) % 3600) / 60
          
          if hours > 0 {
              return "\(hours)h \(minutes)m"
          } else {
              return "\(minutes)m"
          }
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          name: String,
          workoutType: WorkoutType = .general,
          plannedDate: Date? = nil,
          user: User? = nil
      ) {
          self.id = id
          self.name = name
          self.workoutType = workoutType.rawValue
          self.plannedDate = plannedDate
          self.user = user
      }
      
      // MARK: - Methods
      func startWorkout() {
          if completedDate == nil {
              completedDate = Date()
          }
      }
      
      func completeWorkout() {
          completedDate = Date()
          if let startTime = plannedDate {
              durationSeconds = Date().timeIntervalSince(startTime)
          }
      }
      
      func addExercise(_ exercise: Exercise) {
          exercises.append(exercise)
          exercise.workout = self
      }
      
      func createFromTemplate(_ template: WorkoutTemplate) {
          self.name = template.name
          self.workoutType = template.workoutType
          self.templateID = template.id
          
          // Copy exercises from template
          for templateExercise in template.exercises {
              let exercise = Exercise(
                  name: templateExercise.name,
                  muscleGroups: templateExercise.muscleGroups
              )
              
              // Copy sets from template
              for templateSet in templateExercise.sets {
                  let set = ExerciseSet(
                      setNumber: templateSet.setNumber,
                      targetReps: templateSet.targetReps,
                      targetWeightKg: templateSet.targetWeightKg,
                      targetDurationSeconds: templateSet.targetDurationSeconds
                  )
                  exercise.addSet(set)
              }
              
              addExercise(exercise)
          }
      }
  }
  
  // MARK: - WorkoutType Enum
  enum WorkoutType: String, Codable, CaseIterable, Sendable {
      case strength = "strength"
      case cardio = "cardio"
      case flexibility = "flexibility"
      case sports = "sports"
      case general = "general"
      case hiit = "hiit"
      case yoga = "yoga"
      case pilates = "pilates"
      
      var displayName: String {
          switch self {
          case .strength: return "Strength Training"
          case .cardio: return "Cardio"
          case .flexibility: return "Flexibility"
          case .sports: return "Sports"
          case .general: return "General"
          case .hiit: return "HIIT"
          case .yoga: return "Yoga"
          case .pilates: return "Pilates"
          }
      }
      
      var systemImage: String {
          switch self {
          case .strength: return "dumbbell.fill"
          case .cardio: return "figure.run"
          case .flexibility: return "figure.flexibility"
          case .sports: return "sportscourt.fill"
          case .general: return "figure.mixed.cardio"
          case .hiit: return "flame.fill"
          case .yoga: return "figure.yoga"
          case .pilates: return "figure.pilates"
          }
      }
  }
  ```

**Agent Task 2.3.2: Create Exercise Model**
- File: `AirFit/Data/Models/Exercise.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class Exercise: Sendable {
      // MARK: - Properties
      var id: UUID
      var name: String
      var muscleGroupsData: Data?
      var equipmentData: Data?
      var notes: String?
      var orderIndex: Int
      var restSeconds: TimeInterval?
      
      // MARK: - Relationships
      @Relationship(deleteRule: .cascade, inverse: \ExerciseSet.exercise)
      var sets: [ExerciseSet] = []
      
      var workout: Workout?
      
      // MARK: - Computed Properties
      var muscleGroups: [String] {
          get {
              guard let data = muscleGroupsData else { return [] }
              return (try? JSONDecoder().decode([String].self, from: data)) ?? []
          }
          set {
              muscleGroupsData = try? JSONEncoder().encode(newValue)
          }
      }
      
      var equipment: [String] {
          get {
              guard let data = equipmentData else { return [] }
              return (try? JSONDecoder().decode([String].self, from: data)) ?? []
          }
          set {
              equipmentData = try? JSONEncoder().encode(newValue)
          }
      }
      
      var completedSets: [ExerciseSet] {
          sets.filter { $0.isCompleted }
      }
      
      var bestSet: ExerciseSet? {
          sets.max { set1, set2 in
              let volume1 = (set1.completedWeightKg ?? 0) * Double(set1.completedReps ?? 0)
              let volume2 = (set2.completedWeightKg ?? 0) * Double(set2.completedReps ?? 0)
              return volume1 < volume2
          }
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          name: String,
          muscleGroups: [String] = [],
          equipment: [String] = [],
          orderIndex: Int = 0
      ) {
          self.id = id
          self.name = name
          self.orderIndex = orderIndex
          self.muscleGroups = muscleGroups
          self.equipment = equipment
      }
      
      // MARK: - Methods
      func addSet(_ set: ExerciseSet) {
          sets.append(set)
          set.exercise = self
      }
      
      func duplicateLastSet() {
          guard let lastSet = sets.last else { return }
          
          let newSet = ExerciseSet(
              setNumber: lastSet.setNumber + 1,
              targetReps: lastSet.targetReps,
              targetWeightKg: lastSet.targetWeightKg,
              targetDurationSeconds: lastSet.targetDurationSeconds
          )
          addSet(newSet)
      }
  }
  ```

**Agent Task 2.3.3: Create ExerciseSet Model**
- File: `AirFit/Data/Models/ExerciseSet.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class ExerciseSet: Sendable {
      // MARK: - Properties
      var id: UUID
      var setNumber: Int
      var targetReps: Int?
      var completedReps: Int?
      var targetWeightKg: Double?
      var completedWeightKg: Double?
      var targetDurationSeconds: TimeInterval?
      var completedDurationSeconds: TimeInterval?
      var rpe: Double? // Rate of Perceived Exertion (1-10)
      var restDurationSeconds: TimeInterval?
      var notes: String?
      var completedAt: Date?
      
      // MARK: - Relationships
      var exercise: Exercise?
      
      // MARK: - Computed Properties
      var isCompleted: Bool {
          completedReps != nil || completedDurationSeconds != nil
      }
      
      var volume: Double? {
          guard let weight = completedWeightKg ?? targetWeightKg,
                let reps = completedReps ?? targetReps else { return nil }
          return weight * Double(reps)
      }
      
      var oneRepMax: Double? {
          guard let weight = completedWeightKg ?? targetWeightKg,
                let reps = completedReps ?? targetReps,
                reps > 0 else { return nil }
          
          // Epley Formula: 1RM = weight × (1 + reps/30)
          return weight * (1 + Double(reps) / 30)
      }
      
      var intensityPercentage: Double? {
          guard let weight = completedWeightKg ?? targetWeightKg,
                let oneRM = oneRepMax,
                oneRM > 0 else { return nil }
          return (weight / oneRM) * 100
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          setNumber: Int,
          targetReps: Int? = nil,
          targetWeightKg: Double? = nil,
          targetDurationSeconds: TimeInterval? = nil
      ) {
          self.id = id
          self.setNumber = setNumber
          self.targetReps = targetReps
          self.targetWeightKg = targetWeightKg
          self.targetDurationSeconds = targetDurationSeconds
      }
      
      // MARK: - Methods
      func complete(
          reps: Int? = nil,
          weight: Double? = nil,
          duration: TimeInterval? = nil,
          rpe: Double? = nil
      ) {
          self.completedReps = reps ?? targetReps
          self.completedWeightKg = weight ?? targetWeightKg
          self.completedDurationSeconds = duration ?? targetDurationSeconds
          self.rpe = rpe
          self.completedAt = Date()
      }
      
      func reset() {
          completedReps = nil
          completedWeightKg = nil
          completedDurationSeconds = nil
          rpe = nil
          completedAt = nil
      }
  }
  ```

---

**Task 2.4: Define Additional Models**

**Agent Task 2.4.1: Create DailyLog Model**
- File: `AirFit/Data/Models/DailyLog.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class DailyLog: Sendable {
      // MARK: - Properties
      @Attribute(.unique) var date: Date
      var subjectiveEnergyLevel: Int? // 1-5
      var sleepQuality: Int? // 1-5
      var stressLevel: Int? // 1-5
      var mood: String?
      var weight: Double? // kg
      var bodyFat: Double? // percentage
      var notes: String?
      var checkedIn: Bool = false
      
      // Activity Metrics
      var steps: Int?
      var activeCalories: Double?
      var exerciseMinutes: Int?
      var standHours: Int?
      
      // MARK: - Relationships
      var user: User?
      
      // MARK: - Computed Properties
      var overallWellness: Double? {
          let metrics = [subjectiveEnergyLevel, sleepQuality].compactMap { $0 }
          guard !metrics.isEmpty else { return nil }
          
          let stressAdjusted = stressLevel.map { 6 - $0 } // Invert stress (lower is better)
          let allMetrics = metrics + [stressAdjusted].compactMap { $0 }
          
          return Double(allMetrics.reduce(0, +)) / Double(allMetrics.count)
      }
      
      var hasHealthMetrics: Bool {
          steps != nil || activeCalories != nil || exerciseMinutes != nil
      }
      
      var hasSubjectiveMetrics: Bool {
          subjectiveEnergyLevel != nil || sleepQuality != nil || stressLevel != nil
      }
      
      // MARK: - Initialization
      init(
          date: Date = Date(),
          user: User? = nil
      ) {
          self.date = Calendar.current.startOfDay(for: date)
          self.user = user
      }
      
      // MARK: - Methods
      func updateHealthMetrics(
          steps: Int? = nil,
          activeCalories: Double? = nil,
          exerciseMinutes: Int? = nil,
          standHours: Int? = nil
      ) {
          if let steps = steps { self.steps = steps }
          if let calories = activeCalories { self.activeCalories = calories }
          if let minutes = exerciseMinutes { self.exerciseMinutes = minutes }
          if let hours = standHours { self.standHours = hours }
      }
      
      func checkIn(
          energy: Int? = nil,
          sleep: Int? = nil,
          stress: Int? = nil,
          mood: String? = nil
      ) {
          self.subjectiveEnergyLevel = energy
          self.sleepQuality = sleep
          self.stressLevel = stress
          self.mood = mood
          self.checkedIn = true
      }
  }
  ```

**Agent Task 2.4.2: Create CoachMessage Model**
- File: `AirFit/Data/Models/CoachMessage.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class CoachMessage: Sendable {
      // MARK: - Properties
      var id: UUID
      var timestamp: Date
      var role: String
      @Attribute(.externalStorage) var content: String
      var conversationID: UUID?
      
      // AI Metadata
      var modelUsed: String?
      var promptTokens: Int?
      var completionTokens: Int?
      var totalTokens: Int?
      var temperature: Double?
      var responseTimeMs: Int?
      
      // Function Calling
      var functionCallData: Data?
      var functionResultData: Data?
      
      // User Feedback
      var userRating: Int? // 1-5
      var userFeedback: String?
      var wasHelpful: Bool?
      
      // MARK: - Relationships
      var user: User?
      
      // MARK: - Computed Properties
      var messageRole: MessageRole? {
          MessageRole(rawValue: role)
      }
      
      var functionCall: FunctionCall? {
          guard let data = functionCallData else { return nil }
          return try? JSONDecoder().decode(FunctionCall.self, from: data)
      }
      
      var functionResult: FunctionResult? {
          guard let data = functionResultData else { return nil }
          return try? JSONDecoder().decode(FunctionResult.self, from: data)
      }
      
      var estimatedCost: Double? {
          guard let total = totalTokens,
                let model = modelUsed else { return nil }
          
          // Rough cost estimates per 1K tokens
          let costPer1K: Double = switch model {
          case "gpt-4": 0.03
          case "gpt-3.5-turbo": 0.002
          case "claude-3": 0.025
          default: 0.01
          }
          
          return Double(total) / 1000.0 * costPer1K
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          timestamp: Date = Date(),
          role: MessageRole,
          content: String,
          conversationID: UUID? = nil,
          user: User? = nil
      ) {
          self.id = id
          self.timestamp = timestamp
          self.role = role.rawValue
          self.content = content
          self.conversationID = conversationID
          self.user = user
      }
      
      // MARK: - Methods
      func recordAIMetadata(
          model: String,
          promptTokens: Int,
          completionTokens: Int,
          temperature: Double,
          responseTime: TimeInterval
      ) {
          self.modelUsed = model
          self.promptTokens = promptTokens
          self.completionTokens = completionTokens
          self.totalTokens = promptTokens + completionTokens
          self.temperature = temperature
          self.responseTimeMs = Int(responseTime * 1000)
      }
      
      func recordUserFeedback(rating: Int? = nil, feedback: String? = nil, helpful: Bool? = nil) {
          if let rating = rating { self.userRating = rating }
          if let feedback = feedback { self.userFeedback = feedback }
          if let helpful = helpful { self.wasHelpful = helpful }
      }
  }
  
  // MARK: - Supporting Types
  enum MessageRole: String, Codable, Sendable {
      case system = "system"
      case user = "user"
      case assistant = "assistant"
      case function = "function"
      case tool = "tool"
  }
  
  struct FunctionCall: Codable, Sendable {
      let name: String
      let arguments: [String: Any]
      
      enum CodingKeys: String, CodingKey {
          case name, arguments
      }
      
      init(from decoder: Decoder) throws {
          let container = try decoder.container(keyedBy: CodingKeys.self)
          name = try container.decode(String.self, forKey: .name)
          let argumentsData = try container.decode(Data.self, forKey: .arguments)
          arguments = try JSONSerialization.jsonObject(with: argumentsData) as? [String: Any] ?? [:]
      }
      
      func encode(to encoder: Encoder) throws {
          var container = encoder.container(keyedBy: CodingKeys.self)
          try container.encode(name, forKey: .name)
          let argumentsData = try JSONSerialization.data(withJSONObject: arguments)
          try container.encode(argumentsData, forKey: .arguments)
      }
  }
  
  struct FunctionResult: Codable, Sendable {
      let success: Bool
      let result: Any?
      let error: String?
      
      // Similar Codable implementation as FunctionCall
  }
  ```

**Agent Task 2.4.3: Create HealthKitSyncRecord Model**
- File: `AirFit/Data/Models/HealthKitSyncRecord.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class HealthKitSyncRecord: Sendable {
      // MARK: - Properties
      var id: UUID
      var dataType: String // HKQuantityType identifier
      var lastSyncDate: Date
      var syncDirection: String // "read", "write", "both"
      var recordCount: Int
      var success: Bool
      var errorMessage: String?
      
      // MARK: - Relationships
      var user: User?
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          dataType: String,
          syncDirection: SyncDirection,
          user: User? = nil
      ) {
          self.id = id
          self.dataType = dataType
          self.lastSyncDate = Date()
          self.syncDirection = syncDirection.rawValue
          self.recordCount = 0
          self.success = true
          self.user = user
      }
      
      // MARK: - Methods
      func recordSync(count: Int, success: Bool, error: String? = nil) {
          self.lastSyncDate = Date()
          self.recordCount = count
          self.success = success
          self.errorMessage = error
      }
  }
  
  enum SyncDirection: String, Sendable {
      case read = "read"
      case write = "write"
      case both = "both"
  }
  ```

**Agent Task 2.4.4: Create Template Models**
- File: `AirFit/Data/Models/Templates.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class WorkoutTemplate: Sendable {
      var id: UUID
      var name: String
      var descriptionText: String?
      var workoutType: String
      var estimatedDuration: TimeInterval?
      var difficulty: String? // "beginner", "intermediate", "advanced"
      var isSystemTemplate: Bool = false
      var isFavorite: Bool = false
      var lastUsedDate: Date?
      var useCount: Int = 0
      
      @Relationship(deleteRule: .cascade)
      var exercises: [ExerciseTemplate] = []
      
      init(
          id: UUID = UUID(),
          name: String,
          workoutType: WorkoutType = .general,
          isSystemTemplate: Bool = false
      ) {
          self.id = id
          self.name = name
          self.workoutType = workoutType.rawValue
          self.isSystemTemplate = isSystemTemplate
      }
      
      func recordUse() {
          lastUsedDate = Date()
          useCount += 1
      }
  }
  
  @Model
  final class ExerciseTemplate: Sendable {
      var id: UUID
      var name: String
      var muscleGroupsData: Data?
      var orderIndex: Int
      
      @Relationship(deleteRule: .cascade)
      var sets: [SetTemplate] = []
      
      var muscleGroups: [String] {
          get {
              guard let data = muscleGroupsData else { return [] }
              return (try? JSONDecoder().decode([String].self, from: data)) ?? []
          }
          set {
              muscleGroupsData = try? JSONEncoder().encode(newValue)
          }
      }
      
      init(name: String, orderIndex: Int = 0) {
          self.id = UUID()
          self.name = name
          self.orderIndex = orderIndex
      }
  }
  
  @Model
  final class SetTemplate: Sendable {
      var id: UUID
      var setNumber: Int
      var targetReps: Int?
      var targetWeightKg: Double?
      var targetDurationSeconds: TimeInterval?
      
      init(
          setNumber: Int,
          targetReps: Int? = nil,
          targetWeightKg: Double? = nil,
          targetDurationSeconds: TimeInterval? = nil
      ) {
          self.id = UUID()
          self.setNumber = setNumber
          self.targetReps = targetReps
          self.targetWeightKg = targetWeightKg
          self.targetDurationSeconds = targetDurationSeconds
      }
  }
  
  @Model
  final class MealTemplate: Sendable {
      var id: UUID
      var name: String
      var mealType: String
      var descriptionText: String?
      var photoData: Data?
      var estimatedCalories: Double?
      var estimatedProtein: Double?
      var estimatedCarbs: Double?
      var estimatedFat: Double?
      var isSystemTemplate: Bool = false
      var isFavorite: Bool = false
      var lastUsedDate: Date?
      var useCount: Int = 0
      
      @Relationship(deleteRule: .cascade)
      var items: [FoodItemTemplate] = []
      
      init(
          id: UUID = UUID(),
          name: String,
          mealType: MealType = .lunch,
          isSystemTemplate: Bool = false
      ) {
          self.id = id
          self.name = name
          self.mealType = mealType.rawValue
          self.isSystemTemplate = isSystemTemplate
      }
      
      func recordUse() {
          lastUsedDate = Date()
          useCount += 1
      }
  }
  
  @Model
  final class FoodItemTemplate: Sendable {
      var id: UUID
      var name: String
      var quantity: Double?
      var unit: String?
      var calories: Double?
      var proteinGrams: Double?
      var carbGrams: Double?
      var fatGrams: Double?
      
      init(name: String) {
          self.id = UUID()
          self.name = name
      }
  }
  ```

**Agent Task 2.4.5: Create Chat Models**
- File: `AirFit/Data/Models/ChatModels.swift`
- Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @Model
  final class ChatSession: Sendable {
      // MARK: - Properties
      var id: UUID
      var title: String?
      var createdAt: Date
      var lastMessageDate: Date?
      var isActive: Bool
      var archivedAt: Date?
      var messageCount: Int
      
      // MARK: - Relationships
      @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
      var messages: [ChatMessage] = []
      
      var user: User?
      
      // MARK: - Computed Properties
      var displayTitle: String {
          if let title = title, !title.isEmpty {
              return title
          }
          
          // Generate title from first message or date
          if let firstMessage = messages.first {
              return String(firstMessage.content.prefix(50))
          }
          
          return "Chat \(createdAt.formatted(date: .abbreviated, time: .shortened))"
      }
      
      var duration: TimeInterval? {
          guard let first = messages.first?.timestamp,
                let last = messages.last?.timestamp else { return nil }
          return last.timeIntervalSince(first)
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          user: User? = nil,
          title: String? = nil
      ) {
          self.id = id
          self.user = user
          self.title = title
          self.createdAt = Date()
          self.isActive = true
          self.messageCount = 0
      }
      
      // MARK: - Methods
      func addMessage(_ message: ChatMessage) {
          messages.append(message)
          message.session = self
          messageCount = messages.count
          lastMessageDate = message.timestamp
      }
      
      func archive() {
          isActive = false
          archivedAt = Date()
      }
  }
  
  @Model
  final class ChatMessage: Sendable {
      // MARK: - Properties
      var id: UUID
      var content: String
      var role: String
      var timestamp: Date
      var editedAt: Date?
      var metadata: [String: Any]?
      
      // Attachments
      @Relationship(deleteRule: .cascade, inverse: \ChatAttachment.message)
      var attachments: [ChatAttachment] = []
      
      // MARK: - Relationships
      var session: ChatSession?
      
      // MARK: - Computed Properties
      var roleEnum: Role {
          Role(rawValue: role) ?? .user
      }
      
      var isEdited: Bool {
          editedAt != nil
      }
      
      var hasAttachments: Bool {
          !attachments.isEmpty
      }
      
      // Metadata helpers
      var tokens: Int? {
          metadata?["tokens"] as? Int
      }
      
      var confidence: Double? {
          metadata?["confidence"] as? Double
      }
      
      var actionType: String? {
          metadata?["actionType"] as? String
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          session: ChatSession? = nil,
          content: String,
          role: Role,
          attachments: [ChatAttachment] = []
      ) {
          self.id = id
          self.session = session
          self.content = content
          self.role = role.rawValue
          self.timestamp = Date()
          self.attachments = attachments
          self.metadata = [:]
      }
      
      // MARK: - Methods
      func edit(newContent: String) {
          content = newContent
          editedAt = Date()
      }
      
      func addAttachment(_ attachment: ChatAttachment) {
          attachments.append(attachment)
          attachment.message = self
      }
      
      // MARK: - Nested Types
      enum Role: String, Codable, Sendable {
          case system = "system"
          case user = "user"
          case assistant = "assistant"
          case function = "function"
          
          var displayName: String {
              switch self {
              case .system: return "System"
              case .user: return "You"
              case .assistant: return "AI Coach"
              case .function: return "Function"
              }
          }
      }
  }
  
  @Model
  final class ChatAttachment: Sendable {
      // MARK: - Properties
      var id: UUID
      var type: String
      var data: Data?
      var url: String?
      var mimeType: String?
      var fileName: String?
      var fileSize: Int64?
      var thumbnailData: Data?
      var createdAt: Date
      
      // MARK: - Relationships
      var message: ChatMessage?
      
      // MARK: - Computed Properties
      var typeEnum: AttachmentType {
          AttachmentType(rawValue: type) ?? .other
      }
      
      var displayName: String {
          fileName ?? typeEnum.defaultName
      }
      
      var formattedSize: String? {
          guard let size = fileSize else { return nil }
          let formatter = ByteCountFormatter()
          formatter.countStyle = .file
          return formatter.string(fromByteCount: size)
      }
      
      // MARK: - Initialization
      init(
          id: UUID = UUID(),
          type: AttachmentType,
          data: Data? = nil,
          fileName: String? = nil
      ) {
          self.id = id
          self.type = type.rawValue
          self.data = data
          self.fileName = fileName
          self.fileSize = data.map { Int64($0.count) }
          self.createdAt = Date()
          
          // Set mime type based on attachment type
          switch type {
          case .image:
              self.mimeType = "image/jpeg"
          case .document:
              self.mimeType = "application/pdf"
          case .audio:
              self.mimeType = "audio/m4a"
          case .other:
              self.mimeType = "application/octet-stream"
          }
      }
      
      // MARK: - Nested Types
      enum AttachmentType: String, Codable, Sendable {
          case image = "image"
          case document = "document"
          case audio = "audio"
          case other = "other"
          
          var systemImage: String {
              switch self {
              case .image: return "photo"
              case .document: return "doc"
              case .audio: return "waveform"
              case .other: return "paperclip"
              }
          }
          
          var defaultName: String {
              switch self {
              case .image: return "Image"
              case .document: return "Document"
              case .audio: return "Audio"
              case .other: return "Attachment"
              }
          }
      }
  }
  ```

**Agent Task 2.4.6: Update User Model for Chat Relationship**
- Update to User model to add chat sessions:
  ```swift
  // Add to User model relationships:
  @Relationship(deleteRule: .cascade, inverse: \ChatSession.user)
  var chatSessions: [ChatSession] = []
  
  // Add computed property:
  var activeChats: [ChatSession] {
      chatSessions.filter { $0.isActive }
  }
  ```

---

**Task 2.5: Create Data Manager**

**Agent Task 2.5.1: Create DataManager Actor**
- File: `AirFit/Data/Managers/DataManager.swift`
- Complete Implementation:
  ```swift
  import SwiftData
  import Foundation
  
  @globalActor
  actor DataManager {
      static let shared = DataManager()
      
      private init() {}
      
      // MARK: - Initial Setup
      func performInitialSetup() async {
          do {
              let context = AirFitApp.sharedModelContainer.mainContext
              
              // Check if user exists
              let userDescriptor = FetchDescriptor<User>()
              let existingUsers = try context.fetch(userDescriptor)
              
              if existingUsers.isEmpty {
                  AppLogger.info("No existing user found, waiting for onboarding", category: .data)
              } else {
                  AppLogger.info("Found \(existingUsers.count) existing users", category: .data)
                  
                  // Create system templates if needed
                  await createSystemTemplatesIfNeeded(context: context)
              }
          } catch {
              AppLogger.error("Failed to perform initial setup", error: error, category: .data)
          }
      }
      
      // MARK: - System Templates
      private func createSystemTemplatesIfNeeded(context: ModelContext) async {
          do {
              // Check for existing system templates
              var descriptor = FetchDescriptor<WorkoutTemplate>()
              descriptor.predicate = #Predicate { $0.isSystemTemplate == true }
              let existingTemplates = try context.fetch(descriptor)
              
              if existingTemplates.isEmpty {
                  AppLogger.info("Creating system workout templates", category: .data)
                  createDefaultWorkoutTemplates(context: context)
                  try context.save()
              }
              
              // Check meal templates
              var mealDescriptor = FetchDescriptor<MealTemplate>()
              mealDescriptor.predicate = #Predicate { $0.isSystemTemplate == true }
              let existingMealTemplates = try context.fetch(mealDescriptor)
              
              if existingMealTemplates.isEmpty {
                  AppLogger.info("Creating system meal templates", category: .data)
                  createDefaultMealTemplates(context: context)
                  try context.save()
              }
          } catch {
              AppLogger.error("Failed to create system templates", error: error, category: .data)
          }
      }
      
      private func createDefaultWorkoutTemplates(context: ModelContext) {
          // Upper Body Template
          let upperBody = WorkoutTemplate(
              name: "Upper Body Strength",
              workoutType: .strength,
              isSystemTemplate: true
          )
          upperBody.estimatedDuration = 45 * 60 // 45 minutes
          upperBody.difficulty = "intermediate"
          
          // Add exercises
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
          
          // HIIT Template
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
          // Healthy Breakfast
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
  
  // MARK: - Model Extensions for Data Manager
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
  ```

---

**Task 2.6: Create Model Container Configuration**

**Agent Task 2.6.1: Update ModelContainer Configuration**
- File: `AirFit/Application/AirFitApp.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  
  @main
  struct AirFitApp: App {
      // MARK: - Properties
      @Environment(\.scenePhase) private var scenePhase
      @StateObject private var appState = AppState()
      
      // MARK: - Model Container
      static let sharedModelContainer: ModelContainer = {
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
          
          let modelConfiguration = ModelConfiguration(
              schema: schema,
              isStoredInMemoryOnly: false,
              allowsSave: true,
              cloudKitDatabase: .automatic
          )
          
          do {
              let container = try ModelContainer(
                  for: schema,
                  migrationPlan: AirFitMigrationPlan.self,
                  configurations: [modelConfiguration]
              )
              
              // Configure for better performance
              container.mainContext.autosaveEnabled = true
              container.mainContext.undoManager = nil // Disable undo for performance
              
              AppLogger.info("ModelContainer initialized successfully", category: .data)
              return container
          } catch {
              AppLogger.fault("Failed to create ModelContainer", error: error, category: .data)
              fatalError("Could not create ModelContainer: \(error)")
          }
      }()
      
      // MARK: - Body
      var body: some Scene {
          WindowGroup {
              ContentView()
                  .environmentObject(appState)
                  .modelContainer(Self.sharedModelContainer)
                  .onAppear {
                      setupInitialData()
                  }
          }
          .onChange(of: scenePhase) { _, newPhase in
              handleScenePhaseChange(newPhase)
          }
      }
      
      // MARK: - Private Methods
      private func setupInitialData() {
          Task {
              await DataManager.shared.performInitialSetup()
          }
      }
      
      private func handleScenePhaseChange(_ phase: ScenePhase) {
          switch phase {
          case .background:
              // Save any pending changes
              try? Self.sharedModelContainer.mainContext.save()
          default:
              break
          }
      }
  }
  
  // MARK: - Migration Plan
  enum AirFitMigrationPlan: SchemaMigrationPlan {
      static var schemas: [any VersionedSchema.Type] {
          [SchemaV1.self] // Add future versions here
      }
      
      static var stages: [MigrationStage] {
          [] // Add migration stages as schema evolves
      }
  }
  
  // MARK: - Schema Versions
  enum SchemaV1: VersionedSchema {
      static var versionIdentifier = Schema.Version(1, 0, 0)
      static var models: [any PersistentModel.Type] {
          [User.self, OnboardingProfile.self, DailyLog.self, FoodEntry.self,
           FoodItem.self, Workout.self, Exercise.self, ExerciseSet.self,
           CoachMessage.self, ChatSession.self, ChatMessage.self, ChatAttachment.self,
           NutritionData.self, HealthKitSyncRecord.self,
           WorkoutTemplate.self, ExerciseTemplate.self, SetTemplate.self,
           MealTemplate.self, FoodItemTemplate.self]
      }
  }
  ```

---

**4. Testing Requirements**

### Unit Tests

**Agent Task 2.12.1: Create Model Tests**
- File: `AirFitTests/Data/UserModelTests.swift`
- Required Test Cases:
  ```swift
  @MainActor
  final class UserModelTests: XCTestCase {
      var modelContext: ModelContext!
      
      override func setUp() async throws {
          try await super.setUp()
          modelContext = try SwiftDataTestHelper.createTestContext(for: User.self)
      }
      
      func test_createUser_withDefaultValues_shouldInitializeCorrectly() throws {
          // Arrange & Act
          let user = User()
          modelContext.insert(user)
          try modelContext.save()
          
          // Assert
          XCTAssertNotNil(user.id)
          XCTAssertEqual(user.preferredUnits, "imperial")
          XCTAssertTrue(user.foodEntries.isEmpty)
          XCTAssertEqual(user.daysActive, 0)
          XCTAssertFalse(user.isInactive)
      }
      
      func test_userRelationships_whenDeleted_shouldCascadeDelete() throws {
          // Arrange
          let user = User()
          let foodEntry = FoodEntry(user: user)
          let workout = Workout(name: "Test", user: user)
          
          modelContext.insert(user)
          try modelContext.save()
          
          // Act
          modelContext.delete(user)
          try modelContext.save()
          
          // Assert
          let entries = try modelContext.fetch(FetchDescriptor<FoodEntry>())
          let workouts = try modelContext.fetch(FetchDescriptor<Workout>())
          XCTAssertTrue(entries.isEmpty)
          XCTAssertTrue(workouts.isEmpty)
      }
      
      func test_getTodaysLog_withMultipleLogs_shouldReturnToday() throws {
          // Arrange
          let user = User()
          let todayLog = DailyLog(date: Date(), user: user)
          let yesterdayLog = DailyLog(
              date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
              user: user
          )
          
          modelContext.insert(user)
          try modelContext.save()
          
          // Act
          let result = user.getTodaysLog()
          
          // Assert
          XCTAssertEqual(result?.id, todayLog.id)
      }
  }
  ```

**Agent Task 2.12.2: Create Data Manager Tests**
- File: `AirFitTests/Data/DataManagerTests.swift`
- Test Cases:
  - Initial setup creates system templates
  - Templates are not duplicated on subsequent launches
  - Error handling for corrupted data
  - Concurrent access safety

### Integration Tests

**Agent Task 2.12.3: Create SwiftData Integration Tests**
- File: `AirFitTests/Data/SwiftDataIntegrationTests.swift`
- Test Cases:
  - Complex relationship queries
  - Migration between schema versions
  - CloudKit sync simulation
  - Performance with large datasets

---

**5. Acceptance Criteria for Module Completion**

- ✅ All SwiftData models created with proper attributes and relationships
- ✅ Models conform to Sendable for Swift 6 concurrency
- ✅ Inverse relationships correctly defined with cascade rules
- ✅ ModelContainer configured with CloudKit integration
- ✅ Migration plan structure implemented with SchemaV1
- ✅ DataManager actor created for thread-safe operations
- ✅ System templates creation logic implemented
- ✅ All computed properties work correctly
- ✅ Model validation logic in place
- ✅ Helper methods for common operations
- ✅ All models compile without warnings
- ✅ Unit test coverage ≥ 80% for models
- ✅ Integration tests for complex scenarios
- ✅ Performance: Model operations < 50ms
- ✅ Memory: Efficient external storage for large data

**6. Module Dependencies**

- **Requires Completion Of:** Module 1 (Core Setup)
- **Must Be Completed Before:** Module 3-12 (all features need data layer)
- **Can Run In Parallel With:** Module 0 (Testing Foundation)

**7. Performance Requirements**

- Model insertion: < 10ms per record
- Fetch with predicate: < 50ms for 1000 records  
- Relationship traversal: < 5ms
- CloudKit sync: Background, non-blocking

---
