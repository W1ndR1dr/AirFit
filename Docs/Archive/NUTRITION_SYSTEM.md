 Nutrition System Design Document

## Overview
This document outlines AirFit's nutrition system evolution from a "fancy calculator" (V1) to an AI-native intelligent coach (V2) that provides context-aware nutrition recommendations using LLM structured outputs.

## Core Philosophy
- **V1 (Current)**: Formulaic BMR + fixed activity multipliers
- **V2 (Future)**: AI-powered contextual recommendations with structured outputs
- **Calories adjust with activity** - Energy balance is the primary lever
- **Macros are personalized** - LLM sets initial ratios based on goals, user can adjust  
- **LLM provides intelligence** - Beyond math to true coaching intelligence
- **Real-time responsiveness** - Targets update throughout the day from Apple Watch
- **HealthKit First** - No SwiftData for body metrics to maintain actor concurrency
- **Hybrid Data Storage** - Minimal SwiftData for UI state, HealthKit for actual nutrition data

## System Architecture

### 1. Data Flow
```
HealthKit (Apple Watch) → NutritionCalculator (actor) → Dashboard UI
                                    ↓
                             AI Coach Service → Contextual Insights
```

### 2. Key Components

#### NutritionCalculator (New Actor Service)
- **Type**: `actor` (not @MainActor) for concurrent execution
- Implements `ServiceProtocol` for proper lifecycle management
- Calculates BMR using body metrics from HealthKit
- Adds real-time active calories from HealthKit
- Maintains fixed macro ratios
- Returns simple, deterministic targets

#### Body Metrics Strategy (No SwiftData)
- ALL body metrics stored in HealthKit (weight, height, body fat %)
- User model only stores what HealthKit doesn't provide:
  - `biologicalSex: String?` (if not available from HealthKit)
  - `birthDate: Date?` (for age calculation if not in HealthKit)
- Direct HealthKit queries for all calculations
- No `@Model` for body data = keeps service as actor

#### Food Data Architecture (Hybrid Approach)
**Current Issue**: FoodEntry/FoodItem use SwiftData, forcing services to be @MainActor

**Solution**: Hybrid storage pattern
1. **SwiftData** (minimal): UI state, meal organization, user notes
   ```swift
   @Model final class FoodEntry {
       var id: UUID
       var mealType: String
       var loggedAt: Date
       var notes: String?
       var healthKitSampleIDs: [String] // Links to HealthKit
   }
   ```

2. **HealthKit** (primary): Actual nutrition data
   - All calories, macros stored as HKQuantitySample
   - Enables actor-based services
   - Follows platform conventions

3. **Migration Strategy**: 
   - Keep existing FoodEntry for backward compatibility
   - Store new nutrition data in HealthKit
   - FoodEntry becomes a lightweight reference

#### Enhanced Dashboard Integration
- Shows base calories + activity bonus separately
- Updates targets every 5 minutes from Apple Watch
- Smooth animations for changing values
- Transparent calculation display

## Technical Specifications

### 1. Service Implementation
```swift
actor NutritionCalculator: NutritionCalculatorProtocol, ServiceProtocol {
    nonisolated let serviceIdentifier = "nutrition-calculator"
    private let healthKit: HealthKitManaging
    private var _isConfigured = false
    
    init(healthKit: HealthKitManaging) {
        self.healthKit = healthKit
    }
    
    func configure() async throws {
        // Verify HealthKit permissions
        guard await healthKit.authorizationStatus == .authorized else {
            throw AppError.healthKitNotAuthorized
        }
        _isConfigured = true
    }
    
    func calculateDynamicTargets(for user: User) async throws -> NutritionTargets {
        // Fetch body metrics from HealthKit
        async let weight = healthKit.fetchLatestBodyMetric(.bodyMass)
        async let height = healthKit.fetchLatestBodyMetric(.height) 
        async let bodyFat = healthKit.fetchLatestBodyMetric(.bodyFatPercentage)
        async let activeCalories = healthKit.fetchTodayActivityMetrics().activeEnergyBurned
        
        let metrics = try await (weight, height, bodyFat, activeCalories)
        
        // Calculate BMR
        let bmr = calculateBMR(
            weight: metrics.0,
            height: metrics.1,
            bodyFat: metrics.2,
            age: user.age ?? 30,
            sex: user.biologicalSex
        )
        
        // Calculate targets
        let baseCalories = bmr * 1.2
        let totalCalories = baseCalories + (metrics.3?.value ?? 0)
        
        return NutritionTargets(
            baseCalories: baseCalories,
            activeCalorieBonus: metrics.3?.value ?? 0,
            totalCalories: totalCalories,
            protein: (metrics.0 ?? 70) * 0.9, // kg to lbs conversion included
            fat: totalCalories * 0.30 / 9,
            carbs: calculateRemainingCarbs(totalCalories, protein, fat)
        )
    }
}
```

