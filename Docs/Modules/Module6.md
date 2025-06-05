**Modular Sub-Document 6: Dashboard Module (UI & Logic)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
    *   Completion of Modular Sub-Document 1: Core Project Setup & Configuration.
    *   Completion of Modular Sub-Document 2: Data Layer (SwiftData Schema & Managers) – `User`, `OnboardingProfile`, `DailyLog`, `FoodEntry`, `Workout`.
    *   Completion of Modular Sub-Document 4: HealthKit & Context Aggregation Module – `ContextAssembler`, `HealthContextSnapshot`.
    *   Completion of Modular Sub-Document 5: AI Persona Engine & CoachEngine – (Specifically, the ability for `CoachEngine` to generate a persona-driven message, even if not a full chat interaction for this specific feature).
**Date:** May 25, 2025
**Updated For:** iOS 18+, macOS 15+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To implement the main Dashboard screen as the primary landing interface providing a personalized overview of health metrics, AI-driven insights, and quick logging actions with a premium, modern design using iOS 18 capabilities.
*   **Responsibilities:**
    *   Implementing the Morning Canvas dashboard with adaptive layout
    *   AI-generated personalized morning greeting with context awareness
    *   Energy level logging with haptic feedback
    *   Animated macro nutrition rings with SwiftUI's latest animation APIs
    *   Recovery and Performance insight cards
    *   Real-time data synchronization with HealthKit
    *   Efficient data fetching with Swift 6 concurrency
    *   Accessibility-first design implementation
*   **Key Components:**
    *   `DashboardView.swift` - Main container view with adaptive grid
    *   `DashboardViewModel.swift` - Observable state management with async data
    *   Card Views: Morning Greeting, Nutrition, Recovery, Performance
    *   Reusable components: AnimatedRing, MetricCard, QuickActionButton
    *   Services integration: HealthKit, AI Coach, Nutrition tracking

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Theme system, constants, utilities
    *   Module 2: SwiftData models (User, DailyLog, FoodEntry, etc.)
    *   Module 3: Completed onboarding with user profile
    *   Design Specification: UI/UX requirements
*   **Outputs:**
    *   Fully functional dashboard with real-time updates
    *   Entry point for all major app features
    *   Daily engagement touchpoint for users

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 6.0: Dashboard ViewModel Implementation**

