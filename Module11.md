**Modular Sub-Document 11: Settings Module (UI & Logic)**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `User`, `OnboardingProfile`.
    *   Completion of Modular Sub-Document 9: Notifications & Engagement Engine – `NotificationManager` (for notification preferences).
    *   Completion of Modular Sub-Document 10: Services Layer - Configurable AI API Client – `APIKeyManager`, `AIProvider` enum (for AI provider settings).
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To provide users with a centralized interface to manage their application preferences, AI coach persona settings, API key configurations, notification settings, and access other utility functions like data export and privacy information.
*   **Responsibilities:**
    *   Displaying current user settings and preferences.
    *   Allowing users to modify their AI coach's persona (linking back to aspects of the `OnboardingProfile`).
    *   Providing UI for users to input and manage API keys for different LLM providers (`APIKeyManager`).
    *   Allowing users to select their active LLM provider and model (`AIAPIService` configuration).
    *   Managing notification preferences (interacting with `NotificationManager` and system settings).
    *   Allowing users to change their preferred units (imperial/metric).
    *   Providing options for data export.
    *   Displaying links to privacy policy, terms of service, and help/support.
    *   (Future) Option for FaceID/Passcode app lock.
*   **Key Components within this Module:**
    *   `SettingsListView.swift` (Main navigation view for settings sections) in `AirFit/Modules/Settings/Views/`.
    *   `SettingsViewModel.swift` (ObservableObject) in `AirFit/Modules/Settings/ViewModels/`.
    *   Individual setting screen views (e.g., `AIPersonaSettingsView.swift`, `APIKeyManagementView.swift`, `NotificationSettingsView.swift`, `UnitsSettingsView.swift`, `DataManagementView.swift`) in `AirFit/Modules/Settings/Views/SubViews/`.

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Design Specification (v1.2) – UI/UX guidelines for settings screens.
    *   Modular Sub-Document 1: Core utilities, `AppColors`, `AppFonts`.
    *   Modular Sub-Document 2: `User`, `OnboardingProfile` models (for reading and updating preferences).
    *   Modular Sub-Document 9: `NotificationManager` (for getting/setting notification permissions/preferences).
    *   Modular Sub-Document 10: `APIKeyManager`, `AIProvider` enum, `AIAPIServiceProtocol` (for configuring the active AI service).
    *   (Implicit) `OnboardingViewModel` or similar logic if persona refinement reuses parts of the onboarding flow.
*   **Outputs:**
    *   User-configurable application settings.
    *   Updated `User` and `OnboardingProfile` entities in SwiftData with new preferences.
    *   Securely stored API keys via `APIKeyManager`.
    *   Configured `AIAPIService` with user's chosen provider/model.

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 11.0: Settings ViewModel Setup**
    *   **Agent Task 11.0.1:**
        *   Instruction: "Create `SettingsViewModel.swift` in `AirFit/Modules/Settings/ViewModels/`."
        *   Details:
            *   Define an `ObservableObject` class `SettingsViewModel`.
            *   Dependencies (constructor injection or environment):
                *   `modelContext: ModelContext`
                *   `user: User` (the current logged-in user)
                *   `apiKeyManager: APIKeyManager`
                *   `aiApiService: AIAPIServiceProtocol`
                *   `notificationManager: NotificationManager`
            *   `@Published` properties for editable settings:
                *   `preferredUnits: String` (from `user.preferredUnits`)
                *   `selectedAIProvider: AIProvider` (placeholder, needs to be loaded/saved, e.g., via UserDefaults or a new User preference field)
                *   `selectedAIModelIdentifier: String` (placeholder)
                *   `apiKeys: [AIProvider: String]` (dictionary to hold keys entered in UI, not directly from Keychain for display)
                *   `notificationsEnabledSystem: Bool` (from `notificationManager.getNotificationSettings`)
                *   `absenceResponsePreference: String` (from `user.onboardingProfile.communicationPreferencesData`)
                *   `celebrationStylePreference: String` (from `user.onboardingProfile.communicationPreferencesData`)
                *   (Other persona-related settings if they are directly editable without re-running full onboarding)
            *   Methods:
                *   `func loadCurrentSettings()`: Populates published properties from `User`, `OnboardingProfile`, `APIKeyManager` (just to check if key exists, not value), system notification settings.
                *   `func savePreferredUnits()`
                *   `func saveAIProviderSelection(provider: AIProvider, modelIdentifier: String)`: Saves selection (e.g., to UserDefaults or User.preference), then calls `aiApiService.configure(...)`.
                *   `func saveAPIKey(forProvider provider: AIProvider, key: String)`: Calls `apiKeyManager.saveAPIKey(...)`.
                *   `func deleteAPIKey(forProvider provider: AIProvider)`: Calls `apiKeyManager.deleteAPIKey(...)`.
                *   `func openAppSettingsForNotifications()`: Opens the system settings for the app.
                *   `func saveCommunicationPreferences()`: Updates `OnboardingProfile.communicationPreferencesData`.
                *   `func initiateDataExport()`: (Stub for now, logs intent).
        *   Acceptance Criteria: `SettingsViewModel.swift` structure created with properties and method stubs.

