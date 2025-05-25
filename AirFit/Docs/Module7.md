**Modular Sub-Document 7: Workout Logging Module (iOS & WatchOS)**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration (including WatchOS target setup).
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `Workout`, `Exercise`, `ExerciseSet` models.
    *   (For AI Analysis) Completion of Modular Sub-Document 5: AI Persona Engine & CoachEngine – for generating post-workout summaries.
    *   (For WatchOS HealthKit integration) Familiarity with `WorkoutKit` and `HealthKit` concepts from Module 4.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To enable users to plan (future scope, basic for now), actively log, review, and analyze their workouts. The primary active logging experience is designed for Apple Watch, while detailed review and AI-powered post-workout analysis occur on the iOS app.
*   **Responsibilities:**
    *   **WatchOS:**
        *   Providing a UI for starting, tracking, and ending workouts.
        *   Allowing users to log sets, reps, weight, and duration for exercises during an active workout.
        *   Integrating with HealthKit via `HKWorkoutSession` and `HKLiveWorkoutBuilder` to contribute to activity rings and save workouts to Apple Health.
        *   (Future/Optional) Syncing workout data back to the iOS app.
    *   **iOS:**
        *   Displaying a list of past workouts.
        *   Providing a detailed view for each completed workout.
        *   Implementing the UI for the AI-driven Post-Workout Analysis summary.
        *   (Future scope) UI for creating and managing workout plans/templates.
    *   **Shared Logic:** Saving workout data (`Workout`, `Exercise`, `ExerciseSet` entities) to SwiftData. Triggering the AI Post-Workout Analysis via the `CoachEngine`.
*   **Key Components within this Module:**
    *   **WatchOS (in `AirFitWatchApp` target):**
        *   `WorkoutStartView.swift`
        *   `ActiveWorkoutView.swift`
        *   `ExerciseLoggingView.swift` (for logging sets of current exercise)
        *   `WorkoutSummaryWatchView.swift` (brief summary on watch post-workout)
        *   `WatchWorkoutManager.swift` (handles `HKWorkoutSession`, `HKLiveWorkoutBuilder`, data aggregation)
    *   **iOS (in `AirFit/Modules/Workouts/`):**
        *   `WorkoutListView.swift`
        *   `WorkoutDetailView.swift`
        *   `WorkoutSummaryAnalysisView.swift` (displays AI summary)
        *   `WorkoutViewModel.swift` (for iOS views, managing data, triggering AI analysis)
        *   `WorkoutPlanView.swift` (Placeholder for future)
    *   **Shared (Potentially in `AirFit/Data/Managers/` or `AirFit/BusinessLogic/`):**
        *   Logic for saving workouts to SwiftData (might be part of ViewModels or a dedicated `WorkoutDataManager`).

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) – UI/UX details for workout logging and summary screens.
    *   Modular Sub-Document 1: Core utilities, `AppColors`, `AppFonts`.
    *   Modular Sub-Document 2: `Workout`, `Exercise`, `ExerciseSet` SwiftData models.
    *   Modular Sub-Document 4: `HealthKitManager` (for permissions, though WatchOS uses `HKWorkoutSession` directly).
    *   Modular Sub-Document 5: `CoachEngine` for AI Post-Workout Analysis.
*   **Outputs:**
    *   Functional workout logging on Apple Watch, saving data to HealthKit.
    *   Workout data persisted in SwiftData.
    *   iOS interface for viewing workout history and AI-generated summaries.

**3. Detailed Component Specifications & Agent Tasks (WatchOS)**

*(AI Agent Tasks for WatchOS: These require specific instructions for WatchOS UI, HealthKit session management, and data handling. Agents should target the `AirFitWatchApp`.)*

---

**Task 7.0: WatchOS HealthKit Configuration & Permissions**
    *   **Agent Task 7.0.1:**
        *   Instruction: "Ensure the 'AirFitWatchApp Extension' target has the HealthKit capability enabled."
        *   Details: Similar to Task 4.0.1, but for the WatchOS extension target.
        *   Acceptance Criteria: HealthKit capability added to WatchOS extension.
    *   **Agent Task 7.0.2:**
        *   Instruction: "Add required HealthKit usage description keys to the `Info.plist` of the 'AirFitWatchApp'."
        *   Details:
            *   `NSHealthShareUsageDescription`: (e.g., "AirFit Watch tracks your workouts, heart rate, and calories burned to provide detailed performance analysis and contribute to your activity goals.")
            *   This might share the same key as the iOS app but should be present in the WatchApp's Info.plist.
        *   Acceptance Criteria: Keys present in WatchApp's `Info.plist`.
    *   **Agent Task 7.0.3:**
        *   Instruction: "Add necessary background mode capabilities for workouts to the WatchOS target if planning to support background workout sessions (e.g., 'Workout Processing')."
        *   Details: In "Signing & Capabilities," add "Background Modes" and check "Workout processing."
        *   Acceptance Criteria: Background mode for workouts enabled.

