# 07_WatchApp.md

This document provides an overview of the AirFit Apple Watch companion application (`/AirFitWatchApp`).

## Directory Structure:

*   **`/AirFitWatchApp`**: Root directory for the WatchOS target.
    *   `AirFitWatchApp.swift`: The main entry point for the watch app, conforming to the SwiftUI `App` protocol for watchOS.
    *   **`Services`**:
        *   `WatchWorkoutManager.swift`: Manages workout sessions on the watch, interacts with HealthKit for live workout data (heart rate, calories, etc.), and likely syncs data with the iOS app.
    *   **`Views`**:
        *   `ActiveWorkoutView.swift`: Displays metrics and controls while a workout is in progress.
        *   `ExerciseLoggingView.swift`: Allows logging of specific exercises and sets during a workout.
        *   `WorkoutStartView.swift`: The initial view for selecting and starting a workout.
    *   **`AirFitWatchAppTests`**: Unit tests for the watch app components.
        *   `Services/WatchWorkoutManagerTests.swift`: Tests for the `WatchWorkoutManager`.

## Key Components & Responsibilities:

*   **`AirFitWatchApp.swift`**:
    *   Initializes the watch app and sets up the main scene.
*   **`WatchWorkoutManager.swift`**:
    *   **Core Logic**: Handles starting, pausing, resuming, and ending workout sessions on the Apple Watch.
    *   **HealthKit Integration**: Interacts with `HKWorkoutSession` and `HKLiveWorkoutBuilder` to manage live workout metrics.
    *   **Data Collection**: Gathers data like heart rate, active calories, distance, and elapsed time.
    *   **State Management**: Tracks the current state of the workout (idle, running, paused, etc.).
    *   **Data Sync**: Likely responsible for sending completed workout data to the companion iOS app via `WCSession` (as hinted by `WorkoutSyncService.swift` in the iOS app, which receives data). The `WorkoutBuilderData` model is a probable candidate for this data transfer.
*   **`WorkoutStartView.swift`**:
    *   **UI**: Allows the user to select a workout activity type (e.g., Strength Training, Running).
    *   **Action**: Initiates a workout session via `WatchWorkoutManager`.
*   **`ActiveWorkoutView.swift`**:
    *   **UI**: Displays live workout metrics (elapsed time, heart rate, calories).
    *   **Controls**: Provides controls to pause, resume, or end the workout.
*   **`ExerciseLoggingView.swift`**:
    *   **UI**: Enables users to specify the current exercise and log sets (reps, weight, duration).
    *   **Interaction**: Works with `WatchWorkoutManager` to add exercise and set details to the `currentWorkoutData`.

## Key Dependencies:

*   **Consumed:**
    *   SwiftUI for watchOS (System Framework)
    *   HealthKit (System Framework) for workout sessions and live metrics.
    *   WatchConnectivity (System Framework) for communication with the iOS app (implied).
    *   Core Layer from the iOS app (potentially for shared models like `WorkoutBuilderData` or enums, if structured for sharing).
*   **Provided:**
    *   A user interface for workout tracking on Apple Watch.
    *   Workout data to be synced to the iOS application.

## Tests:

*   Unit tests for watch app components are located in `/AirFitWatchApp/AirFitWatchAppTests`.
*   `WatchWorkoutManagerTests.swift` specifically tests the workout management logic, including state transitions and interactions with mock HealthKit and WCSession components.