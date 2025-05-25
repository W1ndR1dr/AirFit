**Modular Sub-Document 6: Dashboard Module (UI & Logic)**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `User`, `OnboardingProfile`, `DailyLog`, `FoodEntry`, `Workout`.
    *   Completion of Modular Sub-Document 4: HealthKit & Context Aggregation Module – `ContextAssembler`, `HealthContextSnapshot`.
    *   Completion of Modular Sub-Document 5: AI Persona Engine & CoachEngine – (Specifically, the ability for `CoachEngine` to generate a persona-driven message, even if not a full chat interaction for this specific feature).
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To implement the main Dashboard screen, which serves as the primary landing interface for the user. It provides a personalized overview of their day, key health metrics, and quick access to logging actions.
*   **Responsibilities:**
    *   Displaying the "Morning Greeting Card" with an AI-generated, persona-driven message.
    *   Implementing the "Energy Logging Micro-Interaction."
    *   Displaying the "NutritionCard" with animated macro rings (Calories, Protein, Carbs, Fat).
    *   Displaying other contextual cards like "RecoveryCard" and "PerformanceCard" (initial versions can be simpler placeholders for data that will be richer later).
    *   Fetching and preparing data for all dashboard cards using a `DashboardViewModel`.
    *   Ensuring the UI adheres to the "clean, classy & premium" design principles.
*   **Key Components within this Module:**
    *   `DashboardView.swift` (Main SwiftUI View) in `AirFit/Modules/Dashboard/Views/`.
    *   `DashboardViewModel.swift` (ObservableObject) in `AirFit/Modules/Dashboard/ViewModels/`.
    *   Individual card views (e.g., `MorningGreetingCardView.swift`, `NutritionCardView.swift`, `EnergyLogCardView.swift`, `RecoveryCardView.swift`, `PerformanceCardView.swift`) in `AirFit/Modules/Dashboard/Views/Cards/`.
    *   Helper views for specific UI elements (e.g., animated macro rings).

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) – UI/UX details for the Dashboard and its cards.
    *   Modular Sub-Document 1: `AppColors`, `AppFonts`, `AppConstants`, `View+Extensions`.
    *   Modular Sub-Document 2: Access to SwiftData models like `User`, `DailyLog`, `FoodEntry`, `FoodItem`, `Workout` to fetch data for display.
    *   Modular Sub-Document 4: `ContextAssembler` to get the `HealthContextSnapshot` for real-time data.
    *   Modular Sub-Document 5: `CoachEngine` (or a specialized part of it) to generate the AI Morning Greeting.
*   **Outputs:**
    *   A fully interactive Dashboard screen.
    *   Mechanism for users to log their subjective energy.
    *   Visual representation of nutrition macro progress.

**3. Detailed Component Specifications & Agent Tasks**

*(AI Agent Tasks: These tasks involve creating SwiftUI views and ViewModel classes, focusing on UI presentation, data fetching, and interaction with other services.)*

---

