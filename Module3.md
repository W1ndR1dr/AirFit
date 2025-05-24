**Modular Sub-Document 3: Onboarding Module (UI & Logic for "Persona Blueprint Flow")**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – specifically `User` and `OnboardingProfile` models.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To implement the complete "Persona Blueprint Flow v3.1" which guides the user through a series of screens to define their AI coach's personality, preferences, and initial goals. This module captures user input, orchestrates the flow, potentially calls an LLM for goal analysis, and saves the resulting `OnboardingProfile`.
*   **Responsibilities:**
    *   Implementing SwiftUI views for each screen of the "Persona Blueprint Flow v3.1."
    *   Managing the state and navigation through the onboarding sequence.
    *   Collecting and validating user inputs from each screen.
    *   Initiating LLM Call 1 (Goal Analysis) if the user provides a custom aspiration.
    *   Constructing the `persona_profile.json` and `communicationPreferences.json` from collected data.
    *   Creating and saving the `User` and `OnboardingProfile` SwiftData entities upon successful completion.
    *   Ensuring a clean, classy, and premium user experience consistent with the Design Specification.
*   **Key Components within this Module:**
    *   SwiftUI Views for each onboarding screen (e.g., `OpeningScreenView.swift`, `LifeSnapshotView.swift`, `CoachingStyleView.swift`, etc.) located in `AirFit/Modules/Onboarding/Views/`.
    *   `OnboardingViewModel.swift` (or `OnboardingManager.swift`) to manage state, data, and flow logic, located in `AirFit/Modules/Onboarding/ViewModels/`.
    *   Helper structs/enums specific to onboarding data collection, if any, in `AirFit/Modules/Onboarding/Models/` or `AirFit/Core/Enums/`.

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) – for UI/UX details of each onboarding screen.
    *   AirFit App - Master Architecture Specification (v1.2) – for LLM call definitions, data flow, and interaction with other layers.
    *   Modular Sub-Document 1: `AppColors`, `AppFonts`, `AppConstants`, `View+Extensions`.
    *   Modular Sub-Document 2: `User`, `OnboardingProfile`, `CommunicationPreferences` models.
    *   (Implicit) A mock or basic implementation of `AIRouterService` for LLM Call 1, or a plan to integrate with it once that service is developed. For initial tasks, the LLM call can be stubbed.
*   **Outputs:**
    *   A fully interactive onboarding user interface.
    *   A new `User` entity and associated `OnboardingProfile` entity saved to SwiftData upon completion.
    *   The application navigates to the main app interface (e.g., Dashboard) after onboarding.

**3. Detailed Component Specifications & Agent Tasks**

*(AI Agent Tasks: These tasks involve creating SwiftUI views, ViewModel/Manager classes, and integrating with previously defined models and utilities. Agents should adhere to the "clean, classy & premium" design philosophy.)*

---

