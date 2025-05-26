**Modular Sub-Document 3: Onboarding Module (UI & Logic for "Persona Blueprint Flow")**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Module 0: Testing Foundation
    *   Completion of Module 1: Core Project Setup & Configuration
    *   Completion of Module 2: Data Layer (SwiftData Schema & Managers)
**Date:** December 2024
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

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
    *   Module 1: `AppColors`, `AppFonts`, `AppConstants`, `View+Extensions`.
    *   Module 2: `User`, `OnboardingProfile`, `CommunicationPreferences` models.
    *   Module 0: Testing framework and guidelines.
*   **Outputs:**
    *   A fully interactive onboarding user interface.
    *   A new `User` entity and associated `OnboardingProfile` entity saved to SwiftData upon completion.
    *   The application navigates to the main app interface (e.g., Dashboard) after onboarding.

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 3.0: Setup Onboarding Flow Management**

**Agent Task 3.0.1: Create OnboardingViewModel**
- Instruction: "Create OnboardingViewModel.swift with complete state management"
- File: `AirFit/Modules/Onboarding/ViewModels/OnboardingViewModel.swift`
- Required Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  
  @MainActor
  @Observable
  final class OnboardingViewModel {
      // MARK: - Navigation State
      private(set) var currentScreen: OnboardingScreen = .openingScreen
      private(set) var isLoading = false
      private(set) var error: Error?
      
      // MARK: - Life Snapshot Data
      var lifeSnapshotData = LifeSnapshotSelections()
      
      // MARK: - Core Aspiration
      var coreAspirationText = ""
      private(set) var coreAspirationStructured: StructuredGoal?
      
      // MARK: - Coaching Style
      var coachingStyleBlend = CoachingStylePreferences()
      
      // MARK: - Engagement Preferences
      var engagementPreference: EngagementPreset = .dataDrivenPartnership
      var customEngagementSettings = CustomEngagementSettings()
      
      // MARK: - Availability
      var typicalAvailability: [WorkoutAvailabilityBlock] = []
      
      // MARK: - Sleep & Boundaries
      var sleepBedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!
      var sleepWakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
      var sleepRhythm: SleepRhythmType = .consistent
      
      // MARK: - Motivation Style
      var achievementAcknowledgement: AchievementStyle = .subtleAffirming
      var inactivityResponse: InactivityResponseStyle = .gentleNudge
      
      // MARK: - Settings
      var preferredUnits: String = "imperial"
      var establishBaseline = true
      
      // MARK: - Dependencies
      private let aiService: AIServiceProtocol
      private let userService: UserServiceProtocol
      private let modelContext: ModelContext
      
      // MARK: - Initialization
      init(
          aiService: AIServiceProtocol,
          userService: UserServiceProtocol,
          modelContext: ModelContext
      ) {
          self.aiService = aiService
          self.userService = userService
          self.modelContext = modelContext
      }
      
      // MARK: - Navigation
      func navigateToNextScreen() {
          guard let currentIndex = OnboardingScreen.allCases.firstIndex(of: currentScreen),
                currentIndex < OnboardingScreen.allCases.count - 1 else { return }
          
          currentScreen = OnboardingScreen.allCases[currentIndex + 1]
          AppLogger.info("Navigated to \(currentScreen)", category: .onboarding)
      }
      
      func navigateToPreviousScreen() {
          guard let currentIndex = OnboardingScreen.allCases.firstIndex(of: currentScreen),
                currentIndex > 0 else { return }
          
          currentScreen = OnboardingScreen.allCases[currentIndex - 1]
          AppLogger.info("Navigated back to \(currentScreen)", category: .onboarding)
      }
      
      // MARK: - Business Logic
      func processCoreAspiration() async {
          guard !coreAspirationText.isBlank else { return }
          
          isLoading = true
          defer { isLoading = false }
          
          do {
              let structuredGoal = try await aiService.analyzeGoal(coreAspirationText)
              self.coreAspirationStructured = structuredGoal
              AppLogger.info("Goal analysis completed", category: .ai)
          } catch {
              self.error = error
              AppLogger.error("Goal analysis failed", error: error, category: .ai)
          }
      }
      
      func completeOnboarding() async throws {
          isLoading = true
          defer { isLoading = false }
          
          // Create persona profile
          let personaProfile = buildPersonaProfile()
          let communicationPrefs = buildCommunicationPreferences()
          
          // Create user and profile
          let user = User(preferredUnits: preferredUnits)
          let profile = OnboardingProfile(
              user: user,
              personaPromptData: try JSONEncoder().encode(personaProfile),
              communicationPreferencesData: try JSONEncoder().encode(communicationPrefs),
              rawFullProfileData: try JSONEncoder().encode(personaProfile)
          )
          
          // Save to SwiftData
          modelContext.insert(user)
          modelContext.insert(profile)
          try modelContext.save()
          
          AppLogger.info("Onboarding completed successfully", category: .onboarding)
      }
      
      // MARK: - Private Methods
      private func buildPersonaProfile() -> PersonaProfile {
          PersonaProfile(
              lifeContext: lifeSnapshotData,
              coreAspiration: coreAspirationText,
              structuredGoal: coreAspirationStructured,
              coachingStyle: coachingStyleBlend,
              engagementPreference: engagementPreference,
              customEngagement: customEngagementSettings,
              availability: typicalAvailability,
              sleepSchedule: SleepSchedule(
                  bedtime: sleepBedtime,
                  wakeTime: sleepWakeTime,
                  rhythm: sleepRhythm
              ),
              motivationStyle: MotivationStyle(
                  achievementStyle: achievementAcknowledgement,
                  inactivityStyle: inactivityResponse
              ),
              establishBaseline: establishBaseline
          )
      }
      
      private func buildCommunicationPreferences() -> CommunicationPreferences {
          CommunicationPreferences(
              coachingStyleBlend: coachingStyleBlend,
              achievementAcknowledgement: achievementAcknowledgement,
              inactivityResponse: inactivityResponse
          )
      }
  }
  ```
- Acceptance Criteria:
  - ViewModel compiles with Swift 6 concurrency
  - All properties are properly observable
  - Navigation methods work correctly
  - Async methods handle errors properly
  - Dependencies are injected (not hardcoded)

**Agent Task 3.0.2: Define Supporting Models**
- Instruction: "Create OnboardingModels.swift with all required types"
- File: `AirFit/Modules/Onboarding/Models/OnboardingModels.swift`
- Required Types:
  ```swift
  import Foundation
  
  // MARK: - Navigation
  enum OnboardingScreen: String, CaseIterable, Sendable {
      case openingScreen = "opening"
      case lifeSnapshot = "lifeSnapshot"
      case coreAspiration = "coreAspiration"
      case coachingStyle = "coachingStyle"
      case engagementPreferences = "engagement"
      case typicalAvailability = "availability"
      case sleepAndBoundaries = "sleep"
      case motivationAndCheckins = "motivation"
      case generatingCoach = "generating"
      case coachProfileReady = "ready"
      
      var title: String {
          switch self {
          case .openingScreen: return ""
          case .lifeSnapshot: return "Life Snapshot"
          case .coreAspiration: return "Core Aspiration"
          case .coachingStyle: return "Coaching Style"
          case .engagementPreferences: return "Engagement"
          case .typicalAvailability: return "Availability"
          case .sleepAndBoundaries: return "Sleep & Recovery"
          case .motivationAndCheckins: return "Motivation"
          case .generatingCoach: return "Creating Your Coach"
          case .coachProfileReady: return "Coach Ready"
          }
      }
      
      var progress: Double {
          guard let index = Self.allCases.firstIndex(of: self) else { return 0 }
          return Double(index) / Double(Self.allCases.count - 2) // Exclude last 2 screens
      }
  }
  
  // MARK: - Life Snapshot
  struct LifeSnapshotSelections: Codable, Sendable {
      var busyProfessional = false
      var parentCaregiver = false
      var student = false
      var shiftWorker = false
      var travelFrequently = false
      var workFromHome = false
      var recovering = false
      var newToFitness = false
      
      var selectedItems: [String] {
          var items: [String] = []
          if busyProfessional { items.append("Busy Professional") }
          if parentCaregiver { items.append("Parent/Caregiver") }
          if student { items.append("Student") }
          if shiftWorker { items.append("Shift Worker") }
          if travelFrequently { items.append("Travel Frequently") }
          if workFromHome { items.append("Work From Home") }
          if recovering { items.append("Recovering from Injury/Illness") }
          if newToFitness { items.append("New to Fitness") }
          return items
      }
  }
  
  // MARK: - Core Aspiration
  struct StructuredGoal: Codable, Sendable {
      let goalType: String
      let primaryMetric: String
      let timeframe: String?
      let specificTarget: String?
      let whyImportant: String?
  }
  
  // MARK: - Coaching Style
  struct CoachingStylePreferences: Codable, Sendable {
      var authoritativeDirect: Double = 0.25
      var empatheticEncouraging: Double = 0.25
      var analyticalPrecise: Double = 0.25
      var playfulMotivating: Double = 0.25
      
      var isValid: Bool {
          abs((authoritativeDirect + empatheticEncouraging + analyticalPrecise + playfulMotivating) - 1.0) < 0.01
      }
      
      mutating func normalize() {
          let total = authoritativeDirect + empatheticEncouraging + analyticalPrecise + playfulMotivating
          guard total > 0 else { return }
          authoritativeDirect /= total
          empatheticEncouraging /= total
          analyticalPrecise /= total
          playfulMotivating /= total
      }
  }
  
  // MARK: - Engagement
  enum EngagementPreset: String, Codable, CaseIterable, Sendable {
      case dataDrivenPartnership = "data_driven"
      case consistentBalanced = "consistent_balanced"
      case guidanceOnDemand = "guidance_on_demand"
      case custom = "custom"
      
      var displayName: String {
          switch self {
          case .dataDrivenPartnership: return "Data-Driven Partnership"
          case .consistentBalanced: return "Consistent & Balanced"
          case .guidanceOnDemand: return "Guidance On-Demand"
          case .custom: return "Custom"
          }
      }
  }
  
  struct CustomEngagementSettings: Codable, Sendable {
      var detailedTracking = false
      var dailyInsights = false
      var autoRecoveryAdjust = false
  }
  
  // MARK: - Availability
  struct WorkoutAvailabilityBlock: Codable, Identifiable, Sendable {
      let id = UUID()
      var dayOfWeek: Int // 1 = Sunday, 7 = Saturday
      var startTime: Date
      var endTime: Date
      
      var dayName: String {
          let formatter = DateFormatter()
          formatter.dateFormat = "EEEE"
          let date = Calendar.current.date(from: DateComponents(weekday: dayOfWeek))!
          return formatter.string(from: date)
      }
  }
  
  // MARK: - Sleep
  enum SleepRhythmType: String, Codable, CaseIterable, Sendable {
      case consistent = "consistent"
      case weekendsDifferent = "weekends_different"
      case highlyVariable = "highly_variable"
      
      var displayName: String {
          switch self {
          case .consistent: return "Consistent"
          case .weekendsDifferent: return "Weekends Different"
          case .highlyVariable: return "Highly Variable"
          }
      }
  }
  
  struct SleepSchedule: Codable, Sendable {
      let bedtime: Date
      let wakeTime: Date
      let rhythm: SleepRhythmType
  }
  
  // MARK: - Motivation
  enum AchievementStyle: String, Codable, CaseIterable, Sendable {
      case enthusiasticCelebration = "enthusiastic"
      case subtleAffirming = "subtle"
      case dataFocused = "data_focused"
      case privateReflection = "private"
      
      var displayName: String {
          switch self {
          case .enthusiasticCelebration: return "Enthusiastic Celebration"
          case .subtleAffirming: return "Subtle & Affirming"
          case .dataFocused: return "Data-Focused"
          case .privateReflection: return "Private Reflection"
          }
      }
  }
  
  enum InactivityResponseStyle: String, Codable, CaseIterable, Sendable {
      case motivationalPush = "motivational"
      case gentleNudge = "gentle"
      case factualReminder = "factual"
      case waitForMe = "wait"
      
      var displayName: String {
          switch self {
          case .motivationalPush: return "Motivational Push"
          case .gentleNudge: return "Gentle Nudge"
          case .factualReminder: return "Factual Reminder"
          case .waitForMe: return "Wait for Me"
          }
      }
  }
  
  struct MotivationStyle: Codable, Sendable {
      let achievementStyle: AchievementStyle
      let inactivityStyle: InactivityResponseStyle
  }
  
  // MARK: - Complete Profile
  struct PersonaProfile: Codable, Sendable {
      let lifeContext: LifeSnapshotSelections
      let coreAspiration: String
      let structuredGoal: StructuredGoal?
      let coachingStyle: CoachingStylePreferences
      let engagementPreference: EngagementPreset
      let customEngagement: CustomEngagementSettings
      let availability: [WorkoutAvailabilityBlock]
      let sleepSchedule: SleepSchedule
      let motivationStyle: MotivationStyle
      let establishBaseline: Bool
  }
  ```
- Acceptance Criteria:
  - All types conform to Codable and Sendable
  - Display names are user-friendly
  - Validation logic works correctly
  - IDs are properly generated for Identifiable types

**Agent Task 3.0.3: Create OnboardingFlowView**
- Instruction: "Create main onboarding container view with progress tracking"
- File: `AirFit/Modules/Onboarding/Views/OnboardingFlowView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  
  struct OnboardingFlowView: View {
      @Environment(\.modelContext) private var modelContext
      @State private var viewModel: OnboardingViewModel
      
      init(aiService: AIServiceProtocol, userService: UserServiceProtocol) {
          let modelContext = ModelContext(ModelContainer.shared)
          _viewModel = State(initialValue: OnboardingViewModel(
              aiService: aiService,
              userService: userService,
              modelContext: modelContext
          ))
      }
      
      var body: some View {
          VStack(spacing: 0) {
              // Progress Bar
              if viewModel.currentScreen != .openingScreen &&
                 viewModel.currentScreen != .generatingCoach &&
                 viewModel.currentScreen != .coachProfileReady {
                  ProgressBar(progress: viewModel.currentScreen.progress)
                      .padding(.horizontal)
                      .padding(.top)
              }
              
              // Screen Content
              Group {
                  switch viewModel.currentScreen {
                  case .openingScreen:
                      OpeningScreenView(viewModel: viewModel)
                  case .lifeSnapshot:
                      LifeSnapshotView(viewModel: viewModel)
                  case .coreAspiration:
                      CoreAspirationView(viewModel: viewModel)
                  case .coachingStyle:
                      CoachingStyleView(viewModel: viewModel)
                  case .engagementPreferences:
                      EngagementPreferencesView(viewModel: viewModel)
                  case .typicalAvailability:
                      TypicalAvailabilityView(viewModel: viewModel)
                  case .sleepAndBoundaries:
                      SleepAndBoundariesView(viewModel: viewModel)
                  case .motivationAndCheckins:
                      MotivationAndCheckinsView(viewModel: viewModel)
                  case .generatingCoach:
                      GeneratingCoachView(viewModel: viewModel)
                  case .coachProfileReady:
                      CoachProfileReadyView(viewModel: viewModel)
                  }
              }
              .transition(.asymmetric(
                  insertion: .move(edge: .trailing).combined(with: .opacity),
                  removal: .move(edge: .leading).combined(with: .opacity)
              ))
              .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreen)
              
              // Privacy Footer
              if viewModel.currentScreen != .generatingCoach &&
                 viewModel.currentScreen != .coachProfileReady {
                  PrivacyFooter()
                      .padding(.bottom)
              }
          }
          .background(AppColors.backgroundPrimary)
          .loadingOverlay(viewModel.isLoading)
          .alert("Error", isPresented: .constant(viewModel.error != nil)) {
              Button("OK") { viewModel.error = nil }
          } message: {
              Text(viewModel.error?.localizedDescription ?? "An error occurred")
          }
          .accessibilityElement(id: "onboarding.flow")
      }
  }
  
  // MARK: - Supporting Views
  struct ProgressBar: View {
      let progress: Double
      
      var body: some View {
          GeometryReader { geometry in
              ZStack(alignment: .leading) {
                  RoundedRectangle(cornerRadius: 2)
                      .fill(AppColors.dividerColor)
                      .frame(height: 4)
                  
                  RoundedRectangle(cornerRadius: 2)
                      .fill(AppColors.accentColor)
                      .frame(width: geometry.size.width * progress, height: 4)
              }
          }
          .frame(height: 4)
          .accessibilityElement(id: "onboarding.progress")
          .accessibilityValue("\(Int(progress * 100))% complete")
      }
  }
  
  struct PrivacyFooter: View {
      var body: some View {
          Button(action: {
              // Open privacy policy
              AppLogger.info("Privacy policy tapped", category: .onboarding)
          }) {
              Text("Privacy & Data")
                  .font(AppFonts.caption)
                  .foregroundColor(AppColors.textTertiary)
          }
          .accessibilityElement(id: "onboarding.privacy")
      }
  }
  ```

---

**Task 3.1: Implement Opening Screen View**

**Agent Task 3.1.1: Create OpeningScreenView**
- Instruction: "Create opening screen with accessibility and proper styling"
- File: `AirFit/Modules/Onboarding/Views/OpeningScreenView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct OpeningScreenView: View {
      @Bindable var viewModel: OnboardingViewModel
      @State private var animateIn = false
      
      var body: some View {
          VStack(spacing: AppSpacing.large) {
              Spacer()
              
              // Logo/Title
              VStack(spacing: AppSpacing.medium) {
                  Image(systemName: "figure.run.circle.fill")
                      .font(.system(size: 80))
                      .foregroundStyle(AppColors.accentGradient)
                      .scaleEffect(animateIn ? 1 : 0.5)
                      .opacity(animateIn ? 1 : 0)
                  
                  Text("AirFit")
                      .font(AppFonts.largeTitle)
                      .foregroundColor(AppColors.textPrimary)
                      .opacity(animateIn ? 1 : 0)
              }
              
              // Tagline
              VStack(spacing: AppSpacing.small) {
                  Text("Let's design your AirFit Coach")
                      .font(AppFonts.title3)
                      .foregroundColor(AppColors.textPrimary)
                      .multilineTextAlignment(.center)
                  
                  Text("Est. 3-4 minutes to create your personalized experience")
                      .font(AppFonts.subheadline)
                      .foregroundColor(AppColors.textSecondary)
                      .multilineTextAlignment(.center)
              }
              .opacity(animateIn ? 1 : 0)
              .offset(y: animateIn ? 0 : 20)
              
              Spacer()
              
              // Actions
              VStack(spacing: AppSpacing.medium) {
                  Button(action: {
                      viewModel.navigateToNextScreen()
                  }) {
                      Text("Begin")
                          .font(AppFonts.bodyBold)
                          .foregroundColor(AppColors.textOnAccent)
                          .frame(maxWidth: .infinity)
                          .padding()
                          .background(AppColors.accentColor)
                          .cornerRadius(AppConstants.Layout.defaultCornerRadius)
                  }
                  .accessibilityElement(id: "onboarding.begin.button")
                  
                  Button(action: {
                      // Skip onboarding
                      AppLogger.info("Onboarding skipped", category: .onboarding)
                  }) {
                      Text("Maybe Later")
                          .font(AppFonts.body)
                          .foregroundColor(AppColors.textSecondary)
                  }
                  .accessibilityElement(id: "onboarding.skip.button")
              }
              .padding(.horizontal, AppSpacing.large)
              .opacity(animateIn ? 1 : 0)
              .offset(y: animateIn ? 0 : 20)
          }
          .padding(AppSpacing.medium)
          .onAppear {
              withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                  animateIn = true
              }
          }
      }
  }
  ```

---

**Task 3.2-3.8: Implement Remaining Onboarding Screens**

For brevity, I'll show the pattern for one more screen, then list the requirements for the others:

**Agent Task 3.2.1: Create LifeSnapshotView**
- Instruction: "Create life snapshot selection screen with multi-select options"
- File: `AirFit/Modules/Onboarding/Views/LifeSnapshotView.swift`
- Key Requirements:
  - Multi-select toggle list
  - At least one selection required
  - HealthKit pre-fill indicators (future)
  - Smooth animations
  - Accessibility for each option

**Similar patterns for:**
- Task 3.3: CoreAspirationView (with text input and predefined options)
- Task 3.4: CoachingStyleView (with interactive sliders and real-time feedback)
- Task 3.5: EngagementPreferencesView (with preset selection and custom options)
- Task 3.6: TypicalAvailabilityView (with time slot picker)
- Task 3.7: SleepAndBoundariesView (with time pickers and rhythm selection)
- Task 3.8: MotivationAndCheckinsView (with style selections)

---

**4. Testing Requirements**

### Unit Tests

**Agent Task 3.13.1: Create OnboardingViewModelTests**
- File: `AirFitTests/Onboarding/OnboardingViewModelTests.swift`
- Required Test Cases:
  ```swift
  @MainActor
  final class OnboardingViewModelTests: XCTestCase {
      var sut: OnboardingViewModel!
      var mockAIService: MockAIService!
      var mockUserService: MockUserService!
      var modelContext: ModelContext!
      
      override func setUp() async throws {
          try await super.setUp()
          
          // Setup in-memory SwiftData
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, OnboardingProfile.self
          )
          
          // Setup mocks
          mockAIService = MockAIService()
          mockUserService = MockUserService()
          
          // Create SUT
          sut = OnboardingViewModel(
              aiService: mockAIService,
              userService: mockUserService,
              modelContext: modelContext
          )
      }
      
      // MARK: - Navigation Tests
      func test_navigateToNextScreen_fromOpeningScreen_shouldAdvanceToLifeSnapshot() {
          // Arrange
          sut.currentScreen = .openingScreen
          
          // Act
          sut.navigateToNextScreen()
          
          // Assert
          XCTAssertEqual(sut.currentScreen, .lifeSnapshot)
      }
      
      func test_navigateToNextScreen_fromLastScreen_shouldNotAdvance() {
          // Arrange
          sut.currentScreen = .coachProfileReady
          
          // Act
          sut.navigateToNextScreen()
          
          // Assert
          XCTAssertEqual(sut.currentScreen, .coachProfileReady)
      }
      
      // MARK: - Goal Analysis Tests
      func test_processCoreAspiration_withValidText_shouldCallAIService() async {
          // Arrange
          sut.coreAspirationText = "I want to lose 20 pounds"
          let expectedGoal = StructuredGoal(
              goalType: "weight_loss",
              primaryMetric: "weight",
              timeframe: "3 months",
              specificTarget: "20 lbs",
              whyImportant: "Health"
          )
          mockAIService.analyzeGoalResult = .success(expectedGoal)
          
          // Act
          await sut.processCoreAspiration()
          
          // Assert
          XCTAssertEqual(sut.coreAspirationStructured?.goalType, "weight_loss")
          XCTAssertFalse(sut.isLoading)
          XCTAssertNil(sut.error)
      }
      
      func test_processCoreAspiration_withEmptyText_shouldNotCallAIService() async {
          // Arrange
          sut.coreAspirationText = ""
          
          // Act
          await sut.processCoreAspiration()
          
          // Assert
          XCTAssertFalse(mockAIService.analyzeGoalCalled)
          XCTAssertNil(sut.coreAspirationStructured)
      }
      
      // MARK: - Onboarding Completion Tests
      func test_completeOnboarding_withValidData_shouldSaveUserAndProfile() async throws {
          // Arrange
          setupValidOnboardingData()
          
          // Act
          try await sut.completeOnboarding()
          
          // Assert
          let users = try modelContext.fetch(FetchDescriptor<User>())
          let profiles = try modelContext.fetch(FetchDescriptor<OnboardingProfile>())
          
          XCTAssertEqual(users.count, 1)
          XCTAssertEqual(profiles.count, 1)
          XCTAssertEqual(users.first?.preferredUnits, "imperial")
      }
      
      // MARK: - Validation Tests
      func test_coachingStyleBlend_shouldNormalizeTo100Percent() {
          // Arrange
          sut.coachingStyleBlend = CoachingStylePreferences(
              authoritativeDirect: 0.5,
              empatheticEncouraging: 0.5,
              analyticalPrecise: 0.5,
              playfulMotivating: 0.5
          )
          
          // Act
          sut.coachingStyleBlend.normalize()
          
          // Assert
          XCTAssertEqual(sut.coachingStyleBlend.authoritativeDirect, 0.25, accuracy: 0.01)
          XCTAssertEqual(sut.coachingStyleBlend.empatheticEncouraging, 0.25, accuracy: 0.01)
          XCTAssertTrue(sut.coachingStyleBlend.isValid)
      }
      
      // MARK: - Helper Methods
      private func setupValidOnboardingData() {
          sut.lifeSnapshotData.busyProfessional = true
          sut.coreAspirationText = "Get healthier"
          sut.coachingStyleBlend = CoachingStylePreferences()
          sut.engagementPreference = .dataDrivenPartnership
          sut.sleepBedtime = Date()
          sut.sleepWakeTime = Date()
      }
  }
  ```
- Test Coverage Requirements:
  - All navigation paths: 100%
  - Business logic methods: 80%
  - Error handling: 100%
  - Data validation: 90%

### UI Tests

**Agent Task 3.13.2: Create OnboardingFlowUITests**
- File: `AirFitUITests/Onboarding/OnboardingFlowUITests.swift`
- Required Test Scenarios:
  ```swift
  final class OnboardingFlowUITests: XCTestCase {
      var app: XCUIApplication!
      var onboardingPage: OnboardingPage!
      
      override func setUp() {
          super.setUp()
          continueAfterFailure = false
          
          app = XCUIApplication()
          app.launchArguments = ["--uitesting", "--reset-onboarding"]
          app.launch()
          
          onboardingPage = OnboardingPage(app: app)
      }
      
      func test_completeOnboardingFlow_happyPath() {
          // Opening Screen
          onboardingPage.verifyOnOpeningScreen()
          onboardingPage.tapBegin()
          
          // Life Snapshot
          onboardingPage.verifyOnLifeSnapshot()
          onboardingPage.selectLifeOption("Busy Professional")
          onboardingPage.tapNext()
          
          // Core Aspiration
          onboardingPage.verifyOnCoreAspiration()
          onboardingPage.selectPredefinedGoal("Lose Weight")
          onboardingPage.tapNext()
          
          // Continue through all screens...
          
          // Verify completion
          XCTAssertTrue(onboardingPage.isOnDashboard())
      }
      
      func test_navigationBack_shouldReturnToPreviousScreen() {
          // Navigate forward
          onboardingPage.tapBegin()
          onboardingPage.selectLifeOption("Student")
          onboardingPage.tapNext()
          
          // Navigate back
          onboardingPage.tapBack()
          
          // Verify
          onboardingPage.verifyOnLifeSnapshot()
      }
      
      func test_validationError_shouldShowAlert() {
          // Skip to life snapshot
          onboardingPage.tapBegin()
          
          // Try to proceed without selection
          onboardingPage.tapNext()
          
          // Verify error
          XCTAssertTrue(app.alerts["Validation Error"].exists)
      }
  }
  ```

### Page Object

**Agent Task 3.13.3: Create OnboardingPage Object**
- File: `AirFitUITests/Pages/OnboardingPage.swift`
- Implementation:
  ```swift
  class OnboardingPage: BasePage {
      // MARK: - Opening Screen
      var beginButton: XCUIElement {
          app.buttons["onboarding.begin.button"]
      }
      
      var skipButton: XCUIElement {
          app.buttons["onboarding.skip.button"]
      }
      
      func verifyOnOpeningScreen() {
          verifyElement(exists: beginButton)
          verifyElement(exists: skipButton)
      }
      
      func tapBegin() {
          tapElement(beginButton)
      }
      
      // MARK: - Life Snapshot
      func selectLifeOption(_ option: String) {
          let toggle = app.switches["onboarding.life.\(option.lowercased().replacingOccurrences(of: " ", with: "_"))"]
          tapElement(toggle)
      }
      
      // MARK: - Navigation
      var nextButton: XCUIElement {
          app.buttons["onboarding.next.button"]
      }
      
      var backButton: XCUIElement {
          app.buttons["onboarding.back.button"]
      }
      
      func tapNext() {
          tapElement(nextButton)
      }
      
      func tapBack() {
          tapElement(backButton)
      }
      
      // MARK: - Verification
      func isOnDashboard() -> Bool {
          app.tabBars["main.tabbar"].waitForExistence(timeout: 5)
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ All 10 screens of "Persona Blueprint Flow v3.1" implemented
- ✅ OnboardingViewModel manages complete state and navigation
- ✅ User inputs validated and stored correctly
- ✅ LLM integration for goal analysis (mocked for testing)
- ✅ Persona profile JSON correctly constructed
- ✅ User and OnboardingProfile saved to SwiftData
- ✅ App routes correctly based on onboarding status
- ✅ UI follows design system (colors, fonts, spacing)
- ✅ All code passes SwiftLint with zero violations
- ✅ Unit test coverage ≥ 80% for ViewModel
- ✅ UI tests cover happy path and error cases
- ✅ Accessibility identifiers on all interactive elements
- ✅ Performance: Screen transitions < 300ms
- ✅ Memory usage: < 50MB during onboarding

**6. Module Dependencies**

- **Requires Completion Of:** Module 0, 1, 2
- **Must Be Completed Before:** Module 4 (Dashboard needs user profile)
- **Can Run In Parallel With:** Module 8 (Meal Discovery)

---