**Agent Task 6.0.1: Create DashboardViewModel**
- File: `AirFit/Modules/Dashboard/ViewModels/DashboardViewModel.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  import Observation
  
  @MainActor
  @Observable
  final class DashboardViewModel {
      // MARK: - State Properties
      private(set) var isLoading = true
      private(set) var error: Error?
      
      // Morning Greeting
      private(set) var morningGreeting = "Good morning!"
      private(set) var greetingContext: GreetingContext?
      
      // Energy Logging
      private(set) var currentEnergyLevel: Int?
      private(set) var isLoggingEnergy = false
      
      // Nutrition Data
      private(set) var nutritionSummary = NutritionSummary()
      private(set) var nutritionTargets = NutritionTargets.default
      
      // Health Insights
      private(set) var recoveryScore: RecoveryScore?
      private(set) var performanceInsight: PerformanceInsight?
      
      // Quick Actions
      private(set) var suggestedActions: [QuickAction] = []
      
      // MARK: - Dependencies
      private let user: User
      private let modelContext: ModelContext
      private let healthKitService: HealthKitServiceProtocol
      private let aiCoachService: AICoachServiceProtocol
      private let nutritionService: NutritionServiceProtocol
      
      // MARK: - Private State
      private var refreshTask: Task<Void, Never>?
      private var lastGreetingDate: Date?
      
      // MARK: - Initialization
      init(
          user: User,
          modelContext: ModelContext,
          healthKitService: HealthKitServiceProtocol,
          aiCoachService: AICoachServiceProtocol,
          nutritionService: NutritionServiceProtocol
      ) {
          self.user = user
          self.modelContext = modelContext
          self.healthKitService = healthKitService
          self.aiCoachService = aiCoachService
          self.nutritionService = nutritionService
      }
      
      // MARK: - Public Methods
      func onAppear() {
          refreshDashboard()
      }
      
      func onDisappear() {
          refreshTask?.cancel()
      }
      
      func refreshDashboard() {
          refreshTask?.cancel()
          refreshTask = Task {
              await loadDashboardData()
          }
      }
      
      func logEnergyLevel(_ level: Int) async {
          guard !isLoggingEnergy else { return }
          
          isLoggingEnergy = true
          defer { isLoggingEnergy = false }
          
          do {
              // Get or create today's log
              let today = Calendar.current.startOfDay(for: Date())
              var descriptor = FetchDescriptor<DailyLog>()
              descriptor.predicate = #Predicate { log in
                  log.user == user && log.date == today
              }
              
              let logs = try modelContext.fetch(descriptor)
              let dailyLog: DailyLog
              
              if let existingLog = logs.first {
                  dailyLog = existingLog
              } else {
                  dailyLog = DailyLog(date: today, user: user)
                  modelContext.insert(dailyLog)
              }
              
              // Update energy level
              dailyLog.subjectiveEnergyLevel = level
              dailyLog.checkedIn = true
              try modelContext.save()
              
              // Update local state
              currentEnergyLevel = level
              
              // Haptic feedback
              await HapticManager.shared.impact(.light)
              
              // Log analytics
              AppLogger.info("Energy level logged: \(level)", category: .data)
              
          } catch {
              self.error = error
              AppLogger.error("Failed to log energy", error: error, category: .data)
          }
      }
      
      // MARK: - Private Methods
      private func loadDashboardData() async {
          isLoading = true
          defer { isLoading = false }
          
          // Load all data concurrently
          await withTaskGroup(of: Void.self) { group in
              group.addTask { await self.loadMorningGreeting() }
              group.addTask { await self.loadEnergyLevel() }
              group.addTask { await self.loadNutritionData() }
              group.addTask { await self.loadHealthInsights() }
              group.addTask { await self.loadQuickActions() }
          }
      }
      
      private func loadMorningGreeting() async {
          // Check if we need a new greeting
          let calendar = Calendar.current
          let shouldRefresh = lastGreetingDate.map { date in
              !calendar.isDateInToday(date)
          } ?? true
          
          guard shouldRefresh else { return }
          
          do {
              // Get health context
              let healthContext = try await healthKitService.getCurrentContext()
              
              // Build greeting context
              let context = GreetingContext(
                  userName: user.name ?? "there",
                  sleepHours: healthContext.lastNightSleepDurationHours,
                  sleepQuality: healthContext.sleepQuality,
                  weather: healthContext.currentWeatherCondition,
                  temperature: healthContext.currentTemperatureCelsius,
                  dayOfWeek: Date().formatted(.dateTime.weekday(.wide)),
                  energyYesterday: healthContext.yesterdayEnergyLevel
              )
              
              // Generate AI greeting
              let greeting = try await aiCoachService.generateMorningGreeting(
                  for: user,
                  context: context
              )
              
              self.morningGreeting = greeting
              self.greetingContext = context
              self.lastGreetingDate = Date()
              
          } catch {
              // Fallback greeting
              self.morningGreeting = generateFallbackGreeting()
              AppLogger.error("Failed to generate AI greeting", error: error, category: .ai)
          }
      }
      
      private func loadEnergyLevel() async {
          do {
              let today = Calendar.current.startOfDay(for: Date())
              var descriptor = FetchDescriptor<DailyLog>()
              descriptor.predicate = #Predicate { log in
                  log.user == user && log.date == today
              }
              
              let logs = try modelContext.fetch(descriptor)
              currentEnergyLevel = logs.first?.subjectiveEnergyLevel
              
          } catch {
              AppLogger.error("Failed to load energy level", error: error, category: .data)
          }
      }
      
      private func loadNutritionData() async {
          do {
              // Load today's nutrition
              let summary = try await nutritionService.getTodaysSummary(for: user)
              self.nutritionSummary = summary
              
              // Load user's targets
              if let profile = user.onboardingProfile,
                 let targets = try? await nutritionService.getTargets(from: profile) {
                  self.nutritionTargets = targets
              }
              
          } catch {
              AppLogger.error("Failed to load nutrition data", error: error, category: .data)
          }
      }
      
      private func loadHealthInsights() async {
          do {
              // Load recovery score
              let recovery = try await healthKitService.calculateRecoveryScore(for: user)
              self.recoveryScore = recovery
              
              // Load performance insight
              let performance = try await healthKitService.getPerformanceInsight(
                  for: user,
                  days: 7
              )
              self.performanceInsight = performance
              
          } catch {
              AppLogger.error("Failed to load health insights", error: error, category: .health)
          }
      }
      
      private func loadQuickActions() async {
          var actions: [QuickAction] = []
          
          // Add meal logging if it's mealtime
          let hour = Calendar.current.component(.hour, from: Date())
          if (11...13).contains(hour) && nutritionSummary.meals[.lunch] == nil {
              actions.append(.logMeal(type: .lunch))
          }
          
          // Add workout if none today
          if !hasWorkoutToday() {
              actions.append(.startWorkout)
          }
          
          // Add water logging
          if nutritionSummary.waterLiters < 2.0 {
              actions.append(.logWater)
          }
          
          self.suggestedActions = actions
      }
      
      private func generateFallbackGreeting() -> String {
          let hour = Calendar.current.component(.hour, from: Date())
          let name = user.name ?? "there"
          
          switch hour {
          case 5..<12:
              return "Good morning, \(name)! Ready to make today count?"
          case 12..<17:
              return "Good afternoon, \(name)! How's your day going?"
          case 17..<22:
              return "Good evening, \(name)! Time to wind down."
          default:
              return "Hello, \(name)! Still up?"
          }
      }
      
      private func hasWorkoutToday() -> Bool {
          let today = Calendar.current.startOfDay(for: Date())
          return user.workouts.contains { workout in
              if let completed = workout.completedDate {
                  return Calendar.current.isDate(completed, inSameDayAs: today)
              }
              return false
          }
      }
  }
  
  // MARK: - Supporting Types
  struct NutritionSummary: Equatable {
      var calories: Double = 0
      var protein: Double = 0
      var carbs: Double = 0
      var fat: Double = 0
      var fiber: Double = 0
      var waterLiters: Double = 0
      var meals: [MealType: FoodEntry] = [:]
  }
  
  struct NutritionTargets: Equatable {
      let calories: Double
      let protein: Double
      let carbs: Double
      let fat: Double
      let fiber: Double
      let water: Double
      
      static let `default` = NutritionTargets(
          calories: 2000,
          protein: 150,
          carbs: 250,
          fat: 70,
          fiber: 30,
          water: 2.5
      )
  }
  
  struct GreetingContext {
      let userName: String
      let sleepHours: Double?
      let sleepQuality: Int?
      let weather: String?
      let temperature: Double?
      let dayOfWeek: String
      let energyYesterday: Int?
  }
  
  struct RecoveryScore: Equatable {
      let score: Int // 0-100
      let components: [Component]
      
      struct Component {
          let name: String
          let value: Double
          let weight: Double
      }
      
      var trend: Trend {
          // Logic to determine trend
          .steady
      }
      
      enum Trend {
          case improving, steady, declining
      }
  }
  
  struct PerformanceInsight: Equatable {
      let summary: String
      let trend: Trend
      let keyMetric: String
      let value: Double
      
      enum Trend {
          case up, steady, down
      }
  }
  
  enum QuickAction: Identifiable {
      case logMeal(type: MealType)
      case startWorkout
      case logWater
      case checkIn
      
      var id: String {
          switch self {
          case .logMeal(let type): return "logMeal_\(type.rawValue)"
          case .startWorkout: return "startWorkout"
          case .logWater: return "logWater"
          case .checkIn: return "checkIn"
          }
      }
      
      var title: String {
          switch self {
          case .logMeal(let type): return "Log \(type.displayName)"
          case .startWorkout: return "Start Workout"
          case .logWater: return "Log Water"
          case .checkIn: return "Daily Check-in"
          }
      }
      
      var systemImage: String {
          switch self {
          case .logMeal: return "fork.knife"
          case .startWorkout: return "figure.run"
          case .logWater: return "drop.fill"
          case .checkIn: return "checkmark.circle"
          }
      }
  }
  ```