---

**Task 7.1: WatchWorkoutManager Implementation (WatchOS)**
    *   **Agent Task 7.1.1:**
        *   Instruction: "Create `WatchWorkoutManager.swift` within the `AirFitWatchApp` group/target."
        *   Details:
            *   Make it an `ObservableObject`.
            *   Properties:
                *   `healthStore = HKHealthStore()`
                *   `session: HKWorkoutSession?`
                *   `builder: HKLiveWorkoutBuilder?`
                *   `@Published var workoutState: WorkoutState = .idle` (Enum: `.idle`, `.starting`, `.running`, `.paused`, `.ending`, `.ended`)
                *   `@Published var heartRate: Double = 0`
                *   `@Published var activeCalories: Double = 0`
                *   `@Published var elapsedTime: TimeInterval = 0` (Timer for workout duration)
                *   `@Published var currentActivityType: HKWorkoutActivityType = .traditionalStrengthTraining` (Allow selection)
                *   `var currentWorkoutData: WorkoutBuilderData = WorkoutBuilderData()` (Struct to hold exercises and sets logged during the session).
            *   Define `WorkoutBuilderData` struct to store `[ExerciseBuilderData]`, where `ExerciseBuilderData` stores `name` and `[SetBuilderData]` (`reps`, `weightKg`, etc.).
        *   Acceptance Criteria: `WatchWorkoutManager.swift` and `WorkoutBuilderData` struct created.
    *   **Agent Task 7.1.2 (Workout Session Control):**
        *   Instruction: "Implement methods in `WatchWorkoutManager.swift` to start, pause, resume, and end a workout session."
        *   Details:
            *   `func requestAuthorization(completion: @escaping (Bool) -> Void)`: Request basic HealthKit auth (e.g., for heart rate, calories, workout routes).
            *   `func startWorkout(activityType: HKWorkoutActivityType)`:
                *   Create `HKWorkoutConfiguration` (set `activityType`, `locationType`).
                *   Create `HKWorkoutSession` and `HKLiveWorkoutBuilder` using the configuration.
                *   Set delegates (`HKWorkoutSessionDelegate`, `HKLiveWorkoutBuilderDelegate`) to `self`.
                *   Call `session.startActivity(with: Date())` and `builder.beginCollection(withStart: Date(), completion: ...)`.
                *   Start internal timer for `elapsedTime`. Update `workoutState`.
            *   `func pauseWorkout()`: Call `session.pause()`. Update `workoutState`. Pause timer.
            *   `func resumeWorkout()`: Call `session.resume()`. Update `workoutState`. Resume timer.
            *   `func endWorkout()`:
                *   Call `session.end()`.
                *   Call `builder.endCollection(withEnd: Date(), completion: ...)`. In completion:
                    *   Access `builder.elapsedTime`.
                    *   (Important) Save the `currentWorkoutData` (exercises, sets) to a temporary store or prepare it for sending to the iOS app (see Task 7.3).
                    *   Call `builder.finishWorkout(completion: ...)`. This saves the workout to HealthKit.
                *   Update `workoutState`. Stop timer. Reset `currentWorkoutData`.
        *   Acceptance Criteria: Workout session control methods implemented.
    *   **Agent Task 7.1.3 (Delegate Methods & Data Collection):**
        *   Instruction: "Implement `HKWorkoutSessionDelegate` and `HKLiveWorkoutBuilderDelegate` methods in `WatchWorkoutManager.swift`."
        *   Details:
            *   `workoutSession(_:didChangeTo:from:date:)`: Update `workoutState`.
            *   `workoutSession(_:didFailWithError:)`: Handle errors, log.
            *   `workoutBuilder(_:didCollectDataOf:)`: Receive collected `HKQuantitySample` data. Update `@Published` properties for heart rate, active calories by processing `builder.statistics(for: quantityType)`.
            *   `workoutBuilderDidCollectEvent(_:)`: Handle workout events (e.g., pause/resume).
        *   Acceptance Criteria: Delegate methods implemented to update live workout metrics.
    *   **Agent Task 7.1.4 (Exercise/Set Logging within Workout):**
        *   Instruction: "Add methods to `WatchWorkoutManager.swift` to record exercise and set data into `currentWorkoutData`."
        *   Details:
            *   `func startNewExercise(name: String, muscleGroups: [String])`
            *   `func logSetForCurrentExercise(reps: Int?, weightKg: Double?, duration: TimeInterval?, rpe: Double?)`
            *   These methods append data to the `currentWorkoutData` arrays.
        *   Acceptance Criteria: Methods for manually logging exercise details during a session are present.