**Task 3.0: Setup Onboarding Flow Management**
    *   **Agent Task 3.0.1:**
        *   Instruction: "Create a Swift file named `OnboardingViewModel.swift` in `AirFit/Modules/Onboarding/ViewModels/`."
        *   Details:
            *   Define an `ObservableObject` class `OnboardingViewModel`.
            *   Properties:
                *   `@Published var currentScreen: OnboardingScreen = .openingScreen` (Define `OnboardingScreen` enum).
                *   `@Published var lifeSnapshotData: LifeSnapshotSelections = LifeSnapshotSelections()` (Define `LifeSnapshotSelections` struct to hold boolean flags for each option).
                *   `@Published var coreAspirationText: String = ""`
                *   `@Published var coreAspirationStructured: StructuredGoal? = nil` (Define `StructuredGoal` struct for LLM output).
                *   `@Published var coachingStyleBlend: CoachingStylePreferences = CoachingStylePreferences()` (Define `CoachingStylePreferences` struct with Double properties for each style, e.g., `authoritativeDirect`, `empatheticEncouraging`).
                *   `@Published var engagementPreference: EngagementPreset = .dataDrivenPartnership` (Define `EngagementPreset` enum: `dataDrivenPartnership`, `consistentBalanced`, `guidanceOnDemand`, `custom`). If `custom`, add individual bools: `detailedTracking`, `dailyInsights`, `autoRecoveryAdjust`.
                *   `@Published var typicalAvailability: [WorkoutAvailabilityBlock] = []` (Define `WorkoutAvailabilityBlock` struct: `dayOfWeek`, `startTime`, `endTime`).
                *   `@Published var sleepBedtime: Date = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!`
                *   `@Published var sleepWakeTime: Date = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!`
                *   `@Published var sleepRhythm: SleepRhythmType = .consistent` (Define `SleepRhythmType` enum: `consistent`, `weekendsDifferent`, `highlyVariable`).
                *   `@Published var achievementAcknowledgement: AchievementStyle = .subtleAffirming` (Define `AchievementStyle` enum).
                *   `@Published var inactivityResponse: InactivityResponseStyle = .gentleNudge` (Define `InactivityResponseStyle` enum).
                *   `@Published var preferredUnits: String = "imperial"` (Can be pre-filled or asked here/settings).
                *   `@Published var establishBaseline: Bool = true`
            *   Methods:
                *   `func navigateToNextScreen()`
                *   `func navigateToPreviousScreen()` (if back navigation is allowed on all screens)
                *   `func processCoreAspiration()` (handles LLM call if custom goal)
                *   `func completeOnboarding(modelContext: ModelContext)` (constructs JSONs, saves User & OnboardingProfile)
            *   Stub out methods for now. Inject `ModelContext` where needed for saving.
        *   Acceptance Criteria: `OnboardingViewModel.swift` and supporting structs/enums are created and compile.
    *   **Agent Task 3.0.2:**
        *   Instruction: "Define the `OnboardingScreen` enum in a new file `OnboardingModels.swift` within `AirFit/Modules/Onboarding/Models/` (or a shared enum file if preferred)."
        *   Details: Include cases for all screens in Persona Blueprint Flow v3.1: `.openingScreen`, `.lifeSnapshot`, `.coreAspiration`, `.coachingStyle`, `.engagementPreferences`, `.typicalAvailability`, `.sleepAndBoundaries`, `.motivationAndCheckins`, `.generatingCoach`, `.coachProfileReady`. Make it `CaseIterable` if useful.
        *   Acceptance Criteria: `OnboardingScreen` enum defined.
    *   **Agent Task 3.0.3:**
        *   Instruction: "Create a main SwiftUI View named `OnboardingFlowView.swift` in `AirFit/Modules/Onboarding/Views/`."
        *   Details:
            *   This view will observe an instance of `OnboardingViewModel`.
            *   It will use a `switch` statement on `viewModel.currentScreen` to display the appropriate screen view.
            *   It will contain the persistent "Privacy & Data" footer and the top progress bar (visual placeholders for now).
            ```swift
            // AirFit/Modules/Onboarding/Views/OnboardingFlowView.swift
            import SwiftUI

            struct OnboardingFlowView: View {
                @StateObject private var viewModel = OnboardingViewModel()
                @Environment(\.modelContext) private var modelContext // For saving at the end

                var body: some View {
                    VStack {
                        // Placeholder for Progress Bar
                        HStack {
                            ForEach(0..<OnboardingScreen.allCases.count - 2, id: \.self) { index in // -2 for generating & profile
                                Rectangle()
                                    .fill(index < OnboardingScreen.allCases.firstIndex(of: viewModel.currentScreen)! ? AppColors.accentColor : Color.gray.opacity(0.3))
                                    .frame(height: 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)


                        // Main content based on current screen
                        switch viewModel.currentScreen {
                        case .openingScreen:
                            OpeningScreenView(viewModel: viewModel)
                        case .lifeSnapshot:
                            LifeSnapshotView(viewModel: viewModel)
                        // ... Add cases for ALL other onboarding screens
                        // case .coreAspiration: CoreAspirationView(viewModel: viewModel)
                        // case .coachingStyle: CoachingStyleView(viewModel: viewModel)
                        // case .engagementPreferences: EngagementPreferencesView(viewModel: viewModel)
                        // case .typicalAvailability: TypicalAvailabilityView(viewModel: viewModel)
                        // case .sleepAndBoundaries: SleepAndBoundariesView(viewModel: viewModel)
                        // case .motivationAndCheckins: MotivationAndCheckinsView(viewModel: viewModel)
                        // case .generatingCoach: GeneratingCoachView(viewModel: viewModel)
                        // case .coachProfileReady: CoachProfileReadyView(viewModel: viewModel, onComplete: { /* Handle completion */ })
                        default: // Temporary
                            Text("Screen not implemented: \(viewModel.currentScreen.rawValue)")
                            Button("Next (Dev)") { viewModel.navigateToNextScreen() }
                        }

                        Spacer() // Pushes content up

                        // Placeholder for Persistent Footer
                        Text("Privacy & Data")
                            .font(AppFonts.secondaryBody(size: 12)) // Use defined AppFonts
                            .foregroundColor(AppColors.textSecondary) // Use defined AppColors
                            .padding(.bottom)
                    }
                    .animation(.default, value: viewModel.currentScreen) // Add animation for screen transitions
                }
            }
            ```
        *   Acceptance Criteria: `OnboardingFlowView.swift` created, uses `OnboardingViewModel`, and can switch between placeholder screen views.

