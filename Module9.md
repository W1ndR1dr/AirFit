Okay, let's define Modular Sub-Document 9: **Notifications & Engagement Engine.**

This module focuses on keeping users engaged through timely, persona-driven notifications and handling user inactivity according to their preferences.

---

**Modular Sub-Document 9: Notifications & Engagement Engine**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `User`, `OnboardingProfile` (to access `communicationPreferencesData` which includes `absence_response`).
    *   Completion of Modular Sub-Document 5: AI Persona Engine & CoachEngine – for generating persona-driven notification content.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To implement a system for proactive user engagement through local notifications. This includes detecting user inactivity, generating persona-driven notification content via the AI, and scheduling these notifications with actionable buttons.
*   **Responsibilities:**
    *   Requesting user permission for notifications.
    *   Implementing logic for "Lapse Detection" (e.g., a daily background task checking `User.lastActiveAt`).
    *   Determining notification strategy based on the user's `absence_response` preference (from `OnboardingProfile.communicationPreferencesData`).
    *   Interacting with the `CoachEngine` to generate short, persona-driven notification content if a proactive check-in is warranted.
    *   Scheduling local notifications using `UNUserNotificationCenter`.
    *   Defining and handling `UNNotificationAction` buttons for notifications (e.g., "Start Workout," "Log Energy").
    *   Handling deep linking or specific app actions when a notification or its action is tapped.
*   **Key Components within this Module:**
    *   `NotificationManager.swift` (Service class) in `AirFit/Services/Platform/` or `AirFit/Modules/Engagement/`.
    *   `EngagementEngine.swift` (Logic for lapse detection and strategy) in `AirFit/Modules/Engagement/Logic/` or `AirFit/BusinessLogic/`.
    *   AppDelegate or SceneDelegate extensions/methods for handling notification registration and responses.
    *   Background task registration (if using `BGTaskScheduler`).

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Master Architecture Specification (v1.2) – Notification strategies, AI interaction for content.
    *   Modular Sub-Document 1: `AppLogger`, `AppConstants`.
    *   Modular Sub-Document 2: `User`, `OnboardingProfile` models, `CommunicationPreferences` struct.
    *   Modular Sub-Document 5: `CoachEngine` for generating notification content.
*   **Outputs:**
    *   Functionality for scheduling and displaying personalized local notifications.
    *   Mechanism for detecting user inactivity and responding according to preferences.
    *   Handling of notification actions to deep-link or trigger app functionality.

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 9.0: Notification Permission & Setup**
    *   **Agent Task 9.0.1:**
        *   Instruction: "Create `NotificationManager.swift` in `AirFit/Services/Platform/`."
        *   Details:
            *   Define a class `NotificationManager`.
            *   Import `UserNotifications`.
            *   Method: `func requestNotificationPermission(completion: @escaping (Bool, Error?) -> Void)`:
                *   Uses `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`.
                *   Logs success/failure using `AppLogger`.
                *   Calls completion handler.
            *   Method: `func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void)`:
                *   Calls `UNUserNotificationCenter.current().getNotificationSettings`.
        *   Acceptance Criteria: `NotificationManager.swift` created with permission request logic.
    *   **Agent Task 9.0.2:**
        *   Instruction: "Integrate notification permission request into the app flow."
        *   Details:
            *   Determine a suitable point to ask for notification permission (e.g., towards the end of onboarding, or when setting first reminder/plan).
            *   Call `NotificationManager.requestNotificationPermission()` from the appropriate ViewModel or app state manager.
            *   For now, this can be called from `OnboardingViewModel.completeOnboarding()` or from `DashboardViewModel.onAppear` (guarded by a check to ask only once).
        *   Acceptance Criteria: Permission request is triggered at a defined point.
    *   **Agent Task 9.0.3:**
        *   Instruction: "Configure the app to handle notification responses by setting the delegate for `UNUserNotificationCenter`."
        *   Details:
            *   In `AirFitApp.swift` or `AppDelegate.swift` (if used):
                *   Make the class conform to `UNUserNotificationCenterDelegate`.
                *   In `init()` or `application(_:didFinishLaunchingWithOptions:)`: Set `UNUserNotificationCenter.current().delegate = self`.
                *   Implement `userNotificationCenter(_:willPresent:withCompletionHandler:)` to decide how to present notifications when app is in foreground (e.g., `completionHandler([.banner, .sound])`).
                *   Implement `userNotificationCenter(_:didReceive:withCompletionHandler:)` to handle taps on notifications or their actions.
        *   Acceptance Criteria: App is set up to receive and handle notification interactions.