### 2. Data Models

#### NutritionTargets (New)
```swift
struct NutritionTargets: Sendable {
    let baseCalories: Double        // BMR × 1.2 (sedentary)
    let activeCalorieBonus: Double  // From Apple Watch
    let totalCalories: Double       // base + active
    let protein: Double             // grams
    let carbs: Double              // grams
    let fat: Double                // grams
    
    // For UI display
    var displayCalories: String {
        "\(Int(baseCalories)) + \(Int(activeCalorieBonus)) = \(Int(totalCalories))"
    }
}
```

#### Updated DashboardNutritionData
```swift
struct DashboardNutritionData {
    // Current intake
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    
    // Dynamic targets from NutritionCalculator
    let calorieTarget: Double
    let proteinTarget: Double
    let carbTarget: Double
    let fatTarget: Double
    
    // New fields for transparency
    let baseCalories: Double
    let activeBonus: Double
}
```

### 3. BMR Calculation Implementation
```swift
private func calculateBMR(
    weight: Double?,      // kg from HealthKit
    height: Double?,      // cm from HealthKit
    bodyFat: Double?,     // percentage from HealthKit
    age: Int,            // calculated from birthDate
    sex: String?         // from User model
) -> Double {
    
    // Validate we have minimum data
    guard let weight = weight else {
        // No weight = can't calculate
        throw AppError.validationError(message: "Weight required for nutrition calculations")
    }
    
    let weightKg = weight  // HealthKit returns in kg
    
    // Try Katch-McArdle first (most accurate with body fat)
    if let bodyFat = bodyFat {
        let leanMassKg = weightKg * (1 - bodyFat / 100)
        return 370 + (21.6 * leanMassKg)
    }
    
    // Try Mifflin-St Jeor (needs height)
    if let height = height {
        let heightCm = height  // HealthKit returns in cm
        let sexFactor = (sex == "male") ? 5.0 : -161.0
        return (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age)) + sexFactor
    }
    
    // Fallback: Modified Harris-Benedict (assume average height)
    let assumedHeight: Double = (sex == "male") ? 178.0 : 165.0
    if sex == "male" {
        return 88.362 + (13.397 * weightKg) + (4.799 * assumedHeight) - (5.677 * Double(age))
    } else {
        return 447.593 + (9.247 * weightKg) + (3.098 * assumedHeight) - (4.330 * Double(age))
    }
}
```

### 4. Daily Target Calculation
```swift
Total Calories = (BMR × 1.2) + Apple Watch Active Calories
Protein = bodyWeight(lbs) × user.proteinGramsPerPound (LLM-personalized)
Fat = totalCalories × user.fatPercentage (LLM-personalized)
Carbs = remaining calories after protein and fat
```

### 5. Update Frequency
- HealthKit sync: Every 5 minutes via background task
- Dashboard refresh: On sync completion + manual refresh
- Cache duration: 5 minutes to prevent excessive queries

## LLM-Driven Macro Personalization

### Overview
During onboarding, the LLM analyzes the user's conversation to generate personalized macro recommendations that align with their goals, training style, and preferences.

### Macro Generation Process
1. **Conversation Analysis**: LLM reviews entire onboarding conversation
2. **Goal Extraction**: Identifies primary fitness goals (muscle building, weight loss, endurance, etc.)
3. **Personalized Recommendations**: Sets initial macro ratios based on:
   - Training intensity and style
   - Body composition goals
   - Lifestyle factors
   - Recovery needs

