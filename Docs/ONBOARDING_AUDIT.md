# AirFit Onboarding Flow Audit

## Executive Summary

The onboarding flow had several critical dependency and timing issues that have now been fixed. The most significant problems were:

1. **API keys are required but set up too late in the flow** ✅ Fixed with validation
2. **Container recreation causes potential service reference issues** ✅ Added error handling
3. **Model selection from API setup doesn't properly persist** ✅ Added synchronization
4. **Onboarding completion flag is never set correctly** ✅ Fixed by calling completeOnboarding()
5. **Whisper setup could be deferred to first use** ⚠️ Still optional in flow

## Fixes Applied

### 1. Added Missing completeOnboarding() Call ✅
- OnboardingView now properly calls `userService.completeOnboarding()` after saving user/persona
- This sets the `user.isOnboarded = true` flag and `onboardingCompletedDate`

### 2. Fixed AppState Completion Check ✅
- Changed from checking `user.onboardingProfile != nil` to `user.isOnboarded`
- Now uses the proper flag as source of truth

### 3. Added AI Service Validation ✅
- OnboardingIntelligence.create() now validates API keys exist
- Validates AI service is functional before allowing onboarding to start
- Throws proper errors if AI services aren't configured

### 4. Improved Model Selection Persistence ✅
- Added `UserDefaults.standard.synchronize()` after saving model selection
- Ensures values are persisted before container recreation

### 5. Enhanced Container Recreation ✅
- Added error handling and AI service validation
- Logs success/failure of AI service resolution in new container

## Current Flow Analysis

### Entry Points and Navigation

1. **App Launch** → `AirFitApp.swift` → `ContentView.swift`
2. **ContentView** determines navigation based on `AppState`:
   - `needsAPISetup` → Show `APISetupView`
   - `shouldCreateUser` → Show `WelcomeView`
   - `shouldShowOnboarding` → Show `OnboardingContainerView`
   - `shouldShowDashboard` → Show `MainTabView`

### Onboarding Phases

1. **healthPermission** - Request HealthKit access
2. **whisperSetup** - Configure voice input (optional)
3. **profileSetup** - Collect birth date and biological sex
4. **conversation** - AI-driven conversation
5. **insightsConfirmation** - Show extracted insights
6. **generating** - Create AI coach persona
7. **confirmation** - Review and accept coaching plan

## Critical Issues Found

### 1. API Key Dependency Problem ❌

**Issue**: OnboardingIntelligence requires AI services to function, but API keys are set up AFTER user creation.

**Current Flow**:
```
1. Check needsAPISetup → Show APISetupView
2. After API setup → Create user → Show onboarding
3. Onboarding tries to use AI services
```

**Problem**: The AI services might fail if the container wasn't properly recreated with the new keys.

**Fix Required**: Ensure container is fully recreated and AI services are available before starting onboarding.

### 2. Container Recreation Race Condition ⚠️

**Issue**: After API setup, ContentView recreates the entire DI container:

```swift
// ContentView.swift lines 31-35
isRecreatingContainer = true
Task {
    await recreateContainer()
}
```

**Problem**: This could invalidate existing service references and cause initialization failures.

### 3. Model Selection Not Persisting ❌

**Issue**: The selected AI model from API setup might not be available in onboarding.

**Flow**:
1. User selects model in `APISetupView`
2. Saved to UserDefaults: `default_ai_provider` and `default_ai_model`
3. OnboardingView tries to load in `loadUserSelectedModel()`
4. But this happens AFTER container recreation

**Problem**: Race condition between saving and loading model selection.

### 4. Onboarding Completion Flag Issue ❌

**Issue**: `UserService.completeOnboarding()` is never called!

**Current Flow**:
```swift
// OnboardingView.swift - completeOnboarding()
let user = try await userServiceResolved.createUser(from: profile)
// Missing: try await userServiceResolved.completeOnboarding()
```

**Problem**: The `user.isOnboarded` flag remains `false` even after onboarding completes.

### 5. Service Initialization Without Validation ❌

**Issue**: OnboardingIntelligence.create() tries to resolve multiple AI-dependent services without checking if API keys exist:

