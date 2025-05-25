**Modular Sub-Document 4: HealthKit & Context Aggregation Module**

**Version:** 1.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – specifically `DailyLog` and potentially `Workout` if this module also saves HealthKit-derived workouts.
**Date:** May 24, 2025

**1. Module Overview**

*   **Purpose:** To manage all interactions with Apple's HealthKit, request user permissions for health data access, fetch relevant health metrics, and assemble this data (along with other contextual information) into a `HealthContextSnapshot`.
*   **Responsibilities:**
    *   Defining and managing the set of HealthKit data types the app requests.
    *   Implementing logic for requesting user authorization to read HealthKit data.
    *   Fetching various health metrics (e.g., sleep, heart rate, HRV, workouts, activity rings, body weight) from HealthKit.
    *   (Potentially) Subscribing to HealthKit background updates for key data types.
    *   Implementing the `ContextAssembler` service, which gathers data from `HealthKitManager`, in-app sources (like `DailyLog`), and other services (like `WeatherService`) to create the `HealthContextSnapshot`.
*   **Key Components within this Module:**
    *   `HealthKitManager.swift` (Service class) located in `AirFit/Services/Health/`.
    *   `ContextAssembler.swift` (Service class) located in `AirFit/Services/AI/` or a general `AirFit/Services/Context/` folder.
    *   `HealthContextSnapshot.swift` (Struct definition) located in `AirFit/Core/Models/` or `AirFit/Services/Context/`.
    *   Configuration for HealthKit entitlements and usage descriptions in `Info.plist`.

**2. Dependencies**

*   **Inputs:**
    *   AirFit App - Master Architecture Specification (v1.2) – for the definition of `HealthContextSnapshot` and understanding what data the AI needs.
    *   Modular Sub-Document 1: `AppLogger`, `AppConstants`.
    *   Modular Sub-Document 2: `DailyLog` model (for fetching subjective energy), `Workout` model (if saving HealthKit workouts directly).
    *   (Future) `WeatherServiceAPIClient` (from Services Layer - Part 1) for weather data.
*   **Outputs:**
    *   A `HealthKitManager` capable of requesting permissions and fetching data.
    *   A `ContextAssembler` capable of creating up-to-date `HealthContextSnapshot` instances.
    *   The app is correctly configured to request HealthKit permissions.

**3. Detailed Component Specifications & Agent Tasks**

*(AI Agent Tasks: These involve creating service classes, data structures, and configuring project settings for HealthKit.)*

---