---

**Task 9.1: Define Notification Categories and Actions**
    *   **Agent Task 9.1.1:**
        *   Instruction: "In `NotificationManager.swift` (or a dedicated setup method called at app launch), define `UNNotificationCategory` objects with `UNNotificationAction`s."
        *   Details:
            *   Example Category 1: "WORKOUT_REMINDER"
                *   Actions:
                    *   `startWorkoutAction`: Title "Start Workout", identifier "START_WORKOUT_ACTION".
                    *   `skipTodayAction`: Title "Skip Today", identifier "SKIP_TODAY_ACTION", options: `.destructive` (if appropriate).
            *   Example Category 2: "ENERGY_LOG_REMINDER"
                *   Actions:
                    *   `logEnergyAction`: Title "Log Energy", identifier "LOG_ENERGY_ACTION".
            *   Register these categories with `UNUserNotificationCenter.current().setNotificationCategories(...)`.
            ```swift
            // In NotificationManager.swift or an app setup location
            func setupNotificationCategories() {
                let startWorkoutAction = UNNotificationAction(identifier: "START_WORKOUT_ACTION", title: "Start Workout", options: [.foreground])
                let skipTodayAction = UNNotificationAction(identifier: "SKIP_TODAY_ACTION", title: "Skip Today", options: []) // Consider .destructive
                let workoutReminderCategory = UNNotificationCategory(identifier: "WORKOUT_REMINDER",
                                                                     actions: [startWorkoutAction, skipTodayAction],
                                                                     intentIdentifiers: [], options: .customDismissAction)

                let logEnergyAction = UNNotificationAction(identifier: "LOG_ENERGY_ACTION", title: "Log Energy", options: [.foreground])
                let energyLogReminderCategory = UNNotificationCategory(identifier: "ENERGY_LOG_REMINDER",
                                                                    actions: [logEnergyAction],
                                                                    intentIdentifiers: [], options: .customDismissAction)
                
                UNUserNotificationCenter.current().setNotificationCategories([workoutReminderCategory, energyLogReminderCategory])
                AppLogger.log("Notification categories registered.", category: .general)
            }
            ```
        *   Acceptance Criteria: Notification categories and actions are defined and registered.

---

**Task 9.2: Implement EngagementEngine for Lapse Detection & Strategy**
    *   **Agent Task 9.2.1:**
        *   Instruction: "Create `EngagementEngine.swift` in `AirFit/Modules/Engagement/Logic/`."
        *   Details:
            *   Class `EngagementEngine`.
            *   Dependencies: `modelContext: ModelContext`, `coachEngine: CoachEngine`, `notificationManager: NotificationManager`.
            *   Method: `func performDailyEngagementCheck(forUser user: User)` (This will be called by a background task or a simpler app launch check for now).
        *   Acceptance Criteria: `EngagementEngine.swift` class structure created.
    *   **Agent Task 9.2.2 (Lapse Detection Logic):**
        *   Instruction: "Implement the core logic for `performDailyEngagementCheck(forUser user: User)` in `EngagementEngine.swift`."
        *   Details:
            1.  Fetch `user.onboardingProfile` to get `communicationPreferencesData`. Decode it to `CommunicationPreferences` struct.
            2.  Check `user.lastActiveAt`. Calculate days since last active. (E.g., if `Date().timeIntervalSince(user.lastActiveAt) / (24*60*60) > 3` for 3 days).
            3.  If a significant lapse is detected (e.g., > 3 days, configurable):
                *   Check `communicationPreferences.absenceResponse`:
                    *   If "give_me_space": Do nothing, or log that user prefers space.
                    *   If "check_in_on_me" or "light_nudge": Proceed to generate and schedule a notification.
            4.  (Future refinement) This check could be more sophisticated, considering workout streaks, etc. For now, simple `lastActiveAt` is sufficient.
            5.  **Updating `lastActiveAt`:** The app needs a mechanism to update `user.lastActiveAt = Date()` whenever the user performs a significant action (opens app, logs data, interacts with coach). This could be a utility function called from various ViewModels or app lifecycle events. *Agent to note this as a separate small task to be implemented across relevant modules.*
        *   Acceptance Criteria: Lapse detection logic implemented based on `lastActiveAt` and `absence_response`.
    *   **Agent Task 9.2.3 (Trigger AI Notification Content Generation):**
        *   Instruction: "If a proactive check-in is warranted in `performDailyEngagementCheck`, call `CoachEngine` to generate notification content."
        *   Details:
            *   Construct a specific request/prompt for `CoachEngine` (e.g., a new method `coachEngine.generateProactiveEngagementMessage(purpose: String, forUser: User) async -> (title: String, body: String)?`).
            *   `purpose` could be "lapse_check_in_light" or "lapse_check_in_stronger" based on `absence_response`.
            *   The `CoachEngine` method would use the user's persona and context to craft a short, engaging title and body.
            *   (Stub/Mock `CoachEngine` call for now). Example mock: `return (title: "Hey [User Name]!", body: "Just checking in. Hope you're doing great! Ready to jump back in?")`
            *   If content is successfully generated, call `notificationManager.scheduleProactiveCheckInNotification(...)` (see next task).
        *   Acceptance Criteria: Logic to call (mocked) `CoachEngine` for notification content is present.