---

**(For each screen in "Persona Blueprint Flow v3.1", create a similar task block. I will detail one fully, and the agent should follow the pattern for the rest.)**

**Task 3.1: Implement Opening Screen View**
    *   **Agent Task 3.1.1:**
        *   Instruction: "Create `OpeningScreenView.swift` in `AirFit/Modules/Onboarding/Views/` as per Persona Blueprint Flow v3.1, Screen 1."
        *   Details:
            *   Use `AppColors`, `AppFonts`, `AppConstants` for styling.
            *   Content: App logo/name (placeholder `Text("AirFit")` for now), "Let’s design your AirFit Coach.", "Est. 3-4 minutes...", "Begin" button, "Maybe Later" button.
            *   "Begin" button action: Call `viewModel.navigateToNextScreen()`.
            *   "Maybe Later" button action: (For now, can also call `navigateToNextScreen()` for flow testing, or implement dismiss logic later).
            ```swift
            // AirFit/Modules/Onboarding/Views/OpeningScreenView.swift
            import SwiftUI

            struct OpeningScreenView: View {
                @ObservedObject var viewModel: OnboardingViewModel // Passed in

                var body: some View {
                    VStack(spacing: AppConstants.defaultPadding * 2) {
                        Spacer()
                        Text("AirFit") // Placeholder for logo/name
                            .font(AppFonts.primaryTitle(size: 40)) // Use defined AppFonts
                            .foregroundColor(AppColors.textPrimary) // Use defined AppColors

                        Text("Let’s design your AirFit Coach.")
                            .font(AppFonts.primaryBody(size: 20))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)

                        Text("Est. 3-4 minutes to create your personalized experience.")
                            .font(AppFonts.secondaryBody(size: 14))
                            .foregroundColor(AppColors.textSecondary.opacity(0.7))

                        Spacer()

                        Button(action: {
                            viewModel.navigateToNextScreen()
                        }) {
                            Text("Begin")
                                .font(AppFonts.primaryBody(size: 18).weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.accentColor)
                                .cornerRadius(AppConstants.defaultCornerRadius)
                        }
                        .padding(.horizontal, AppConstants.defaultPadding * 2)

                        Button(action: {
                            // For now, treat as "skip onboarding" for dev flow
                            // Later, this might dismiss the onboarding flow.
                            AppLogger.log("'Maybe Later' tapped on Opening Screen.", category: .onboarding)
                            // viewModel.skipOnboarding() // Implement this method if needed
                        }) {
                            Text("Maybe Later")
                                .font(AppFonts.primaryBody(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.bottom, AppConstants.defaultPadding)
                    }
                    .padding(AppConstants.defaultPadding)
                }
            }
            ```
        *   Acceptance Criteria: `OpeningScreenView.swift` created, compiles, visually matches design intent, and buttons trigger ViewModel actions.

---