### Example Macro Profiles
```json
// Strength Training Focus
{
  "proteinGramsPerPound": 1.3,
  "fatPercentage": 0.25,
  "approach": "Fuel for growth",
  "rationale": "Higher protein supports muscle growth and recovery. Moderate fat leaves room for performance-driving carbs.",
  "flexibilityNotes": "Hit protein daily, let carbs and fat balance over the week"
}

// Weight Loss Focus
{
  "proteinGramsPerPound": 1.1,
  "fatPercentage": 0.30,
  "approach": "Sustainable deficit",
  "rationale": "Elevated protein preserves muscle during weight loss. Balanced fat supports hormones and satiety.",
  "flexibilityNotes": "Focus on weekly averages. One high day won't derail progress"
}

// Endurance Focus
{
  "proteinGramsPerPound": 0.8,
  "fatPercentage": 0.25,
  "approach": "Endurance fuel",
  "rationale": "Moderate protein meets recovery needs. Lower fat maximizes carb availability for sustained energy.",
  "flexibilityNotes": "Prioritize carbs around training sessions"
}
```

### User Adjustability
- Initial macros set by LLM during onboarding
- Users can adjust in Settings at any time
- Changes persist and override LLM recommendations
- Coach acknowledges and adapts to user preferences

## LLM Integration

### Context Provided to AI
```json
{
  "baseCalories": 2100,
  "activeCaloriesEarned": 450,
  "totalTarget": 2550,
  "currentIntake": {
    "calories": 1200,
    "protein": 85,
    "carbs": 150,
    "fat": 40
  },
  "workoutsToday": ["45 min strength training - legs"],
  "lastMealTime": "2 hours ago",
  "timeSinceWorkout": "1 hour"
}
```

### AI Responsibilities
- Contextual meal timing advice
- Workout-specific recovery guidance
- Pattern recognition and behavioral insights
- Celebration of achievements
- Educational snippets about nutrition

### Example AI Responses
- Post-workout: "Great leg session! Aim for 30-40g protein within the next hour for optimal recovery."
- Under-eating: "You're 800 calories under target. Your muscles need fuel to grow!"
- Rest day: "Light activity today - perfect for recovery. Stay on track with your 2180 calorie target."

## UI/UX Specifications

### Dashboard Display
```
Nutrition
─────────────────────────
Calories: 1,450 / 2,680
Base: 2,100 + Activity: 580

[Visual progress rings for each macro]
Protein: 95g / 162g
Carbs: 185g / 335g  
Fat: 48g / 89g
```

### Key Features
- Real-time updates with smooth animations
- Clear breakdown of base vs earned calories
- Color-coded macro rings (Red: Protein, Teal: Carbs, Yellow: Fat)
- Contextual AI insights below rings

## Critical Architecture Updates

### User Model Changes
**Issue**: Current User model has static nutrition targets that conflict with dynamic system

**Required Changes**:
```swift
@Model final class User {
    // Remove these static fields:
    var calorieTarget: Double = 2000  // ❌ DELETE
    var proteinTarget: Double = 150   // ❌ DELETE
    var carbTarget: Double = 250      // ❌ DELETE
    var fatTarget: Double = 65        // ❌ DELETE
    
    // Add these for BMR calculation:
    var biologicalSex: String?  // "male"/"female" 
    var birthDate: Date?        // For age calculation
    
    // Add personalized macro preferences:
    var proteinGramsPerPound: Double = 0.9  // Set by LLM during onboarding
    var fatPercentage: Double = 0.30         // Set by LLM during onboarding
    var macroFlexibility: String = "balanced" // "strict", "balanced", "flexible"
    
    // Add computed property for age:
    var age: Int? {
        guard let birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }
}
```

### Service Architecture Alignment
1. **NutritionCalculator**: `actor` (not @MainActor) - calculates from HealthKit
2. **NutritionService**: Remains `@MainActor` (SwiftData constraint) - handles FoodEntry
3. **DashboardNutritionService**: Updates to use NutritionCalculator for targets