---

**Task 9.3: Scheduling Notifications via NotificationManager**
    *   **Agent Task 9.3.1:**
        *   Instruction: "Add methods to `NotificationManager.swift` for scheduling different types of notifications."
        *   Details:
            *   `func scheduleProactiveCheckInNotification(title: String, body: String, timeInterval: TimeInterval = 5, categoryIdentifier: String = "GENERAL_CHECK_IN")` (using a generic category for now, or make it specific like "LAPSE_REMINDER").
            *   `func scheduleWorkoutReminder(title: String, body: String, dateComponents: DateComponents, categoryIdentifier: String = "WORKOUT_REMINDER")` (for future use when scheduling planned workouts).
            *   Inside these methods:
                *   Create `UNMutableNotificationContent`: set `title`, `body`, `sound = .default`, `categoryIdentifier`.
                *   Create `UNNotificationTrigger` (e.g., `UNTimeIntervalNotificationTrigger`, `UNCalendarNotificationTrigger`).
                *   Create `UNNotificationRequest`.
                *   Call `UNUserNotificationCenter.current().add(request)`. Handle errors with `AppLogger`.
        *   Acceptance Criteria: Methods for scheduling notifications are implemented.
    *   **Agent Task 9.3.2 (Example Scheduling from EngagementEngine):**
        *   Instruction: "In `EngagementEngine.performDailyEngagementCheck`, if AI content is generated, call the appropriate `NotificationManager` scheduling method."
        *   Details: For example, if a light nudge is needed, schedule it for a few seconds/minutes in the future for testing, or a specific time of day (e.g., next day at 9 AM).
        *   Acceptance Criteria: `EngagementEngine` calls `NotificationManager` to schedule the notification.

---

**Task 9.4: Handling Notification Actions & Deep Linking**
    *   **Agent Task 9.4.1:**
        *   Instruction: "In the `UNUserNotificationCenterDelegate` implementation (e.g., `AirFitApp.swift` or `AppDelegate.swift`), expand `userNotificationCenter(_:didReceive:withCompletionHandler:)` to handle custom action identifiers."
        *   Details:
            *   Switch on `response.actionIdentifier`:
                *   Case `"START_WORKOUT_ACTION"`: Log, then navigate/deep-link to the workout start screen. (For now, `AppLogger.log("Start Workout action tapped.")`).
                *   Case `"SKIP_TODAY_ACTION"`: Log, potentially update user's plan or stats.
                *   Case `"LOG_ENERGY_ACTION"`: Log, navigate/deep-link to the energy logging UI.
                *   Case `UNNotificationDefaultActionIdentifier` (user tapped the main notification body): Log, open the app to the main screen (Dashboard).
            *   Call `completionHandler()`.
            *   **(Deep Linking):** Actual navigation will require a robust deep linking strategy, possibly involving a global navigation coordinator or environment objects that can trigger sheet/fullScreenCover presentations or programmatic navigation. For now, logging the intent is sufficient.
        *   Acceptance Criteria: Notification action handling logic is in place (with logging for now).

