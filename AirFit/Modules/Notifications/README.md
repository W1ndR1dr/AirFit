# Notifications Module (Module 9)

This module handles all notification-related functionality for AirFit, including local notifications, push notifications, engagement tracking, and Live Activities.

## Architecture

The module follows the MVVM-C pattern:

### Coordinator
- `NotificationsCoordinator.swift` - Manages module dependencies and navigation

### Managers (Stateful orchestration)
- `NotificationManager.swift` - Core notification scheduling and authorization
- `LiveActivityManager.swift` - Dynamic Island and Live Activities

### Services (Business logic)
- `EngagementEngine.swift` - User engagement tracking and re-engagement
- `NotificationContentGenerator.swift` - AI-powered notification content generation

### Models
- `NotificationModels.swift` - All notification-related data structures

## Features

1. **Local Notifications**
   - Morning greetings
   - Workout reminders
   - Meal reminders
   - Hydration reminders
   - Achievement notifications

2. **Engagement Tracking**
   - User activity monitoring
   - Lapse detection (respects user preferences)
   - Re-engagement campaigns
   - Background task scheduling

3. **Live Activities**
   - Real-time workout tracking
   - Meal logging progress
   - Dynamic Island integration

4. **AI Integration**
   - Personalized notification content
   - Context-aware messaging
   - Fallback templates when AI unavailable

## Usage

```swift
// Initialize the coordinator
let coordinator = NotificationsCoordinator(
    modelContext: modelContext,
    coachEngine: coachEngine
)

// Setup notifications
try await coordinator.setupNotifications()

// Schedule smart notifications for a user
await coordinator.scheduleSmartNotifications(for: user)

// Start a workout live activity
try await coordinator.startWorkoutLiveActivity(workoutType: "Strength Training")
```

## Configuration

Add to Info.plist:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.airfit.lapseDetection</string>
    <string>com.airfit.engagementAnalysis</string>
</array>
<key>NSSupportsLiveActivities</key>
<true/>
```

## Testing

Tests are located in `AirFitTests/Modules/Notifications/`