# Quick Start Guide for New Agents

## TL;DR - What You Need to Know

**The codebase is 75% complete and well-built. Don't rebuild it - finish it.**

## Instant Context

### What This App Is
- AI-powered fitness coach for iOS
- Uses HealthKit + SwiftData + Multiple LLMs
- Personal use app (not commercial yet)
- Modern SwiftUI architecture

### Current State
- ✅ **Working**: AI chat, nutrition tracking, health integration
- ⚡ **Partial**: Workout tracking, settings, dashboard
- ❌ **Missing**: Tests, photo food logging, workout UI

### Quality Assessment
- **Architecture**: Excellent (A-)
- **Implementation**: Good (B+)
- **Testing**: Poor (D)
- **Overall**: Worth completing

## For Agents Working on Features

### Safe to Modify
```
✅ AirFit/Modules/Workouts/     # Needs UI completion
✅ AirFit/Modules/FoodTracking/  # Photo feature needed
✅ AirFit/AirFitTests/           # Needs many more tests
✅ Docs/                         # Keep it updated
```

### Modify with Caution
```
⚠️ AirFit/Core/DI/              # DI system works well
⚠️ AirFit/Services/AI/          # Complex but functional
⚠️ AirFit/Application/          # Core app structure
```

### Don't Touch (Works Well)
```
❌ AirFit/Core/Theme/            # Theming is complete
❌ AirFit/Modules/Chat/          # Chat works perfectly
❌ Navigation system             # Type-safe and solid
```

## Common Tasks

### Running the App
```bash
# Open in Xcode
open AirFit.xcodeproj

# Build and run (iPhone 15 Pro simulator)
# The app will launch with a working AI coach
```

### Fix SwiftLint Issues
```bash
swiftlint --fix
# Then manually fix remaining issues
```

### Run Tests
```bash
xcodebuild test -scheme AirFit -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
# Warning: Only 2% coverage currently
```

### Key Files to Understand

1. **Entry Point**: `AirFitApp.swift`
2. **DI Setup**: `DIBootstrapper.swift` 
3. **Navigation**: `NavigationState.swift`
4. **AI Core**: `CoachEngine.swift` (warning: 2000+ lines)
5. **Main Screen**: `TodayDashboardView.swift`

## Critical Issues to Fix

### Immediate (Crashes)
```swift
// 1. App Store ID - AppConstants.swift:6
static let appStoreId = "YOUR_APP_STORE_ID" // REPLACE THIS

// 2. Fatal Errors - CoachEngine.swift:1535
fatalError("Use DI container...") // REMOVE THESE

// 3. Force Unwraps - Throughout
try! something() // FIX THESE (59 instances)
```

### High Priority
- Connect `RecoveryDetailView` to real data (currently mock)
- Break up `SettingsListView.swift` (2,266 lines!)
- Add integration tests for critical paths

## What's Actually Working

### You Can Use Today
1. **AI Chat**: Talk to the coach, get responses
2. **Nutrition**: Log food, see macro rings
3. **Dashboard**: View health metrics
4. **Settings**: Configure API keys
5. **Onboarding**: Complete user setup

### Partially Working
1. **Workouts**: Data models work, UI incomplete
2. **Recovery**: Calculations need connection
3. **Photos**: Infrastructure ready, needs implementation

## Architecture Quick Reference

### Pattern: Clean Architecture + MVVM-C
```
Views (SwiftUI) → ViewModels → Services (Actors) → Data (SwiftData/HealthKit)
```

### Dependency Injection
```swift
// Everything goes through DI container
let service = try await container.resolve(MyProtocol.self)
```

### Navigation
```swift
// Type-safe coordinator pattern
navigationState.navigate(to: .chat)
```

### Error Handling
```swift
// Consistent AppError enum
throw AppError.networkError("Description")
```

## Feature Flags

Located in `FeatureToggles.swift`:
```swift
static let watchSetupEnabled = false  // Watch app disabled
static let simpleOnboarding = false   // Using full onboarding
static let photoFoodLogging = false   // Not implemented yet
```

## Where to Find Things

### Core Logic
- **AI**: `/Modules/AI/`
- **Health**: `/Services/Health/`
- **Nutrition**: `/Modules/FoodTracking/`

### UI Components
- **Common**: `/Core/Views/`
- **Screens**: `/Modules/*/Views/`
- **Theme**: `/Core/Theme/`

### Configuration
- **Constants**: `/Core/Constants/`
- **DI Setup**: `/Core/DI/`
- **Services**: `/Services/`

## Testing Approach

### Current Tests (Minimal)
```
AirFitTests/
├── AIServiceTests.swift      # Basic modes
├── DISmokeTests.swift        # DI resolution
└── TestSupport.swift         # Good mocking setup
```

### What Needs Testing
1. **Critical**: Error paths, network failures
2. **Important**: User flows, data persistence
3. **Nice**: UI states, performance

## Working with the AI System

### Multiple Providers
```swift
// Supports Claude, GPT-4, Gemini
// Automatic fallback on failure
// Located in /Services/AI/LLMProviders/
```

### Streaming Responses
```swift
// Real-time streaming works
// Stop button functional
// See ChatViewModel.swift
```

### Function Calling
```swift
// AI can execute functions
// See CoachEngine+Functions.swift
```

## Common Gotchas

1. **SwiftData Constraints**: Some services forced to @MainActor
2. **Large Files**: Some views/services are 1000+ lines
3. **Force Unwraps**: Will crash in edge cases
4. **Mock Data**: Some views show fake data
5. **Watch App**: Code exists but disabled

## Quick Wins

If you want to contribute immediately:

1. **Add Tests**: Pick any service, add tests
2. **Fix Force Unwraps**: Search for `!` and fix
3. **Break Up Large Files**: Refactor big views
4. **Connect Mock Data**: Wire up real data sources
5. **Document Code**: Add missing documentation

## Questions to Ask Yourself

Before starting work:
1. Is this feature in the 75% complete or 25% incomplete?
2. Are there existing patterns I should follow?
3. Will my changes break existing functionality?
4. Should I add tests for this?
5. Is there technical debt I can clean up?

## Final Advice

**This is good code that needs completion, not replacement.** The architecture is solid, the patterns are modern, and most features work. Focus on:

1. Making it reliable (remove crashes)
2. Making it complete (finish features)
3. Making it tested (add coverage)

The codebase is closer to ship than to scrap. Treat it with respect and help it cross the finish line. 🚀