---

**Task 11.1: Main Settings Navigation View**
    *   **Agent Task 11.1.1:**
        *   Instruction: "Create `SettingsListView.swift` in `AirFit/Modules/Settings/Views/`."
        *   Details:
            *   Use a `NavigationView` (or `NavigationStack`) with a `List` or `Form`.
            *   Sections: "AI Coach," "API Configuration," "App Preferences," "Data & Privacy," "About."
            *   Each row in a section will be a `NavigationLink` to a specific settings sub-view.
            *   Example Rows:
                *   AI Coach: "Customize Persona" (navigates to `AIPersonaSettingsView`), "Communication Style" (navigates to `CommunicationSettingsView`).
                *   API Configuration: "Manage API Keys & Models" (navigates to `APIConfigurationView`).
                *   App Preferences: "Units" (navigates to `UnitsSettingsView`), "Notifications" (navigates to `NotificationSettingsView`).
                *   Data & Privacy: "Export My Data" (triggers `viewModel.initiateDataExport()`), "Privacy Policy" (opens URL).
                *   About: "Version [AppVersion]", "Acknowledgements".
            *   Inject/ObservedObject `SettingsViewModel`. Call `viewModel.loadCurrentSettings()` on appear.
            ```swift
            // AirFit/Modules/Settings/Views/SettingsListView.swift
            import SwiftUI

            struct SettingsListView: View {
                @StateObject var viewModel: SettingsViewModel // Initialized with dependencies

                var body: some View {
                    NavigationView { // Or NavigationStack
                        Form {
                            Section("AI Coach") {
                                NavigationLink("Customize Persona", destination: AIPersonaSettingsView(viewModel: viewModel)) // Placeholder View
                                NavigationLink("Communication Style", destination: CommunicationSettingsView(viewModel: viewModel)) // Placeholder View
                            }

                            Section("API Configuration") {
                                NavigationLink("Manage API Keys & Models", destination: APIConfigurationView(viewModel: viewModel)) // Placeholder View
                            }

                            Section("App Preferences") {
                                NavigationLink("Units", destination: UnitsSettingsView(viewModel: viewModel)) // Placeholder View
                                NavigationLink("Notifications", destination: NotificationSettingsView(viewModel: viewModel)) // Placeholder View
                            }
                            
                            Section("Data & Privacy") {
                                Button("Export My Data") {
                                    viewModel.initiateDataExport()
                                }
                                Button("Privacy Policy") { /* Open URL */ }
                            }

                            Section("About") {
                                HStack {
                                    Text("Version")
                                    Spacer()
                                    Text(AppConstants.appVersionString) // Add appVersionString to AppConstants
                                }
                                // NavigationLink("Acknowledgements", destination: AcknowledgementsView())
                            }
                        }
                        .navigationTitle("Settings")
                        .onAppear {
                            viewModel.loadCurrentSettings()
                        }
                    }
                }
            }
            ```
        *   Acceptance Criteria: Main settings navigation view created with sections and `NavigationLink` placeholders.

---

