# Critical Implementation Specifications - STOP VIBE CODING

This document specifies EXACTLY what is implemented vs what is stubbed. **READ THIS BEFORE MAKING ANY CHANGES.**

## 🚨 CRITICAL: Areas Where Agents Make Wrong Assumptions

### 1. **AI Function Implementations**

#### ✅ FULLY IMPLEMENTED (Don't Re-implement)
- `handleNutritionParsing()` - Works with real DirectAIProcessor
- `handleWorkoutGeneration()` - Complete with persona integration  
- `handleWorkoutAdaptation()` - Fetches and adapts real workouts
- `handleGoalSetting()` - Creates SMART goals with DB persistence
- `handlePerformanceAnalysis()` - Comprehensive metrics analysis
- `handleEducationalContent()` - Real AI-powered content generation

#### ❌ STUBBED (Need Implementation)
```swift
// CoachEngine+Functions.swift:429-433
func handleWatchTransfer() -> String {
    return "Workout has been sent to your Apple Watch!" // STUB - No real transfer
}

// CoachEngine+Functions.swift:435-440  
func handleWorkoutAnalysis(workout_id: String) -> String {
    return "Generic response ignoring workout_id" // STUB - Ignores parameter
}
```

**⚠️ DO NOT ASSUME**: That watch transfer works or workout analysis is connected to real data.

### 2. **Workout System Architecture**

#### ✅ WHAT EXISTS (Don't Rebuild)
- **Complete data models** with HealthKit integration
- **AI-first architecture** - NO TEMPLATES BY DESIGN
- **Full Watch app** (8 views) but intentionally disabled
- **WorkoutBuilderView** (829 lines) - fully functional
- **WorkoutDashboardView** (1,121 lines) - complete implementation

#### ❌ WHAT'S MISSING (Needs Building)
- **AllWorkoutsView** - Just placeholder text
- **Active workout session** for iPhone (watch has it)
- **Workout statistics** visualization

**⚠️ DO NOT CREATE**: Workout templates, rigid categories, or traditional planning systems. The AI generates everything dynamically.

### 3. **Photo Food Logging**

#### ✅ FULLY IMPLEMENTED (Production Ready)
```swift
// PhotoInputView.swift - Complete implementation
- AVFoundation camera capture
- Vision framework text extraction  
- Base64 image → Multimodal LLM analysis
- FoodConfirmationView for editing
- Full integration with NutritionService
```

#### 🎯 ARCHITECTURAL DECISIONS
- **NO Core ML** - Pure cloud-based LLM analysis
- **NO Image Storage** - Process and discard for privacy
- **Hybrid Approach** - Vision for text + LLM for food recognition

**⚠️ DO NOT**: Add Core ML models, store images persistently, or build offline fallbacks. This is intentional.

### 4. **Recovery System**

#### ✅ FULLY CONNECTED (Not Mock Data)
Despite comment at RecoveryDetailView.swift:632, the system is FULLY CONNECTED:
```swift
// RecoveryDetailView.swift:91-122
@State private var inference = RecoveryInference()
// Real data from HealthKit → RecoveryInference → UI
```

#### 🎯 ALGORITHM SPECIFICATIONS
- **HRV Analysis**: SDNN with 7-day rolling baseline
- **Z-Score Methodology**: Personal baseline comparison
- **Multi-factor Scoring**: HRV + RHR + Sleep + Training Load
- **Self-Calibrating**: Bias adjustment with subjective feedback

**⚠️ DO NOT**: Invent pseudo-scientific formulas or use population norms. The system uses established sports science.

### 5. **HealthKit Synchronization**

#### ✅ WHAT'S IMPLEMENTED
- **Read**: Comprehensive fetching of all health metrics
- **Write**: Body metrics, nutrition, workouts
- **Background**: Real-time observer for critical metrics
- **Caching**: Sophisticated cache with anchors

#### ❌ WHAT'S MISSING
- **Conflict Resolution**: No handling of duplicate entries
- **Source Priority**: No configurable data source preferences
- **Background Tasks**: No BGAppRefreshTask for periodic sync
- **Partial Permissions**: No handling of mixed read/write states