**Task 4.0: Project Configuration for HealthKit**
    *   **Agent Task 4.0.1:**
        *   Instruction: "Enable the HealthKit capability for the 'AirFit' iOS target."
        *   Details: In Xcode, navigate to the project settings, select the "AirFit" iOS target, go to the "Signing & Capabilities" tab, and click the "+" button to add the "HealthKit" capability. Ensure "Clinical Health Records" is NOT selected unless explicitly required (it's not for this app spec).
        *   Acceptance Criteria: The HealthKit capability is listed for the iOS target. An `AirFit.entitlements` file is created or updated.
    *   **Agent Task 4.0.2:**
        *   Instruction: "Add required HealthKit usage description keys to the `Info.plist` file for the 'AirFit' iOS target."
        *   Details: Add the following keys with user-facing strings explaining why the app needs access. These strings must be clear and build user trust.
            *   `NSHealthShareUsageDescription`: (e.g., "AirFit uses your health data to provide personalized coaching insights, track your progress, and tailor workout and nutrition advice. Your data is used to understand your activity levels, sleep patterns, and other wellness metrics to help your AI Coach support your goals.")
            *   `NSHealthUpdateUsageDescription`: (e.g., "AirFit needs permission to save workouts you log in the app to Apple Health. This allows you to keep all your fitness data in one place and contributes to your activity rings.") *(Initially, we might only read data, but good to have if we plan to write workouts later).*
        *   Acceptance Criteria: The specified keys and their string values are present in the iOS target's `Info.plist`.

---

**Task 4.1: Define HealthContextSnapshot Struct**
    *   **Agent Task 4.1.1:**
        *   Instruction: "Create a new Swift file named `HealthContextSnapshot.swift` in `AirFit/Core/Models/` (or `AirFit/Services/Context/` if preferred for service-related DTOs)."
        *   Details: Define the `HealthContextSnapshot` struct. This struct will be populated by `ContextAssembler`.
            ```swift
            // AirFit/Core/Models/HealthContextSnapshot.swift
            import Foundation

            struct HealthContextSnapshot {
                // Timestamps
                let timestamp: Date // When this snapshot was generated
                let date: Date // The current day (start of day) for context

                // User-Logged Subjective Data (from DailyLog or live input)
                var subjectiveEnergyLevel: Int? // 1-5 scale
                var subjectiveMood: Int? // (Future placeholder) 1-5 scale
                var subjectiveStress: Int? // (Future placeholder) 1-5 scale

                // Environmental Data
                var currentWeatherCondition: String? // e.g., "Sunny", "Cloudy" (from WeatherService)
                var currentTemperatureCelsius: Double? // (from WeatherService)

                // HealthKit - Activity & Vitals
                var restingHeartRateBPM: Double?
                var heartRateVariabilitySDNNms: Double?
                var activeEnergyBurnedTodayKcal: Double?
                var stepCountToday: Int?
                var exerciseMinutesToday: Int?
                var standHoursToday: Int?

                // HealthKit - Sleep
                var lastNightSleepDurationHours: Double?
                var lastNightSleepEfficiencyPercentage: Double? // (Total time asleep / Total time in bed) * 100
                var lastNightBedtime: Date?
                var lastNightWaketime: Date?

                // HealthKit - Body Measurements
                var latestBodyWeightKg: Double?
                var latestBodyFatPercentage: Double? // (If available)

                // App-Specific Context
                var activeWorkoutNameInProgress: String? // If a workout is currently active in the app
                var timeSinceLastCoachInteractionMinutes: Int?
                var lastMealLogged: String? // e.g., "Breakfast, 2 hours ago" (summary)
                var upcomingPlannedWorkoutName: String? // Name of the next planned workout today/tomorrow

                // Recent Performance Snippets (Optional, could be fetched on demand by AI function call too)
                // var recentPRs: [String]? // e.g., ["Squat: 100kg (3 days ago)"]
                // var daysSinceLastWorkoutOfTypeX: [String: Int]? // e.g., ["Strength": 2, "Cardio": 1]

                init(timestamp: Date = Date(),
                     date: Date = Calendar.current.startOfDay(for: Date()),
                     subjectiveEnergyLevel: Int? = nil,
                     currentWeatherCondition: String? = nil,
                     currentTemperatureCelsius: Double? = nil,
                     restingHeartRateBPM: Double? = nil,
                     heartRateVariabilitySDNNms: Double? = nil,
                     activeEnergyBurnedTodayKcal: Double? = nil,
                     stepCountToday: Int? = nil,
                     exerciseMinutesToday: Int? = nil,
                     standHoursToday: Int? = nil,
                     lastNightSleepDurationHours: Double? = nil,
                     lastNightSleepEfficiencyPercentage: Double? = nil,
                     lastNightBedtime: Date? = nil,
                     lastNightWaketime: Date? = nil,
                     latestBodyWeightKg: Double? = nil,
                     latestBodyFatPercentage: Double? = nil,
                     activeWorkoutNameInProgress: String? = nil,
                     timeSinceLastCoachInteractionMinutes: Int? = nil,
                     lastMealLogged: String? = nil,
                     upcomingPlannedWorkoutName: String? = nil
                ) {
                    self.timestamp = timestamp
                    self.date = date
                    self.subjectiveEnergyLevel = subjectiveEnergyLevel
                    // Initialize all other properties...
                    self.currentWeatherCondition = currentWeatherCondition
                    self.currentTemperatureCelsius = currentTemperatureCelsius
                    self.restingHeartRateBPM = restingHeartRateBPM
                    self.heartRateVariabilitySDNNms = heartRateVariabilitySDNNms
                    self.activeEnergyBurnedTodayKcal = activeEnergyBurnedTodayKcal
                    self.stepCountToday = stepCountToday
                    self.exerciseMinutesToday = exerciseMinutesToday
                    self.standHoursToday = standHoursToday
                    self.lastNightSleepDurationHours = lastNightSleepDurationHours
                    self.lastNightSleepEfficiencyPercentage = lastNightSleepEfficiencyPercentage
                    self.lastNightBedtime = lastNightBedtime
                    self.lastNightWaketime = lastNightWaketime
                    self.latestBodyWeightKg = latestBodyWeightKg
                    self.latestBodyFatPercentage = latestBodyFatPercentage
                    self.activeWorkoutNameInProgress = activeWorkoutNameInProgress
                    self.timeSinceLastCoachInteractionMinutes = timeSinceLastCoachInteractionMinutes
                    self.lastMealLogged = lastMealLogged
                    self.upcomingPlannedWorkoutName = upcomingPlannedWorkoutName
                }
            }
            ```
        *   Acceptance Criteria: `HealthContextSnapshot.swift` struct is created and compiles. It includes all specified fields with appropriate optionality.

---

**Task 4.2: Implement HealthKitManager Service**
    *   **Agent Task 4.2.1:**
        *   Instruction: "Create a new Swift file named `HealthKitManager.swift` in `AirFit/Services/Health/`."
        *   Details:
            *   Import `HealthKit`.
            *   Define a class `HealthKitManager` (can be an `ObservableObject` if its state needs to be observed by UI, e.g., authorization status, but primarily a service).
            *   Private property: `let healthStore = HKHealthStore()`.
            *   Define sets for HealthKit types to read:
                ```swift
                private var readDataTypes: Set<HKObjectType> {
                    return [
                        HKObjectType.quantityType(forIdentifier: .heartRate)!,
                        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
                        HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
                        HKObjectType.quantityType(forIdentifier: .stepCount)!,
                        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                        HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
                        HKObjectType.quantityType(forIdentifier: .appleStandTime)!, // If using Apple's stand goal
                        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                        HKObjectType.quantityType(forIdentifier: .bodyMass)!, // Weight
                        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
                        HKObjectType.workoutType() // To read workouts logged by other apps
                        // Add other types as needed
                    ]
                }
                // Define writeDataTypes if the app will save data to HealthKit
                // private var writeDataTypes: Set<HKSampleType> = [
                // HKObjectType.workoutType(),
                // HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
                // ]
                ```
        *   Acceptance Criteria: `HealthKitManager.swift` created with `healthStore` and data type sets.
    *   **Agent Task 4.2.2 (Authorization):**
        *   Instruction: "Implement `requestHealthKitAuthorization(completion: @escaping (Bool, Error?) -> Void)` method in `HealthKitManager.swift`."
        *   Details:
            *   Check if HealthKit is available using `HKHealthStore.isHealthDataAvailable()`. If not, complete with `false` and an error.
            *   Call `healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes) { success, error in ... }`.
            *   Handle the completion block, log success/failure using `AppLogger`, and call the method's completion handler on the main thread.
        *   Acceptance Criteria: Authorization method correctly requests permissions for defined data types.
    *   **Agent Task 4.2.3 (Data Fetching Methods - Examples):**
        *   Instruction: "Implement asynchronous methods in `HealthKitManager.swift` to fetch key metrics. Start with: `fetchLatestRestingHeartRate() async -> Double?`, `fetchLatestHRV() async -> Double?`, `fetchTodayStepCount() async -> Int?`, `fetchLastNightSleepAnalysis() async -> (duration: Double?, efficiency: Double?, bedtime: Date?, waketime: Date?)`."
        *   Details (Example for one, agent to replicate pattern):
            ```swift
            // In HealthKitManager.swift

            func fetchLastNightSleepAnalysis() async -> (durationInHours: Double?, efficiencyPercentage: Double?, bedtime: Date?, waketime: Date?) {
                guard HKHealthStore.isHealthDataAvailable(),
                      healthStore.authorizationStatus(for: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!) == .sharingAuthorized else {
                    AppLogger.log("HealthKit not available or sleep analysis not authorized.", category: .healthKit, level: .info)
                    return (nil, nil, nil, nil)
                }

                let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
                let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                
                // Predicate for the last 24 hours (adjust as needed for "last night")
                let calendar = Calendar.current
                let endDate = Date()
                guard let startDate = calendar.date(byAdding: .hour, value: -24, to: endDate) else { // More robust "last night" logic might be needed
                    return (nil, nil, nil, nil)
                }
                let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

                return await withCheckedContinuation { continuation in
                    let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                        if let error = error {
                            AppLogger.error("Failed to fetch sleep samples: \(error.localizedDescription)", category: .healthKit, error: error)
                            continuation.resume(returning: (nil, nil, nil, nil))
                            return
                        }

                        guard let sleepSamples = samples as? [HKCategorySample] else {
                            continuation.resume(returning: (nil, nil, nil, nil))
                            return
                        }
                        
                        var totalTimeInBedSeconds: TimeInterval = 0
                        var totalTimeAsleepSeconds: TimeInterval = 0
                        var overallBedtime: Date? = Date.distantFuture // Find earliest start
                        var overallWaketime: Date? = Date.distantPast // Find latest end

                        for sample in sleepSamples {
                            let duration = sample.endDate.timeIntervalSince(sample.startDate)
                            totalTimeInBedSeconds += duration
                            if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue { // Includes InBed, Awake, Asleep, REM, Core, Deep
                                totalTimeAsleepSeconds += duration
                            }
                            if sample.startDate < overallBedtime! { overallBedtime = sample.startDate }
                            if sample.endDate > overallWaketime! { overallWaketime = sample.endDate }
                        }
                        
                        if totalTimeInBedSeconds == 0 {
                            continuation.resume(returning: (nil, nil, nil, nil))
                            return
                        }

                        let durationHours = totalTimeAsleepSeconds / 3600.0
                        let efficiency = (totalTimeAsleepSeconds / totalTimeInBedSeconds) * 100.0
                        
                        let finalBedtime = (overallBedtime == Date.distantFuture) ? nil : overallBedtime
                        let finalWaketime = (overallWaketime == Date.distantPast) ? nil : overallWaketime

                        continuation.resume(returning: (durationHours, efficiency, finalBedtime, finalWaketime))
                    }
                    healthStore.execute(query)
                }
            }
            // Agent to implement other fetch methods (RHR, HRV, Steps, Active Energy, Weight, etc.)
            // For quantity types, use HKStatisticsQuery or HKSampleQuery with appropriate predicates (e.g., for today, or latest sample).
            // Example for a quantity type (latest resting heart rate):
            // Use HKSampleQuery, sort by endDate descending, limit 1.
            // For daily totals (steps, active energy), use HKStatisticsQuery for sum over today's date range.
            ```
        *   Acceptance Criteria: Asynchronous fetching methods for specified HealthKit data are implemented, use appropriate query types, handle errors, and return optional values.
    *   **Agent Task 4.2.4 (Human/Designer Task - Refine "Last Night" Logic):**
        *   The logic for "last night's sleep" can be tricky (e.g., user goes to bed after midnight). Review and refine the predicate for `fetchLastNightSleepAnalysis` to accurately capture the primary sleep session preceding the current day. Common approach: query samples from (yesterday 12 PM) to (today 12 PM), then find the longest "inBed" session. This needs careful thought and testing.

---

**Task 4.3: Implement ContextAssembler Service**
    *   **Agent Task 4.3.1:**
        *   Instruction: "Create a new Swift file named `ContextAssembler.swift` in `AirFit/Services/Context/` (or `AirFit/Services/AI/`)."
        *   Details:
            *   Define a class `ContextAssembler`.
            *   It should have access to `HealthKitManager` (via dependency injection or as a shared instance).
            *   (Future) It will also access other services like `WeatherServiceAPIClient` and the app's SwiftData `ModelContext` (passed in or accessed via environment).
        *   Acceptance Criteria: `ContextAssembler.swift` class structure created.
    *   **Agent Task 4.3.2:**
        *   Instruction: "Implement an asynchronous method `assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot` in `ContextAssembler.swift`."
        *   Details:
            *   This method will call the various fetching methods on `HealthKitManager`.
            *   It will fetch subjective data (e.g., `subjectiveEnergyLevel`) from `DailyLog` for the current day using the provided `modelContext`. (Agent needs to implement a fetch request for `DailyLog` for today's date).
            *   (Stub for now) It will call (mocked) `WeatherService` to get weather data.
            *   (Stub for now) It will fetch app-specific context (active workout, last meal summary - this might require querying `Workout` and `FoodEntry` from `modelContext`).
            *   Populate all fields of a `HealthContextSnapshot` instance with the fetched/stubbed data.
            *   Return the `HealthContextSnapshot`.
            *   Use `AppLogger` for any errors during assembly.
            ```swift
            // In ContextAssembler.swift
            import SwiftData
            import Foundation // For ModelContext if not directly in SwiftUI environment

            class ContextAssembler {
                private let healthKitManager: HealthKitManager
                // private let weatherService: WeatherServiceAPIClient // Add when WeatherService is available
                // Add other services as needed

                init(healthKitManager: HealthKitManager /*, weatherService: WeatherServiceAPIClient */) {
                    self.healthKitManager = healthKitManager
                    // self.weatherService = weatherService
                }

                func assembleSnapshot(modelContext: ModelContext) async -> HealthContextSnapshot {
                    // Fetch HealthKit Data (concurrently if possible)
                    async let rhr = healthKitManager.fetchLatestRestingHeartRate()
                    async let hrv = healthKitManager.fetchLatestHRV()
                    async let steps = healthKitManager.fetchTodayStepCount()
                    // ... other HealthKit calls (active energy, exercise time, stand hours, weight, body fat)
                    async let sleepData = healthKitManager.fetchLastNightSleepAnalysis()
                    
                    // Fetch Subjective Data from DailyLog for today
                    var subjectiveEnergy: Int? = nil
                    let todayStart = Calendar.current.startOfDay(for: Date())
                    let predicate = #Predicate<DailyLog> { log in log.date == todayStart }
                    var descriptor = FetchDescriptor<DailyLog>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
                    descriptor.fetchLimit = 1
                    do {
                        let logs = try modelContext.fetch(descriptor)
                        subjectiveEnergy = logs.first?.subjectiveEnergyLevel
                    } catch {
                        AppLogger.error("Failed to fetch today's DailyLog: \(error.localizedDescription)", category: .data, error: error)
                    }

                    // Fetch Weather Data (Mock for now)
                    let weatherCondition: String? = "Sunny (Mock)" // await weatherService.getCurrentWeather().condition
                    let temperature: Double? = 22.0 // await weatherService.getCurrentWeather().temperatureCelsius

                    // Fetch App-Specific Context (Stubs for now)
                    let activeWorkoutName: String? = nil // Logic to check current app state
                    let timeSinceLastInteraction: Int? = 60 // Logic to check last CoachMessage timestamp
                    // Logic to get last meal summary from FoodEntry
                    let lastMealLoggedSummary: String? = "Breakfast, 1 hour ago (Mock)"
                    // Logic to get upcoming planned workout from Workout
                    let upcomingWorkoutName: String? = "Upper Body Strength (Mock)"


                    // Await all HealthKit results
                    let (rhrValue, hrvValue, stepsValue, sleep) = await (rhr, hrv, steps, sleepData)
                    // ... await other healthKit results

                    return HealthContextSnapshot(
                        subjectiveEnergyLevel: subjectiveEnergy,
                        currentWeatherCondition: weatherCondition,
                        currentTemperatureCelsius: temperature,
                        restingHeartRateBPM: rhrValue,
                        heartRateVariabilitySDNNms: hrvValue,
                        stepCountToday: stepsValue,
                        // ... populate all other fields from fetched/stubbed data
                        lastNightSleepDurationHours: sleep.durationInHours,
                        lastNightSleepEfficiencyPercentage: sleep.efficiencyPercentage,
                        lastNightBedtime: sleep.bedtime,
                        lastNightWaketime: sleep.waketime,
                        activeWorkoutNameInProgress: activeWorkoutName,
                        timeSinceLastCoachInteractionMinutes: timeSinceLastInteraction,
                        lastMealLogged: lastMealLoggedSummary,
                        upcomingPlannedWorkoutName: upcomingWorkoutName
                        // ... etc.
                    )
                }
            }
            ```
        *   Acceptance Criteria: `assembleSnapshot` method implemented, calls (mocked or real) services, and constructs a `HealthContextSnapshot`.

---

**Task 4.4: Integrate HealthKit Authorization into App Flow**
    *   **Agent Task 4.4.1:**
        *   Instruction: "Determine where and when to request HealthKit authorization. A common place is during onboarding (e.g., after explaining its benefits) or on first access to a feature that requires it."
        *   Details: For AirFit, a good point might be towards the end of the "Persona Blueprint Flow" (e.g., before the "Generating Coach" screen) or when the user first lands on the Dashboard if they skipped/deferred onboarding authorization.
        *   Create a method in `OnboardingViewModel` (or a shared app state manager) like `func requestHealthKitAccessIfNeeded(healthKitManager: HealthKitManager, completion: @escaping (Bool) -> Void)`. This method would call `healthKitManager.requestHealthKitAuthorization`.
        *   The UI (e.g., a specific onboarding screen or a modal on the dashboard) should then call this method.
        *   Acceptance Criteria: A clear strategy for triggering HealthKit authorization is defined, and placeholder for UI interaction is noted. The method to trigger it is added to an appropriate ViewModel/Manager.
    *   **Agent Task 4.4.2 (UI - Placeholder):**
        *   Instruction: "Designate a specific point in the UI flow (e.g., a new Onboarding screen or a button on the Dashboard) where the `requestHealthKitAccessIfNeeded` method will be called."
        *   Details: Agent to note this down. Actual UI implementation for this trigger can be a separate task in the Onboarding or Dashboard module. For now, ensure the logic hook exists.
        *   Acceptance Criteria: The trigger point is documented.

---

**Task 4.5: Final Review & Commit**
    *   **Agent Task 4.5.1:**
        *   Instruction: "Review `HealthKitManager.swift`, `ContextAssembler.swift`, and `HealthContextSnapshot.swift` for correctness, adherence to specifications, error handling, and asynchronous operation best practices."
        *   Acceptance Criteria: All components function as intended, code is clean, and follows styling guidelines.
    *   **Agent Task 4.5.2:**
        *   Instruction: "Ensure HealthKit entitlements and `Info.plist` descriptions are correctly configured."
        *   Acceptance Criteria: Project configuration for HealthKit is complete.
    *   **Agent Task 4.5.3:**
        *   Instruction: "Stage all new and modified files related to this module."
        *   Acceptance Criteria: `git status` shows all relevant files staged.
    *   **Agent Task 4.5.4:**
        *   Instruction: "Commit the staged changes with a descriptive message."
        *   Details: Commit message: "Feat: Implement HealthKitManager and ContextAssembler for health data aggregation".
        *   Acceptance Criteria: Git history shows the new commit. Project builds successfully.

**Task 4.6: Add Unit Tests**
    *   **Agent Task 4.6.1 (HealthKitManager Unit Tests):**
        *   Instruction: "Create `HealthKitManagerTests.swift` in `AirFitTests/`."
        *   Details: Use in-memory containers and mocks for HealthKit as outlined in `TESTING_GUIDELINES.md`.
        *   Acceptance Criteria: Tests compile and pass.
    *   **Agent Task 4.6.2 (ContextAssembler Unit Tests):**
        *   Instruction: "Create `ContextAssemblerTests.swift` in `AirFitTests/`."
        *   Details: Mock dependencies and verify assembled snapshots.
        *   Acceptance Criteria: Tests compile and pass.

---

**4. Acceptance Criteria for Module Completion**

*   The Xcode project is correctly configured with HealthKit capabilities and `Info.plist` usage descriptions.
*   The `HealthContextSnapshot` struct is defined with all required fields.
*   `HealthKitManager` can request user authorization and fetch specified HealthKit data types asynchronously.
*   `ContextAssembler` can create a `HealthContextSnapshot` by gathering data from `HealthKitManager` and other (mocked for now) sources.
*   A clear point in the app flow is identified for triggering HealthKit authorization.
*   All code passes SwiftLint checks and adheres to project conventions.
*   The module is committed to Git.
*   Unit tests for `HealthKitManager` and `ContextAssembler` are implemented and pass.

**5. Code Style Reminders for this Module**

*   Use `async/await` for all HealthKit data fetching operations.
*   Handle HealthKit authorization status and errors gracefully.
*   Ensure all HealthKit queries are efficient and only request necessary data.
*   Use `AppLogger` extensively for debugging HealthKit interactions and context assembly.
*   When dealing with `Date` predicates for HealthKit, be very careful about time zones and start/end of day logic. HealthKit stores data in UTC but usually queries are made based on local calendar days.

---

This module involves significant interaction with a platform framework (HealthKit) and requires careful handling of permissions, asynchronous operations, and data transformation. Clear, testable methods in `HealthKitManager` will be key. The `ContextAssembler` will grow in complexity as more data sources (like live weather, detailed app state) are integrated.