**Agent Task 6.0.2: Create Service Protocols**
- File: `AirFit/Modules/Dashboard/Services/DashboardServiceProtocols.swift`
- Implementation:
  ```swift
  import Foundation
  import SwiftData
  
  protocol HealthKitServiceProtocol: Sendable {
      func getCurrentContext() async throws -> HealthContext
      func calculateRecoveryScore(for user: User) async throws -> RecoveryScore
      func getPerformanceInsight(for user: User, days: Int) async throws -> PerformanceInsight
  }
  
  protocol AICoachServiceProtocol: Sendable {
      func generateMorningGreeting(for user: User, context: GreetingContext) async throws -> String
  }
  
  protocol NutritionServiceProtocol: Sendable {
      func getTodaysSummary(for user: User) async throws -> NutritionSummary
      func getTargets(from profile: OnboardingProfile) async throws -> NutritionTargets
  }
  
  struct HealthContext {
      let lastNightSleepDurationHours: Double?
      let sleepQuality: Int?
      let currentWeatherCondition: String?
      let currentTemperatureCelsius: Double?
      let yesterdayEnergyLevel: Int?
      let currentHeartRate: Int?
      let hrv: Double?
      let steps: Int?
  }
  ```

---

**Task 6.1: Dashboard View Implementation**

**Agent Task 6.1.1: Create DashboardView**
- File: `AirFit/Modules/Dashboard/Views/DashboardView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  
  struct DashboardView: View {
      @State private var viewModel: DashboardViewModel
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
                      loadingView
                  } else {
                      dashboardContent
                  }
              }
              .navigationTitle("Dashboard")
              .background(AppColors.backgroundPrimary.edgesIgnoringSafeArea(.all))
              .onAppear {
                  viewModel.fetchDashboardData()
              }
          }
      }

      // MARK: - Subviews
      private var loadingView: some View {
          VStack(spacing: AppSpacing.large) {
              ProgressView()
                  .controlSize(.large)
                  .tint(AppColors.accentColor)
              
              Text("Loading your dashboard...")
                  .font(AppFonts.body)
                  .foregroundColor(AppColors.textSecondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, 100)
      }

      private var dashboardContent: some View {
          LazyVGrid(columns: columns, spacing: AppConstants.defaultPadding) {
              MorningGreetingCardView(greeting: viewModel.morningGreeting, energyLogViewModel: viewModel) // Pass VM or specific state
          }
          .padding(AppConstants.defaultPadding)
      }
  }
  ```

---

**Task 6.2: Morning Greeting Card Implementation**

