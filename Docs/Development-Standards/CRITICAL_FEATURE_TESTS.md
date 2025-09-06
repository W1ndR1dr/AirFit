# Critical Feature Test Coverage

## Overview
These tests MUST pass before and after any optimization. They represent the core functionality that users depend on.

## 🔴 Critical User Journeys

### 1. **First-Time User Onboarding**
```swift
class FirstTimeUserTests: XCTestCase {
    
    func testCompleteOnboardingPath() async {
        // Reset to fresh state
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Critical checkpoints
        let checkpoints = [
            "User sees welcome screen",
            "Health permission requested",
            "Health data loads if permitted",
            "Voice setup optional but accessible", 
            "Profile data saves correctly",
            "AI conversation works",
            "Persona generates successfully",
            "User can start using app"
        ]
        
        // Verify each checkpoint
        for checkpoint in checkpoints {
            let success = await verifyCheckpoint(checkpoint)
            XCTAssertTrue(success, "Failed: \(checkpoint)")
        }
    }
}
```

### 2. **Daily Active User Flow**
```swift
class DailyUserTests: XCTestCase {
    
    func testMorningRoutine() async {
        // What users do every morning
        
        // 1. Open app - must be instant
        let launchTime = await measureAppLaunch()
        XCTAssertLessThan(launchTime, 1.0) // Under 1 second
        
        // 2. Check dashboard - data must be fresh
        let dashboard = await openDashboard()
        XCTAssertTrue(dashboard.hasCurrentData)
        XCTAssertEqual(dashboard.visibleCards.count, 4)
        
        // 3. Log breakfast - must be smooth
        let foodTracking = await navigateToFoodTracking()
        XCTAssertTrue(foodTracking.cameraReady)
        XCTAssertTrue(foodTracking.searchWorks)
        
        // 4. Chat with AI - must respond
        let chat = await openChat()
        let response = await chat.send("Good morning!")
        XCTAssertFalse(response.isEmpty)
    }
}
```

### 3. **Data Integrity Tests**
```swift
class DataIntegrityTests: XCTestCase {
    
    func testUserDataPersistence() async {
        // Create user data
        let profile = OnboardingProfile(
            birthDate: Date(),
            biologicalSex: "male"
        )
        
        // Save it
        let user = await userService.createUser(from: profile)
        
        // Force quit and restart
        await forceQuitApp()
        await launchApp()
        
        // Verify data survived
        let loadedUser = await userService.currentUser
        XCTAssertEqual(loadedUser?.id, user.id)
        XCTAssertEqual(loadedUser?.birthDate, profile.birthDate)
    }
    
    func testHealthKitSync() async {
        // Verify bi-directional sync
        let testWorkout = createTestWorkout()
        
        // Save to HealthKit
        await healthKit.save(testWorkout)
        
        // Verify appears in our app
        let workouts = await fetchRecentWorkouts()
        XCTAssertTrue(workouts.contains(testWorkout))
    }
}
```

## 🟡 Performance Benchmarks

### Must-Meet Performance Criteria
```swift
class PerformanceBenchmarks: XCTestCase {
    
    func testCriticalPerformanceMetrics() {
        // App Launch
        XCTAssertLessThan(appLaunchTime, 1.0)
        
        // Tab Switching  
        XCTAssertLessThan(tabSwitchTime, 0.1)
        
        // Search Response
        XCTAssertLessThan(searchResponseTime, 0.3)
        
        // AI First Token
        XCTAssertLessThan(aiFirstTokenTime, 2.0)
        
        // Memory Usage
        XCTAssertLessThan(baselineMemory, 200_000_000) // 200MB
        
        // No Memory Leaks
        XCTAssertEqual(memoryLeaks.count, 0)
    }
}
```

## 🟢 Feature-Specific Safety Tests

### Dashboard Safety
```swift
extension DashboardTests {
    
    func testAllCardsFunction() {
        let cards = [
            ("NutritionCard", testNutritionCardTap),
            ("ActivityCard", testActivityCardTap),
            ("SleepCard", testSleepCardTap),
            ("CoachCard", testCoachCardTap)
        ]
        
        for (cardName, test) in cards {
            XCTContext.runActivity(named: "Test \(cardName)") { _ in
                test()
            }
        }
    }
    
    func testDataRefreshDoesntLoseState() {
        // Set some state
        dashboard.selectedTimeRange = .week
        dashboard.expandedCards = ["NutritionCard"]
        
        // Refresh
        await dashboard.refresh()
        
        // State preserved
        XCTAssertEqual(dashboard.selectedTimeRange, .week)
        XCTAssertEqual(dashboard.expandedCards, ["NutritionCard"])
    }
}
```