### NO Backward Compatibility Needed
Since this is v1.0 with no existing users:
- Remove all static nutrition fields immediately
- Update all references to use NutritionCalculator
- No migration needed, no technical debt

## Key Files for Implementation

### Files That Need Updates:
1. **User Model**: `/AirFit/Data/Models/User.swift`
   - Remove: `calorieTarget`, `proteinTarget`, `carbTarget`, `fatTarget` (lines 19-22)
   - Add: `biologicalSex: String?`, `birthDate: Date?`, computed `age` property

2. **HealthKit Manager**: `/AirFit/Services/Health/HealthKitManager.swift`
   - Add: `fetchLatestBodyMetric()` method for height
   - Already has: weight fetching, activity metrics, nutrition saving

3. **Dashboard Services**:
   - `/AirFit/Modules/Dashboard/Services/DashboardNutritionService.swift`
     - Currently uses static targets from User model
     - Needs to inject and use NutritionCalculator
   - `/AirFit/Modules/Dashboard/Models/DashboardModels.swift`
     - Has existing `NutritionTargets` struct that needs updating

4. **AI Integration**:
   - `/AirFit/Modules/AI/CoachEngine.swift`
     - `generateDashboardContent()` method (line 1573) uses static `user.calorieTarget`
     - Needs to use dynamic targets from NutritionCalculator

5. **Food Tracking**:
   - `/AirFit/Modules/FoodTracking/Models/FoodTrackingModels.swift`
     - `FoodNutritionSummary` has hardcoded default goals (lines 21-27)
     - Should use dynamic targets

6. **DI Container**: `/AirFit/Core/DI/DIBootstrapper.swift`
   - Add NutritionCalculator registration

### Key Context:
- **HealthKit Permissions**: Already includes `.height` (line 34 in HealthKitDataTypes.swift)
- **Service Standards**: Services should be `actor` unless they need `@MainActor` (SwiftData constraint)
- **SwiftData Standards**: Don't store body metrics in SwiftData - use HealthKit
- **Existing HealthKit Integration**: Already saves nutrition to HealthKit with 5-minute duplicate detection
- **BodyMetrics struct**: Currently missing height field (see HealthContextSnapshot.swift lines 199-236)
- **Current Nutrition Flow**: FoodEntry (SwiftData) → HealthKit sync → Dashboard display
- **AI Context**: CoachEngine passes static targets to AI for dashboard content generation

### Breaking Changes to Handle:
1. **CoachEngine.generateDashboardContent()** (line 1598, 1707-1713)
   - Uses `user.calorieTarget`, `user.proteinTarget` directly
   - Needs to await NutritionCalculator results

2. **DashboardNutritionService.getTargets()** (line 80)
   - Returns static targets based on goal type
   - Should call NutritionCalculator instead

3. **FoodNutritionSummary** struct (FoodTrackingModels.swift)
   - Has hardcoded default goals
   - Should accept dynamic targets as parameters

4. **NutritionRingsView** 
   - Expects targets in DashboardNutritionData
   - Already structured correctly, just needs dynamic data

## Implementation Checklist

### Phase 0: Architecture Alignment
- [ ] Remove static nutrition target fields from User model (lines 19-22)
- [ ] Add biologicalSex and birthDate to User model
- [ ] Add age computed property to User model
- [ ] Update all references to user.calorieTarget to use NutritionCalculator

### Phase 1: Foundation
- [ ] Create NutritionCalculatorProtocol
- [ ] Implement NutritionCalculator actor service
- [ ] Add BMR calculation functions (Katch-McArdle, Mifflin-St Jeor, Harris-Benedict)
- [ ] Register service in DI container with proper factory pattern
- [ ] Create NutritionTargets struct with base/active/total separation

### Phase 2: HealthKit Integration
- [ ] Add fetchLatestBodyMetric() method to HealthKitManager
- [ ] Extend HealthKitManaging protocol with new method
- [ ] Add height to BodyMetrics struct (currently missing)
- [ ] Verify Apple Watch active calorie sync works
- [ ] Handle missing data scenarios gracefully