**Agent Task 6.2.1: Create MorningGreetingCard**
- File: `AirFit/Modules/Dashboard/Views/Cards/MorningGreetingCard.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct MorningGreetingCard: View {
      let greeting: String
      let context: GreetingContext?
      let currentEnergy: Int?
      let onEnergyLog: (Int) -> Void
      
      @State private var showEnergyPicker = false
      @State private var animateIn = false
      
      var body: some View {
          VStack(alignment: .leading, spacing: AppSpacing.medium) {
              // Greeting Text
              Text(greeting)
                  .font(AppFonts.title3)
                  .foregroundColor(AppColors.textPrimary)
                  .multilineTextAlignment(.leading)
                  .fixedSize(horizontal: false, vertical: true)
                  .opacity(animateIn ? 1 : 0)
                  .offset(y: animateIn ? 0 : 20)
              
              // Context Pills
              if let context = context {
                  contextPills(for: context)
                      .opacity(animateIn ? 1 : 0)
                      .offset(y: animateIn ? 0 : 20)
              }
              
              Divider()
                  .padding(.vertical, AppSpacing.xSmall)
              
              // Energy Logger
              VStack(alignment: .leading, spacing: AppSpacing.small) {
                  Text("How's your energy?")
                      .font(AppFonts.caption)
                      .foregroundColor(AppColors.textSecondary)
                  
                  if let energy = currentEnergy {
                      HStack {
                          EnergyLevelIndicator(level: energy)
                          Spacer()
                          Button("Update") {
                              showEnergyPicker = true
                          }
                          .font(AppFonts.caption)
                          .foregroundColor(AppColors.accentColor)
                      }
                  } else {
                      Button(action: { showEnergyPicker = true }) {
                          Label("Log Energy", systemImage: "bolt.fill")
                              .font(AppFonts.callout)
                              .frame(maxWidth: .infinity)
                              .padding(.vertical, AppSpacing.small)
                              .background(AppColors.accentColor.opacity(0.1))
                              .foregroundColor(AppColors.accentColor)
                              .cornerRadius(AppConstants.Layout.smallCornerRadius)
                      }
                  }
              }
              .opacity(animateIn ? 1 : 0)
              .offset(y: animateIn ? 0 : 20)
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(AppColors.cardBackground)
          .cornerRadius(AppConstants.Layout.defaultCornerRadius)
          .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
          .sheet(isPresented: $showEnergyPicker) {
              EnergyPickerSheet(
                  currentLevel: currentEnergy,
                  onSelect: { level in
                      onEnergyLog(level)
                      showEnergyPicker = false
                  }
              )
              .presentationDetents([.height(300)])
              .presentationDragIndicator(.visible)
          }
          .onAppear {
              withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                  animateIn = true
              }
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Morning greeting: \(greeting)")
          .accessibilityHint(currentEnergy == nil ? "Tap to log your energy level" : "Your energy is logged as \(currentEnergy!)")
      }
      
      @ViewBuilder
      private func contextPills(for context: GreetingContext) -> some View {
          ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: AppSpacing.small) {
                  if let sleep = context.sleepHours {
                      ContextPill(
                          icon: "bed.double.fill",
                          text: "\(Int(sleep))h sleep",
                          color: sleep >= 7 ? .green : .orange
                      )
                  }
                  
                  if let weather = context.weather {
                      ContextPill(
                          icon: weatherIcon(for: weather),
                          text: weather,
                          color: .blue
                      )
                  }
                  
                  if let temp = context.temperature {
                      ContextPill(
                          icon: "thermometer",
                          text: "\(Int(temp))°",
                          color: temperatureColor(for: temp)
                      )
                  }
              }
          }
      }
      
      private func weatherIcon(for condition: String) -> String {
          switch condition.lowercased() {
          case "sunny", "clear": return "sun.max.fill"
          case "cloudy": return "cloud.fill"
          case "rainy", "rain": return "cloud.rain.fill"
          case "snow": return "cloud.snow.fill"
          default: return "cloud.sun.fill"
          }
      }
      
      private func temperatureColor(for temp: Double) -> Color {
          switch temp {
          case ..<10: return .blue
          case 10..<20: return .teal
          case 20..<30: return .green
          default: return .orange
          }
      }
  }
  
  // MARK: - Supporting Views
  struct ContextPill: View {
      let icon: String
      let text: String
      let color: Color
      
      var body: some View {
          Label(text, systemImage: icon)
              .font(AppFonts.caption)
              .padding(.horizontal, AppSpacing.small)
              .padding(.vertical, 4)
              .background(color.opacity(0.15))
              .foregroundColor(color)
              .cornerRadius(12)
      }
  }
  
  struct EnergyLevelIndicator: View {
      let level: Int
      
      private var emoji: String {
          switch level {
          case 1: return "😴"
          case 2: return "😪"
          case 3: return "😐"
          case 4: return "😊"
          case 5: return "🔥"
          default: return "😐"
          }
      }
      
      private var description: String {
          switch level {
          case 1: return "Very Low"
          case 2: return "Low"
          case 3: return "Moderate"
          case 4: return "Good"
          case 5: return "Excellent"
          default: return "Unknown"
          }
      }
      
      var body: some View {
          HStack(spacing: AppSpacing.small) {
              Text(emoji)
                  .font(.title2)
              
              VStack(alignment: .leading, spacing: 2) {
                  Text("Energy: \(description)")
                      .font(AppFonts.footnote)
                      .foregroundColor(AppColors.textPrimary)
                  
                  HStack(spacing: 2) {
                      ForEach(1...5, id: \.self) { i in
                          RoundedRectangle(cornerRadius: 2)
                              .fill(i <= level ? AppColors.accentColor : AppColors.dividerColor)
                              .frame(width: 20, height: 4)
                      }
                  }
              }
          }
      }
  }
  
  struct EnergyPickerSheet: View {
      let currentLevel: Int?
      let onSelect: (Int) -> Void
      
      @State private var selectedLevel: Int?
      @Environment(\.dismiss) private var dismiss
      
      var body: some View {
          NavigationStack {
              VStack(spacing: AppSpacing.large) {
                  Text("How's your energy today?")
                      .font(AppFonts.title3)
                      .padding(.top)
                  
                  HStack(spacing: AppSpacing.medium) {
                      ForEach(1...5, id: \.self) { level in
                          EnergyOption(
                              level: level,
                              isSelected: selectedLevel == level,
                              onTap: {
                                  selectedLevel = level
                                  HapticManager.shared.impact(.light)
                                  onSelect(level)
                              }
                          )
                      }
                  }
                  .padding(.horizontal)
                  
                  Spacer()
              }
              .navigationTitle("Log Energy")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                  ToolbarItem(placement: .navigationBarTrailing) {
                      Button("Cancel") {
                          dismiss()
                      }
                  }
              }
          }
          .onAppear {
              selectedLevel = currentLevel
          }
      }
  }
  
  struct EnergyOption: View {
      let level: Int
      let isSelected: Bool
      let onTap: () -> Void
      
      private var emoji: String {
          switch level {
          case 1: return "😴"
          case 2: return "😪"
          case 3: return "😐"
          case 4: return "😊"
          case 5: return "🔥"
          default: return "😐"
          }
      }
      
      var body: some View {
          VStack(spacing: AppSpacing.small) {
              Text(emoji)
                  .font(.system(size: 44))
              
              Text("\(level)")
                  .font(AppFonts.caption)
                  .foregroundColor(isSelected ? AppColors.accentColor : AppColors.textSecondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, AppSpacing.medium)
          .background(
              RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                  .fill(isSelected ? AppColors.accentColor.opacity(0.1) : AppColors.cardBackground)
                  .overlay(
                      RoundedRectangle(cornerRadius: AppConstants.Layout.defaultCornerRadius)
                          .stroke(isSelected ? AppColors.accentColor : AppColors.dividerColor, lineWidth: 2)
                  )
          )
          .scaleEffect(isSelected ? 1.05 : 1.0)
          .onTapGesture(perform: onTap)
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
      }
  }
  ```

