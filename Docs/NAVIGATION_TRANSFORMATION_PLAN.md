# AirFit Navigation Transformation Plan

## Executive Summary

Transform AirFit from a dashboard-centric app to an AI-chat-centric experience where the coach conversation is the primary interface. All other features (food logging, workouts, stats) flow through natural conversation with the AI.

## Current State Issues

### Critical Problems
1. **Chat is completely inaccessible** - No way to reach the "central interaction experience"
2. **No tab navigation** - App goes straight from onboarding to dashboard
3. **Broken quick actions** - All navigate to `.nutritionDetail` which doesn't exist
4. **One-way navigation** - Once in settings, no clear way back
5. **Disconnected modules** - Each feature is an island

### Missing AI-Native Features
- No persistent chat bubble/FAB for instant AI access
- No voice-first interactions
- No AI suggestions in navigation
- No conversational shortcuts

## Optimal AI-Native Solution

### Core Principle: "Chat is the OS"

The AI coach conversation should be:
- Always accessible (persistent FAB or gesture)
- The primary way to navigate ("Show me my nutrition" → opens nutrition view)
- Context-aware (knows what screen you're on)
- Proactive (suggests actions based on time/data)

### 1. Navigation Architecture

```
ContentView
  └── MainTabView (with floating AI chat overlay)
      ├── Chat (default tab) - Full conversation view
      ├── Dashboard - AI-curated daily insights  
      ├── Food - Voice-first logging with AI parsing
      ├── Activity - Workouts with AI form coaching
      └── Profile - Stats & settings
```

### 2. AI-First Navigation Features

#### Floating AI Assistant
- **Persistent FAB** in bottom-right (always visible)
- **Minimized chat view** when on other tabs
- **Voice activation** with wake word "Hey Coach"
- **Contextual awareness** of current screen

#### Conversational Navigation
```swift
// User says: "Show me what I ate today"
// AI responds and navigates to Food tab with today's meals

// User says: "I want to work out"  
// AI asks what type and navigates to workout starter

// User says: "How's my recovery?"
// AI explains and shows recovery dashboard
```

#### Smart Quick Actions
- AI-generated based on:
  - Time of day
  - User patterns  
  - Missing data
  - Health metrics
  - Previous conversations

### 3. Implementation Strategy

#### Phase 1: Core Navigation (Immediate)
1. Create `MainTabView` with Chat as default
2. Add `NavigationState` for cross-tab communication
3. Fix quick actions to use proper navigation
4. Make chat accessible from everywhere

#### Phase 2: AI Integration (Next)
1. Add floating AI bubble overlay
2. Implement voice navigation commands
3. Add conversational navigation parser
4. Create AI-powered quick actions

#### Phase 3: Intelligence Layer (Future)
1. Proactive suggestions based on patterns
2. Contextual help on each screen
3. Voice-first everything
4. Predictive navigation

### 4. Technical Architecture

#### NavigationState (Shared)
```swift
@MainActor
@Observable
final class NavigationState {
    // Tab Management
    var selectedTab: MainTabView.Tab = .chat
    var previousTab: MainTabView.Tab?
    
    // AI Chat State
    var isChatMinimized = false
    var hasUnreadMessages = false
    var lastAIPrompt: String?
    
    // Cross-Tab Communication
    var pendingChatPrompt: String?
    var navigationIntent: NavigationIntent?
    
    // Voice State
    var isListeningForWakeWord = true
    var voiceInputActive = false
}
```

#### Update GlobalEnums.AppTab
The existing AppTab enum needs updating to include Chat:
```swift
public enum AppTab: String, CaseIterable, Sendable {
    case chat       // NEW - make this the primary tab
    case dashboard  
    case meals      // Rename to 'food' for clarity
    case workouts   // NEW - replace 'discover' 
    case profile    // NEW - replace 'progress' with unified profile/stats
    
    public var systemImage: String {
        switch self {
        case .chat: return "message.fill"
        case .dashboard: return "house.fill"
        case .meals: return "fork.knife"
        case .workouts: return "figure.run"
        case .profile: return "person.circle.fill"
        }
    }
}
```

#### NavigationIntent (AI-Driven)
```swift
enum NavigationIntent {
    case showFood(date: Date?, mealType: MealType?)
    case startWorkout(type: WorkoutType?)
    case showStats(metric: HealthMetric?)
    case logQuickAction(type: QuickActionType)
    case executeCommand(parsed: ParsedCommand)
}
```

### 5. AI Coach Integration Points

Every screen should have AI integration:

#### Dashboard
- AI generates personalized greeting
- Suggests actions based on data gaps
- Explains metrics in natural language

#### Food Tracking  
- Voice-first food logging
- AI parses complex meal descriptions
- Suggests based on goals and patterns

#### Workouts
- AI form coaching via camera
- Conversational workout programming
- Real-time encouragement

#### Profile/Stats
- AI explains trends
- Suggests goal adjustments
- Celebrates achievements

### 6. User Flows

#### Primary Flow (AI-Centric)
1. Open app → See chat with morning greeting
2. Say/type "I just ate breakfast"
3. AI parses, confirms, logs food
4. Suggests next action based on goals
5. All navigation through conversation

#### Quick Action Flow
1. See floating AI bubble
2. Tap for quick actions (AI-generated)
3. Or long-press for voice input
4. AI handles intent and navigation

### 7. Visual Design

#### Tab Bar
- Glass morphism effect
- Gradient tint on selected tab
- Unread indicator on chat tab
- Smooth gradient transitions

#### Floating AI Assistant
- Pulsing gradient when active
- Minimizes to bubble when navigating
- Voice waveform during input
- Always accessible, never intrusive

### 8. Empty States

Each empty state invites AI interaction:
- Chat: "Say hello to start your journey!"
- Food: "Tell me what you've eaten today"
- Workouts: "Ready to move? Let's create a plan"
- Dashboard: "Loading your personalized insights..."

### 9. File Structure

```
Application/
  ├── MainTabView.swift (NEW)
  ├── NavigationState.swift (NEW)
  └── ContentView.swift (MODIFY)

Core/Views/
  ├── FloatingAIAssistant.swift (NEW)
  ├── MinimizedChatView.swift (NEW)
  └── VoiceInputOverlay.swift (NEW)

Modules/Profile/
  └── Views/ProfileView.swift (NEW)

Modules/Dashboard/
  └── Views/DashboardView.swift (MODIFY - fix quick actions)
```

### 10. Success Metrics

- Chat engagement > 80% of sessions
- Voice input usage > 50% of interactions  
- Quick action completion rate > 70%
- Cross-tab navigation via AI > 30%
- User retention improvement > 25%

## Implementation Details

### LocalCommandParser Integration

The existing LocalCommandParser already supports navigation commands. We need to extend it:

```swift
// Add to LocalCommandParser
case navigateToChat
case navigateToFood
case navigateToWorkouts
case navigateToProfile
case showNutrition(date: Date?)
case showWorkoutHistory
case showRecovery

// Update parse() method to handle phrases like:
// "show me my food" → navigateToFood
// "chat with coach" → navigateToChat
// "start workout" → navigateToWorkouts + trigger workout start
// "how's my recovery" → showRecovery
```

### AI Context Awareness

Each tab should provide context to the AI:

```swift
protocol AIContextProvider {
    var aiContext: String { get }
    var suggestedPrompts: [String] { get }
}

// Example for FoodLoggingView
extension FoodLoggingView: AIContextProvider {
    var aiContext: String {
        "User is viewing food tracking. Today: \(summary.calories)/\(targets.calories) cal"
    }
    
    var suggestedPrompts: [String] {
        ["Log my lunch", "What should I eat?", "Show nutrition goals"]
    }
}
```

### Voice Navigation Flow

1. User says "Hey Coach" or taps FAB
2. Voice input activates with visual feedback
3. LocalCommandParser checks for navigation intent
4. If navigation command: execute immediately
5. If not: send to AI with current context

### Quick Action Intelligence

```swift
func generateQuickActions(for context: AppContext) -> [QuickAction] {
    let hour = Date().hour
    let hasLoggedMeals = context.todaysMeals.count > 0
    let lastWorkout = context.lastWorkoutDate
    
    var actions: [QuickAction] = []
    
    // Time-based suggestions
    if (6...9).contains(hour) && !hasLoggedMeals {
        actions.append(.logMeal(type: .breakfast))
    }
    
    // Pattern-based suggestions
    if daysSince(lastWorkout) > 2 {
        actions.append(.startWorkout)
    }
    
    // Goal-based suggestions
    if context.waterIntake < context.waterGoal * 0.5 {
        actions.append(.logWater)
    }
    
    return actions
}
```

## Next Steps

1. **Phase 1 (Immediate)**
   - Update AppTab enum to include chat
   - Create MainTabView with chat as default
   - Fix DashboardCoordinator destinations
   - Fix handleQuickAction to use real navigation

2. **Phase 2 (This Week)**
   - Add NavigationState for cross-tab communication
   - Extend LocalCommandParser for navigation
   - Create floating AI assistant view
   - Add voice input to FAB

3. **Phase 3 (Next Week)**
   - Implement AIContextProvider protocol
   - Add context awareness to each screen
   - Create intelligent quick action generation
   - Add conversational navigation parsing

The goal: Make AirFit feel like having a real fitness coach in your pocket who knows everything about you and can help instantly with voice or text.