**Task 11.2: AI Persona & Communication Settings UI**
    *   **Agent Task 11.2.1:**
        *   Instruction: "Create `AIPersonaSettingsView.swift` in `AirFit/Modules/Settings/Views/SubViews/`."
        *   Details:
            *   This view allows users to potentially re-trigger parts of the onboarding flow or directly edit some high-level persona aspects.
            *   Option 1 (Simple): Display current persona summary (e.g., "Your coach is primarily Analytical & Insightful..."). Button: "Retake Persona Quiz" (navigates back to `OnboardingFlowView`, perhaps with a flag to indicate it's a refinement pass).
            *   Option 2 (Advanced): Allow direct editing of some `OnboardingProfile` elements if deemed safe without full re-onboarding (e.g., adjust coaching style blend sliders from Module 3's `CoachingStyleView` if that view is made reusable). This is more complex.
            *   **Focus on Option 1 (Retake Persona Quiz) for the initial AI agent task.**
            *   Binds to relevant `SettingsViewModel` properties/methods.
        *   Acceptance Criteria: View for initiating persona refinement created.
    *   **Agent Task 11.2.2:**
        *   Instruction: "Create `CommunicationSettingsView.swift` in `AirFit/Modules/Settings/Views/SubViews/`."
        *   Details:
            *   Allow editing of `absenceResponsePreference` and `celebrationStylePreference`.
            *   Use `Picker` controls bound to `viewModel.absenceResponsePreference` and `viewModel.celebrationStylePreference`.
            *   Options for pickers should match those from Onboarding Flow v3.1, Screen 8.
            *   "Save" button calls `viewModel.saveCommunicationPreferences()`.
        *   Acceptance Criteria: View for editing communication preferences created and functional.

---

**Task 11.3: API Configuration UI**
    *   **Agent Task 11.3.1:**
        *   Instruction: "Create `APIConfigurationView.swift` in `AirFit/Modules/Settings/Views/SubViews/`."
        *   Details:
            *   `Picker` to select `AIProvider` (from `AIProvider.allCases`), bound to `viewModel.selectedAIProvider`.
            *   `TextField` for `currentModelIdentifier` for the selected provider, bound to `viewModel.selectedAIModelIdentifier`. (Provide common model IDs as suggestions if possible, or link to provider docs).
            *   For each `AIProvider` in `AIProvider.allCases`:
                *   Display provider name.
                *   `SecureField` to input API key, bound to a temporary state variable.
                *   Button "Save Key for [Provider Name]" calls `viewModel.saveAPIKey(forProvider: provider, key: enteredKey)`.
                *   Button "Delete Key for [Provider Name]" calls `viewModel.deleteAPIKey(forProvider: provider)` (show confirmation alert).
                *   Indicate if a key is currently set for that provider (e.g., by checking `viewModel.apiKeyManager.getAPIKey(forProvider: provider) != nil` in `loadCurrentSettings`).
            *   A master "Save Configuration" button that calls `viewModel.saveAIProviderSelection(...)` with the chosen provider and model ID.
        *   Acceptance Criteria: UI for managing API keys and selecting active provider/model created.

---

**Task 11.4: App Preferences UI (Units, Notifications)**
    *   **Agent Task 11.4.1:**
        *   Instruction: "Create `UnitsSettingsView.swift` in `AirFit/Modules/Settings/Views/SubViews/`."
        *   Details:
            *   `Picker` to select preferred units ("imperial", "metric"), bound to `viewModel.preferredUnits`.
            *   "Save" button calls `viewModel.savePreferredUnits()`.
        *   Acceptance Criteria: View for selecting units created.
    *   **Agent Task 11.4.2:**
        *   Instruction: "Create `NotificationSettingsView.swift` in `AirFit/Modules/Settings/Views/SubViews/`."
        *   Details:
            *   Display current system notification status (`viewModel.notificationsEnabledSystem`).
            *   Button "Open System Notification Settings" that calls `viewModel.openAppSettingsForNotifications()`.
            *   (Future scope: Add toggles for specific notification types if app has granular internal notification controls).
        *   Acceptance Criteria: View for managing notification settings created.

---

**Task 11.5: Data Management UI (Export)**
    *   **Agent Task 11.5.1:**
        *   Instruction: "Create `DataManagementView.swift` in `AirFit/Modules/Settings/Views/SubViews/` (or integrate 'Export My Data' directly into `SettingsListView`)."
        *   Details:
            *   Button "Export My Data".
            *   When tapped, call `viewModel.initiateDataExport()`.
            *   The ViewModel method will, for now, just log "Data export initiated."
            *   **(Future Implementation for Data Export):** This would involve:
                1.  Querying all relevant user data from SwiftData (`User`, `OnboardingProfile`, `Workout`, `FoodEntry`, etc.).
                2.  Serializing this data into a common format (e.g., JSON or CSV files, zipped).
                3.  Using `ShareLink` or `UIActivityViewController` to allow the user to save/share the exported data.
                *   This is a complex task; the agent's current scope is just the UI trigger and ViewModel stub.
        *   Acceptance Criteria: UI element to trigger data export exists and calls the ViewModel method.

---

**Task 11.6: Implement SettingsViewModel Logic**
    *   **Agent Task 11.6.1 (Loading & Saving Preferences):**
        *   Instruction: "Implement all methods in `SettingsViewModel.swift` related to loading and saving preferences."
        *   Details:
            *   `loadCurrentSettings()`: Fetch data from `user`, `user.onboardingProfile` (decode `communicationPreferencesData`), check `notificationManager.getNotificationSettings()`, load saved AI provider/model from UserDefaults (or a new User preference field). For API keys, just check existence with `apiKeyManager` to update UI, don't load actual keys into ViewModel published properties for security.
            *   `savePreferredUnits()`: Update `user.preferredUnits`, save `modelContext`.
            *   `saveAIProviderSelection()`: Save provider/model to UserDefaults/User.preference. Call `aiApiService.configure(provider: apiKey: apiKeyManager.getAPIKey(forProvider: provider) ?? "", modelIdentifier: modelIdentifier)`. Handle case where API key for selected provider is missing.
            *   `saveAPIKey()`: Call `apiKeyManager`. Re-configure `aiApiService` if this key is for the currently selected provider.
            *   `deleteAPIKey()`: Call `apiKeyManager`. If deleting key for active provider, potentially clear `aiApiService` config or prompt user.
            *   `saveCommunicationPreferences()`: Create `CommunicationPreferences` struct, encode to Data, update `user.onboardingProfile.communicationPreferencesData`, save `modelContext`.
            *   `openAppSettingsForNotifications()`: Use `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`.
        *   Acceptance Criteria: ViewModel methods correctly load and save all specified settings.
    *   **Agent Task 11.6.2 (App Version Display):**
        *   Instruction: "In `AppConstants.swift`, add `static var appVersionString: String`."
        *   Details: Get version from `Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"` and build number `Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"`.
        *   Acceptance Criteria: App version constant available.

---

**Task 11.7: Final Review & Commit**
    *   **Agent Task 11.7.1 (Review UI & Logic):**
        *   Instruction: "Review all Settings views and `SettingsViewModel` for UI correctness, data binding, saving/loading logic, and interaction with other services (`APIKeyManager`, `NotificationManager`, `AIAPIService`)."
        *   Acceptance Criteria: All settings screens are functional, data persists, and interactions with services are correct.
    *   **Agent Task 11.7.2 (Commit):**
        *   Instruction: "Stage and commit all new and modified files for this module."
        *   Details: Commit message: "Feat: Implement Settings module for user preferences and API configuration".
        *   Acceptance Criteria: All changes committed. Project builds and settings are usable.

**Task 11.8: Add Unit & UI Tests**
    *   **Agent Task 11.8.1 (SettingsViewModel Unit Tests):**
        *   Instruction: "Create `SettingsViewModelTests.swift` in `AirFitTests/`."
        *   Details: Mock `APIKeyManager` and `NotificationManager` following `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 11.8.2 (Settings UI Tests):**
        *   Instruction: "Create `SettingsUITests.swift` in `AirFitUITests/` covering navigation and form interactions."
        *   Details: Use accessibility identifiers on controls.
        *   Acceptance Criteria: UI tests compile and pass.

---

**4. Acceptance Criteria for Module Completion**

*   A navigable settings interface allows users to access various preference categories.
*   Users can view and modify AI persona communication preferences.
*   Users can securely input, manage, and delete API keys for supported LLM providers.
*   Users can select their preferred LLM provider and model, configuring the `AIAPIService`.
*   Users can change preferred measurement units.
*   Users can manage notification settings (linking to system settings).
*   A (stubbed) option for data export is present.
*   Links to privacy policy and app version are available.
*   All settings are persisted correctly.
*   UI adheres to design principles and code passes SwiftLint.
*   Unit tests for `SettingsViewModel` and UI tests for settings navigation are implemented and pass.

**5. Code Style Reminders for this Module**

*   Use `Form` for structuring settings screens where appropriate.
*   Ensure `SecureField` is used for API key input.
*   Provide clear user feedback when settings are saved or errors occur.
*   When modifying `OnboardingProfile` data, ensure it's done safely and the `modelContext` is saved.
*   For API keys, ViewModel should not hold the actual key strings in `@Published` properties for extended periods or after they are saved to Keychain. UI should re-fetch or use temporary state variables for input.

---

This module provides essential user control and customization. The API key management and AI provider selection are particularly important for your "vibe-coding" goal of letting users choose their backend.
