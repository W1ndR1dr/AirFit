# Safe Refactoring Guide

## Overview
This guide ensures we can optimize performance without breaking features. Every optimization must pass through these safety gates.

## 🛡️ The Safety Framework

### 1. **Feature Inventory First**
Before touching any code, document EVERYTHING the current implementation does:

```markdown
## Module: Onboarding
### Features:
- [ ] Health permission request
- [ ] Health data loading with progress
- [ ] Whisper voice setup
- [ ] Profile data collection (birthdate, sex)
- [ ] AI conversation with follow-ups
- [ ] Context quality tracking
- [ ] Persona generation with progress
- [ ] Coach confirmation/refinement
- [ ] Apple Watch setup
- [ ] Session persistence
- [ ] Error recovery with retry
- [ ] Model selection
- [ ] Fallback plan generation
```

### 2. **Behavioral Tests Before Refactoring**

#### Step 1: Write Feature Tests
```swift
// Tests that verify current behavior BEFORE optimization
class OnboardingFeatureTests: XCTestCase {
    
    func testHealthPermissionFlow() async {
        // Document current behavior
        let onboarding = try await createOnboarding()
        
        // Verify all features work
        XCTAssertTrue(onboarding.canRequestHealthPermission)
        XCTAssertNotNil(onboarding.healthDataLoadingView)
        
        // Trigger health permission
        await onboarding.startHealthAnalysis()
        
        // Verify progress updates
        XCTAssertTrue(onboarding.isLoadingHealthData)
        XCTAssertEqual(onboarding.healthDataStatus, "Requesting permission...")
    }
    
    func testConversationContextTracking() {
        // Document how context quality updates
        let onboarding = createOnboarding()
        
        // Initial state
        XCTAssertEqual(onboarding.contextQuality.overall, 0.0)
        
        // After first message
        await onboarding.analyzeConversation("I want to lose weight")
        XCTAssertGreaterThan(onboarding.contextQuality.goalClarity, 0.0)
    }
}
```

#### Step 2: Snapshot Tests
```swift
class OnboardingSnapshotTests: XCTestCase {
    
    func testAllOnboardingPhases() {
        // Capture visual state of each phase
        let phases: [OnboardingView.Phase] = [
            .healthPermission,
            .healthDataLoading,
            .whisperSetup,
            .profileSetup,
            .conversation,
            .insightsConfirmation,
            .generating,
            .confirmation,
            .watchSetup
        ]
        
        for phase in phases {
            let view = OnboardingView(phase: phase)
            assertSnapshot(matching: view, as: .image)
        }
    }
}
```

### 3. **The Refactoring Safety Checklist**

For EVERY optimization:

#### Pre-Flight Checklist
- [ ] Feature inventory documented
- [ ] Current behavior tests written and passing
- [ ] Snapshot tests captured
- [ ] Performance baseline measured
- [ ] Git commit of working state

#### During Refactoring
- [ ] Keep old implementation commented nearby
- [ ] Run tests after each significant change
- [ ] Verify no public API changes
- [ ] Check memory leaks with Instruments

#### Post-Refactoring Verification
- [ ] All original tests still pass
- [ ] Snapshot tests match (or differences are intentional)
- [ ] Performance improved (measured)
- [ ] No new warnings/errors
- [ ] Manual QA of all features

### 4. **The A/B Testing Pattern**

For risky optimizations, implement side-by-side:

```swift
struct DashboardView: View {
    @AppStorage("use_optimized_dashboard") var useOptimized = false
    
    var body: some View {
        if useOptimized {
            OptimizedDashboardView() // New implementation
        } else {
            LegacyDashboardView() // Current implementation
        }
    }
}
```

This allows:
- Gradual rollout
- Easy rollback
- Side-by-side testing
- Performance comparison

### 5. **Integration Test Suite**

Create end-to-end tests that verify complete flows:

```swift
class OnboardingIntegrationTests: XCTestCase {
    
    func testCompleteOnboardingFlow() async {
        // Start fresh
        let app = XCUIApplication()
        app.launchArguments = ["--reset-onboarding"]
        app.launch()
        
        // Health permission
        XCTAssert(app.buttons["Connect Health"].exists)
        app.buttons["Connect Health"].tap()
        
        // Wait for health data loading
        XCTAssert(app.staticTexts["Loading activity data..."].waitForExistence(timeout: 5))
        
        // Continue through all phases...
        // This ensures the FULL flow works
    }
}
```

## 🔍 Module-Specific Safety Patterns

### Dashboard Module
```swift
// Before optimizing DashboardViewModel
class DashboardSafetyTests: XCTestCase {
    
    func testAllCardsLoad() {
        // Document which cards exist
        let expectedCards = [
            "NutritionCard",
            "ActivityCard", 
            "SleepCard",
            "CoachCard"
        ]
        
        let dashboard = DashboardViewModel()
        XCTAssertEqual(dashboard.visibleCards, expectedCards)
    }
    
    func testDataRefresh() {
        // Verify refresh behavior
        let dashboard = DashboardViewModel()
        let initialData = dashboard.nutritionData
        
        await dashboard.refresh()
        
        XCTAssertNotEqual(dashboard.nutritionData, initialData)
        XCTAssertTrue(dashboard.lastRefresh > Date.distantPast)
    }
}
```

