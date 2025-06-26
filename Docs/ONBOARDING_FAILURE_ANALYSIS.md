# Onboarding Failure Analysis: Keychain Persistence and Unhandled Errors

**Date:** 2025-06-25
**Author:** Gemini
**Status:** Analysis Complete

## 1. Executive Summary

The application failed to show the API key setup on a fresh install and subsequently froze during the onboarding process. The root cause is a combination of two distinct and unrelated issues:

1.  **Persistent API Keys in Keychain**: The app correctly skipped the API setup screen because API keys from a *previous* installation were found in the iOS Keychain, which persists even after an app is deleted. This is expected behavior, but it prevented the desired "first-launch" experience.
2.  **Unhandled HealthKit Timeout Error**: The app then crashed during the onboarding flow because the HealthKit authorization request timed out, and this error was not handled within the SwiftUI view, leading to a fatal state.

This document details the sequence of events and provides actionable recommendations to improve robustness.

## 2. Root Cause Analysis: A Step-by-Step Breakdown

The logs show a clear, logical sequence of events that led to the failure.

### Step 1: App Launch and Keychain Discovery

Upon launching the "freshly installed" app, the `AppState.loadUserState()` method was called. This method correctly queried the `APIKeyManager`.

-   **Key Finding:** The iOS Keychain is a secure storage system that **persists data even when an app is uninstalled and reinstalled**. Your API keys were still present in the Keychain from a prior installation.

-   **Log Evidence:**
    ```
    [AppState.swift:55] loadUserState() - Found configured API key for: OpenAI
    [AppState.swift:55] loadUserState() - Found configured API key for: Google Gemini
    [AppState.swift:55] loadUserState() - Found configured API key for: Anthropic
    ```

### Step 2: Correctly Skipping the API Setup View

Because the `APIKeyManager` found existing keys, the `appState.needsAPISetup` flag was correctly set to `false`.

-   **Log Evidence:**
    ```
    [AppState.swift:58] loadUserState() - API setup check - configured providers: 3, needs setup: false
    ```
-   **Result:** The `ContentView`'s routing logic correctly determined that the API setup screen was not needed and, because no `User` object existed in the newly created database, it proceeded to the onboarding flow.

### Step 3: The Real Failure Point - Unhandled HealthKit Timeout

The app successfully created a new user and transitioned to the `OnboardingContainerView`.

-   **Log Evidence:**
    ```
    [AppState.swift:98] createNewUser() - New user created
    [ContentView.swift:44] body - ContentView: Using manifesto onboarding...
    [OnboardingIntelligence.swift:72] startHealthAnalysis() - Starting HealthKit authorization request
    ```
-   This is where the critical failure occurred. The `startHealthAnalysis()` function threw an error because the system's permission prompt timed out.

-   **Log Evidence of Failure:**
    ```
    FAILED prompting authorization request ... error Authorization session timed out
    [AppLogger.swift:87] error(_:error:category:context:) - HealthKit authorization failed
    ```

### Step 4: The Crash

The `OnboardingContainerView` calls `await loadIntelligence()` from a `.task` modifier. The `loadIntelligence` function, in turn, calls `intelligence.startHealthAnalysis()`. When the timeout error was thrown, it propagated up and was **not caught within the SwiftUI view's task**. An unhandled error thrown from a `.task` modifier can lead to an inconsistent UI state, view rendering failure (the black screen), or a crash.

## 3. Actionable Recommendations

### Recommendation 1: Make HealthKit Authorization Robust (High Priority)

The immediate bug is the unhandled error. The `OnboardingContainerView` must be updated to handle potential failures during the initialization of its services.

**File to Modify:** `AirFit/Modules/Onboarding/Views/OnboardingContainerView.swift`

**Code Fix:**
```swift
// In OnboardingContainerView.swift

// Add these state variables
@State private var isLoading = true
@State private var error: Error?

// Modify the .task modifier
.task {
    // isLoading = true // Already set
    // error = nil
    do {
        // This is the call that can throw the HealthKit timeout error
        intelligence = try await diContainer.resolve(OnboardingIntelligence.self)
        isLoading = false
    } catch {
        self.error = error
        self.isLoading = false
        AppLogger.error("Failed to resolve OnboardingIntelligence", error: error, category: .app)
    }
}

// Modify the body to handle the error state
var body: some View {
    Group {
        if isLoading {
            ProgressView("Setting up...")
        } else if let intelligence = intelligence {
            OnboardingView(intelligence: intelligence)
        } else if let error = error {
            // Present a user-friendly error view with a retry option
            ErrorRecoveryView(error: error, onRetry: { 
                Task { await loadIntelligence() } 
            })
        }
    }
    .task { ... } // The modified task from above
}
```

### Recommendation 2: Add a Developer Reset Function (Medium Priority)

To solve the underlying issue of not being able to test the "true" first-launch experience, we should add a debug-only feature to clear all persistent data.

**Proposed Implementation:**

1.  Add a "Reset App State" button within the `Settings` -> `Debug Tools` menu (only visible in `#if DEBUG` builds).
2.  This button's action should call a new `resetAllData()` function in a developer-focused service.
3.  The function should perform two actions:
    *   **Clear Keychain:** Delete all API keys stored by `APIKeyManager`.
    *   **Clear SwiftData:** Delete the `default.store` file to wipe the database.
4.  After clearing the data, the app should programmatically restart or navigate to the root view to re-trigger the initialization flow.

This will allow for reliable and repeatable testing of the complete first-launch and onboarding sequence.