---

**Task 6.3: Nutrition Card Implementation**

**Agent Task 6.3.1: Create NutritionCard**
- File: `AirFit/Modules/Dashboard/Views/Cards/NutritionCard.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct NutritionCard: View {
      let summary: NutritionSummary
      let targets: NutritionTargets
      
      @State private var animateRings = false
      
      private var caloriesProgress: Double {
          min(summary.calories / targets.calories, 1.0)
      }
      
      private var proteinProgress: Double {
          min(summary.protein / targets.protein, 1.0)
      }
      
      private var carbsProgress: Double {
          min(summary.carbs / targets.carbs, 1.0)
      }
      
      private var fatProgress: Double {
          min(summary.fat / targets.fat, 1.0)
      }
      
      var body: some View {
          VStack(alignment: .leading, spacing: AppSpacing.medium) {
              // Header
              HStack {
                  Label("Nutrition", systemImage: "fork.knife")
                      .font(AppFonts.headline)
                      .foregroundColor(AppColors.textPrimary)
                  
                  Spacer()
                  
                  Image(systemName: "chevron.right")
                      .font(.caption)
                      .foregroundColor(AppColors.textTertiary)
              }
              
              // Macro Rings
              HStack(spacing: AppSpacing.medium) {
                  // Main calories ring
                  ZStack {
                      AnimatedRing(
                          progress: animateRings ? caloriesProgress : 0,
                          gradient: AppColors.caloriesGradient,
                          lineWidth: 12
                      )
                      .frame(width: 80, height: 80)
                      
                      VStack(spacing: 2) {
                          Text("\(Int(summary.calories))")
                              .font(AppFonts.headline)
                              .foregroundColor(AppColors.textPrimary)
                          Text("cal")
                              .font(AppFonts.caption)
                              .foregroundColor(AppColors.textSecondary)
                      }
                  }
                  
                  // Macro breakdown
                  VStack(alignment: .leading, spacing: AppSpacing.small) {
                      MacroRow(
                          label: "Protein",
                          value: summary.protein,
                          target: targets.protein,
                          color: AppColors.proteinColor
                      )
                      
                      MacroRow(
                          label: "Carbs",
                          value: summary.carbs,
                          target: targets.carbs,
                          color: AppColors.carbsColor
                      )
                      
                      MacroRow(
                          label: "Fat",
                          value: summary.fat,
                          target: targets.fat,
                          color: AppColors.fatColor
                      )
                  }
              }
              
              // Water intake
              HStack {
                  Image(systemName: "drop.fill")
                      .foregroundColor(.blue)
                      .font(.caption)
                  
                  Text("\(summary.waterLiters, specifier: "%.1f")L / \(targets.water, specifier: "%.1f")L")
                      .font(AppFonts.caption)
                      .foregroundColor(AppColors.textSecondary)
                  
                  Spacer()
                  
                  ProgressView(value: min(summary.waterLiters / targets.water, 1.0))
                      .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                      .frame(width: 60)
              }
          }
          .padding()
          .background(AppColors.cardBackground)
          .cornerRadius(AppConstants.Layout.defaultCornerRadius)
          .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
          .onAppear {
              withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                  animateRings = true
              }
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("Nutrition: \(Int(summary.calories)) calories consumed")
      }
  }
  
  struct MacroRow: View {
      let label: String
      let value: Double
      let target: Double
      let color: Color
      
      private var progress: Double {
          min(value / target, 1.0)
      }
      
      var body: some View {
          HStack(spacing: AppSpacing.small) {
              Circle()
                  .fill(color)
                  .frame(width: 8, height: 8)
              
              Text(label)
                  .font(AppFonts.caption)
                  .foregroundColor(AppColors.textSecondary)
                  .frame(width: 50, alignment: .leading)
              
              Text("\(Int(value))g")
                  .font(AppFonts.caption)
                  .foregroundColor(AppColors.textPrimary)
              
              ProgressView(value: progress)
                  .progressViewStyle(LinearProgressViewStyle(tint: color))
                  .frame(width: 40)
          }
      }
  }
  ```