**Task 6.0: Dashboard ViewModel Setup**
    *   **Agent Task 6.0.1:**
        *   Instruction: "Create `DashboardViewModel.swift` in `AirFit/Modules/Dashboard/ViewModels/`."
        *   Details:
            *   Define an `ObservableObject` class `DashboardViewModel`.
            *   Dependencies (passed in constructor or via DI):
                *   `modelContext: ModelContext`
                *   `contextAssembler: ContextAssembler`
                *   `coachEngine: CoachEngine` (or a specific service for AI greetings if decoupled)
                *   `user: User` (The currently logged-in user, fetched once or passed in)
            *   `@Published` properties:
                *   `morningGreeting: String = "Loading greeting..."`
                *   `currentEnergyLevel: Int?` (for the energy log, fetched from `DailyLog` for today)
                *   `caloriesConsumed: Double = 0`, `caloriesTarget: Double = 2000` (example target)
                *   `proteinConsumed: Double = 0`, `proteinTarget: Double = 150` (example target)
                *   `carbsConsumed: Double = 0`, `carbsTarget: Double = 250` (example target)
                *   `fatConsumed: Double = 0`, `fatTarget: Double = 70` (example target)
                *   `recoveryScore: Double?` (placeholder, from `HealthContextSnapshot`)
                *   `performanceTrend: String?` (placeholder, e.g., "Trending Up")
                *   `isLoading: Bool = true`
            *   Methods:
                *   `func fetchDashboardData()`: Calls sub-methods to load all necessary data.
                *   `private func fetchAIMorningGreeting()`: Interacts with `CoachEngine` to get the greeting.
                *   `private func fetchNutritionData()`: Fetches today's `FoodEntry` items from SwiftData and calculates consumed macros. (Targets might come from user's `OnboardingProfile` or goals later).
                *   `private func fetchCurrentEnergyLog()`: Fetches `DailyLog` for today.
                *   `func logEnergy(level: Int)`: Saves/updates `DailyLog` for today with the new energy level.
                *   `private func fetchContextualData()`: Uses `ContextAssembler` to get `HealthContextSnapshot` for recovery/performance cards.
        *   Acceptance Criteria: `DashboardViewModel.swift` structure created with properties and method stubs.
    *   **Agent Task 6.0.2 (Fetch Dashboard Data Logic):**
        *   Instruction: "Implement the `fetchDashboardData()` method in `DashboardViewModel.swift`."
        *   Details:
            *   Set `isLoading = true`.
            *   Call `fetchAIMorningGreeting()`, `fetchNutritionData()`, `fetchCurrentEnergyLog()`, `fetchContextualData()` asynchronously (e.g., using `async let` or a `TaskGroup`).
            *   Once all data is fetched, set `isLoading = false`.
            *   Call this method from the ViewModel's initializer or an `onAppear` modifier in the `DashboardView`.
        *   Acceptance Criteria: Data fetching orchestration logic implemented.

---

**Task 6.1: Main Dashboard View Structure**
    *   **Agent Task 6.1.1:**
        *   Instruction: "Create `DashboardView.swift` in `AirFit/Modules/Dashboard/Views/`."
        *   Details:
            *   This view will observe an instance of `DashboardViewModel`.
            *   Use a `ScrollView` containing a `LazyVGrid` for the cards, as per Design Spec 6.1.
            *   Columns for `LazyVGrid`: e.g., `[GridItem(.flexible()), GridItem(.flexible())]` for two columns on wider screens, or a single column for narrower ones (agent can start with a fixed number, e.g., 1 or 2).
            *   Display a loading indicator (e.g., `ProgressView`) if `viewModel.isLoading` is true.
            *   Order of cards: MorningGreeting (full width if possible), EnergyLog (can be part of MorningGreeting or separate small card), NutritionCard, RecoveryCard, PerformanceCard.
            ```swift
            // AirFit/Modules/Dashboard/Views/DashboardView.swift
            import SwiftUI
            import SwiftData // If User is fetched here

            struct DashboardView: View {
                @StateObject private var viewModel: DashboardViewModel
                @Environment(\.modelContext) private var modelContext // For initializing ViewModel if needed

                // Assuming User is fetched and passed or available globally
                // This is a simplification; a robust app would have user session management.
                // For now, let's assume we fetch the first user or a specific user.
                private var user: User // Needs to be initialized

                init(user: User, contextAssembler: ContextAssembler, coachEngine: CoachEngine) {
                    self.user = user
                    // Initialize StateObject here, passing dependencies from environment or app state
                    _viewModel = StateObject(wrappedValue: DashboardViewModel(
                        modelContext: modelContext, // This won't work directly, modelContext is not available in init
                                                    // ViewModel should take modelContainer or use @ModelActor
                                                    // Simpler for now: pass specific user and let VM query its relations
                        contextAssembler: contextAssembler,
                        coachEngine: coachEngine,
                        user: user // Pass the specific user
                    ))
                }
                
                // Alternative init if VM takes modelContainer
                // init(user: User, modelContainer: ModelContainer, contextAssembler: ContextAssembler, coachEngine: CoachEngine) { ... }


                let columns: [GridItem] = [
                    GridItem(.flexible(), spacing: AppConstants.defaultPadding),
                    // GridItem(.flexible(), spacing: AppConstants.defaultPadding) // For two columns
                ]

                var body: some View {
                    NavigationView { // Or NavigationStack for newer iOS
                        ScrollView {
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.top, 50)
                            } else {
                                LazyVGrid(columns: columns, spacing: AppConstants.defaultPadding) {
                                    MorningGreetingCardView(greeting: viewModel.morningGreeting, energyLogViewModel: viewModel) // Pass VM or specific state
                                        // .gridCellColumns(columns.count) // Make it span full width if 2 columns
                                    
                                    NutritionCardView(
                                        caloriesConsumed: viewModel.caloriesConsumed, caloriesTarget: viewModel.caloriesTarget,
                                        proteinConsumed: viewModel.proteinConsumed, proteinTarget: viewModel.proteinTarget,
                                        carbsConsumed: viewModel.carbsConsumed, carbsTarget: viewModel.carbsTarget,
                                        fatConsumed: viewModel.fatConsumed, fatTarget: viewModel.fatTarget
                                    )

                                    RecoveryCardView(recoveryScore: viewModel.recoveryScore)
                                    PerformanceCardView(performanceTrend: viewModel.performanceTrend)
                                }
                                .padding(AppConstants.defaultPadding)
                            }
                        }
                        .navigationTitle("Dashboard")
                        .background(AppColors.backgroundPrimary.edgesIgnoringSafeArea(.all))
                        .onAppear {
                            viewModel.fetchDashboardData()
                        }
                    }
                }
            }
            ```
            *   *Note to You (Vibe-Coder):* The `modelContext` injection into `DashboardViewModel` from `DashboardView`'s `init` is tricky with `@StateObject`. A common pattern is to pass the `ModelContainer` or have the `ViewModel` use `@ModelActor` for SwiftData operations, or fetch the `User` outside and pass it in. The provided snippet simplifies by assuming `User` is passed and VM fetches its relations. This is a point where agent might struggle and need guidance or a simpler pattern first.
        *   Acceptance Criteria: `DashboardView.swift` created, uses `DashboardViewModel`, displays loading state, and lays out placeholder card views in a `LazyVGrid`.

