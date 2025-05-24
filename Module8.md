**Modular Sub-Document 8: Nutrition Logging Module (UI, Voice, AI Parsing)**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `FoodEntry`, `FoodItem`, `User`, `MealType` enum.
    *   (For AI Parsing) Completion of Modular Sub-Document 5: AI Persona Engine & CoachEngine – specifically the `parseAndLogComplexNutrition` High-Value Function capability.
    *   (For Voice Input) An on-device speech recognition service wrapper (e.g., `WhisperServiceWrapper` - to be detailed in Services Layer - Part 1, Module F, but we can define its interface here).
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To enable users to log their nutritional intake easily and accurately, with a primary focus on voice-first input for complex meals and AI-powered parsing to structure the data. It also supports simpler, manual entry methods.
*   **Responsibilities:**
    *   Providing UI for initiating nutrition logging (e.g., selecting meal type, triggering voice input).
    *   Capturing audio input for voice logging.
    *   Interacting with an on-device speech recognition service (`WhisperServiceWrapper`) to transcribe audio to text.
    *   Orchestrating the parsing of transcribed text:
        *   Attempting local parsing for very simple, high-confidence entries (e.g., "Log an apple").
        *   Sending complex transcriptions to the `CoachEngine` to invoke the `parseAndLogComplexNutrition` AI function.
    *   Displaying AI-parsed food items to the user for confirmation and quick editing.
    *   Saving structured `FoodEntry` and associated `FoodItem` entities to SwiftData.
    *   Providing a UI to view and manually add/edit food entries and items.
*   **Key Components within this Module:**
    *   `NutritionLoggingView.swift` (Main UI for initiating logging) in `AirFit/Modules/Nutrition/Views/`.
    *   `VoiceInputView.swift` (UI for hold-to-speak recording) in `AirFit/Modules/Nutrition/Views/`.
    *   `FoodItemConfirmationView.swift` (UI to confirm/edit AI-parsed items) in `AirFit/Modules/Nutrition/Views/`.
    *   `ManualFoodEntryView.swift` (UI for manual item-by-item logging) in `AirFit/Modules/Nutrition/Views/`.
    *   `NutritionLogViewModel.swift` (ObservableObject) in `AirFit/Modules/Nutrition/ViewModels/`.
    *   `NutritionLogOrchestrator.swift` (Logic for deciding parsing strategy) in `AirFit/Modules/Nutrition/Logic/` or within the ViewModel.
    *   `WhisperServiceWrapperProtocol.swift` and a mock implementation (actual implementation in Services Layer module).

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) – UI/UX details for nutrition logging.
    *   Modular Sub-Document 1: `AppColors`, `AppFonts`, `AppConstants`, `AppLogger`.
    *   Modular Sub-Document 2: `FoodEntry`, `FoodItem`, `User`, `MealType` enum.
    *   Modular Sub-Document 5: `CoachEngine` (for `parseAndLogComplexNutrition` function).
    *   (Interface for) `WhisperServiceWrapperProtocol`.