**Agent Task 6.3.2: Create AnimatedRing Component**
- File: `AirFit/Modules/Dashboard/Views/Components/AnimatedRing.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct AnimatedRing: View {
      let progress: Double
      let gradient: LinearGradient
      let lineWidth: CGFloat
      
      @State private var animatedProgress: Double = 0
      
      var body: some View {
          ZStack {
              // Background ring
              Circle()
                  .stroke(AppColors.dividerColor, lineWidth: lineWidth)
              
              // Progress ring
              Circle()
                  .trim(from: 0, to: animatedProgress)
                  .stroke(gradient, style: StrokeStyle(
                      lineWidth: lineWidth,
                      lineCap: .round
                  ))
                  .rotationEffect(.degrees(-90))
                  .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedProgress)
          }
          .onChange(of: progress) { _, newValue in
              animatedProgress = newValue
          }
          .onAppear {
              animatedProgress = progress
          }
      }
  }
  ```

---

**Task 6.4: Recovery and Performance Cards**

**Agent Task 6.4.1: Create RecoveryCard**
- File: `AirFit/Modules/Dashboard/Views/Cards/RecoveryCard.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct RecoveryCard: View {
      let score: RecoveryScore?
      
      @State private var animateScore = false
      
      private var scoreColor: Color {
          guard let score = score else { return AppColors.textSecondary }
          switch score.score {
          case 80...: return .green
          case 60..<80: return .yellow
          default: return .orange
          }
      }
      
      var body: some View {
          VStack(alignment: .leading, spacing: AppSpacing.medium) {
              // Header
              HStack {
                  Label("Recovery", systemImage: "heart.fill")
                      .font(AppFonts.headline)
                      .foregroundColor(AppColors.textPrimary)
                  
                  Spacer()
                  
                  if let trend = score?.trend {
                      TrendIndicator(trend: trend)
                  }
              }
              
              // Score Display
              if let score = score {
                  HStack(alignment: .bottom) {
                      Text("\(score.score)")
                          .font(.system(size: 48, weight: .bold, design: .rounded))
                          .foregroundColor(scoreColor)
                          .opacity(animateScore ? 1 : 0)
                          .scaleEffect(animateScore ? 1 : 0.5)
                      
                      Text("/ 100")
                          .font(AppFonts.body)
                          .foregroundColor(AppColors.textSecondary)
                          .padding(.bottom, 8)
                  }
                  
                  // Key Components
                  VStack(alignment: .leading, spacing: 4) {
                      ForEach(score.components.prefix(3), id: \.name) { component in
                          HStack {
                              Text(component.name)
                                  .font(AppFonts.caption)
                                  .foregroundColor(AppColors.textSecondary)
                              
                              Spacer()
                              
                              Text("\(Int(component.value * 100))%")
                                  .font(AppFonts.caption)
                                  .foregroundColor(AppColors.textPrimary)
                          }
                      }
                  }
              } else {
                  // No data state
                  VStack(spacing: AppSpacing.small) {
                      Image(systemName: "heart.slash")
                          .font(.title)
                          .foregroundColor(AppColors.textTertiary)
                      
                      Text("No recovery data")
                          .font(AppFonts.caption)
                          .foregroundColor(AppColors.textSecondary)
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical)
              }
          }
          .padding()
          .background(AppColors.cardBackground)
          .cornerRadius(AppConstants.Layout.defaultCornerRadius)
          .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
          .onAppear {
              withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                  animateScore = true
              }
          }
      }
  }
  
  struct PerformanceCard: View {
      let insight: PerformanceInsight?
      
      var body: some View {
          VStack(alignment: .leading, spacing: AppSpacing.medium) {
              // Header
              HStack {
                  Label("Performance", systemImage: "chart.line.uptrend.xyaxis")
                      .font(AppFonts.headline)
                      .foregroundColor(AppColors.textPrimary)
                  
                  Spacer()
                  
                  if let trend = insight?.trend {
                      TrendIndicator(trend: trend)
                  }
              }
              
              // Content
              if let insight = insight {
                  Text(insight.summary)
                      .font(AppFonts.body)
                      .foregroundColor(AppColors.textPrimary)
                      .fixedSize(horizontal: false, vertical: true)
                  
                  HStack {
                      Text(insight.keyMetric)
                          .font(AppFonts.caption)
                          .foregroundColor(AppColors.textSecondary)
                      
                      Spacer()
                      
                      Text("\(insight.value, specifier: "%.1f")")
                          .font(AppFonts.headline)
                          .foregroundColor(AppColors.accentColor)
                  }
              } else {
                  // No data state
                  VStack(spacing: AppSpacing.small) {
                      Image(systemName: "chart.xyaxis.line")
                          .font(.title)
                          .foregroundColor(AppColors.textTertiary)
                      
                      Text("Building your insights...")
                          .font(AppFonts.caption)
                          .foregroundColor(AppColors.textSecondary)
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical)
              }
          }
          .padding()
          .background(AppColors.cardBackground)
          .cornerRadius(AppConstants.Layout.defaultCornerRadius)
          .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
      }
  }
  
  // MARK: - Shared Components
  struct TrendIndicator: View {
      let trend: Any
      
      private var icon: String {
          if let recoveryTrend = trend as? RecoveryScore.Trend {
              switch recoveryTrend {
              case .improving: return "arrow.up.circle.fill"
              case .steady: return "minus.circle.fill"
              case .declining: return "arrow.down.circle.fill"
              }
          } else if let performanceTrend = trend as? PerformanceInsight.Trend {
              switch performanceTrend {
              case .up: return "arrow.up.circle.fill"
              case .steady: return "minus.circle.fill"
              case .down: return "arrow.down.circle.fill"
              }
          }
          return "minus.circle.fill"
      }
      
      private var color: Color {
          if let recoveryTrend = trend as? RecoveryScore.Trend {
              switch recoveryTrend {
              case .improving: return .green
              case .steady: return .yellow
              case .declining: return .orange
              }
          } else if let performanceTrend = trend as? PerformanceInsight.Trend {
              switch performanceTrend {
              case .up: return .green
              case .steady: return .yellow
              case .down: return .orange
              }
          }
          return .gray
      }
      
      var body: some View {
          Image(systemName: icon)
              .font(.caption)
              .foregroundColor(color)
      }
  }
  ```

