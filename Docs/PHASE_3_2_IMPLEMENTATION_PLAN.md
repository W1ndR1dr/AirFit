# Phase 3.2 Implementation Plan

**Created**: 2025-06-10  
**Purpose**: Tactical plan for completing Phase 3.2 AI optimizations

## Remaining Tasks Overview

1. ✅ **AIResponseCache Memory Leak** (Bug Fix) - COMPLETE
2. ✅ **AIWorkoutService Implementation** - COMPLETE  
3. ✅ **AIGoalService Implementation** - COMPLETE
4. 🚧 **AIAnalyticsService Implementation** - IN PROGRESS
5. 🔴 **CRITICAL: Persona Coherence Refactoring** - DISCOVERED

Total: ~4 hours of focused work remaining

## Task 1: AIResponseCache Memory Leak 🔴 CRITICAL

### Problem
- Task in init() runs without cancellation
- Detached tasks for disk saves never cancelled
- No cleanup of expired entries

### Solution
```swift
actor AIResponseCache {
    private var initTask: Task<Void, Never>?
    private var activeTasks = Set<Task<Void, Never>>()
    
    init() {
        initTask = Task {
            await loadDiskCacheMetadata()
            await startPeriodicCleanup()
        }
    }
    
    func reset() async {
        initTask?.cancel()
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
        // Rest of reset...
    }
}
```

### Test Plan
- Verify tasks are cancelled on reset
- Check memory usage doesn't grow unbounded
- Ensure disk operations complete or cancel cleanly

## Task 2: AIWorkoutService Implementation ✅ COMPLETE

### What Was Implemented
- Real AI-powered workout generation using LLM
- Exercise database integration with equipment/muscle filtering
- JSON-structured prompts and response parsing
- Workout adaptation based on user feedback

### Implementation Plan
1. **Exercise Selection Algorithm**
   ```swift
   func selectExercises(
       muscles: [String],
       equipment: [String],
       duration: Int
   ) -> [PlannedExercise] {
       // Filter exercise database by equipment
       // Balance muscle groups
       // Fit within time constraint
   }
   ```

2. **AI Integration for Personalization**
   ```swift
   let prompt = """
   Create a \(duration)-minute workout plan for \(goal).
   Equipment: \(equipment.joined(separator: ", "))
   Focus: \(targetMuscles.joined(separator: ", "))
   """
   let aiSuggestions = try await aiService.completeChat(...)
   ```

3. **Adaptive Modifications**
   - Parse feedback (too hard, too easy, etc.)
   - Adjust intensity, volume, or exercise selection
   - Learn from user preferences

### Dependencies
- Need exercise database (already exists in Resources/exercises.json)
- AIService for generating variations
- User's workout history for personalization

## Task 3: AIGoalService Implementation ✅ COMPLETE

### What Was Implemented
- Real AI-powered goal refinement using structured JSON prompts
- Dynamic milestone generation with AI
- Goal adjustment analysis based on progress
- SMART criteria validation through LLM

### Implementation Plan
1. **AI-Powered Goal Analysis**
   ```swift
   func analyzeGoalWithAI(_ goal: String) async throws -> GoalAnalysis {
       let prompt = """
       Analyze this fitness goal: "\(goal)"
       Provide:
       1. Specific measurable targets
       2. Realistic timeline
       3. Key milestones
       4. Potential obstacles
       """
   }
   ```

2. **Personalized Recommendations**
   - Consider user's fitness level
   - Account for past performance
   - Suggest complementary goals

3. **Dynamic Adjustments**
   - Monitor progress via HealthKit
   - Suggest modifications based on performance
   - Celebrate achievements

## Task 4: AIAnalyticsService Implementation

### Current State
- Returns empty analytics
- No trend detection
- No predictions

### Implementation Plan
1. **Data Aggregation**
   ```swift
   func aggregateMetrics(days: Int) async throws -> MetricsSummary {
       // Fetch from HealthKit
       // Calculate averages, totals, streaks
       // Identify patterns
   }
   ```

2. **Trend Analysis**
   - Moving averages for key metrics
   - Identify improving/declining patterns
   - Correlate different metrics

3. **AI-Enhanced Insights**
   ```swift
   let prompt = """
   Analyze these fitness metrics:
   \(metricsJSON)
   Provide actionable insights and predictions.
   """
   ```

4. **Predictive Modeling**
   - Simple linear projections
   - Goal achievement likelihood
   - Suggested interventions

## Implementation Order

### Why This Order?
1. **Memory Leak First** - Fix bugs before features
2. **AIWorkoutService** - Most user-visible impact
3. **AIGoalService** - Builds on workout capabilities  
4. **AIAnalyticsService** - Depends on data from others

## Testing Strategy

### Unit Tests Needed
- AIResponseCache: Task cancellation, memory cleanup
- AIWorkoutService: Exercise selection logic
- AIGoalService: Milestone calculations
- AIAnalyticsService: Trend detection accuracy

### Integration Tests
- AI service mock responses
- End-to-end workout generation
- Goal tracking with real data

## Success Criteria

1. **No Memory Leaks** - Instruments shows stable memory
2. **Real Workouts** - Generated plans are executable
3. **Smart Goals** - AI improves goal quality
4. **Actionable Analytics** - Users get valuable insights

## Risk Mitigation

### AI Service Failures
- Fallback to rule-based logic
- Cache successful responses
- Graceful degradation

### Performance Concerns  
- Implement timeouts
- Background processing where possible
- Progress indicators for users

## Demo Mode Considerations

Each service should work in demo mode:
- AIWorkoutService: Pre-defined quality workouts
- AIGoalService: Realistic goal suggestions
- AIAnalyticsService: Sample trend data

This ensures users can experience features without API keys.

## Task 5: Persona Coherence Refactoring 🔴 CRITICAL

### Problem Discovered
All AI services use generic system prompts instead of the user's personalized coach persona created during onboarding. This fragments the user experience and wastes the elaborate persona generation.

### Solution
Inject PersonaService into all AI services and use the user's PersonaProfile for system prompts, with task-specific context added as messages.

### Implementation Plan
1. **Update DIBootstrapper** - Add PersonaService to AI service registrations
2. **Update Each AI Service** - Add PersonaService dependency
3. **Refactor Prompts** - Use persona.systemPrompt with task context
4. **Maintain Coherence** - One coach personality across all features

### Expected Impact
- Consistent coach personality across all interactions
- Preserves onboarding investment
- Creates magical coherent experience
- Uses existing architecture patterns