### Phase 3: Dashboard Integration
- [ ] Update DashboardNutritionData to include baseCalories and activeBonus
- [ ] Modify DashboardNutritionService to use NutritionCalculator
- [ ] Update NutritionRingsView to show base + activity breakdown
- [ ] Add smooth animations for target changes
- [ ] Update DashboardViewModel to refresh on HealthKit sync

### Phase 4: AI Context Enhancement
- [ ] Add dynamic nutrition context to AICoachService
- [ ] Include base vs earned calories in context
- [ ] Pass workout detection for contextual advice
- [ ] Test AI responses for various scenarios
- [ ] Ensure AI explains changes naturally

### Phase 5: Testing & Polish
- [ ] Unit tests for BMR calculations
- [ ] Integration tests with mock HealthKit data
- [ ] UI tests for dynamic updates
- [ ] Performance testing (5-minute sync shouldn't impact UI)
- [ ] Edge case handling (new user, missing data, etc.)

## Final Architecture Summary

### What We're Building
A dynamic nutrition system that:
1. Calculates personalized calorie targets using BMR + Apple Watch activity
2. Maintains stable macro ratios for consistency
3. Updates in real-time as users burn calories
4. Provides AI-powered contextual guidance

### Key Design Decisions
1. **NutritionCalculator as Actor**: Enables concurrent calculations without blocking UI
2. **HealthKit for Body Metrics**: No SwiftData for health data per our standards
3. **Hybrid Food Storage**: Keep existing FoodEntry for UI, store nutrition in HealthKit
4. **Fixed Macro Ratios**: 0.9g/lb protein, 30% fat, rest carbs - simplicity over complexity
5. **5-Minute Updates**: Balances real-time feel with battery efficiency

### Data Flow
```
User burns calories → Apple Watch → HealthKit → NutritionCalculator → Dashboard
                                                         ↓
                                                   AI Coach (context)
```

## Current Implementation Status

### What Exists:
- ✅ HealthKit integration for saving nutrition data
- ✅ Dashboard displays nutrition with rings
- ✅ AI coach generates content using nutrition context
- ✅ Food tracking saves to both SwiftData and HealthKit
- ✅ `.height` permission already in HealthKit permissions
- ✅ LLM-driven macro personalization during onboarding
- ✅ PersonaProfile stores nutrition recommendations
- ✅ User model has personalized macro preferences

### What's Implemented (as of 2025-01-04):
- ✅ NutritionCalculator service with BMR calculations
- ✅ Dynamic calorie calculation based on activity
- ✅ BMR calculation from body metrics (3-tier formula)
- ✅ Height fetching from HealthKit
- ✅ User model has biologicalSex and birthDate
- ✅ Removed static nutrition targets from User model
- ✅ CoachEngine uses dynamic targets
- ✅ DashboardNutritionService uses NutritionCalculator
- ✅ LLM generates personalized macro recommendations
- ✅ Settings UI for macro adjustment (NutritionSettingsView)
- ✅ FoodTrackingViewModel uses dynamic targets
- ✅ Onboarding UI collects birthDate (ProfileSetupView)

### Current System: "Fancy Calculator"
The current implementation uses basic math with fixed multipliers:
```swift
// Simple activity multipliers
let activityMultiplier = 1.2 // sedentary
let totalCalories = bmr * activityMultiplier
```

This approach:
- ❌ Uses fixed activity factors (1.2-1.9)
- ❌ Doesn't consider workout intensity or recovery
- ❌ No awareness of user's goals or progress
- ❌ Can't adapt based on results
- ✅ Is deterministic and fast
- ✅ Works as a baseline

## Progress Tracker

### Current Status: V1 Complete, Planning AI-Native V2
Last Updated: 2025-01-07

### Completed Items
- ✅ System design approved
- ✅ Architecture documented and refined
- ✅ Added `.height` to HealthKit permissions
- ✅ Added missing data handling patterns to standards
- ✅ Resolved all architecture conflicts
- ✅ Deep dive analysis of current codebase
- ✅ Identified all breaking changes
- ✅ Phase 0: Removed static nutrition fields from User model
- ✅ Phase 1: Created NutritionCalculator with BMR calculations
- ✅ Phase 2: Updated services to use dynamic targets
- ✅ LLM Integration: Added personalized macro recommendations

### Next Steps
1. Create Settings UI for macro adjustment
2. Update FoodTrackingViewModel to display dynamic targets
3. Add birthDate collection in onboarding if missing
4. Test end-to-end flow with various user profiles

## Design Decisions Log

### Decision 1: Fixed Macro Ratios
**Date**: 2024-01-15
**Rationale**: Research shows consistent macro targets improve adherence. Daily fluctuations add complexity without meaningful benefit.
**Alternative Considered**: Dynamic macro adjustment based on workout type
**Outcome**: Keeping macros fixed, only adjusting total calories

### Decision 2: 5-Minute Sync Interval  
**Date**: 2024-01-15
**Rationale**: Balances real-time feel with battery efficiency
**Alternative Considered**: Continuous sync or 15-minute intervals
**Outcome**: 5 minutes provides good UX without excessive battery drain

### Decision 3: LLM for Context, Not Calculation
**Date**: 2024-01-15
**Rationale**: Keeps calculations deterministic and fast while leveraging AI for insights
**Alternative Considered**: LLM calculates targets dynamically
**Outcome**: Local calculation + AI intelligence provides best of both worlds

### Decision 4: No SwiftData for Body Metrics
**Date**: 2024-01-15
**Rationale**: Following SWIFTDATA_STANDARDS.md - body metrics belong in HealthKit. Keeps NutritionCalculator as actor for concurrent execution.
**Alternative Considered**: BodyMetrics @Model class
**Outcome**: Direct HealthKit queries maintain service concurrency

### Decision 5: Service as Actor, Not @MainActor
**Date**: 2024-01-15
**Rationale**: Per SERVICE_LAYER_STANDARDS.md - services should be actors unless they need @MainActor. No SwiftData = no @MainActor constraint.
**Alternative Considered**: @MainActor service for easier UI updates
**Outcome**: Actor service with proper async boundaries for better performance

### Decision 6: LLM-Driven Macro Personalization
**Date**: 2025-01-04
**Rationale**: Different users have vastly different macro needs based on goals (1.3g/lb for strength vs 0.8g/lb for endurance). One-size-fits-all approach doesn't serve users well.
**Alternative Considered**: Fixed macro profiles users select from
**Outcome**: LLM analyzes onboarding conversation to set initial macros, users can adjust in Settings. Provides personalization with flexibility.

### Decision 7: AI-Native Architecture for V2
**Date**: 2025-01-07
**Rationale**: Current system uses fixed activity multipliers (1.2-1.9) that don't capture nuance of training stress, recovery status, or individual variation. Real intelligence requires context-aware adjustments.
**Alternative Considered**: More complex formula-based calculations
**Outcome**: Pursuing structured outputs from LLMs to provide truly intelligent nutrition recommendations while keeping BMR calculation formulaic. Maintains current system as fallback.

## Implementation Notes for Future Development

### Development Standards to Follow:
1. **SERVICE__LAYER_STANDARDS.md**: 
   - Services are actors unless they need @MainActor
   - Lazy DI registration (don't create services at startup)
   - Implement ServiceProtocol with proper lifecycle
   
2. **SWIFTDATA_STANDARDS.md**:
   - Don't store health data in SwiftData
   - Use HealthKit for body metrics, nutrition data
   - SwiftData only for app-specific data (personas, chat history)

3. **ERROR_HANDLING_STANDARDS.md**:
   - All user-facing errors must be AppError
   - Services return nil for missing data, don't fabricate
   - ViewModels decide display defaults

### Unit Conversions
- HealthKit returns weight in kilograms, height in centimeters
- Our protein calculation uses pounds: `protein = weightLbs × 0.9`
- Remember to convert: `weightLbs = weightKg × 2.20462`

### Protocol Requirements
The `NutritionCalculatorProtocol` should expose:
- Primary calculation method returning `NutritionTargets`
- Individual BMR calculation for debugging/display
- Must be `Sendable` for actor boundaries

### Integration Points
1. **DashboardNutritionService**: Will need to inject and call NutritionCalculator across actor boundary
2. **Onboarding**: Should prompt for height/weight if missing from HealthKit
3. **Settings**: Users need ability to update biologicalSex and birthDate
4. **FoodTrackingViewModel**: Should display dynamic targets, not static User fields

### Cache Considerations
- 5-minute cache prevents excessive HealthKit queries
- Cache key should include user ID to support multiple users
- Cache should invalidate when user logs new workout

### Missing Data UX
When data is missing:
- Weight missing: Cannot calculate, show "Add weight in Health app"
- Height missing: Use population average, show warning
- Age missing: Default to 30, prompt for birthDate
- Sex missing: Use female formula (lower BMR = safer default)

### Testing Scenarios
Future implementation should test:
- New user with no HealthKit data
- User with only weight (no height/age)
- Rapid activity changes (multiple workouts)
- Cache expiration and refresh
- Actor boundary crossings

## Testing Scenarios

### Scenario 1: Standard Training Day
- Morning: Base 2100 cal target
- Post-workout: +450 cal from strength training
- Evening: Total 2550 cal target
- Verify: Smooth UI updates, appropriate AI messaging

### Scenario 2: Rest Day
- All day: Minimal activity (+80 cal)
- Total: 2180 cal target  
- Verify: No confusion about low targets, supportive AI messaging

### Scenario 3: Unexpected Activity
- No workout planned
- Spontaneous hike adds +600 cal
- Verify: System adapts without user intervention

### Scenario 4: Missing Data
- No height/weight data
- Verify: Sensible defaults (1800 BMR)
- Prompt user to add data

## AI-Native Nutrition System (V2 Design)

### Vision: From Calculator to Coach
Transform the nutrition system from deterministic calculations to intelligent, context-aware recommendations using LLM structured outputs.

### Architecture Shift
```swift
// Current: Fixed multipliers
let totalCalories = bmr * 1.375 // "lightly active"

// AI-Native: Contextual intelligence
let context = NutritionContext(
    bmr: bmr,
    recentActivity: healthData.weeklyPattern,
    todaysWorkout: workouts.today,
    recovery: healthData.hrv,
    sleep: healthData.sleepQuality,
    stress: healthData.stressLevel,
    goals: user.currentGoals,
    recentProgress: bodyComposition.trend
)

let targets = try await aiService.structuredRequest(
    prompt: buildNutritionPrompt(context),
    schema: DynamicNutritionTargets.self
)
```

### Structured Output Schema
```swift
struct DynamicNutritionTargets: Codable {
    let calories: Int
    let protein_g: Int
    let carbs_g: Int
    let fat_g: Int
    let reasoning: String
    let adjustments: [String]
    let confidence: Double
    
    // Context-aware recommendations
    let preworkout_carbs_g: Int?
    let postworkout_protein_g: Int?
    let recovery_focus: String?
}
```

### What AI Handles vs Formula
**Keep Formulaic:**
- BMR calculation (Mifflin-St Jeor)
- Basic unit conversions
- Calorie math (protein × 4 + carbs × 4 + fat × 9)

**Outsource to AI:**
- Activity multiplier (considers intensity, duration, recovery)
- Goal-based adjustments (bulk/cut/maintain)
- Timing recommendations
- Recovery prioritization
- Adaptation based on progress

### Implementation Strategy

#### Phase 1: Structured Output Integration
Each provider has different capabilities:

**OpenAI** (Most mature):
```swift
let response = try await openAI.chat(
    model: "gpt-4-turbo",
    messages: [...],
    responseFormat: .jsonSchema(DynamicNutritionTargets.self)
)
```

**Anthropic** (Coming soon):
```swift
// Currently use XML tags, JSON schema support in beta
let response = try await claude.complete(
    prompt: wrapWithXMLSchema(prompt),
    model: "claude-3-sonnet"
)
```

**Google Gemini** (Native JSON):
```swift
let response = try await gemini.generate(
    model: "gemini-2.0-flash",
    contents: [...],
    generationConfig: .init(
        responseMimeType: "application/json",
        responseSchema: nutritionSchema
    )
)
```

#### Phase 2: Context Building
Comprehensive context for intelligent recommendations:

```swift
struct NutritionContext {
    // Baseline
    let bmr: Double
    let age: Int
    let biologicalSex: String
    
    // Activity patterns
    let weeklyWorkouts: [WorkoutSummary]
    let todaysActivity: ActivityMetrics
    let stepCount: Int
    
    // Recovery indicators
    let hrv: Double?
    let sleepHours: Double?
    let sleepQuality: String?
    let muscleSoreness: [String: Int]? // muscle group -> severity
    
    // Goals & progress
    let primaryGoal: String // "muscle_gain", "fat_loss", "performance"
    let weeklyWeightChange: Double?
    let energyLevels: String? // "high", "normal", "low", "fatigued"
    
    // Behavioral
    let mealTimingPreference: String?
    let previousDayCompliance: Double? // % of targets hit
}
```

#### Phase 3: Fallback Strategy
When AI fails, fall back gracefully:

```swift
func calculateNutritionTargets(context: NutritionContext) async -> DynamicNutritionTargets {
    do {
        // Try AI-powered calculation
        return try await aiService.structuredRequest(
            prompt: buildPrompt(context),
            schema: DynamicNutritionTargets.self,
            timeout: 5.0
        )
    } catch {
        // Fallback to current calculator
        AppLogger.warning("AI nutrition failed, using calculator", category: .ai)
        return calculateFallbackTargets(context)
    }
}
```

### Example Prompts & Responses

**Prompt for Heavy Training Day:**
```
Calculate nutrition targets for:
- 28yo male, 180lbs, BMR 1850
- Today: Leg day (squats, deadlifts) + 10k steps
- HRV: 45ms (below baseline of 55ms)
- Sleep: 6 hours (poor)
- Goal: Muscle gain
- Weekly trend: +0.5lbs
```

**Expected Structured Response:**
```json
{
  "calories": 2850,
  "protein_g": 195,
  "carbs_g": 380,
  "fat_g": 75,
  "reasoning": "Elevated calories to support recovery from heavy leg training. Higher protein due to poor HRV indicating recovery need. Extra carbs for glycogen replenishment.",
  "adjustments": [
    "Added 200 cal for recovery stress",
    "Increased protein by 15g for low HRV",
    "Prioritized carbs over fat for training fuel"
  ],
  "confidence": 0.85,
  "postworkout_protein_g": 40,
  "recovery_focus": "Prioritize sleep tonight for adaptation"
}
```

### Benefits of AI-Native Approach
1. **Nuanced Activity Assessment**: Not just "moderately active" but understanding actual training stress
2. **Recovery-Aware**: Adjusts based on HRV, sleep, soreness
3. **Goal Alignment**: Different strategies for cutting vs bulking
4. **Behavioral Insights**: Learns from compliance patterns
5. **Educational**: Explains why targets change

### Implementation Checklist
- [ ] Research structured output capabilities (in progress)
- [ ] Design comprehensive NutritionContext model
- [ ] Create provider-specific implementations
- [ ] Build fallback calculator for reliability
- [ ] Test schema validation across providers
- [ ] Implement retry logic with timeout
- [ ] Add telemetry for success rates
- [ ] Create A/B test framework (AI vs calculator)

### Success Metrics
- AI response time < 2 seconds
- Success rate > 95%
- User satisfaction with recommendations
- Improved compliance vs static targets
- Better progress toward goals

## Future Enhancements
1. Multi-day optimization (weekly periodization)
2. Meal timing intelligence
3. Supplement recommendations
4. Restaurant meal adjustments
5. Social event planning

## References
- Katch-McArdle Formula: https://en.wikipedia.org/wiki/Basal_metabolic_rate
- Protein Requirements: International Society of Sports Nutrition Position Stand
- Energy Balance: ACSM Guidelines for Exercise Testing and Prescription

---

This document should be updated throughout implementation to track progress and capture any design changes or lessons learned.