### Chat Module
```swift
// Critical behaviors to preserve
class ChatSafetyTests: XCTestCase {
    
    func testMessagePersistence() {
        // Messages must persist across sessions
    }
    
    func testStreamingResponse() {
        // AI responses must stream character by character
    }
    
    func testOfflineMode() {
        // Chat must show cached messages when offline
    }
}
```

## 🚨 Red Flags During Optimization

### 1. **Changing Public APIs**
```swift
// ❌ DANGER: Breaking change
class OnboardingIntelligence {
    // Old: private init(...)
    // New: init(...) // Made public - breaks encapsulation
}

// ✅ SAFE: Internal optimization
class OnboardingIntelligence {
    init(...) {
        // Same public API, optimized internals
    }
}
```

### 2. **Removing "Unused" Code**
```swift
// ❌ DANGER: Looks unused but isn't
func validateServicesInBackground() {
    // This runs async - tools might say it's unused!
}

// ✅ SAFE: Verify with tests first
// Add test that fails if method is removed
```

### 3. **Changing Timing**
```swift
// ❌ DANGER: Changed order
// Old: Request permission → Load data
// New: Load data → Request permission

// ✅ SAFE: Preserve sequences
// Keep critical ordering intact
```

## 📊 Performance Regression Tests

Add performance tests to prevent future regressions:

```swift
class PerformanceTests: XCTestCase {
    
    func testDashboardLoadTime() {
        measure(metrics: [XCTClockMetric()]) {
            let dashboard = DashboardView()
            _ = dashboard.body
        }
        
        // Assert baseline performance
        XCTAssertLessThan(executionTime, 0.2) // 200ms
    }
    
    func testMemoryUsage() {
        let options = XCTMeasureOptions()
        options.iterationCount = 1
        
        measure(metrics: [XCTMemoryMetric()], options: options) {
            // Load chat with 1000 messages
            let chat = ChatView(mockLongConversation)
            _ = chat.body
        }
        
        // Assert memory bounds
        XCTAssertLessThan(peakMemory, 100_000_000) // 100MB
    }
}
```

## 🔄 The Safe Refactoring Workflow

### Phase 1: Document
1. List ALL features
2. Document current behavior
3. Note any undocumented side effects

### Phase 2: Test
1. Write tests for current behavior
2. Add snapshot tests
3. Create performance baselines

### Phase 3: Refactor
1. Make incremental changes
2. Run tests after each change
3. Keep old code commented until verified

### Phase 4: Verify
1. All tests pass
2. Manual QA checklist complete
3. Performance improved
4. No regressions

### Phase 5: Clean Up
1. Remove old code
2. Update documentation
3. Add regression tests

## 📝 Manual QA Checklists

### Onboarding QA Checklist
- [ ] Fresh install flow works
- [ ] Returning user flow works
- [ ] Skip options work at each phase
- [ ] Error recovery works
- [ ] All text input works
- [ ] Voice input works
- [ ] Progress saves between app launches
- [ ] Watch setup detects watch correctly
- [ ] Persona generation completes
- [ ] Coach personality matches inputs

### Dashboard QA Checklist
- [ ] All cards load
- [ ] Pull to refresh works
- [ ] Tapping cards navigates correctly
- [ ] Data updates in real-time
- [ ] Works offline with cached data
- [ ] Handles errors gracefully

## 🛠️ Debugging Tools

### 1. **Feature Flags**
```swift
enum FeatureFlags {
    static let useOptimizedDashboard = false
    static let useVirtualizedChat = false
    static let useBackgroundCameraInit = false
}
```

### 2. **Performance Overlay**
```swift
#if DEBUG
struct PerformanceDebugView: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            VStack {
                Text("Renders: \(renderCount)")
                Text("Memory: \(memoryUsage)MB")
            }
        }
    }
}
#endif
```

### 3. **Logging Guards**
```swift
// Add before/after logging
AppLogger.info("Starting optimization: \(feature)")
// ... optimization code ...
AppLogger.info("Completed optimization: \(feature)")
```

## ⚡ Quick Safety Checks

Before committing ANY optimization:

1. **The 5-Minute Check**
   - Do all existing tests pass?
   - Does the app still build?
   - Can you complete the basic flow?

2. **The 15-Minute Check**
   - Run the full test suite
   - Check memory in Instruments
   - Test on oldest supported device

3. **The 1-Hour Check**
   - Full manual QA
   - Performance benchmarks
   - Code review with teammate

## 🎯 Golden Rules

1. **If you can't test it, don't optimize it**
2. **Small, incremental changes are safer**
3. **Keep the old code until the new code is proven**
4. **Performance without correctness is worthless**
5. **When in doubt, measure**

---

*"Make it work, make it right, make it fast, but KEEP IT WORKING throughout."*