### Chat Safety
```swift
extension ChatTests {
    
    func testMessageOrderingPreserved() {
        // Send multiple messages quickly
        let messages = (1...10).map { "Message \($0)" }
        
        for message in messages {
            await chat.send(message)
        }
        
        // Verify order preserved
        let displayed = chat.displayedMessages.map { $0.text }
        XCTAssertEqual(displayed, messages)
    }
    
    func testStreamingDoesntDuplicate() {
        // Start streaming response
        let streamHandle = await chat.streamResponse(to: "Hello")
        
        // Simulate partial tokens
        await streamHandle.receive("Hel")
        await streamHandle.receive("Hello")
        await streamHandle.receive("Hello, how")
        
        // Should have ONE message, not three
        XCTAssertEqual(chat.messages.count, 2) // User + AI
    }
}
```

## 🔄 State Preservation Tests

```swift
class StatePreservationTests: XCTestCase {
    
    func testOnboardingStateRestoration() {
        // Start onboarding
        let onboarding = OnboardingView()
        onboarding.phase = .conversation
        onboarding.conversationCount = 3
        onboarding.userInput = "I want to lose 20 pounds"
        
        // Simulate app termination
        let savedState = onboarding.saveState()
        
        // Restore
        let restored = OnboardingView(state: savedState)
        XCTAssertEqual(restored.phase, .conversation)
        XCTAssertEqual(restored.conversationCount, 3)
        XCTAssertEqual(restored.userInput, "I want to lose 20 pounds")
    }
}
```

## 🛡️ Regression Prevention

### Visual Regression Tests
```swift
class VisualRegressionTests: XCTestCase {
    
    func testCriticalUIElements() {
        let criticalViews = [
            DashboardView(),
            ChatView(),
            FoodTrackingView(),
            ExerciseLibraryView(),
            SettingsView()
        ]
        
        for view in criticalViews {
            assertSnapshot(
                matching: view,
                as: .image(precision: 0.99),
                record: false // Set to true to update baselines
            )
        }
    }
}
```

### API Contract Tests
```swift
class APIContractTests: XCTestCase {
    
    func testPublicAPIsUnchanged() {
        // These interfaces must remain stable
        
        // OnboardingIntelligence
        XCTAssertTrue(OnboardingIntelligence.self.init != nil)
        XCTAssertTrue(OnboardingIntelligence.self.startHealthAnalysis != nil)
        
        // DashboardViewModel
        XCTAssertTrue(DashboardViewModel.self.refresh != nil)
        
        // ChatViewModel
        XCTAssertTrue(ChatViewModel.self.send(_:) != nil)
    }
}
```

## 📊 Test Execution Strategy

### Before Each Optimization
```bash
# Run full test suite and save results
swift test > before_optimization.txt

# Run performance benchmarks
xcodebuild test -scheme PerformanceTests > before_performance.txt

# Capture memory baseline
instruments -t Leaks MyApp.app > before_memory.trace
```

### After Each Optimization
```bash
# Compare test results
swift test > after_optimization.txt
diff before_optimization.txt after_optimization.txt

# Verify performance improved
xcodebuild test -scheme PerformanceTests > after_performance.txt
# Parse and compare times

# Check for memory regressions
instruments -t Leaks MyApp.app > after_memory.trace
# Compare memory usage
```

## ⚠️ Breaking Change Detection

```swift
class BreakingChangeDetector: XCTestCase {
    
    func testNoBreakingChanges() {
        let publicSymbols = [
            "OnboardingIntelligence.init",
            "DashboardViewModel.refresh",
            "ChatViewModel.send",
            "HealthKitManager.requestAuthorization"
        ]
        
        for symbol in publicSymbols {
            XCTAssertTrue(
                symbolExists(symbol),
                "Breaking change detected: \(symbol) was removed or modified"
            )
        }
    }
}
```

## 🚦 Go/No-Go Criteria

Before deploying ANY optimization:

### Must Pass (No Exceptions)
- [ ] All existing unit tests pass
- [ ] All integration tests pass  
- [ ] No memory leaks introduced
- [ ] Performance actually improved
- [ ] No crashes in 30-minute usage test

### Should Pass (Fix if Possible)
- [ ] Snapshot tests match (or changes are intentional)
- [ ] Code coverage hasn't decreased
- [ ] No new warnings
- [ ] No increase in binary size > 5%

### Nice to Have
- [ ] Improved test coverage
- [ ] Better documentation
- [ ] Cleaner code structure

---

*"A test not written is a bug waiting to happen during optimization."*