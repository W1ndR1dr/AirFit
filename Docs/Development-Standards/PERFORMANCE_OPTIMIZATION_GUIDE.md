# Performance Optimization Guide

## Overview
This guide documents performance optimization patterns discovered during the onboarding refactor. Use these principles to identify and fix performance issues throughout the codebase while preserving all features.

## 🎯 Core Principles

### 1. **Synchronous UI Initialization**
- **Problem**: Async dependency injection for UI components causes loading screens
- **Solution**: UI objects should initialize synchronously, defer heavy work
- **Pattern**: 
  ```swift
  // ❌ BAD
  struct SomeView: View {
      @State private var viewModel: ViewModel?
      var body: some View {
          if let viewModel { /* content */ } 
          else { ProgressView().task { viewModel = await createViewModel() } }
      }
  }
  
  // ✅ GOOD
  struct SomeView: View {
      @StateObject private var viewModel = ViewModel()
      var body: some View { /* content immediately visible */ }
  }
  ```

### 2. **Avoid Task.detached**
- **Problem**: Breaks actor isolation, causes race conditions, hard to debug
- **Solution**: Use regular Tasks with proper actor isolation
- **Pattern**:
  ```swift
  // ❌ BAD
  Task.detached { [weak self] in
      guard let self else { return }
      // Complex coordination required
  }
  
  // ✅ GOOD
  Task {
      // Direct access to self, proper isolation
  }
  ```

### 3. **Lazy Service Initialization**
- **Problem**: Heavy initialization during object creation
- **Solution**: Initialize services lazily on first use
- **Pattern**:
  ```swift
  // ❌ BAD
  init() {
      validateAPIKeys()
      checkServiceHealth()
      loadConfiguration()
  }
  
  // ✅ GOOD
  init() {
      // Just assign dependencies
      Task { validateServicesInBackground() }
  }
  ```

## 🔍 Areas to Audit

### 1. **Dashboard Module** (`/Modules/Dashboard/`)
**Symptoms to look for:**
- Loading screens on tab switches
- Async view model creation
- Multiple sequential API calls
- Unnecessary re-renders

**Potential optimizations:**
- Make DashboardViewModel initialize synchronously
- Batch API calls where possible
- Cache computed properties
- Use `@StateObject` instead of `@State` + async loading

### 2. **Chat Module** (`/Modules/Chat/`)
**Symptoms to look for:**
- Message sending delays
- UI freezing during AI responses
- Scroll performance issues
- Memory growth from message history

**Potential optimizations:**
- Stream AI responses without blocking UI
- Virtualize message list for large conversations
- Debounce typing indicators
- Preload recent messages synchronously

### 3. **Food Tracking** (`/Modules/FoodTracking/`)
**Symptoms to look for:**
- Camera preview delays
- Slow food search
- Blocking UI during nutrition calculations
- Database query performance

**Potential optimizations:**
- Initialize camera session in background
- Implement search debouncing
- Cache nutrition calculations
- Batch database operations

### 4. **Settings Module** (`/Modules/Settings/`)
**Symptoms to look for:**
- Slow settings screen load
- Delays when toggling options
- API key validation blocking UI
- Theme changes causing full re-renders

**Potential optimizations:**
- Load settings synchronously from UserDefaults
- Validate API keys in background
- Optimize theme switching with targeted updates
- Cache computed settings values

### 5. **DI Container** (`/Core/DI/`)
**Current issues:**
- All resolution is async
- No differentiation between UI and service objects
- Missing performance metrics

**Proposed improvements:**
```swift
// Add synchronous resolution for UI objects
func resolveSync<T>(_ type: T.Type) -> T
// Keep async for truly async services
func resolve<T>(_ type: T.Type) async throws -> T
```

## 🛠️ Optimization Workflow

### Step 1: Profile First
```bash
# Use Instruments to identify actual bottlenecks
# - Time Profiler for CPU usage
# - Memory Graph for leaks
# - View Hierarchy for render issues
```

### Step 2: Audit Initialization
1. Find all async view initialization
2. Identify heavy work in constructors
3. Look for Task.detached usage
4. Check for synchronous network calls

### Step 3: Apply Patterns
1. Make UI initialization synchronous
2. Defer heavy work to background
3. Add loading states only where necessary
4. Preserve all existing features

### Step 4: Measure Impact
- App launch time
- Time to interactive
- Memory usage
- Frame rate during transitions

## 📊 Performance Metrics

### Target Metrics
- **App Launch**: < 0.5s to first screen
- **View Transitions**: < 100ms
- **API Response Handling**: Non-blocking UI
- **Memory Growth**: < 10MB per minute of use
- **Frame Rate**: Consistent 60fps (120fps on ProMotion)

### Anti-Patterns to Eliminate

#### 1. **Async View Creation**
```swift
// ❌ Loading screen just to create a view
OnboardingContainerView shows ProgressView while creating OnboardingView
```

#### 2. **Sequential Async Operations**
```swift
// ❌ Waterfall of async calls
let service1 = await resolve(Service1.self)
let service2 = await resolve(Service2.self)  
let service3 = await resolve(Service3.self)

// ✅ Parallel when independent
async let service1 = resolve(Service1.self)
async let service2 = resolve(Service2.self)
async let service3 = resolve(Service3.self)
let (s1, s2, s3) = await (service1, service2, service3)
```

#### 3. **Blocking Main Thread**
```swift
// ❌ Heavy computation on main thread
@MainActor func calculateComplexValue() -> Int {
    // CPU intensive work
}

// ✅ Move computation off main thread
func calculateComplexValue() async -> Int {
    await Task.detached(priority: .userInitiated) {
        // CPU intensive work
    }.value
}
```

## 🎯 Quick Wins

### 1. **Remove Unnecessary Abstractions**
- Container views that only load other views
- Coordinator patterns that add no value
- Factory methods that could be simple inits

### 2. **Batch Operations**
- Combine multiple API calls
- Batch database writes
- Coalesce UI updates

### 3. **Cache Aggressively**
- Computed properties that rarely change
- API responses with known lifetimes
- Expensive view calculations

### 4. **Defer Non-Critical Work**
```swift
// Load critical data first
init() {
    loadEssentialData()
    Task {
        await loadNiceToHaveData()
        await validateServices()
        await syncWithCloud()
    }
}
```

## 📝 Checklist for Each Module

- [ ] No loading screens for view creation
- [ ] All UI objects initialize synchronously  
- [ ] Heavy work happens in background
- [ ] No Task.detached without strong justification
- [ ] API calls don't block UI
- [ ] Proper error handling without disrupting UX
- [ ] Memory usage is bounded
- [ ] Frame rate stays at 60fps
- [ ] All original features preserved
- [ ] Added performance monitoring

## 🚀 Next Steps

1. **Priority 1**: Dashboard performance (most visited screen)
2. **Priority 2**: Chat module (core feature, real-time requirements)
3. **Priority 3**: Food tracking (camera + search performance)
4. **Priority 4**: Settings (less critical but should be instant)
5. **Priority 5**: Systematic DI container improvements

## 💡 Remember

> "Make it work, make it right, make it fast" - but we're past the first two stages. Now it's time to make it fast without breaking what works.

The goal is surgical optimization: identify specific bottlenecks, apply targeted fixes, and measure improvements. Don't optimize prematurely, but don't accept poor performance as inevitable.