---

**Task 6.5: Quick Actions Card**

**Agent Task 6.5.1: Create QuickActionsCard**
- File: `AirFit/Modules/Dashboard/Views/Cards/QuickActionsCard.swift`
- Implementation:
  ```swift
  import SwiftUI
  
  struct QuickActionsCard: View {
      let actions: [QuickAction]
      
      var body: some View {
          VStack(alignment: .leading, spacing: AppSpacing.medium) {
              Text("Quick Actions")
                  .font(AppFonts.headline)
                  .foregroundColor(AppColors.textPrimary)
              
              ForEach(actions) { action in
                  QuickActionButton(action: action)
              }
          }
          .padding()
          .background(AppColors.cardBackground)
          .cornerRadius(AppConstants.Layout.defaultCornerRadius)
          .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
      }
  }
  
  struct QuickActionButton: View {
      let action: QuickAction
      
      var body: some View {
          Button(action: handleAction) {
              HStack {
                  Image(systemName: action.systemImage)
                      .font(.title3)
                      .foregroundColor(AppColors.accentColor)
                      .frame(width: 32)
                  
                  Text(action.title)
                      .font(AppFonts.body)
                      .foregroundColor(AppColors.textPrimary)
                  
                  Spacer()
                  
                  Image(systemName: "chevron.right")
                      .font(.caption)
                      .foregroundColor(AppColors.textTertiary)
              }
              .padding(.vertical, AppSpacing.small)
          }
          .buttonStyle(PlainButtonStyle())
      }
      
      private func handleAction() {
          switch action {
          case .logMeal(let type):
              // Navigate to meal logging
              AppLogger.info("Quick action: Log \(type.displayName)", category: .ui)
          case .startWorkout:
              // Navigate to workout
              AppLogger.info("Quick action: Start workout", category: .ui)
          case .logWater:
              // Show water logging
              AppLogger.info("Quick action: Log water", category: .ui)
          case .checkIn:
              // Show check-in
              AppLogger.info("Quick action: Daily check-in", category: .ui)
          }
      }
  }
  ```

---

**4. Testing Requirements**

### Unit Tests

**Agent Task 6.12.1: Create DashboardViewModel Tests**
- File: `AirFitTests/Dashboard/DashboardViewModelTests.swift`
- Required Test Cases:
  ```swift
  @MainActor
  final class DashboardViewModelTests: XCTestCase {
      var sut: DashboardViewModel!
      var mockHealthKit: MockHealthKitService!
      var mockAICoach: MockAICoachService!
      var mockNutrition: MockNutritionService!
      var modelContext: ModelContext!
      var testUser: User!
      
      override func setUp() async throws {
          try await super.setUp()
          
          // Setup in-memory context
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, DailyLog.self, FoodEntry.self
          )
          
          // Create test user
          testUser = User(name: "Test User")
          modelContext.insert(testUser)
          try modelContext.save()
          
          // Setup mocks
          mockHealthKit = MockHealthKitService()
          mockAICoach = MockAICoachService()
          mockNutrition = MockNutritionService()
          
          // Create SUT
          sut = DashboardViewModel(
              user: testUser,
              modelContext: modelContext,
              healthKitService: mockHealthKit,
              aiCoachService: mockAICoach,
              nutritionService: mockNutrition
          )
      }
      
      func test_onAppear_shouldLoadAllData() async {
          // Arrange
          mockHealthKit.mockContext = HealthContext(
              lastNightSleepDurationHours: 7.5,
              sleepQuality: 4,
              currentWeatherCondition: "Sunny",
              currentTemperatureCelsius: 22,
              yesterdayEnergyLevel: 3,
              currentHeartRate: 65,
              hrv: 45,
              steps: 5000
          )
          
          mockAICoach.mockGreeting = "Good morning! You got great sleep!"
          
          mockNutrition.mockSummary = NutritionSummary(
              calories: 1200,
              protein: 80,
              carbs: 150,
              fat: 40,
              fiber: 20,
              waterLiters: 1.5,
              meals: [:]
          )
          
          // Act
          await sut.onAppear()
          
          // Allow async operations to complete
          try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
          
          // Assert
          XCTAssertFalse(sut.isLoading)
          XCTAssertEqual(sut.morningGreeting, "Good morning! You got great sleep!")
          XCTAssertEqual(sut.nutritionSummary.calories, 1200)
          XCTAssertTrue(mockHealthKit.getCurrentContextCalled)
          XCTAssertTrue(mockAICoach.generateGreetingCalled)
          XCTAssertTrue(mockNutrition.getTodaysSummaryCalled)
      }
      
      func test_logEnergyLevel_shouldSaveToDatabase() async throws {
          // Act
          await sut.logEnergyLevel(4)
          
          // Assert
          let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
          XCTAssertEqual(logs.count, 1)
          XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 4)
          XCTAssertEqual(sut.currentEnergyLevel, 4)
          XCTAssertFalse(sut.isLoggingEnergy)
      }
      
      func test_logEnergyLevel_withExistingLog_shouldUpdate() async throws {
          // Arrange
          let existingLog = DailyLog(date: Date(), user: testUser)
          existingLog.subjectiveEnergyLevel = 2
          modelContext.insert(existingLog)
          try modelContext.save()
          
          // Act
          await sut.logEnergyLevel(5)
          
          // Assert
          let logs = try modelContext.fetch(FetchDescriptor<DailyLog>())
          XCTAssertEqual(logs.count, 1)
          XCTAssertEqual(logs.first?.subjectiveEnergyLevel, 5)
      }
  }
  ```