**Task 3.2 - 3.8: Implement Remaining Onboarding Screens**
    *   **Agent Task (Pattern):** For each screen specified in "Persona Blueprint Flow v3.1" (Life Snapshot, Core Aspiration, Coaching Style, Engagement Preferences, Typical Availability, Sleep & Boundaries, Motivational Style & Check-ins):
        *   Instruction: "Create `[ScreenName]View.swift` in `AirFit/Modules/Onboarding/Views/`. Implement the UI and interactions as described in Persona Blueprint Flow v3.1, Screen X: '[Screen Title]'."
        *   Details:
            *   Use appropriate SwiftUI controls (Text, Button, Toggle, Slider, Picker, List, custom Checkbox if needed).
            *   Bind UI controls to the corresponding `@Published` properties in `OnboardingViewModel`.
            *   Use `AppColors`, `AppFonts`, `AppConstants` for styling.
            *   Include "Next" buttons that call `viewModel.navigateToNextScreen()`.
            *   For sliders in `CoachingStyleView`, provide descriptive text feedback below/beside each slider that updates dynamically based on the slider's value (as specified in flow v3.1).
            *   For `CoreAspirationView`, if "Describe Your Own" is chosen, provide a `TextEditor` for input, and the "Next" button should trigger `viewModel.processCoreAspiration()` before `navigateToNextScreen()`.
            *   (HealthKit Pre-fill): For screens like Life Snapshot or Sleep, note where HealthKit data *would* pre-fill options. The actual HealthKit fetch logic will be in Module D; for now, the ViewModel properties can have default values.
        *   Acceptance Criteria (for each screen): View created, compiles, binds correctly to ViewModel, visually aligns with design, "Next" button functions.

---