---

**Task 7.2: WatchOS Workout UI (WatchOS)**
    *   **Agent Task 7.2.1 (WorkoutStartView):**
        *   Instruction: "Create `WorkoutStartView.swift` for WatchOS."
        *   Details:
            *   Allow user to select `HKWorkoutActivityType` (e.g., Strength Training, Running, Cycling) using a `Picker` or `List`.
            *   "Start" button that calls `watchWorkoutManager.startWorkout(activityType: selectedActivity)`.
            *   Inject/EnvironmentObject `WatchWorkoutManager`.
        *   Acceptance Criteria: View allows activity selection and starts a workout.
    *   **Agent Task 7.2.2 (ActiveWorkoutView):**
        *   Instruction: "Create `ActiveWorkoutView.swift` for WatchOS."
        *   Details:
            *   The main view during a workout. Use `TabView` for different pages (Metrics, Exercise Logger, Controls).
            *   **Metrics Page:** Display `elapsedTime`, `heartRate`, `activeCalories` from `WatchWorkoutManager`.
            *   **Exercise Logger Page (Placeholder/Basic):** Button "Add Exercise" or "Log Set for Current" that navigates to `ExerciseLoggingView`. Display current exercise name.
            *   **Controls Page:** Buttons for "Pause"/"Resume", "End Workout". These call methods on `WatchWorkoutManager`.
            *   Handle `workoutState` changes from `WatchWorkoutManager` to update UI (e.g., disable buttons, change text).
        *   Acceptance Criteria: Active workout UI displays live metrics and controls.
    *   **Agent Task 7.2.3 (ExerciseLoggingView - Modal or Navigation):**
        *   Instruction: "Create `ExerciseLoggingView.swift` for WatchOS."
        *   Details:
            *   Allows user to input details for the current exercise's set (reps, weight, duration).
            *   Use Digital Crown (`.digitalCrownRotation`) for quick adjustments to numbers.
            *   "Log Set" button calls `watchWorkoutManager.logSetForCurrentExercise(...)`.
            *   "Next Exercise" button (or similar) calls `watchWorkoutManager.startNewExercise(...)`.
            *   Minimalist and focused UI as per Design Spec 6.2.
        *   Acceptance Criteria: View allows logging set details effectively on the watch.
    *   **Agent Task 7.2.4 (WorkoutSummaryWatchView):**
        *   Instruction: "Create `WorkoutSummaryWatchView.swift` for WatchOS."
        *   Details: Displayed after a workout ends. Shows brief summary (total time, calories, maybe number of exercises). "Done" button.
        *   Acceptance Criteria: Basic summary view after workout completion.

---

**Task 7.3: WatchOS to iOS Data Sync (Initial Strategy - WCS or SwiftData CloudKit)**
    *   **Agent Task 7.3.1 (Choose Sync Method - Human Decision Point):**
        *   **Option A (WatchConnectivity - WCS):** Suitable for sending discrete data packets (like the `WorkoutBuilderData` upon workout completion). Requires implementing `WCSession` delegates on both iOS and WatchOS.
        *   **Option B (SwiftData with CloudKit):** If SwiftData models are configured for CloudKit syncing, data saved on the watch *could* automatically sync to iOS. This is more seamless if it works reliably but can have delays and complexities.
        *   **For initial AI tasking, let's assume WCS for controlled, explicit data transfer.**
    *   **Agent Task 7.3.2 (WCS Setup on Watch - `WatchWorkoutManager`):**
        *   Instruction: "In `WatchWorkoutManager.swift`, setup `WCSession` and implement `session(_:activationDidCompleteWith:error:)`."
        *   Details: Activate session. In `endWorkout()`, after `builder.finishWorkout`, serialize `currentWorkoutData` (e.g., to JSON `Data`) and send it to the paired iOS device using `WCSession.default.sendMessageData(_:replyHandler:errorHandler:)`.
        *   Acceptance Criteria: WCS session activated on watch, data sent on workout end.
    *   **Agent Task 7.3.3 (WCS Setup on iOS - AppDelegate or dedicated manager):**
        *   Instruction: "On the iOS side (e.g., in `AppDelegate.swift` or a new `WatchConnectivityManager.swift` in `AirFit/Services/Platform/`), setup `WCSession` and implement `session(_:didReceiveMessageData:)`."
        *   Details: Activate session. In `didReceiveMessageData`, deserialize the received `Data` back into `WorkoutBuilderData`.
        *   This received data then needs to be processed and saved as `Workout`, `Exercise`, `ExerciseSet` SwiftData entities (see Task 7.4).
        *   Acceptance Criteria: iOS app receives workout data from watch via WCS.