```swift
async let aiService = container.resolve(AIServiceProtocol.self)
async let llmOrchestrator = container.resolve(LLMOrchestrator.self)
// etc...
```

**Problem**: These will fail if API keys aren't configured.

## Recommended Flow Order

### Current (Problematic) Flow:
1. Check API setup → Show APISetupView if needed
2. Create user
3. Start onboarding (assumes AI is ready)
4. HealthKit → Whisper → Profile → AI Conversation

### Recommended Flow:
1. **API Setup First** (before any user creation)
2. **Validate AI Services** (ensure they're initialized)
3. **Create User**
4. **Start Onboarding** with guaranteed AI access:
   - HealthKit Permission (optional)
   - Profile Setup (basic info)
   - AI Conversation (now safe)
   - Whisper Setup (contextually when first needed)
   - Persona Generation
   - Confirmation & Save

## Specific Fixes Required

### 1. Fix Onboarding Completion

In `OnboardingView.swift`, update `completeOnboarding()`:

```swift
private func completeOnboarding() {
    Task {
        do {
            // ... existing code ...
            
            // Create user
            let user = try await userServiceResolved.createUser(from: profile)
            
            // Save persona
            try await personaServiceResolved.savePersona(plan.generatedPersona, for: user.id)
            
            // CRITICAL: Mark onboarding as complete
            try await userServiceResolved.completeOnboarding()
            
            // Clear session
            await intelligence.clearSession()
            
            // Only post notification after everything is saved
            await MainActor.run {
                NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            }
        } catch {
            // ... error handling ...
        }
    }
}
```

### 2. Add AI Service Validation

Before starting onboarding, validate AI services are available:

```swift
// In OnboardingContainerView or AppState
private func validateAIServices() async throws {
    let testPrompt = "Test"
    let testResult = try await aiService.complete(prompt: testPrompt, context: nil)
    guard !testResult.isEmpty else {
        throw AppError.serviceError(message: "AI services not properly configured")
    }
}
```

### 3. Fix Model Selection Timing

Ensure model selection is saved and loaded correctly:

```swift
// In APISetupViewModel.saveAndContinue()
UserDefaults.standard.synchronize() // Force synchronization

// In OnboardingView.loadUserSelectedModel()
// Add delay or ensure UserDefaults has synced
```

### 4. Improve Container Recreation

Make container recreation more robust:

```swift
private func recreateContainer() async {
    // Store critical state
    let currentUser = appState?.currentUser
    
    // Recreate container
    let modelContainer = try? await diContainer.resolve(ModelContainer.self)
    if let modelContainer = modelContainer {
        let newContainer = DIBootstrapper.createAppContainer(modelContainer: modelContainer)
        
        // Validate AI services are ready
        do {
            let aiService = try await newContainer.resolve(AIServiceProtocol.self)
            // Quick validation
        } catch {
            // Handle initialization failure
        }
        
        activeContainer = newContainer
    }
    
    // Restore state
    isRecreatingContainer = false
    await appState?.loadUserState()
}
```

## Testing Recommendations

1. **Test API Key Flow**:
   - Start fresh (no API keys)
   - Add API key
   - Ensure onboarding can use AI immediately

2. **Test Interruption Recovery**:
   - Start onboarding
   - Force quit app mid-flow
   - Relaunch and ensure proper recovery

3. **Test Completion**:
   - Complete full onboarding
   - Ensure transition to dashboard
   - Verify `user.isOnboarded = true`

4. **Test Error Cases**:
   - Invalid API key
   - Network failures during AI calls
   - Container recreation failures

## Priority Fixes

1. **HIGH**: Fix `completeOnboarding()` to call `userService.completeOnboarding()`
2. **HIGH**: Validate AI services before starting onboarding
3. **MEDIUM**: Improve container recreation robustness
4. **MEDIUM**: Fix model selection persistence
5. **LOW**: Consider deferring Whisper setup

## Conclusion

The onboarding flow has a solid architecture but suffers from timing and dependency issues. The main problems stem from:

1. Assuming AI services are available when they might not be
2. Not properly setting completion flags
3. Race conditions in container recreation

With the fixes outlined above, the onboarding should become much more reliable and handle edge cases properly.