**Task 3.9: Implement Logic in OnboardingViewModel**
    *   **Agent Task 3.9.1 (Navigation):**
        *   Instruction: "Implement the `navigateToNextScreen()` and `navigateToPreviousScreen()` methods in `OnboardingViewModel.swift`."
        *   Details: Use the `OnboardingScreen` enum and its `allCases` to advance or go back. Handle edge cases (first/last screen).
        *   Acceptance Criteria: Navigation logic works correctly through all defined screens.
    *   **Agent Task 3.9.2 (Goal Analysis - LLM Call):**
        *   Instruction: "Implement the `processCoreAspiration()` method in `OnboardingViewModel.swift`."
        *   Details:
            *   If `coreAspirationText` is not blank:
                *   Construct the system prompt for "LLM Call 1: Goal Analysis" (from Master Architecture Spec 3.2). Inject `coreAspirationText`.
                *   (Stub/Mock) Simulate a call to `AIRouterService.getStreamingResponse()` (or a non-streaming equivalent if simpler for this specific JSON output call).
                *   The AI Router service will be fully implemented later. For now, the agent can create a mock function within the ViewModel or assume a global mock service that returns a predefined valid JSON string (e.g., `{"goal_type": "aesthetic", "primary_metric": "body_fat_percentage", ...}`).
                *   Parse the returned JSON into the `coreAspirationStructured` property. Handle potential parsing errors.
                *   Log the request and (mock) response using `AppLogger`.
        *   Acceptance Criteria: Method attempts to process custom goal text, (mock) interacts with an AI service, and updates `coreAspirationStructured`.
    *   **Agent Task 3.9.3 (Completion Logic):**
        *   Instruction: "Implement the `completeOnboarding(modelContext: ModelContext)` method in `OnboardingViewModel.swift`."
        *   Details:
            1.  Create a new `User` object, populating `preferredUnits`.
            2.  Construct the `persona_profile.json` data: This involves creating a dictionary or a Swift `Codable` struct that mirrors the `persona_profile.json` structure discussed previously (which includes life context, goal info, blend percentages, tracking style, sleep details, celebration style, absence response, etc., all sourced from the ViewModel's @Published properties). Encode this to `Data` using `JSONEncoder`. This will be stored as `personaPromptData` in `OnboardingProfile`.
            3.  Construct `CommunicationPreferences` struct from ViewModel data and encode to `Data` for `communicationPreferencesData`.
            4.  Store the full `persona_profile.json` data also as `rawFullProfileData`.
            5.  Create an `OnboardingProfile` object, linking it to the new `User`, and providing the generated `Data` objects.
            6.  Insert both `User` and `OnboardingProfile` into the `modelContext`.
            7.  Attempt to save the `modelContext`. Handle errors with `AppLogger`.
            8.  Set a flag or trigger a callback to indicate onboarding is complete (for navigation to the main app).
        *   Acceptance Criteria: Method correctly assembles data, creates `User` and `OnboardingProfile` entities, and saves them to SwiftData.

---

**Task 3.10: Implement Final Onboarding Screens (Generating & Profile Ready)**
    *   **Agent Task 3.10.1:**
        *   Instruction: "Create `GeneratingCoachView.swift` in `AirFit/Modules/Onboarding/Views/`."
        *   Details:
            *   Display an elegant loading animation (e.g., animated progress bar fill, morphing shapes as per Design Spec). Show text like "Crafting Your Coach…", "Analyzing preferences…".
            *   In its `onAppear`, this view should trigger `viewModel.completeOnboarding(modelContext: modelContext)`.
            *   After a simulated delay (or upon completion of `completeOnboarding`), automatically call `viewModel.navigateToNextScreen()` to go to `CoachProfileReadyView`.
        *   Acceptance Criteria: View displays loading animation and text, triggers completion logic, and navigates.
    *   **Agent Task 3.10.2:**
        *   Instruction: "Create `CoachProfileReadyView.swift` in `AirFit/Modules/Onboarding/Views/`."
        *   Details:
            *   Display the summary of the generated coach profile as per "Persona Blueprint Flow v3.1, Screen 10." This involves fetching the just-saved `OnboardingProfile` data (or passing relevant ViewModel data directly) to show coaching style summary, primary aspiration, engagement style, communication boundaries, and the "Establish Baseline" toggle.
            *   "Begin with My Coach" button: Triggers a callback/navigation to the main app (e.g., Dashboard).
            *   "Review & Refine Settings" button: (Future) Navigates to a settings area to tweak persona elements. For now, can also navigate to the main app.
        *   Acceptance Criteria: View displays profile summary and actions.

---

**Task 3.11: Integrate Onboarding into App Flow**
    *   **Agent Task 3.11.1:**
        *   Instruction: "Modify `AirFit/Application/AirFitApp.swift` and its `ContentView.swift` (or create a new root view like `MainView.swift`)."
        *   Details:
            *   Implement logic to check if a `User` and `OnboardingProfile` exist in SwiftData.
            *   If onboarding is NOT complete: Display `OnboardingFlowView`.
            *   If onboarding IS complete: Display the main app content (e.g., a placeholder `Text("Dashboard Placeholder")` for now).
            *   The `OnboardingFlowView` should have a callback or mechanism to signal completion to this root view so it can switch its displayed content.
        *   Acceptance Criteria: App correctly shows onboarding for new users and skips to main content for existing users.

---

**Task 3.12: Final Review & Commit**
    *   **Agent Task 3.12.1:**
        *   Instruction: "Review all created SwiftUI views and the `OnboardingViewModel` for correctness, adherence to design specifications, data binding, navigation logic, and interaction with SwiftData."
        *   Acceptance Criteria: All components function as intended, code is clean, and follows styling guidelines.
    *   **Agent Task 3.12.2:**
        *   Instruction: "Stage all new and modified files related to the Onboarding module."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 3.12.3:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Implement Onboarding 'Persona Blueprint Flow' UI and core logic".
        *   Acceptance Criteria: Git history shows the new commit. Project builds and runs the onboarding flow.

---

**4. Acceptance Criteria for Module Completion**

*   All screens of the "Persona Blueprint Flow v3.1" are implemented as SwiftUI views.
*   `OnboardingViewModel` manages the state, data collection, and navigation for the entire flow.
*   User inputs are correctly captured and stored in the ViewModel.
*   LLM Call 1 (Goal Analysis) is (mock) integrated for custom goal input.
*   Upon completion, `persona_profile.json` data is correctly constructed, and `User` and `OnboardingProfile` entities are successfully saved to SwiftData.
*   The application correctly routes users through the onboarding flow or to the main app content based on their onboarding status.
*   The UI adheres to the "clean, classy & premium" design principles and uses `AppColors`, `AppFonts`, etc.
*   All code passes SwiftLint checks.

**5. Code Style Reminders for this Module**

*   SwiftUI views should be broken down into smaller, reusable sub-views where appropriate for clarity and maintainability.
*   Use `@StateObject` for the `OnboardingViewModel` in `OnboardingFlowView` and `@ObservedObject` when passing it to sub-views.
*   Ensure all user-interactive elements are accessible and provide appropriate feedback.
*   ViewModel logic should be clearly separated from view rendering.
*   Use `AppLogger` for logging key events and potential errors during the onboarding process.

---

This module is quite substantial. Due to the number of screens and the ViewModel logic, this will likely involve many iterations with the AI agent(s). Clear instructions for each screen's specific UI elements and bindings will be crucial. Good luck with the "vibe-coding"!