---

**Task 7.4: iOS Workout Data Handling & ViewModel (iOS)**
    *   **Agent Task 7.4.1:**
        *   Instruction: "Create `WorkoutViewModel.swift` in `AirFit/Modules/Workouts/ViewModels/`."
        *   Details:
            *   `ObservableObject` class.
            *   Dependencies: `modelContext: ModelContext`, `coachEngine: CoachEngine`.
            *   `@Published var workouts: [Workout] = []`
            *   `@Published var selectedWorkoutDetail: Workout?`
            *   `@Published var aiWorkoutSummary: String?`
            *   Methods:
                *   `func fetchWorkouts(forUser user: User)`: Fetches all `Workout` entities for the user from SwiftData, sorts by date.
                *   `func processReceivedWatchWorkout(data: WorkoutBuilderData, forUser user: User)`:
                    *   Creates new `Workout`, `Exercise`, `ExerciseSet` entities in SwiftData from the `WorkoutBuilderData`.
                    *   Saves the `modelContext`.
                    *   Calls `fetchWorkouts()` to refresh the list.
                    *   Triggers `generateAIPostWorkoutAnalysis(forWorkout: newWorkout)`.
                *   `func generateAIPostWorkoutAnalysis(forWorkout workout: Workout)`:
                    *   Prepare data for `CoachEngine`: `plannedWorkout` (if any, nil for now), `completedWorkout` (the one just saved), relevant `historicalPerformance` (e.g., last few workouts of same type, PRs - complex, can be stubbed), `HealthContextSnapshot` (relevant for the time of workout).
                    *   Call a new method on `CoachEngine` (e.g., `coachEngine.generatePostWorkoutSummary(details: PostWorkoutAnalysisRequest) async -> String?`). This method in `CoachEngine` would use an LLM.
                    *   Update `viewModel.aiWorkoutSummary` with the result.
        *   Acceptance Criteria: `WorkoutViewModel.swift` structure and method stubs created.
    *   **Agent Task 7.4.2 (Implement ViewModel Logic):**
        *   Instruction: "Implement the core logic for `fetchWorkouts`, `processReceivedWatchWorkout`, and `generateAIPostWorkoutAnalysis` (with mock/stub for CoachEngine call) in `WorkoutViewModel.swift`."
        *   Acceptance Criteria: ViewModel methods handle data fetching, processing of watch data, saving to SwiftData, and triggering AI analysis (stubbed).

---

**Task 7.5: iOS Workout UI (iOS)**
    *   **Agent Task 7.5.1 (WorkoutListView):**
        *   Instruction: "Create `WorkoutListView.swift` in `AirFit/Modules/Workouts/Views/`."
        *   Details:
            *   Displays a list of workouts fetched by `WorkoutViewModel`.
            *   Each row shows workout name, date, perhaps duration.
            *   Tapping a row navigates to `WorkoutDetailView`.
            *   Uses `.onAppear { viewModel.fetchWorkouts(forUser: currentUser) }`.
        *   Acceptance Criteria: View lists workouts.
    *   **Agent Task 7.5.2 (WorkoutDetailView):**
        *   Instruction: "Create `WorkoutDetailView.swift` in `AirFit/Modules/Workouts/Views/`."
        *   Details:
            *   Input: A `Workout` object.
            *   Displays detailed information: all exercises, sets, reps, weight, duration.
            *   Includes a section or button to view/load the `WorkoutSummaryAnalysisView`.
            *   Calls `viewModel.generateAIPostWorkoutAnalysis(forWorkout: workout)` if summary not yet loaded.
        *   Acceptance Criteria: View displays workout details.
    *   **Agent Task 7.5.3 (WorkoutSummaryAnalysisView):**
        *   Instruction: "Create `WorkoutSummaryAnalysisView.swift` in `AirFit/Modules/Workouts/Views/`."
        *   Details:
            *   Input: `aiSummaryText: String?` (from `WorkoutViewModel.aiWorkoutSummary`).
            *   Displays the AI-generated summary with markdown formatting.
            *   Shows a loading indicator if `aiSummaryText` is nil and analysis is in progress.
        *   Acceptance Criteria: View displays AI-generated workout summary.