---

**Task 6.2: Implement Morning Greeting Card & AI Integration**
    *   **Agent Task 6.2.1:**
        *   Instruction: "Create `MorningGreetingCardView.swift` in `AirFit/Modules/Dashboard/Views/Cards/`."
        *   Details:
            *   Input: `greeting: String` and a reference to `DashboardViewModel` (or specific properties/methods for energy logging).
            *   Display the greeting text.
            *   Embed the Energy Logging Micro-Interaction (Task 6.3).
            *   Style according to "clean, classy" (e.g., nice background, good typography).
        *   Acceptance Criteria: View created, displays greeting, and has a placeholder for energy log.
    *   **Agent Task 6.2.2 (AI Greeting Logic in ViewModel):**
        *   Instruction: "Implement `private func fetchAIMorningGreeting()` in `DashboardViewModel.swift`."
        *   Details:
            *   Check if a greeting has already been fetched today (to avoid re-generation on every view appear). Store last fetched date or greeting locally in VM or UserDefaults for this simple check.
            *   Construct a very specific request/prompt for the `CoachEngine` (or a dedicated AI service method) to generate *only* a morning greeting. This is not a full chat.
                *   The prompt should instruct the AI to:
                    *   Act as the user's defined persona (from `user.onboardingProfile.personaPromptData`).
                    *   Consider elements from a minimal `HealthContextSnapshot` (e.g., previous night's sleep quality, current weather - provided by `ContextAssembler`).
                    *   Keep the greeting concise, positive, and relevant to the morning.
                    *   Example for `CoachEngine`: `coachEngine.generateShortPersonaMessage(promptDetails: PersonaMessageRequest(context: snapshot, purpose: "morning_greeting"), forUser: user) async -> String?` (This method would need to be added to `CoachEngine`).
            *   (Stub/Mock `CoachEngine` call for now if full `CoachEngine` is not ready for this specific type of one-off message generation). For example, the mock could return: `"Good morning, [User's Name if available]! You got [X] hours of sleep. It's [Weather] today. Let's make it a great one!"`
            *   Update `viewModel.morningGreeting` with the result.
            *   Handle errors using `AppLogger`.
        *   Acceptance Criteria: Method attempts to fetch/generate AI greeting and updates the `@Published` property.

---

**Task 6.3: Implement Energy Logging Micro-Interaction**
    *   **Agent Task 6.3.1:**
        *   Instruction: "Create `EnergyLogInputView.swift` (or integrate directly into `MorningGreetingCardView.swift`)."
        *   Details:
            *   Display a row of 5 selectable icons (e.g., 😴 to 🔥, or simple numbered circles).
            *   When an icon is tapped, it calls `viewModel.logEnergy(level: tappedLevel)`.
            *   Visually indicate the `viewModel.currentEnergyLevel`.
            *   Provide subtle haptic feedback on tap.
        *   Acceptance Criteria: UI for energy logging implemented and functional.
    *   **Agent Task 6.3.2 (Energy Logging Logic in ViewModel):**
        *   Instruction: "Implement `private func fetchCurrentEnergyLog()` and `func logEnergy(level: Int)` in `DashboardViewModel.swift`."
        *   Details:
            *   `fetchCurrentEnergyLog()`: Query SwiftData for a `DailyLog` for `user` and today's date. If found, update `viewModel.currentEnergyLevel`.
            *   `logEnergy(level: Int)`:
                *   Check if a `DailyLog` for `user` and today exists.
                *   If yes, update its `subjectiveEnergyLevel`.
                *   If no, create a new `DailyLog` with the date, level, and user.
                *   Insert/Update in `modelContext` and save.
                *   Update `viewModel.currentEnergyLevel`.
                *   Log using `AppLogger`.
        *   Acceptance Criteria: ViewModel methods correctly fetch and save energy log data.

---

**Task 6.4: Implement Nutrition Card with Macro Rings**
    *   **Agent Task 6.4.1:**
        *   Instruction: "Create `NutritionCardView.swift` in `AirFit/Modules/Dashboard/Views/Cards/`."
        *   Details:
            *   Inputs: `caloriesConsumed`, `caloriesTarget`, `proteinConsumed`, `proteinTarget`, etc. (from `DashboardViewModel`).
            *   Design: Display four animated, concentric rings for Calories, Protein, Carbs, Fat.
            *   Use specified `LinearGradient` fills (from `AppColors`).
            *   Animate ring progress from 0 to current value on appear.
            *   Display text labels for each macro and its progress (e.g., "Protein: 75/150g").
        *   Acceptance Criteria: View created, displays macro rings and text, rings are animated.
    *   **Agent Task 6.4.2 (Macro Ring Animation Helper - Optional):**
        *   Instruction: "Create a reusable SwiftUI view `AnimatedRingView.swift` if the ring logic is complex."
        *   Details: Takes progress (0.0 to 1.0), color/gradient, size, stroke width as parameters. Uses `AnimatablePair` or similar for smooth animation.
        *   Acceptance Criteria: Reusable animated ring component created.
    *   **Agent Task 6.4.3 (Nutrition Data Logic in ViewModel):**
        *   Instruction: "Implement `private func fetchNutritionData()` in `DashboardViewModel.swift`."
        *   Details:
            *   Fetch all `FoodEntry` entities for the `user` for today's date from SwiftData.
            *   Iterate through their `items` and sum up `calories`, `proteinGrams`, `carbGrams`, `fatGrams`.
            *   Update the corresponding `@Published` properties in the ViewModel.
            *   (Targets): For now, use hardcoded targets. Later, these could come from user's goals/`OnboardingProfile`.
        *   Acceptance Criteria: ViewModel method correctly fetches and calculates consumed macros.

---

**Task 6.5: Implement Placeholder Recovery & Performance Cards**
    *   **Agent Task 6.5.1:**
        *   Instruction: "Create `RecoveryCardView.swift` in `AirFit/Modules/Dashboard/Views/Cards/`."
        *   Details:
            *   Input: `recoveryScore: Double?` (from `DashboardViewModel`).
            *   Display "Recovery" title and the score (e.g., "75%").
            *   Simple visual representation (e.g., a progress bar or colored circle).
            *   (Placeholder: Actual calculation of recovery score is complex and likely a future task or derived from HealthKit's readiness scores if available).
        *   Acceptance Criteria: Placeholder recovery card created.
    *   **Agent Task 6.5.2:**
        *   Instruction: "Create `PerformanceCardView.swift` in `AirFit/Modules/Dashboard/Views/Cards/`."
        *   Details:
            *   Input: `performanceTrend: String?` (from `DashboardViewModel`).
            *   Display "Performance" title and the trend string (e.g., "Trending Up").
            *   Simple icon representing trend (e.g., up arrow).
            *   (Placeholder: Actual performance trend analysis is a future complex AI task).
        *   Acceptance Criteria: Placeholder performance card created.
    *   **Agent Task 6.5.3 (Contextual Data Logic in ViewModel):**
        *   Instruction: "Implement `private func fetchContextualData()` in `DashboardViewModel.swift`."
        *   Details:
            *   Call `contextAssembler.assembleSnapshot(modelContext: modelContext)`.
            *   Update `viewModel.recoveryScore` from the snapshot (e.g., using `hrv` or a placeholder logic for now).
            *   Update `viewModel.performanceTrend` with placeholder data.
        *   Acceptance Criteria: ViewModel method fetches snapshot and updates relevant properties.

---

**Task 6.6: Final Review & Commit**
    *   **Agent Task 6.6.1:**
        *   Instruction: "Review all Dashboard views and `DashboardViewModel` for correctness, adherence to design, data binding, data fetching logic, and interaction with other services (mocked or real)."
        *   Acceptance Criteria: All components function as intended, UI is clean, data is displayed correctly.
    *   **Agent Task 6.6.2:**
        *   Instruction: "Ensure the `DashboardView` is correctly integrated into the main app flow (e.g., displayed after successful onboarding, as set up in Module 3)."
        *   Acceptance Criteria: Navigation to Dashboard works.
    *   **Agent Task 6.6.3:**
        *   Instruction: "Stage all new and modified files related to the Dashboard module."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 6.6.4:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Implement Dashboard UI with Morning Greeting, Nutrition, and placeholder cards".
        *   Acceptance Criteria: Git history shows the new commit. Project builds and runs, displaying the dashboard.

**Task 6.7: Add Unit & UI Tests**
    *   **Agent Task 6.7.1 (DashboardViewModel Unit Tests):**
        *   Instruction: "Create `DashboardViewModelTests.swift` in `AirFitTests/`."
        *   Details: Use mocks for `CoachEngine` and `ContextAssembler` with an in-memory container following `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 6.7.2 (Dashboard UI Tests):**
        *   Instruction: "Create `DashboardUITests.swift` in `AirFitUITests/` to validate card interactions."
        *   Details: Verify greeting, macro ring animations, and navigation using accessibility identifiers.
        *   Acceptance Criteria: UI tests compile and pass.

---

**4. Acceptance Criteria for Module Completion**

*   `DashboardView` displays a `LazyVGrid` of cards.
*   `DashboardViewModel` fetches and provides data for all cards, including an AI-generated morning greeting (via `CoachEngine` stub/mock) and calculated nutrition summaries.
*   The Morning Greeting Card displays the AI message and includes a functional Energy Logging Micro-Interaction.
*   The Nutrition Card displays animated macro rings for Calories, Protein, Carbs, and Fat.
*   Placeholder Recovery and Performance cards display basic information.
*   The UI adheres to the "clean, classy & premium" design principles.
*   All code passes SwiftLint checks.
*   Unit tests for `DashboardViewModel` and UI tests for `DashboardView` are implemented and pass.

**5. Code Style Reminders for this Module**

*   Break down complex card views into smaller, reusable SwiftUI components.
*   Ensure `DashboardViewModel` handles data loading states (e.g., `isLoading`) to provide good UX.
*   Use asynchronous patterns (`async/await`, `TaskGroup`) in the ViewModel for efficient data fetching.
*   Animations for macro rings should be smooth and performant.
*   Use `AppLogger` for logging data fetching and AI interaction events.

---

This Dashboard module is a significant piece of UI work and also starts to tie together several backend services (even if some are mocked initially). The AI-generated morning greeting is the first user-visible output of the persona engine.
