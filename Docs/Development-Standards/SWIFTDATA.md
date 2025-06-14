# SwiftData Standards for AirFit

**Last Updated**: 2025-06-14  
**Status**: Active - Critical Architecture Guidelines  
**Priority**: 🚨 Critical - Affects service actor isolation and performance

## Table of Contents
1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [When to Use SwiftData vs Native Frameworks](#when-to-use-swiftdata-vs-native-frameworks)
4. [Model Design Patterns](#model-design-patterns)
5. [Actor Isolation Constraints](#actor-isolation-constraints)
6. [ModelContext Handling](#modelcontext-handling)
7. [Performance Guidelines](#performance-guidelines)
8. [Migration Strategies](#migration-strategies)
9. [Anti-Patterns](#anti-patterns)
10. [Quick Reference](#quick-reference)

## Overview

SwiftData is a powerful persistence framework but comes with significant architectural constraints, especially around concurrency. This document defines when and how to use SwiftData optimally while minimizing its impact on service actor isolation.

**Key Insight**: SwiftData `@Model` types are not `Sendable`, forcing services that use `ModelContext` to be `@MainActor`, which blocks concurrency. We minimize this by using native frameworks (HealthKit, WorkoutKit) for data that can be stored elsewhere.

## Core Principles

### 1. **Native Frameworks First**
```swift
// ✅ PREFERRED: Use HealthKit for health data
let healthStore = HKHealthStore()
healthStore.save(samples) // Thread-safe, background capable

// ❌ AVOID: SwiftData for data that belongs in native frameworks
@Model class HealthMetric { } // Forces service to @MainActor
```

### 2. **SwiftData for App-Specific Value**
```swift
// ✅ CORRECT: App-specific data that adds unique value
@Model class CoachPersona { } // AI personas - unique to our app
@Model class ChatSession { } // Conversation history - app-specific

// ❌ WRONG: Generic health data in SwiftData
@Model class WorkoutSession { } // Should use HealthKit HKWorkout
```

### 3. **Minimize Actor Constraint Impact**
```swift
// ✅ GOAL: Keep most services as actors
actor NutritionService { } // HealthKit-based, no SwiftData

// ❌ CONSTRAINT: Only when absolutely necessary
@MainActor class UserService { } // Must use SwiftData for personas
```

## When to Use SwiftData vs Native Frameworks

### ✅ Use SwiftData For:

#### 1. **AI & Coaching Data**
```swift
@Model class CoachPersona {
    var systemPrompt: String
    var communicationStyle: Data
    var adaptationRules: Data
}

@Model class ChatSession {
    var messages: [ChatMessage]
    var conversationContext: Data
}
```
**Rationale**: No native framework equivalent, core app value-add

#### 2. **App-Specific User Preferences**
```swift
@Model class UserPreferences {
    var preferredUnits: String
    var notificationSettings: Data
    var onboardingCompleted: Bool
}
```
**Rationale**: App-specific settings not suitable for system frameworks

#### 3. **Custom Goal Definitions**
```swift
@Model class CustomGoal {
    var title: String
    var customCriteria: Data
    var aiGeneratedMilestones: [Milestone]
}
```
**Rationale**: Complex goal logic beyond HealthKit's basic goals

#### 4. **Service Coordination Metadata**
```swift
@Model class SyncRecord {
    var lastSyncDate: Date
    var dataType: String
    var conflicts: [ConflictResolution]
}
```
**Rationale**: Internal app coordination, not user-facing data

### ❌ Use Native Frameworks For:

#### 1. **Nutrition Data → HealthKit**
```swift
// ❌ WRONG: SwiftData nutrition
@Model class FoodEntry { var calories: Double }

// ✅ CORRECT: HealthKit nutrition
let caloriesSample = HKQuantitySample(
    type: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: 500),
    start: Date(),
    end: Date()
)
```

#### 2. **Workout Data → HealthKit + WorkoutKit**
```swift
// ❌ WRONG: SwiftData workouts
@Model class Workout { var exercises: [Exercise] }

// ✅ CORRECT: HealthKit workouts
let workout = HKWorkout(
    activityType: .traditionalStrengthTraining,
    start: startDate,
    end: endDate,
    duration: duration,
    totalEnergyBurned: calories,
    totalDistance: nil,
    metadata: ["exercises": exerciseData]
)
```

#### 3. **Body Metrics → HealthKit**
```swift
// ❌ WRONG: SwiftData body data
@Model class BodyMetrics { var weight: Double }

// ✅ CORRECT: HealthKit body measurements
let weightSample = HKQuantitySample(
    type: HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
    quantity: HKQuantity(unit: .pound(), doubleValue: 150),
    start: Date(),
    end: Date()
)
```

## Model Design Patterns

### ✅ Optimal @Model Design

#### 1. **Sendable Compliance**
```swift
@Model
final class ChatMessage: @unchecked Sendable {
    // @unchecked Sendable required for SwiftData models
    // SwiftData ensures thread safety through ModelContext
    var content: String
    var timestamp: Date
    var role: MessageRole
}
```

#### 2. **Relationship Management**
```swift
@Model
final class ChatSession {
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage] = []
    
    // Use cascade deletion for dependent data
    // Use nullify for independent references
}
```

#### 3. **Performance Optimization**
```swift
@Model
final class CoachMessage {
    // Use indexes for common queries
    #Index<CoachMessage>(
        [\.userID], 
        [\.timestamp], 
        [\.userID, \.conversationID, \.timestamp]
    )
    
    // External storage for large content
    @Attribute(.externalStorage)
    var content: String
}
```

### ❌ Anti-Patterns to Avoid

#### 1. **Health Data in SwiftData**
```swift
// ❌ WRONG: Forces service to @MainActor
@Model class NutritionEntry {
    var calories: Double // Should be in HealthKit
}

@MainActor // ← Forced due to SwiftData usage
class NutritionService {
    func save(_ entry: NutritionEntry) { } // Blocks main thread
}
```

#### 2. **Large Blob Storage**
```swift
// ❌ WRONG: Large files in SwiftData
@Model class MediaEntry {
    var videoData: Data // Multiple MB, should use file system
}

// ✅ CORRECT: File references in SwiftData
@Model class MediaEntry {
    var videoURL: URL // Reference to file system storage
}
```

## Actor Isolation Constraints

### Understanding the Core Issue

```swift
// The fundamental constraint:
@Model class User { } // Not Sendable

actor SomeService {
    func useModel() {
        let context = ModelContext(container) // ❌ Error: ModelContext not Sendable
        // Cannot use ModelContext in actor - requires @MainActor
    }
}
```

### Services That Must Be @MainActor

#### Current Constraints (4 services):
```swift
@MainActor final class UserService {
    private let modelContext: ModelContext // SwiftData constraint
}

@MainActor final class GoalService {
    private let modelContext: ModelContext // For custom goals
}

@MainActor final class ChatHistoryService {
    private let modelContext: ModelContext // For conversation data
}

@MainActor final class OnboardingService {
    private let modelContext: ModelContext // For persona data
}
```

#### Optimal Future State (2 services):
```swift
// Only truly app-specific services need @MainActor
@MainActor final class UserService { } // User preferences + personas
@MainActor final class ChatService { } // AI conversation history

// All health/fitness services become actors
actor NutritionService { } // HealthKit-based
actor WorkoutService { } // HealthKit + WorkoutKit based
actor HealthMetricsService { } // HealthKit-based
```

### Cross-Actor Communication Patterns

#### ✅ Correct: Actor to @MainActor
```swift
actor HealthKitService {
    func fetchTodaysNutrition() async -> NutritionData {
        // Fetch from HealthKit (thread-safe)
    }
}

@MainActor
final class DashboardViewModel {
    func loadData() async {
        // Crosses actor boundary safely
        let nutrition = await healthKitService.fetchTodaysNutrition()
        self.nutritionData = nutrition
    }
}
```

#### ❌ Wrong: Passing ModelContext Across Actors
```swift
actor BadService {
    func processModel(_ context: ModelContext) { // ❌ Not Sendable
        // This won't compile
    }
}
```

## ModelContext Handling

### ✅ Correct Patterns

#### 1. **Singleton Context Pattern**
```swift
@MainActor
final class UserService {
    private let modelContext: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
    }
    
    func saveUser(_ user: User) async throws {
        modelContext.insert(user)
        try modelContext.save()
    }
}
```

#### 2. **Background Context for Heavy Operations**
```swift
@MainActor
final class DataMigrationService {
    private let modelContainer: ModelContainer
    
    func performHeavyMigration() async throws {
        // Create background context for heavy work
        let backgroundContext = ModelContext(modelContainer)
        
        await Task.detached {
            // Heavy processing on background context
            // Merge changes back to main context when done
        }.value
    }
}
```

#### 3. **Transaction Management**
```swift
@MainActor
extension UserService {
    func updateUserProfile(_ updates: ProfileUpdate) async throws {
        guard let user = await getCurrentUser() else {
            throw AppError.userNotFound
        }
        
        // Group related changes in single save
        user.name = updates.name
        user.email = updates.email
        user.lastModified = Date()
        
        try modelContext.save() // Single transaction
    }
}
```

### ❌ Anti-Patterns

#### 1. **Context Leakage**
```swift
// ❌ WRONG: Exposing ModelContext
class BadService {
    var modelContext: ModelContext // Don't expose!
}

// ✅ CORRECT: Hide implementation details
class GoodService {
    private let modelContext: ModelContext // Private!
    
    func save<T>(_ item: T) where T: PersistentModel {
        // Controlled access only
    }
}
```

#### 2. **Cross-Thread Context Usage**
```swift
// ❌ WRONG: Using context on wrong thread
let context = modelContainer.mainContext
Task.detached {
    context.save() // ❌ Main context on background thread
}

// ✅ CORRECT: Use appropriate context
let backgroundContext = ModelContext(modelContainer)
Task.detached {
    backgroundContext.save() // ✅ Background context on background thread
}
```

## Performance Guidelines

### Query Optimization

#### 1. **Use Indexes for Common Patterns**
```swift
@Model
final class CoachMessage {
    // Index for user-specific queries
    #Index<CoachMessage>([\.userID])
    
    // Composite index for complex queries
    #Index<CoachMessage>([\.userID, \.timestamp])
    
    var userID: UUID
    var timestamp: Date
}
```

#### 2. **Efficient Fetch Descriptors**
```swift
// ✅ GOOD: Specific, limited queries
func getRecentMessages(for userID: UUID) -> [CoachMessage] {
    let descriptor = FetchDescriptor<CoachMessage>(
        predicate: #Predicate { message in
            message.userID == userID &&
            message.timestamp >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        },
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)],
        limit: 50 // Always limit!
    )
    return try modelContext.fetch(descriptor)
}

// ❌ BAD: Unlimited queries
func getAllMessages() -> [CoachMessage] {
    let descriptor = FetchDescriptor<CoachMessage>() // No limit!
    return try modelContext.fetch(descriptor) // Could return thousands
}
```

#### 3. **External Storage for Large Data**
```swift
@Model
final class ConversationSession {
    var sessionID: UUID
    
    // Large content goes to external storage
    @Attribute(.externalStorage)
    var fullTranscript: String
    
    // Small metadata stays in database
    var messageCount: Int
    var duration: TimeInterval
}
```

### Memory Management

#### 1. **Batch Processing**
```swift
// ✅ GOOD: Process in batches
func migrateLargeDataset() async throws {
    let batchSize = 100
    var offset = 0
    
    while true {
        let batch = try modelContext.fetch(
            FetchDescriptor<OldModel>(
                sortBy: [SortDescriptor(\.id)],
                limit: batchSize,
                offset: offset
            )
        )
        
        if batch.isEmpty { break }
        
        // Process batch
        for item in batch {
            // Convert to new format
        }
        
        try modelContext.save()
        offset += batchSize
    }
}
```

#### 2. **Relationship Loading Strategy**
```swift
// Control relationship loading explicitly
let descriptor = FetchDescriptor<ChatSession>(
    predicate: #Predicate { $0.userID == userID },
    relationshipKeyPathsForPrefetching: [\.messages] // Prefetch only when needed
)
```

## Migration Strategies

### From SwiftData to Native Frameworks

#### Step 1: Dual-Write Migration
```swift
@MainActor
final class NutritionService {
    private let modelContext: ModelContext
    private let healthKitManager: HealthKitManager
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        // 1. Save to SwiftData (existing functionality)
        modelContext.insert(entry)
        try modelContext.save()
        
        // 2. Also save to HealthKit (new)
        let samples = try await convertToHealthKit(entry)
        try await healthKitManager.save(samples)
    }
}
```

#### Step 2: Read Migration
```swift
actor NutritionService { // Now can be actor!
    private let healthKitManager: HealthKitManager
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        // Read from HealthKit only
        let samples = try await healthKitManager.fetchNutrition(for: date)
        return samples.map { convertFromHealthKit($0) }
    }
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        // Save to HealthKit only
        let samples = try await convertToHealthKit(entry)
        try await healthKitManager.save(samples)
    }
}
```

#### Step 3: Cleanup
```swift
// Remove SwiftData models
// @Model class FoodEntry { } // Delete this file

// Update DI registration
container.register(NutritionServiceProtocol.self) { resolver in
    let healthKit = try await resolver.resolve(HealthKitManager.self)
    return await NutritionService(healthKitManager: healthKit)
    // No more ModelContext needed!
}
```

### Data Conversion Patterns

#### SwiftData → HealthKit
```swift
func convertToHealthKit(_ foodEntry: FoodEntry) async throws -> [HKQuantitySample] {
    var samples: [HKQuantitySample] = []
    
    // Convert calories
    if let calories = foodEntry.totalCalories, calories > 0 {
        let caloriesSample = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            start: foodEntry.loggedAt,
            end: foodEntry.loggedAt,
            metadata: [
                "AirFitFoodEntryID": foodEntry.id.uuidString,
                "AirFitMealType": foodEntry.mealType
            ]
        )
        samples.append(caloriesSample)
    }
    
    // Convert protein, carbs, fat similarly...
    return samples
}
```

#### HealthKit → App Model
```swift
func convertFromHealthKit(_ sample: HKQuantitySample) -> NutritionEntry {
    return NutritionEntry(
        id: UUID(uuidString: sample.metadata?["AirFitFoodEntryID"] as? String) ?? UUID(),
        calories: sample.quantity.doubleValue(for: .kilocalorie()),
        timestamp: sample.startDate,
        source: .healthKit
    )
}
```

## Anti-Patterns

### ❌ Common Mistakes

#### 1. **Using SwiftData for Health Data**
```swift
// ❌ WRONG: Health data in SwiftData
@Model class HealthMetric {
    var heartRate: Double
    var bloodPressure: Double
}

// Consequences:
// - Service must be @MainActor (blocks concurrency)
// - No integration with Health app
// - No Apple Watch sync
// - Poor privacy compliance
```

#### 2. **Ignoring Thread Safety**
```swift
// ❌ WRONG: Unsafe ModelContext sharing
class BadService {
    static let sharedContext = ModelContext(container) // ❌ Shared state
}

// ❌ WRONG: Context on wrong thread
func backgroundTask() {
    Task.detached {
        let user = User()
        ModelContext.main.insert(user) // ❌ Main context on background thread
    }
}
```

#### 3. **Inefficient Queries**
```swift
// ❌ WRONG: Loading everything to filter
func findUserByEmail(_ email: String) -> User? {
    let allUsers = try! modelContext.fetch(FetchDescriptor<User>()) // ❌ Fetch all
    return allUsers.first { $0.email == email } // ❌ Filter in memory
}

// ✅ CORRECT: Database-level filtering
func findUserByEmail(_ email: String) -> User? {
    let descriptor = FetchDescriptor<User>(
        predicate: #Predicate { $0.email == email }
    )
    return try? modelContext.fetch(descriptor).first
}
```

#### 4. **Blocking Main Thread**
```swift
// ❌ WRONG: Heavy SwiftData work on main thread
@MainActor
func importLargeDataset() {
    for item in thousandsOfItems { // ❌ Blocks UI
        let model = convertToModel(item)
        modelContext.insert(model)
    }
    try! modelContext.save() // ❌ Heavy save on main thread
}

// ✅ CORRECT: Background processing
func importLargeDataset() async {
    let backgroundContext = ModelContext(modelContainer)
    
    await Task.detached {
        for item in thousandsOfItems {
            let model = convertToModel(item)
            backgroundContext.insert(model)
        }
        try! backgroundContext.save()
    }.value
    
    // Notify main thread when done
}
```

## Quick Reference

### Decision Matrix: SwiftData vs Native Frameworks

| Data Type | SwiftData | HealthKit | WorkoutKit | File System |
|-----------|-----------|-----------|------------|-------------|
| **AI Personas** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Chat History** | ✅ Yes | ❌ No | ❌ No | 🔶 Maybe |
| **User Preferences** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Nutrition Data** | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Workout Sessions** | ❌ No | ✅ Yes | 🔶 Maybe | ❌ No |
| **Body Metrics** | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Exercise Plans** | ❌ No | 🔶 Maybe | ✅ Yes | ❌ No |
| **Media Files** | ❌ No | ❌ No | ❌ No | ✅ Yes |

### Service Actor Status Guide

```swift
// ✅ Can be actors (no SwiftData dependency)
actor HealthKitService { }
actor WeatherService { }
actor NetworkManager { }
actor CacheService { }

// ❌ Must be @MainActor (SwiftData dependency)
@MainActor class UserService { } // User preferences + personas
@MainActor class ChatService { } // Conversation history

// 🎯 Goal: Minimize @MainActor services
// Current: 40% @MainActor / 60% actors
// Target: 20% @MainActor / 80% actors
```

### Performance Checklist

- [ ] Use native frameworks for health/fitness data
- [ ] Add indexes for common query patterns
- [ ] Use `@Attribute(.externalStorage)` for large content
- [ ] Limit query results with `limit` parameter
- [ ] Process large datasets in batches
- [ ] Use background contexts for heavy operations
- [ ] Avoid sharing ModelContext across threads
- [ ] Profile query performance in Instruments

### Migration Priority

1. **High Impact**: Nutrition data → HealthKit (unlocks NutritionService as actor)
2. **High Impact**: Workout data → HealthKit/WorkoutKit (unlocks WorkoutService as actor)
3. **Medium Impact**: Body metrics → HealthKit (simplifies HealthKitManager)
4. **Low Impact**: Media → File system (reduces SwiftData size)

## Integration with Other Standards

- **Concurrency**: See `CONCURRENCY_STANDARDS.md` for actor patterns
- **Service Layer**: See `SERVICE_LAYER_STANDARDS.md` for service architecture
- **Performance**: See `PERFORMANCE_STANDARDS.md` for optimization techniques

---

**Key Takeaway**: Use SwiftData sparingly for truly app-specific data. Prefer native frameworks to maximize actor-based concurrency and system integration. The goal is 80% actors / 20% @MainActor services for optimal performance.