### UI Tests

**Agent Task 6.12.2: Create Dashboard UI Tests**
- File: `AirFitUITests/Dashboard/DashboardUITests.swift`
- Required Test Scenarios:
  ```swift
  final class DashboardUITests: XCTestCase {
      var app: XCUIApplication!
      
      override func setUp() {
          super.setUp()
          continueAfterFailure = false
          
          app = XCUIApplication()
          app.launchArguments = ["--uitesting", "--skip-onboarding"]
          app.launch()
      }
      
      func test_dashboard_displaysAllCards() {
          // Wait for dashboard to load
          let dashboard = app.scrollViews["dashboard.scrollview"]
          XCTAssertTrue(dashboard.waitForExistence(timeout: 5))
          
          // Verify cards exist
          XCTAssertTrue(app.staticTexts["Good morning"].exists)
          XCTAssertTrue(app.staticTexts["Nutrition"].exists)
          XCTAssertTrue(app.staticTexts["Recovery"].exists)
          XCTAssertTrue(app.staticTexts["Performance"].exists)
      }
      
      func test_energyLogging_workflow() {
          // Tap log energy button
          let logButton = app.buttons["Log Energy"]
          XCTAssertTrue(logButton.waitForExistence(timeout: 5))
          logButton.tap()
          
          // Select energy level
          let energyOption = app.buttons["energy.option.4"]
          XCTAssertTrue(energyOption.waitForExistence(timeout: 2))
          energyOption.tap()
          
          // Verify update
          XCTAssertTrue(app.staticTexts["Energy: Good"].waitForExistence(timeout: 2))
      }
      
      func test_nutritionCard_tapShowsDetail() {
          // Tap nutrition card
          let nutritionCard = app.buttons["dashboard.nutrition.card"]
          XCTAssertTrue(nutritionCard.waitForExistence(timeout: 5))
          nutritionCard.tap()
          
          // Verify detail view appears
          XCTAssertTrue(app.navigationBars["Nutrition Details"].waitForExistence(timeout: 2))
      }
      
      func test_pullToRefresh_updatesData() {
          // Pull to refresh
          let dashboard = app.scrollViews["dashboard.scrollview"]
          dashboard.swipeDown(velocity: .fast)
          
          // Verify loading indicator
          XCTAssertTrue(app.activityIndicators.firstMatch.exists)
          
          // Wait for refresh to complete
          XCTAssertFalse(app.activityIndicators.firstMatch.waitForExistence(timeout: 3))
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ Dashboard displays with adaptive grid layout for different screen sizes
- ✅ Morning greeting shows AI-generated personalized message
- ✅ Energy logging works with haptic feedback and saves to database
- ✅ Nutrition card displays animated macro rings with accurate progress
- ✅ Recovery and Performance cards show health insights
- ✅ Quick actions provide relevant shortcuts based on context
- ✅ Pull-to-refresh updates all dashboard data
- ✅ All animations are smooth and performant (60fps)
- ✅ Accessibility labels and hints on all interactive elements
- ✅ Dashboard loads within 1 second on iPhone 16 Pro
- ✅ Memory usage stays under 100MB
- ✅ Unit test coverage ≥ 80% for ViewModel
- ✅ UI tests cover all major interactions
- ✅ No SwiftLint violations
- ✅ Works in both light and dark modes

**6. Module Dependencies**

- **Requires Completion Of:** Modules 1, 2, 3, partial Module 10
- **Must Be Completed Before:** Module 5 (Meal Logging uses dashboard)
- **Can Run In Parallel With:** Module 7 (Settings), Module 11 (Notifications)

**7. Performance Requirements**

- Initial load: < 1 second
- Animation frame rate: 60fps on ProMotion displays
- Data refresh: < 2 seconds
- Memory usage: < 100MB
- Energy logging response: < 100ms

---