---

**Task 9.5: Background Task for Lapse Detection (Advanced - Initial Stub)**
    *   **Agent Task 9.5.1 (Register Background Task Identifier):**
        *   Instruction: "Add a background task identifier to the `Info.plist` for the iOS target under `BGTaskSchedulerPermittedIdentifiers`."
        *   Details: E.g., `com.example.airfit.dailyEngagementCheck`.
        *   Acceptance Criteria: Identifier added to `Info.plist`.
    *   **Agent Task 9.5.2 (Register and Schedule Task - Stub):**
        *   Instruction: "In `AirFitApp.swift` (or `AppDelegate`), create methods to register and schedule the background task using `BGTaskScheduler`."
        *   Details:
            *   Import `BackgroundTasks`.
            *   `func registerBackgroundTasks()`: Called at app launch. Use `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)`. The `launchHandler` will create an instance of `EngagementEngine` and call `performDailyEngagementCheck`.
            *   `func scheduleDailyEngagementCheckTask()`: Creates a `BGAppRefreshTaskRequest` and submits it. Schedule it to run, e.g., once a day.
            *   **(Initial Implementation Note):** Full background task execution can be complex to test and debug. For initial development, the `performDailyEngagementCheck` can be called when the app enters the foreground or on a timer for easier testing, with the `BGTaskScheduler` integration refined later.
        *   Acceptance Criteria: Methods for registering and scheduling background tasks are stubbed or implemented for foreground testing.

---

**Task 9.6: Final Review & Commit**
    *   **Agent Task 9.6.1 (Review Full Flow):**
        *   Instruction: "Review `NotificationManager`, `EngagementEngine`, and notification delegate handling for permission requests, lapse detection logic, AI content generation triggering (mocked), notification scheduling, and action handling (logged)."
        *   Acceptance Criteria: The end-to-end flow for proactive engagement is logically sound.
    *   **Agent Task 9.6.2 (Test Local Notifications):**
        *   Instruction: "Trigger test notifications from `EngagementEngine` (e.g., by manually setting `lastActiveAt` to an old date and running the check) to verify they appear and actions can be interacted with."
        *   Acceptance Criteria: Local notifications are successfully scheduled and received. Actions are logged.
    *   **Agent Task 9.6.3 (Commit):**
        *   Instruction: "Stage and commit all new and modified files for this module."
        *   Details: Commit message: "Feat: Implement Notifications & Engagement Engine with lapse detection".
        *   Acceptance Criteria: All changes committed. Project builds.

---

**4. Acceptance Criteria for Module Completion**

*   The app requests and handles notification permissions.
*   Notification categories and custom actions are defined and registered.
*   `EngagementEngine` can detect user inactivity based on `lastActiveAt` and `absence_response` preferences.
*   `EngagementEngine` can trigger (mocked) `CoachEngine` calls to generate persona-driven notification content.
*   `NotificationManager` can schedule local notifications with titles, bodies, and category identifiers.
*   Basic handling for notification taps and custom actions is implemented (logging the intent).
*   (Stubbed/Initial) Mechanism for periodic lapse detection (e.g., on app foreground or via BGTaskScheduler setup).
*   All code passes SwiftLint.

**5. Code Style Reminders for this Module**

*   Ensure all `UserNotifications` framework calls are made correctly, including setting the delegate.
*   Handle asynchronous nature of permission requests and notification scheduling.
*   Logic in `EngagementEngine` should be clear and testable (even if dependent on mocked AI calls initially).
*   Deep linking from notification actions can be complex; focus on logging the correct intent first and implement full navigation later as part of a broader navigation strategy.
*   When implementing background tasks, ensure they are efficient and complete their work promptly, calling `task.setTaskCompleted(success:)`.

---

This module sets up the important mechanism for keeping users engaged. The complexity will grow when the AI content generation is fully implemented and when background tasks are robustly handled. For now, getting the permissions, basic scheduling, and action handling in place is key.