---

**Task 7.6: Final Review & Commit**
    *   **Agent Task 7.6.1 (Review WatchOS):**
        *   Instruction: "Review all WatchOS components (`WatchWorkoutManager`, views) for workout session handling, data logging, HealthKit integration, and WCS data sending."
        *   Acceptance Criteria: WatchOS functionality for active workout logging is robust.
    *   **Agent Task 7.6.2 (Review iOS):**
        *   Instruction: "Review iOS `WorkoutViewModel` and views for WCS data reception, SwiftData saving, workout display, and AI summary integration (stubbed)."
        *   Acceptance Criteria: iOS functionality for workout review and analysis is correctly structured.
    *   **Agent Task 7.6.3 (Test WCS - if possible with tools):**
        *   Instruction: "If simulator/device pairing allows, test the WCS data transfer from watch to iOS."
        *   Acceptance Criteria: Workout data logged on watch appears on iOS for processing.
    *   **Agent Task 7.6.4 (Commit):**
        *   Instruction: "Stage and commit all new and modified files for this module with a descriptive message."
        *   Details: Commit message: "Feat: Implement Workout Logging Module for WatchOS and iOS with AI Analysis".
        *   Acceptance Criteria: All changes committed. Project builds for both iOS and WatchOS.

**Task 7.7: Add Unit & UI Tests**
    *   **Agent Task 7.7.1 (WorkoutViewModel Unit Tests):**
        *   Instruction: "Create `WorkoutViewModelTests.swift` in `AirFitTests/`."
        *   Details: Mock HealthKit and WatchConnectivity interactions following `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 7.7.2 (WatchWorkoutManager Unit Tests):**
        *   Instruction: "Create `WatchWorkoutManagerTests.swift` in `AirFitTests/`."
        *   Details: Verify workout session state management.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 7.7.3 (Workout UI Tests):**
        *   Instruction: "Create `WorkoutUITests.swift` in `AirFitUITests/` for key workout logging flows."
        *   Details: Use accessibility identifiers for start, pause, and end actions.
        *   Acceptance Criteria: UI tests compile and pass.

---

**4. Acceptance Criteria for Module Completion**

*   User can start, track (live metrics), pause, resume, and end workouts on Apple Watch.
*   Workout data (exercises, sets) logged on the watch is saved to HealthKit by the WatchOS app.
*   Logged workout data from the watch is successfully transmitted to the iOS app (e.g., via WCS).
*   The iOS app processes this data and saves it as `Workout`, `Exercise`, `ExerciseSet` entities in SwiftData.
*   iOS app can display a list of past workouts and detailed views for each.
*   The mechanism to trigger AI Post-Workout Analysis is in place, and the iOS app can display the (stubbed/mocked) AI-generated summary.
*   Both WatchOS and iOS UIs adhere to design principles.
*   All code passes SwiftLint checks.
*   Unit tests for `WorkoutViewModel` and `WatchWorkoutManager`, and UI tests for workout flows are implemented and pass.

**5. Code Style Reminders for this Module**

*   **WatchOS:** Prioritize performance and battery life. Keep UIs simple and interactions quick. Handle `HKWorkoutSession` states carefully.
*   **iOS:** Ensure efficient data fetching for workout lists. Use `async/await` for AI analysis calls.
*   **Data Sync (WCS):** Handle `WCSession` activation and reachability. Ensure data serialization/deserialization is robust.
*   Error handling for HealthKit operations and data syncing is critical.
*   Use `AppLogger` extensively on both platforms.

---

This is a very comprehensive module with two distinct platform targets. The WatchConnectivity part, if chosen, can be tricky to get right, especially for AI agents if they don't have a sophisticated understanding of inter-process communication. SwiftData with CloudKit might be an alternative path if the agent is more adept with that, but it introduces its own set of challenges (sync delays, conflict resolution). For now, WCS provides more explicit control.