**⚠️ CRITICAL**: The system assumes eventual consistency, not strict sync. Don't implement strict synchronization.

## Architecture Philosophy - MUST UNDERSTAND

### AI-Native Design
```
Traditional App: User → Templates → Data
AirFit:         User → AI → Personalized Experience → Data
```

### No Templates Philosophy
- **Workouts**: AI generates, no preset templates
- **Meals**: AI analyzes, no meal templates
- **Coaching**: AI personalizes, no generic advice

### Data Flow Principles
1. **Local First**: SwiftData is primary, HealthKit secondary
2. **AI Enhancement**: Every feature enhanced by AI
3. **Privacy First**: Process and discard sensitive data
4. **Progressive Enhancement**: System learns from usage

## Implementation Rules

### ALWAYS DO
1. Check if feature already exists before building
2. Follow existing patterns (look at similar modules)
3. Use dependency injection via DIContainer
4. Implement @Observable ViewModels, not ObservableObject
5. Handle errors with AppError enum
6. Use existing UI components from CommonComponents

### NEVER DO
1. Create workout/meal templates
2. Store images persistently (privacy decision)
3. Implement strict HealthKit sync (eventual consistency)
4. Add Core ML models (cloud-based decision)
5. Build offline-first features (requires connectivity)
6. Use force unwrapping or fatal errors

## Specific Implementation Guidance

### When Implementing Watch Transfer
```swift
// Current stub at CoachEngine+Functions.swift:429
// Should implement:
1. Check WatchConnectivity.isSupported
2. Use WorkoutPlanTransferService (already exists)
3. Send PlannedWorkoutData structure
4. Handle transfer confirmation
5. Update UI with real status
```

### When Implementing Workout Analysis
```swift
// Current stub at CoachEngine+Functions.swift:435
// Should implement:
1. Parse workout_id parameter
2. Fetch workout from SwiftData
3. Calculate performance metrics
4. Compare to previous workouts
5. Generate personalized insights via AI
```

### When Implementing Conflict Resolution
```swift
// For HealthKit sync conflicts:
1. Implement last-write-wins for same-day data
2. User entries always override HealthKit
3. Merge non-conflicting data
4. Add user preference for source priority
```

## Testing Before Implementation

Before implementing ANY feature, verify:

1. **Does it already exist?** Search codebase thoroughly
2. **Is there a stub?** Check for hardcoded returns
3. **What's the intended architecture?** Look for comments/TODOs
4. **Are there existing patterns?** Check similar features
5. **Is it intentionally disabled?** Check FeatureToggles

## Common Vibe Coding Mistakes

### ❌ Mistake: "I'll add workout templates"
✅ Reality: AI generates all workouts dynamically

### ❌ Mistake: "I'll store meal photos"
✅ Reality: Privacy-first design processes and discards

### ❌ Mistake: "I'll add offline mode"
✅ Reality: Cloud-first architecture by design

### ❌ Mistake: "Recovery view needs real data"
✅ Reality: Already connected to RecoveryInference

### ❌ Mistake: "I'll fix the circular dependencies"
✅ Reality: No circular dependencies found - clean architecture

## File-Specific Warnings

### SettingsListView.swift (2,266 lines)
- **DO**: Break into smaller views
- **DON'T**: Rewrite from scratch

### CoachEngine.swift (2,112 lines)
- **DO**: Extract functions to services
- **DON'T**: Change the AI routing logic

### RecoveryDetailView.swift
- **IGNORE**: Line 632 comment about mock data
- **REALITY**: Fully connected to real data

### PhotoInputView.swift
- **EXISTS**: Fully implemented photo capture
- **DON'T**: Add Core ML or image storage

## Summary

This codebase is **75% complete with clear architectural decisions**. The remaining 25% is:
- UI completion (workout screens)
- Stub implementations (2 functions)
- Testing and reliability
- Performance optimization

**The architecture is intentional.** What looks like missing features are often deliberate design decisions. Always verify assumptions before implementing.