*   **Outputs:**
    *   Functionality for users to log their nutrition via voice or manual entry.
    *   `FoodEntry` and `FoodItem` records persisted in SwiftData.
    *   Updated macro totals (implicitly, as Dashboard's NutritionCard reads this data).

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 8.0: Define Speech Service Interface & Mock**
    *   **Agent Task 8.0.1:**
        *   Instruction: "Create `WhisperServiceWrapperProtocol.swift` in `AirFit/Services/Platform/` (or a dedicated `AirFit/Services/Speech/` folder)."
        *   Details: Define the protocol for the on-device speech transcription service.
            ```swift
            // AirFit/Services/Platform/WhisperServiceWrapperProtocol.swift
            import Foundation
            import Combine // Or use async/await for transcription result

            enum TranscriptionError: Error {
                case unavailable
                case permissionDenied
                case failedToStart
                case processingError(Error?)
            }

            protocol WhisperServiceWrapperProtocol {
                var isAvailable: CurrentValueSubject<Bool, Never> { get } // Or a simple Bool property
                var isTranscribing: CurrentValueSubject<Bool, Never> { get }

                func requestPermission(completion: @escaping (Bool) -> Void)
                func startTranscription(resultHandler: @escaping (Result<String, TranscriptionError>) -> Void)
                func stopTranscription() // Transcription result delivered via resultHandler
            }
            ```
        *   Acceptance Criteria: Protocol defined.
    *   **Agent Task 8.0.2:**
        *   Instruction: "Create `MockWhisperServiceWrapper.swift` in a `Tests/Mocks/` directory (or similar testing support location)."
        *   Details: Implement `WhisperServiceWrapperProtocol` with mock behavior.
            ```swift
            // Tests/Mocks/MockWhisperServiceWrapper.swift
            import Foundation
            import Combine
            // Assuming WhisperServiceWrapperProtocol is accessible here (e.g. via @testable import AirFit or by being in same target)

            class MockWhisperServiceWrapper: WhisperServiceWrapperProtocol {
                var isAvailable = CurrentValueSubject<Bool, Never>(true)
                var isTranscribing = CurrentValueSubject<Bool, Never>(false)
                var mockTranscript: String = "For lunch I had a large salad with grilled chicken, mixed greens, tomatoes, cucumber, and a light vinaigrette."
                var permissionGranted: Bool = true
                private var currentResultHandler: ((Result<String, TranscriptionError>) -> Void)?

                func requestPermission(completion: @escaping (Bool) -> Void) {
                    completion(permissionGranted)
                }

                func startTranscription(resultHandler: @escaping (Result<String, TranscriptionError>) -> Void) {
                    guard permissionGranted else {
                        resultHandler(.failure(.permissionDenied))
                        return
                    }
                    isTranscribing.send(true)
                    self.currentResultHandler = resultHandler
                    AppLogger.log("MockWhisperService: Transcription started.", category: .general)
                    // Simulate transcription completion after a delay in stopTranscription
                }

                func stopTranscription() {
                    isTranscribing.send(false)
                    AppLogger.log("MockWhisperService: Transcription stopped.", category: .general)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Simulate processing delay
                        if let handler = self.currentResultHandler {
                            handler(.success(self.mockTranscript))
                        }
                        self.currentResultHandler = nil
                    }
                }
            }
            ```        *   Acceptance Criteria: Mock service created and implements the protocol.

---

**Task 8.1: Nutrition Logging ViewModel Setup**
    *   **Agent Task 8.1.1:**
        *   Instruction: "Create `NutritionLogViewModel.swift` in `AirFit/Modules/Nutrition/ViewModels/`."
        *   Details:
            *   Define an `ObservableObject` class `NutritionLogViewModel`.
            *   Dependencies (constructor injection):
                *   `modelContext: ModelContext`
                *   `coachEngine: CoachEngine`
                *   `whisperService: WhisperServiceWrapperProtocol`
                *   `user: User` (current user)
            *   `@Published` properties:
                *   `currentMealType: MealType = .snack`
                *   `isRecording: Bool = false` (reflects `whisperService.isTranscribing`)
                *   `transcribedText: String = ""`
                *   `parsedFoodItems: [ParsedFoodItemDisplay] = []` (Define `ParsedFoodItemDisplay` struct: `id: UUID`, `name: String`, `quantity: String`, `unit: String`, `calories: String` - all strings for easy editing in UI before conversion).
                *   `isProcessingAIText: Bool = false`
                *   `showConfirmationScreen: Bool = false`
                *   `errorMessage: String?`
            *   Methods:
                *   `func requestMicrophonePermission()`
                *   `func toggleRecording()` (calls `whisperService.start/stopTranscription`)
                *   `private func handleTranscriptionResult(_ result: Result<String, TranscriptionError>)`
                *   `private func processTranscribedTextForParsing()`
                *   `func confirmAndSaveLoggedItems()`
                *   `func discardParsedItems()`
                *   `func updateParsedItem(id: UUID, updatedItem: ParsedFoodItemDisplay)`
                *   `func addManualFoodItem()` (for manual entry flow)
        *   Acceptance Criteria: `NutritionLogViewModel.swift` structure created with properties and method stubs.
    *   **Agent Task 8.1.2 (Define ParsedFoodItemDisplay):**
        *   Instruction: "Define the `ParsedFoodItemDisplay` struct, potentially within `NutritionLogViewModel.swift` or a shared Models file for this module."
        *   Details:
            ```swift
            struct ParsedFoodItemDisplay: Identifiable, Equatable { // Equatable for diffing if needed
                let id: UUID // To identify for editing
                var name: String
                var quantity: String // Keep as String for TextField binding
                var unit: String
                var calories: String // Keep as String
                // Add protein, carbs, fat as strings if editable at this stage
            }
            ```
        *   Acceptance Criteria: Struct defined.

---

**Task 8.2: UI for Initiating Logging & Voice Input**
    *   **Agent Task 8.2.1:**
        *   Instruction: "Create `NutritionLoggingView.swift` in `AirFit/Modules/Nutrition/Views/`."
        *   Details:
            *   This is the main entry point for logging nutrition.
            *   Allow selection of `MealType` using a `Picker` bound to `viewModel.currentMealType`.
            *   Button to navigate to manual entry (`ManualFoodEntryView`).
            *   Prominent "Hold to Speak" button that navigates to or presents `VoiceInputView`.
            *   Display `viewModel.errorMessage` if present.
            *   Inject `NutritionLogViewModel`.
        *   Acceptance Criteria: Main logging initiation view created.
    *   **Agent Task 8.2.2:**
        *   Instruction: "Create `VoiceInputView.swift` in `AirFit/Modules/Nutrition/Views/`."
        *   Details:
            *   Modal or pushed view.
            *   Large microphone button.
            *   On `.onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in ... }, perform: { viewModel.toggleRecording() })` on the button:
                *   When `isPressing` becomes `true` and `!viewModel.isRecording`: call `viewModel.toggleRecording()` to start.
                *   When gesture ends (finger lifted) and `viewModel.isRecording`: call `viewModel.toggleRecording()` to stop.
            *   Visual feedback for recording state (e.g., button changes appearance, animation).
            *   Display "Listening..." or similar text while `viewModel.isRecording`.
            *   Display `viewModel.transcribedText` as it comes in (if service supports live transcription updates, else show after stop).
            *   Once transcription is complete and `viewModel.showConfirmationScreen` becomes true, navigate/present `FoodItemConfirmationView`.
            *   Handle `viewModel.errorMessage`.
        *   Acceptance Criteria: Voice input view with hold-to-speak functionality created.

---

**Task 8.3: Logic for Transcription and Parsing Orchestration**
    *   **Agent Task 8.3.1 (Microphone Permission & Recording Logic in ViewModel):**
        *   Instruction: "Implement `requestMicrophonePermission()` and `toggleRecording()` in `NutritionLogViewModel.swift`."
        *   Details:
            *   `requestMicrophonePermission()`: Calls `whisperService.requestPermission()`.
            *   `toggleRecording()`:
                *   If `viewModel.isRecording` is true, call `whisperService.stopTranscription()`.
                *   If false, reset `transcribedText`, `parsedFoodItems`, `errorMessage`. Then call `whisperService.startTranscription { result in self.handleTranscriptionResult(result) }`.
            *   Subscribe to `whisperService.isTranscribing` to update `viewModel.isRecording`.
        *   Acceptance Criteria: Methods correctly interact with `WhisperServiceWrapperProtocol`.
    *   **Agent Task 8.3.2 (Handle Transcription Result in ViewModel):**
        *   Instruction: "Implement `private func handleTranscriptionResult(_ result: Result<String, TranscriptionError>)` in `NutritionLogViewModel.swift`."
        *   Details:
            *   Switch on `result`:
                *   `.success(let text)`: Set `viewModel.transcribedText = text`. Call `viewModel.processTranscribedTextForParsing()`.
                *   `.failure(let error)`: Set `viewModel.errorMessage` appropriately. Log error.
        *   Acceptance Criteria: Transcription results are handled, and processing is triggered.
    *   **Agent Task 8.3.3 (Process Transcribed Text in ViewModel):**
        *   Instruction: "Implement `private func processTranscribedTextForParsing()` in `NutritionLogViewModel.swift`."
        *   Details:
            1.  Set `isProcessingAIText = true`.
            2.  **(Simple Local Parser - Stub for now):** Implement basic local check. E.g., if `transcribedText.lowercased() == "log an apple"`, directly create a `ParsedFoodItemDisplay` for an apple and add to `viewModel.parsedFoodItems`. Set `showConfirmationScreen = true`. `isProcessingAIText = false`. Return.
            3.  **(Complex AI Parsing):** If not caught by local parser:
                *   Call `coachEngine.parseAndLogComplexNutrition(naturalLanguageInput: transcribedText, mealType: currentMealType.rawValue)` (This is a new method to add to `CoachEngine` that specifically invokes the `parseAndLogComplexNutrition` function call to the LLM).
                *   This `CoachEngine` method should return `[ParsedFoodItem]` or similar structured data from the LLM's function call result. This requires the `CoachEngine` to:
                    *   Make an LLM call with the `parseAndLogComplexNutrition` function available.
                    *   Receive the `AIFunctionCall` from the LLM.
                    *   The "arguments" of this function call from the LLM will contain the structured list of food items.
                    *   `CoachEngine` then decodes these arguments into Swift structs (e.g., an array of `struct LLMParsedFoodItem { var name: String; var quantity: Double?; ... }`).
                *   Convert `[LLMParsedFoodItem]` to `[ParsedFoodItemDisplay]` (converting numbers to strings for UI).
                *   Update `viewModel.parsedFoodItems`.
                *   Set `viewModel.showConfirmationScreen = true`.
                *   Set `viewModel.isProcessingAIText = false`.
                *   Handle errors (e.g., if LLM fails to parse), update `errorMessage`.
        *   Acceptance Criteria: Logic to decide between local and AI parsing (stubbed) and to (mock) call `CoachEngine` for AI parsing is implemented. `parsedFoodItems` is updated.

---

**Task 8.4: UI for Confirmation and Editing**
    *   **Agent Task 8.4.1:**
        *   Instruction: "Create `FoodItemConfirmationView.swift` in `AirFit/Modules/Nutrition/Views/`."
        *   Details:
            *   Presented when `viewModel.showConfirmationScreen` is true.
            *   Display a `List` or `ForEach` of `viewModel.parsedFoodItems`.
            *   Each row should allow editing of `name`, `quantity`, `unit`, `calories` (using `TextFields` bound to the properties of `ParsedFoodItemDisplay`). This implies `ParsedFoodItemDisplay` items in the ViewModel's array need to be mutable or easily replaceable.
            *   Buttons: "Add Item" (navigates to `ManualFoodEntryView` to add one more), "Save Log," "Discard."
            *   "Save Log" calls `viewModel.confirmAndSaveLoggedItems()`.
            *   "Discard" calls `viewModel.discardParsedItems()` and dismisses the view.
        *   Acceptance Criteria: Confirmation view displays parsed items and allows editing and actions.

---

**Task 8.5: Saving Logic in ViewModel**
    *   **Agent Task 8.5.1:**
        *   Instruction: "Implement `func confirmAndSaveLoggedItems()` and `func discardParsedItems()` in `NutritionLogViewModel.swift`."
        *   Details:
            *   `discardParsedItems()`: Clear `parsedFoodItems`, `transcribedText`, set `showConfirmationScreen = false`.
            *   `confirmAndSaveLoggedItems()`:
                1.  Create a new `FoodEntry` object: set `loggedAt = Date()`, `mealType = currentMealType.rawValue`, `rawTranscript = transcribedText` (if from voice), AI parsing metadata (if from AI). Assign to `user`.
                2.  For each `ParsedFoodItemDisplay` in `parsedFoodItems`:
                    *   Convert string properties (quantity, calories) back to `Double`. Handle potential conversion errors.
                    *   Create a new `FoodItem` object, populating its fields.
                    *   Add the new `FoodItem` to the `FoodEntry`'s `items` relationship.
                3.  Insert the `FoodEntry` (which cascades to `FoodItem`s) into `modelContext`.
                4.  Save `modelContext`. Handle errors.
                5.  Call `discardParsedItems()` to reset state and dismiss confirmation view.
                *   Log success/failure.
        *   Acceptance Criteria: Methods correctly save data to SwiftData or discard pending changes.

---

**Task 8.6: Manual Food Entry (Basic)**
    *   **Agent Task 8.6.1:**
        *   Instruction: "Create `ManualFoodEntryView.swift` in `AirFit/Modules/Nutrition/Views/`."
        *   Details:
            *   Allows user to add one `FoodItem` at a time.
            *   Fields for name, quantity, unit, calories, protein, carbs, fat (all `TextFields`).
            *   "Save Item" button: Creates a `ParsedFoodItemDisplay` from the input and adds it to `viewModel.parsedFoodItems`. Dismisses itself and returns to `FoodItemConfirmationView` (if that's the flow) or directly saves a single-item `FoodEntry`.
            *   (Simpler first version): This view could directly create and save a `FoodEntry` with a single `FoodItem` without going through the `parsedFoodItems` array if opened directly (not from confirmation screen).
        *   Acceptance Criteria: Basic manual food item entry view created.

---

**Task 8.7: Final Review & Commit**
    *   **Agent Task 8.7.1 (Review Full Flow):**
        *   Instruction: "Review the entire nutrition logging flow: voice input, (mocked) transcription, (mocked) AI parsing, confirmation/editing, and saving. Check ViewModel logic, UI bindings, and data persistence."
        *   Acceptance Criteria: The end-to-end flow is logically sound, and components interact as expected.
    *   **Agent Task 8.7.2 (Commit):**
        *   Instruction: "Stage and commit all new and modified files for this module."
        *   Details: Commit message: "Feat: Implement Nutrition Logging module with voice input and AI parsing stubs".
        *   Acceptance Criteria: All changes committed. Project builds.

---

**4. Acceptance Criteria for Module Completion**

*   User can initiate nutrition logging, select a meal type.
*   Voice input can be captured using a hold-to-speak interface (interacting with a mocked `WhisperServiceWrapper`).
*   Transcribed text is (mock) processed by `CoachEngine` for complex parsing or handled by a stubbed local parser.
*   AI-parsed (or locally parsed) food items are displayed in a confirmation view, allowing for edits.
*   Confirmed food items are saved as `FoodEntry` and `FoodItem` entities in SwiftData.
*   A basic manual food entry option is available.
*   The UI adheres to design principles. All code passes SwiftLint.

**5. Code Style Reminders for this Module**

*   ViewModel should clearly manage states like `isRecording`, `isProcessingAIText`, `showConfirmationScreen`.
*   Error handling is important for transcription, AI parsing, and data conversion/saving.
*   Keep parsing logic in `NutritionLogOrchestrator` or dedicated ViewModel methods separate from view code.
*   Ensure `ParsedFoodItemDisplay` uses `String` for editable fields and that conversion to/from numeric types for saving/display is robust.

---

This module introduces voice interaction and a significant AI function call. The interaction between the `NutritionLogViewModel`, the (mocked) `WhisperServiceWrapper`, and the `CoachEngine` is key. The confirmation/editing step is crucial for user trust when AI is involved in parsing.
