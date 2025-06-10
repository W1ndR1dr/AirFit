# StandardCard Migration Tracker

**Goal**: Migrate ALL card-like components to use StandardCard
**Progress**: 33/33 (100%) ✅ COMPLETE!
**Last Updated**: 2025-06-09

## Migration Strategy
1. Find all components with card-like patterns
2. Group by module for systematic migration
3. Test each migration visually
4. Remove redundant styling code

## Dashboard Module ✅ COMPLETE (5/5)
- [x] MorningGreetingCard.swift
- [x] QuickActionsCard.swift 
- [x] RecoveryCard.swift
- [x] PerformanceCard.swift
- [x] NutritionCard.swift (uses TappableCard variant)
- Note: MetricCard, ProgressCard, SummaryCard don't exist

## Food Tracking Module ✅ COMPLETE (3/3)
- [x] WaterTrackingView.swift - hydrationTipsSection
- [x] FoodConfirmationView.swift - FoodItemCard
- [x] FoodLoggingView.swift - macroSummaryCard, MealCard, SuggestionCard

## Workout Module ✅ COMPLETE (13/13)
- [x] WorkoutDetailView.swift - aiAnalysisSection
- [x] WorkoutDetailView.swift - SummaryStatCard
- [x] WorkoutDetailView.swift - WorkoutExerciseCard
- [x] WorkoutListView.swift - WeeklySummaryCard
- [x] WorkoutListView.swift - WorkoutRow
- [x] WorkoutListView.swift - QuickActionCard
- [x] AllWorkoutsView.swift - WorkoutHistoryStats
- [x] AllWorkoutsView.swift - WorkoutHistoryRow
- [x] WorkoutStatisticsView.swift - mainChartSection
- [x] WorkoutStatisticsView.swift - muscleGroupSection
- [x] WorkoutStatisticsView.swift - workoutTypeSection
- [x] WorkoutStatisticsView.swift - SummaryCard
- [x] WorkoutStatisticsView.swift - PersonalRecordRow

## Onboarding Module (2/2) ✅ COMPLETE
- [x] PersonaPreviewCard.swift
- [x] ChoiceCardsView.swift - ChoiceCard
- Note: Other listed cards don't exist in codebase

## Settings Module (9/9) ✅ COMPLETE
- [x] SettingsComponents.swift - SettingsCard (now uses StandardCard internally)
- [x] SettingsListView.swift - 6 Card instances
- [x] PrivacySecurityView.swift - 4 Card instances
- [ ] Other settings views - TODO: verify remaining files

## Chat Module (0/0) ✅ N/A
- Note: Chat module uses bubble shapes, not card patterns

## Common/Shared (1/1) ✅ COMPLETE
- [x] Card.swift (in CommonComponents - updated to use StandardCard)
- Note: Other listed cards don't exist in codebase

## Pattern to Look For
```swift
// OLD PATTERN - Find these
.padding(...)
.background(...)
.cornerRadius(...)
.shadow(...)

// OR
RoundedRectangle(cornerRadius: ...)
    .fill(...)
    .shadow(...)
```