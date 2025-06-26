# Navigation Implementation Context

## Current State Summary

### What Exists:
- ✅ All major views (ChatView, FoodLoggingView, WorkoutListView, DashboardView)
- ✅ Coordinator pattern for each module
- ✅ LocalCommandParser with navigation support
- ✅ AppTab enum (needs updating)
- ✅ Beautiful UI components (GlassCard, CascadeText, gradients)

### What's Broken:
- ❌ No TabView implementation
- ❌ Chat completely inaccessible 
- ❌ Quick actions all go to .nutritionDetail (doesn't exist)
- ❌ DashboardDestination enum missing most destinations
- ❌ No cross-module navigation

### What's Missing:
- ❌ MainTabView
- ❌ NavigationState for cross-tab communication
- ❌ ProfileView
- ❌ Floating AI Assistant (FAB)
- ❌ Voice navigation commands

## Key Implementation Notes

### 1. Tab Order & Defaults
```swift
// Optimal tab order for muscle memory
[.chat, .dashboard, .food, .workouts, .profile]

// Chat as default because it's the "central interaction"
@State private var selectedTab = AppTab.chat
```

### 2. Navigation Pattern
Each tab has its own NavigationStack to maintain independent navigation state:
```swift
TabView(selection: $selectedTab) {
    NavigationStack { ChatView() }
        .tag(AppTab.chat)
    NavigationStack { DashboardView() }
        .tag(AppTab.dashboard)
    // etc...
}
```

### 3. Cross-Tab Navigation
Use environment object for navigation state:
```swift
@EnvironmentObject var navigationState: NavigationState

// From quick action:
navigationState.selectedTab = .food
navigationState.pendingFoodAction = .logMeal(type: .lunch)
```

### 4. AI Integration Points

Every navigation should be AI-aware:
- Tab switches can trigger AI context updates
- Voice commands bypass UI entirely
- AI can suggest next navigation based on patterns

### 5. Floating AI Assistant Design

The FAB should:
- Always visible (except during text input)
- Minimize to corner when not active
- Expand to show current AI response
- Support both tap (quick actions) and hold (voice)

### 6. Voice Command Examples

LocalCommandParser should handle:
- "Show dashboard" → Switch to dashboard tab
- "Log breakfast" → Food tab + breakfast logging
- "Start workout" → Workout tab + start flow
- "Chat" or "Coach" → Return to chat tab
- "What did I eat today?" → Food tab + today view
- "Check recovery" → Dashboard + recovery card

### 7. Quick Action Intelligence

Quick actions should be:
- Time-aware (breakfast in morning, etc.)
- Context-aware (current tab, recent actions)
- Goal-aware (missing data, behind on goals)
- Pattern-aware (usual workout time, meal times)

### 8. Performance Considerations

- Lazy load tab content (don't init all VMs at once)
- Keep chat VM in memory (primary interaction)
- Preload next likely tab based on patterns
- Cache voice recognition for common commands

### 9. Testing Considerations

Test navigation flows:
- Onboarding → MainTabView (chat default)
- Quick action → correct tab + action
- Voice command → navigation
- Deep links → correct tab + view
- Background/foreground → maintain state

### 10. Future Enhancements

- Gesture navigation (swipe between tabs)
- 3D Touch/long press shortcuts
- Widget quick actions
- Siri Shortcuts for navigation
- Apple Watch navigation sync

## Critical Path

1. Get basic TabView working with Chat accessible
2. Fix quick actions to actually navigate
3. Add voice navigation via LocalCommandParser
4. Implement floating AI assistant
5. Polish with animations and haptics

The navigation transformation is critical because users currently can't access the chat - the app's core feature. This must be fixed immediately.