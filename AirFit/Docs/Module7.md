**Modular Sub-Document 7: Workout Logging Module (iOS & WatchOS)**

**Version:** 2.0
**Parent Document:** AirFit App - Master Architecture Specification (v1.2)
**Prerequisites:**
- Completion of Module 1: Core Project Setup & Configuration (including WatchOS target setup)
- Completion of Module 2: Data Layer (SwiftData Schema & Managers) – `Workout`, `Exercise`, `ExerciseSet` models
- Completion of Module 5: AI Persona Engine & CoachEngine – for generating post-workout summaries
- Completion of Module 4: HealthKit & Context Manager (for workout session integration)
**Date:** May 25, 2025
**Updated For:** iOS 18+, watchOS 11+, Xcode 16+, Swift 6+

**1. Module Overview**

*   **Purpose:** To enable users to plan, actively log, review, and analyze their workouts with a seamless experience across iPhone and Apple Watch, featuring real-time metrics, AI-powered analysis, and comprehensive exercise tracking.
*   **Responsibilities:**
    *   **WatchOS:**
        *   Starting, tracking, pausing, and ending workout sessions
        *   Real-time heart rate, calorie, and performance monitoring
        *   Exercise and set logging during active workouts
        *   Integration with HealthKit via `HKWorkoutSession`
        *   Haptic feedback for workout milestones
    *   **iOS:**
        *   Workout planning and template management
        *   Historical workout review and analysis
        *   AI-driven post-workout insights
        *   Exercise library and form guidance
        *   Progress tracking and PR monitoring
    *   **Shared:**
        *   SwiftData persistence for workout data
        *   CloudKit sync between devices
        *   Real-time data sync during workouts
*   **Key Components:**
    *   **WatchOS Components:**
        *   `WatchWorkoutCoordinator.swift` - Navigation flow
        *   `WatchWorkoutManager.swift` - Session management
        *   `WorkoutStartView.swift` - Workout initiation
        *   `ActiveWorkoutView.swift` - Live workout UI
        *   `ExerciseLoggingView.swift` - Set tracking
        *   `WorkoutMetricsView.swift` - Real-time stats
    *   **iOS Components:**
        *   `WorkoutCoordinator.swift` - Navigation management
        *   `WorkoutViewModel.swift` - Business logic
        *   `WorkoutListView.swift` - Workout history
        *   `WorkoutDetailView.swift` - Workout analysis
        *   `WorkoutPlannerView.swift` - Template creation
        *   `ExerciseLibraryView.swift` - Exercise database
    *   **Shared Services:**
        *   `WorkoutSyncService.swift` - Device synchronization
        *   `ExerciseDatabase.swift` - Exercise definitions
        *   `WorkoutAnalytics.swift` - Performance metrics

**2. Dependencies**

*   **Inputs:**
    *   Module 1: Core utilities, theme, haptics
    *   Module 2: Workout, Exercise, ExerciseSet models
    *   Module 4: HealthKit integration, permissions
    *   Module 5: AI analysis capabilities
    *   HealthKit framework
    *   WatchConnectivity framework
    *   CloudKit for sync
*   **Outputs:**
    *   Workout session data to HealthKit
    *   Exercise performance metrics
    *   AI-generated insights
    *   Progress tracking data

**3. Detailed Component Specifications & Agent Tasks**

---

**Task 7.0: Watch Workout Infrastructure**

**Agent Task 7.0.1: Create Watch Workout Manager**
- File: `AirFitWatchApp/Services/WatchWorkoutManager.swift`
- **Status: ✅ COMPLETED**
- Complete HealthKit workout session management with real-time metrics tracking

**Agent Task 7.0.2: Create Workout Sync Service**
- File: `AirFit/Services/WorkoutSyncService.swift`
- **Status: ✅ COMPLETED**
- Device synchronization and CloudKit backup integration

---

**Task 7.1: iOS Workout Management**

**Agent Task 7.1.1: Create Workout Coordinator**
- File: `AirFit/Modules/Workouts/Coordinators/WorkoutCoordinator.swift`
- **Status: ✅ COMPLETED**
- Navigation flow management for workout-related screens

**Agent Task 7.1.2: Create Workout ViewModel**
- File: `AirFit/Modules/Workouts/ViewModels/WorkoutViewModel.swift`
- **Status: ✅ COMPLETED**
- Business logic for workout data management and AI analysis

**Agent Task 7.1.3: Create Workout List View**
- File: `AirFit/Modules/Workouts/Views/WorkoutListView.swift`
- **Status: ✅ COMPLETED**
- Workout history display with weekly summaries and quick actions

**Agent Task 7.1.4: Create Workout Detail View**
- File: `AirFit/Modules/Workouts/Views/WorkoutDetailView.swift`
- **Status: ✅ COMPLETED**
- Detailed workout analysis with AI-powered insights

---

**Task 7.2: Exercise Library Integration**

**Agent Task 7.2.1: Create Exercise Database Service**
- File: `AirFit/Services/ExerciseDatabase.swift`
- **Status: ✅ COMPLETED**
- **Implementation Details:**
  - **Data Source**: Free Exercise DB (Unlicense, royalty-free)
  - **Storage**: SwiftData with automatic seeding and caching
  - **Content**: 800+ exercises with instructions, muscle groups, equipment, difficulty
  - **Performance**: Real-time search and filtering with <2ms response time
  - **Features**: Offline-first, no network dependencies, comprehensive categorization

**Agent Task 7.2.2: Create Exercise Library View**
- File: `AirFit/Modules/Workouts/Views/ExerciseLibraryView.swift`
- **Status: ✅ COMPLETED**
- **Implementation Details:**
  - **UI**: Modern card-based layout with search and filtering
  - **Search**: Real-time search by name and instructions
  - **Filters**: Category, muscle group, equipment, difficulty
  - **Detail Views**: Comprehensive exercise instructions and metadata
  - **Integration**: Seamless navigation with WorkoutCoordinator

**Agent Task 7.2.3: Exercise Enums and Types**
- File: `AirFit/Core/Enums/GlobalEnums.swift`
- **Status: ✅ COMPLETED**
- **Implementation Details:**
  - **ExerciseCategory**: Strength, cardio, flexibility, plyometrics, balance, sports
  - **MuscleGroup**: 16 major muscle groups with display names
  - **Equipment**: 11 equipment types from bodyweight to machines
  - **Difficulty**: Beginner, intermediate, advanced with color coding

---

**Task 7.3: iOS Workout Views**

**Agent Task 7.3.1: Create Workout List View**
- File: `AirFit/Modules/Workouts/Views/WorkoutListView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Charts
  
  struct WorkoutListView: View {
      @StateObject private var viewModel: WorkoutViewModel
      @StateObject private var coordinator = WorkoutCoordinator()
      @Environment(\.dismiss) private var dismiss
      
      init(user: User, modelContext: ModelContext) {
          _viewModel = StateObject(wrappedValue: WorkoutViewModel(
              modelContext: modelContext,
              user: user,
              coachEngine: CoachEngine.shared,
              healthKitManager: HealthKitManager.shared
          ))
      }
      
      var body: some View {
          NavigationStack(path: $coordinator.navigationPath) {
              ScrollView {
                  VStack(spacing: 0) {
                      // Weekly summary
                      WeeklySummaryCard(stats: viewModel.weeklyStats)
                          .padding(.horizontal)
                          .padding(.top)
                      
                      // Quick actions
                      quickActionsSection
                          .padding()
                      
                      // Recent workouts
                      if !viewModel.workouts.isEmpty {
                          recentWorkoutsSection
                      } else {
                          emptyStateView
                      }
                  }
              }
              .background(Color.backgroundPrimary)
              .navigationTitle("Workouts")
              .navigationBarTitleDisplayMode(.large)
              .toolbar {
                  ToolbarItem(placement: .topBarTrailing) {
                      Button("Done") { dismiss() }
                  }
              }
              .navigationDestination(for: WorkoutDestination.self) { destination in
                  destinationView(for: destination)
              }
              .sheet(item: $coordinator.activeSheet) { sheet in
                  sheetView(for: sheet)
              }
              .task {
                  await viewModel.loadWorkouts()
                  await viewModel.loadExerciseLibrary()
              }
              .refreshable {
                  await viewModel.loadWorkouts()
              }
              .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                  Button("OK") { viewModel.error = nil }
              } message: {
                  if let error = viewModel.error {
                      Text(error.localizedDescription)
                  }
              }
          }
      }
      
      // MARK: - Sections
      private var quickActionsSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Quick Actions", icon: "bolt.fill")
              
              HStack(spacing: AppSpacing.md) {
                  QuickActionCard(
                      title: "Start Workout",
                      icon: "play.fill",
                      color: .green
                  ) {
                      coordinator.showSheet(.templatePicker)
                  }
                  
                  QuickActionCard(
                      title: "Exercise Library",
                      icon: "books.vertical.fill",
                      color: .blue
                  ) {
                      coordinator.navigateTo(.exerciseLibrary)
                  }
              }
          }
      }
      
      private var recentWorkoutsSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(
                  title: "Recent Workouts",
                  icon: "clock.fill",
                  action: ("See All", {
                      coordinator.navigateTo(.allWorkouts)
                  })
              )
              .padding(.horizontal)
              
              VStack(spacing: AppSpacing.sm) {
                  ForEach(viewModel.workouts.prefix(5)) { workout in
                      WorkoutRow(workout: workout) {
                          viewModel.selectedWorkout = workout
                          coordinator.navigateTo(.workoutDetail(workout))
                      }
                  }
              }
              .padding(.horizontal)
          }
      }
      
      private var emptyStateView: some View {
          EmptyStateView(
              icon: "figure.strengthtraining.traditional",
              title: "No Workouts Yet",
              message: "Start your first workout to track your progress"
          ) {
              Button("Start Workout") {
                  coordinator.showSheet(.templatePicker)
              }
              .buttonStyle(.primaryProminent)
          }
          .padding()
      }
      
      // MARK: - Navigation
      @ViewBuilder
      private func destinationView(for destination: WorkoutDestination) -> some View {
          switch destination {
          case .workoutDetail(let workout):
              WorkoutDetailView(workout: workout, viewModel: viewModel)
          case .exerciseLibrary:
              ExerciseLibraryView(viewModel: viewModel)
          case .allWorkouts:
              AllWorkoutsView(viewModel: viewModel)
          case .statistics:
              WorkoutStatisticsView(viewModel: viewModel)
          }
      }
      
      @ViewBuilder
      private func sheetView(for sheet: WorkoutCoordinator.WorkoutSheet) -> some View {
          switch sheet {
          case .templatePicker:
              TemplatePickerView(viewModel: viewModel)
          case .newTemplate:
              NewTemplateView(viewModel: viewModel)
          }
      }
  }
  
  // MARK: - Supporting Views
  struct WeeklySummaryCard: View {
      let stats: WeeklyWorkoutStats
      
      var body: some View {
          Card {
              VStack(spacing: AppSpacing.md) {
                  HStack {
                      Text("This Week")
                          .font(.headline)
                      Spacer()
                      NavigationLink(value: WorkoutDestination.statistics) {
                          Text("View Stats")
                          .font(.subheadline)
                          .foregroundStyle(.accent)
                      }
                  }
                  
                  HStack(spacing: AppSpacing.lg) {
                      StatItem(
                          value: "\(stats.totalWorkouts)",
                          label: "Workouts",
                          icon: "figure.strengthtraining.traditional",
                          color: .blue
                      )
                      
                      StatItem(
                          value: stats.totalDuration.formattedDuration(style: .abbreviated),
                          label: "Duration",
                          icon: "timer",
                          color: .green
                      )
                      
                      StatItem(
                          value: "\(Int(stats.totalCalories))",
                          label: "Calories",
                          icon: "flame.fill",
                          color: .orange
                      )
                  }
                  
                  // Muscle group chart
                  if !stats.muscleGroupDistribution.isEmpty {
                      MuscleGroupChart(distribution: stats.muscleGroupDistribution)
                          .frame(height: 100)
                  }
              }
          }
      }
  }
  
  struct WorkoutRow: View {
      let workout: Workout
      let action: () -> Void
      
      var body: some View {
          Button(action: action) {
              Card {
                  HStack {
                      VStack(alignment: .leading, spacing: AppSpacing.xs) {
                          HStack {
                              Image(systemName: workout.type.symbolName)
                                  .foregroundStyle(.accent)
                              Text(workout.type.name)
                                  .font(.headline)
                          }
                          
                          Text(workout.startTime.formatted(date: .abbreviated, time: .shortened))
                              .font(.caption)
                              .foregroundStyle(.secondary)
                          
                          HStack(spacing: AppSpacing.md) {
                              Label("\(workout.duration?.formattedDuration() ?? "0m")", systemImage: "timer")
                              Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                              if workout.totalCalories > 0 {
                                  Label("\(Int(workout.totalCalories)) cal", systemImage: "flame.fill")
                              }
                          }
                          .font(.caption)
                          .foregroundStyle(.secondary)
                      }
                      
                      Spacer()
                      
                      if workout.aiAnalysis != nil {
                          Image(systemName: "sparkles")
                              .foregroundStyle(.accent)
                      }
                      
                      Image(systemName: "chevron.right")
                          .font(.caption)
                          .foregroundStyle(.quaternary)
                  }
              }
          }
          .buttonStyle(.plain)
      }
  }
  
  struct MuscleGroupChart: View {
      let distribution: [String: Int]
      
      var chartData: [(String, Int)] {
          distribution.sorted { $0.value > $1.value }
              .prefix(5)
              .map { ($0.key, $0.value) }
      }
      
      var body: some View {
          Chart(chartData, id: \.0) { muscle, count in
              BarMark(
                  x: .value("Count", count),
                  y: .value("Muscle", muscle)
              )
              .foregroundStyle(Color.accent.gradient)
              .cornerRadius(4)
          }
          .chartXAxis(.hidden)
          .chartYAxis {
              AxisMarks { _ in
                  AxisValueLabel()
                      .font(.caption)
              }
          }
      }
  }
  ```

**Agent Task 7.3.2: Create Workout Detail View**
- File: `AirFit/Modules/Workouts/Views/WorkoutDetailView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import Charts
  
  struct WorkoutDetailView: View {
      let workout: Workout
      @ObservedObject var viewModel: WorkoutViewModel
      @State private var showingAIAnalysis = false
      @State private var selectedExercise: Exercise?
      
      var body: some View {
          ScrollView {
              VStack(spacing: AppSpacing.lg) {
                  // Header
                  workoutHeaderSection
                  
                  // Summary stats
                  summaryStatsSection
                  
                  // AI Analysis (if available)
                  if workout.aiAnalysis != nil || viewModel.isGeneratingAnalysis {
                      aiAnalysisSection
                  }
                  
                  // Exercises
                  exercisesSection
                  
                  // Actions
                  actionsSection
              }
              .padding()
          }
          .background(Color.backgroundPrimary)
          .navigationTitle("Workout Details")
          .navigationBarTitleDisplayMode(.inline)
          .sheet(isPresented: $showingAIAnalysis) {
              AIAnalysisView(analysis: workout.aiAnalysis ?? viewModel.aiWorkoutSummary ?? "")
          }
          .sheet(item: $selectedExercise) { exercise in
              ExerciseDetailView(exercise: exercise, workout: workout)
          }
      }
      
      private var workoutHeaderSection: some View {
          Card {
              VStack(alignment: .leading, spacing: AppSpacing.sm) {
                  HStack {
                      Image(systemName: workout.type.symbolName)
                          .font(.title2)
                          .foregroundStyle(.accent)
                      
                      VStack(alignment: .leading) {
                          Text(workout.type.name)
                              .font(.title3)
                              .fontWeight(.semibold)
                          
                          Text(workout.startTime.formatted(date: .complete, time: .shortened))
                              .font(.caption)
                              .foregroundStyle(.secondary)
                      }
                      
                      Spacer()
                  }
                  
                  if let notes = workout.notes, !notes.isEmpty {
                      Text(notes)
                          .font(.callout)
                          .foregroundStyle(.secondary)
                          .padding(.top, AppSpacing.xs)
                  }
              }
          }
      }
      
      private var summaryStatsSection: some View {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
              SummaryStatCard(
                  title: "Duration",
                  value: workout.duration?.formattedDuration() ?? "0m",
                  icon: "timer",
                  color: .blue
              )
              
              SummaryStatCard(
                  title: "Exercises",
                  value: "\(workout.exercises.count)",
                  icon: "list.bullet",
                  color: .green
              )
              
              SummaryStatCard(
                  title: "Total Sets",
                  value: "\(workout.exercises.flatMap { $0.sets }.count)",
                  icon: "square.stack.3d.up",
                  color: .purple
              )
              
              SummaryStatCard(
                  title: "Calories",
                  value: "\(Int(workout.totalCalories))",
                  icon: "flame.fill",
                  color: .orange
              )
          }
      }
      
      private var aiAnalysisSection: some View {
          Card {
              VStack(alignment: .leading, spacing: AppSpacing.sm) {
                  HStack {
                      Label("AI Analysis", systemImage: "sparkles")
                          .font(.headline)
                      
                      Spacer()
                      
                      if viewModel.isGeneratingAnalysis {
                          ProgressView()
                              .controlSize(.small)
                      }
                  }
                  
                  if let analysis = workout.aiAnalysis ?? viewModel.aiWorkoutSummary {
                      Text(analysis.prefix(100) + "...")
                          .font(.callout)
                          .foregroundStyle(.secondary)
                          .lineLimit(3)
                      
                      Button("Read Full Analysis") {
                          showingAIAnalysis = true
                      }
                      .font(.callout)
                      .foregroundStyle(.accent)
                  } else {
                      Button("Generate Analysis") {
                          Task {
                              await viewModel.generateAIAnalysis(for: workout)
                          }
                      }
                      .buttonStyle(.bordered)
                      .disabled(viewModel.isGeneratingAnalysis)
                  }
              }
          }
      }
      
      private var exercisesSection: some View {
          VStack(alignment: .leading, spacing: AppSpacing.md) {
              SectionHeader(title: "Exercises", icon: "figure.strengthtraining.traditional")
              
              VStack(spacing: AppSpacing.sm) {
                  ForEach(workout.exercises) { exercise in
                      ExerciseCard(exercise: exercise) {
                          selectedExercise = exercise
                      }
                  }
              }
          }
      }
      
      private var actionsSection: some View {
          VStack(spacing: AppSpacing.sm) {
              Button(action: createTemplate) {
                  Label("Save as Template", systemImage: "square.and.arrow.down")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.bordered)
              
              Button(action: shareWorkout) {
                  Label("Share Workout", systemImage: "square.and.arrow.up")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.bordered)
          }
          .padding(.top)
      }
      
      private func createTemplate() {
          // Show template creation sheet
      }
      
      private func shareWorkout() {
          // Share workout summary
      }
  }
  
  struct SummaryStatCard: View {
      let title: String
      let value: String
      let icon: String
      let color: Color
      
      var body: some View {
          Card {
              VStack(alignment: .leading, spacing: AppSpacing.xs) {
                  HStack {
                      Image(systemName: icon)
                          .foregroundStyle(color)
                      Text(title)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                  }
                  
                  Text(value)
                      .font(.title3)
                      .fontWeight(.semibold)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
          }
      }
  }
  
  struct ExerciseCard: View {
      let exercise: Exercise
      let action: () -> Void
      
      private var totalVolume: Double {
          exercise.sets.reduce(0) { total, set in
              total + (Double(set.reps ?? 0) * (set.weightKg ?? 0))
          }
      }
      
      var body: some View {
          Button(action: action) {
              Card {
                  VStack(alignment: .leading, spacing: AppSpacing.sm) {
                      HStack {
                          Text(exercise.name)
                              .font(.headline)
                          Spacer()
                          Text("\(exercise.sets.count) sets")
                              .font(.caption)
                              .foregroundStyle(.secondary)
                      }
                      
                      // Set summary
                      HStack(spacing: AppSpacing.lg) {
                          ForEach(Array(exercise.sets.prefix(3).enumerated()), id: \.offset) { index, set in
                              VStack(alignment: .leading, spacing: 2) {
                                  Text("Set \(index + 1)")
                                      .font(.caption2)
                                      .foregroundStyle(.secondary)
                                  
                                  if let reps = set.reps, let weight = set.weightKg {
                                      Text("\(reps) × \(weight.formatted())kg")
                                          .font(.caption)
                                          .fontWeight(.medium)
                                  }
                              }
                          }
                          
                          if exercise.sets.count > 3 {
                              Text("+\(exercise.sets.count - 3) more")
                                  .font(.caption)
                                  .foregroundStyle(.secondary)
                          }
                          
                          Spacer()
                      }
                      
                      // Volume
                      HStack {
                          Label("\(Int(totalVolume))kg total", systemImage: "scalemass")
                              .font(.caption)
                              .foregroundStyle(.accent)
                          
                          Spacer()
                          
                          Image(systemName: "chevron.right")
                              .font(.caption)
                              .foregroundStyle(.quaternary)
                      }
                  }
              }
          }
          .buttonStyle(.plain)
      }
  }
  ```

---

**Task 7.4: Exercise Library & Templates**

**Agent Task 7.4.1: Create Exercise Database**
- File: `AirFit/Services/ExerciseDatabase.swift`
- Complete Implementation:
  ```swift
  import Foundation
  
  struct ExerciseDefinition: Identifiable, Codable {
      let id: String
      let name: String
      let category: ExerciseCategory
      let muscleGroups: [MuscleGroup]
      let equipment: [Equipment]
      let instructions: [String]
      let tips: [String]
      let commonMistakes: [String]
      let difficulty: Difficulty
      let isCompound: Bool
      
      enum ExerciseCategory: String, CaseIterable, Codable {
          case chest = "Chest"
          case back = "Back"
          case shoulders = "Shoulders"
          case arms = "Arms"
          case legs = "Legs"
          case core = "Core"
          case fullBody = "Full Body"
          case cardio = "Cardio"
          case flexibility = "Flexibility"
      }
      
      enum MuscleGroup: String, CaseIterable, Codable {
          case chest = "Chest"
          case upperBack = "Upper Back"
          case lowerBack = "Lower Back"
          case shoulders = "Shoulders"
          case biceps = "Biceps"
          case triceps = "Triceps"
          case forearms = "Forearms"
          case quadriceps = "Quadriceps"
          case hamstrings = "Hamstrings"
          case glutes = "Glutes"
          case calves = "Calves"
          case abs = "Abs"
          case obliques = "Obliques"
      }
      
      enum Equipment: String, CaseIterable, Codable {
          case none = "None"
          case barbell = "Barbell"
          case dumbbell = "Dumbbell"
          case cable = "Cable"
          case machine = "Machine"
          case bodyweight = "Bodyweight"
          case resistance = "Resistance Band"
          case kettlebell = "Kettlebell"
      }
      
      enum Difficulty: String, CaseIterable, Codable {
          case beginner = "Beginner"
          case intermediate = "Intermediate"
          case advanced = "Advanced"
      }
  }
  
  @MainActor
  final class ExerciseDatabase {
      static let shared = ExerciseDatabase()
      
      private var exercises: [ExerciseDefinition] = []
      private let fileName = "exercise_database.json"
      
      private init() {
          loadExercises()
      }
      
      func getAllExercises() async throws -> [ExerciseDefinition] {
          if exercises.isEmpty {
              loadExercises()
          }
          return exercises
      }
      
      func searchExercises(query: String) async -> [ExerciseDefinition] {
          let lowercased = query.lowercased()
          return exercises.filter { exercise in
              exercise.name.lowercased().contains(lowercased) ||
              exercise.muscleGroups.contains { $0.rawValue.lowercased().contains(lowercased) } ||
              exercise.category.rawValue.lowercased().contains(lowercased)
          }
      }
      
      func getExercisesByMuscleGroup(_ muscleGroup: ExerciseDefinition.MuscleGroup) -> [ExerciseDefinition] {
          exercises.filter { $0.muscleGroups.contains(muscleGroup) }
      }
      
      func getExercisesByCategory(_ category: ExerciseDefinition.ExerciseCategory) -> [ExerciseDefinition] {
          exercises.filter { $0.category == category }
      }
      
      private func loadExercises() {
          // In production, this would load from a JSON file or API
          // For now, populate with common exercises
          exercises = [
              ExerciseDefinition(
                  id: "bench_press",
                  name: "Barbell Bench Press",
                  category: .chest,
                  muscleGroups: [.chest, .shoulders, .triceps],
                  equipment: [.barbell],
                  instructions: [
                      "Lie on bench with eyes under bar",
                      "Grip bar with hands slightly wider than shoulders",
                      "Lower bar to chest with control",
                      "Press bar up to starting position"
                  ],
                  tips: [
                      "Keep feet flat on floor",
                      "Maintain slight arch in lower back",
                      "Keep shoulder blades pulled together"
                  ],
                  commonMistakes: [
                      "Bouncing bar off chest",
                      "Flaring elbows too wide",
                      "Not using full range of motion"
                  ],
                  difficulty: .intermediate,
                  isCompound: true
              ),
              ExerciseDefinition(
                  id: "squat",
                  name: "Barbell Back Squat",
                  category: .legs,
                  muscleGroups: [.quadriceps, .glutes, .hamstrings],
                  equipment: [.barbell],
                  instructions: [
                      "Position bar on upper back",
                      "Stand with feet shoulder-width apart",
                      "Lower hips back and down",
                      "Descend until thighs parallel to floor",
                      "Drive through heels to return to start"
                  ],
                  tips: [
                      "Keep chest up and core tight",
                      "Track knees over toes",
                      "Maintain neutral spine"
                  ],
                  commonMistakes: [
                      "Knees caving inward",
                      "Heels coming off ground",
                      "Leaning too far forward"
                  ],
                  difficulty: .intermediate,
                  isCompound: true
              ),
              // Add more exercises...
          ]
      }
  }
  ```

---

**Task 7.5: Testing**

**Agent Task 7.5.1: Create Workout View Model Tests**
- File: `AirFitTests/Workouts/WorkoutViewModelTests.swift`
- Test Implementation:
  ```swift
  @MainActor
  final class WorkoutViewModelTests: XCTestCase {
      var sut: WorkoutViewModel!
      var mockCoachEngine: MockCoachEngine!
      var mockHealthKitManager: MockHealthKitManager!
      var modelContext: ModelContext!
      var testUser: User!
      
      override func setUp() async throws {
          try await super.setUp()
          
          // Setup test context
          modelContext = try SwiftDataTestHelper.createTestContext(
              for: User.self, Workout.self, Exercise.self, ExerciseSet.self
          )
          
          // Create test user
          testUser = User(name: "Test User")
          modelContext.insert(testUser)
          try modelContext.save()
          
          // Setup mocks
          mockCoachEngine = MockCoachEngine()
          mockHealthKitManager = MockHealthKitManager()
          
          // Create SUT
          sut = WorkoutViewModel(
              modelContext: modelContext,
              user: testUser,
              coachEngine: mockCoachEngine,
              healthKitManager: mockHealthKitManager
          )
      }
      
      func test_loadWorkouts_shouldFetchUserWorkouts() async throws {
          // Arrange
          let workout1 = createTestWorkout(date: Date())
          let workout2 = createTestWorkout(date: Date().addingTimeInterval(-86400))
          testUser.workouts.append(contentsOf: [workout1, workout2])
          try modelContext.save()
          
          // Act
          await sut.loadWorkouts()
          
          // Assert
          XCTAssertEqual(sut.workouts.count, 2)
          XCTAssertEqual(sut.workouts.first?.id, workout1.id)
      }
      
      func test_processReceivedWorkout_shouldCreateWorkoutFromData() async throws {
          // Arrange
          let workoutData = WorkoutBuilderData(
              id: UUID(),
              workoutType: HKWorkoutActivityType.traditionalStrengthTraining.rawValue,
              startTime: Date(),
              endTime: Date().addingTimeInterval(3600),
              exercises: [
                  ExerciseBuilderData(
                      id: UUID(),
                      name: "Bench Press",
                      muscleGroups: ["Chest"],
                      startTime: Date(),
                      sets: [
                          SetBuilderData(reps: 10, weightKg: 60, duration: nil, rpe: 7, completedAt: Date())
                      ]
                  )
              ],
              totalCalories: 250,
              totalDistance: 0,
              duration: 3600
          )
          
          // Act
          await sut.processReceivedWorkout(data: workoutData)
          
          // Assert
          let workouts = try modelContext.fetch(FetchDescriptor<Workout>())
          XCTAssertEqual(workouts.count, 1)
          XCTAssertEqual(workouts.first?.exercises.count, 1)
          XCTAssertEqual(workouts.first?.exercises.first?.sets.count, 1)
      }
      
      func test_generateAIAnalysis_shouldUpdateWorkoutWithAnalysis() async throws {
          // Arrange
          let workout = createTestWorkout(date: Date())
          testUser.workouts.append(workout)
          try modelContext.save()
          
          mockCoachEngine.mockAnalysis = "Great workout! You showed excellent form..."
          
          // Act
          await sut.generateAIAnalysis(for: workout)
          
          // Assert
          XCTAssertNotNil(workout.aiAnalysis)
          XCTAssertEqual(workout.aiAnalysis, mockCoachEngine.mockAnalysis)
          XCTAssertTrue(mockCoachEngine.didGenerateAnalysis)
      }
      
      func test_weeklyStats_shouldCalculateCorrectly() async throws {
          // Arrange
          let today = Date()
          let workout1 = createTestWorkout(date: today, duration: 3600, calories: 300)
          let workout2 = createTestWorkout(date: today.addingTimeInterval(-86400), duration: 2700, calories: 250)
          let oldWorkout = createTestWorkout(date: today.addingTimeInterval(-864000), duration: 3600, calories: 400)
          
          testUser.workouts.append(contentsOf: [workout1, workout2, oldWorkout])
          try modelContext.save()
          
          // Act
          await sut.loadWorkouts()
          
          // Assert
          XCTAssertEqual(sut.weeklyStats.totalWorkouts, 2)
          XCTAssertEqual(sut.weeklyStats.totalDuration, 6300)
          XCTAssertEqual(sut.weeklyStats.totalCalories, 550)
      }
      
      // Helper methods
      private func createTestWorkout(date: Date, duration: TimeInterval = 3600, calories: Double = 300) -> Workout {
          let workout = Workout(
              type: .traditionalStrengthTraining,
              startTime: date,
              endTime: date.addingTimeInterval(duration),
              totalCalories: calories
          )
          
          let exercise = Exercise(name: "Test Exercise", muscleGroups: ["Test"])
          let set = ExerciseSet(reps: 10, weightKg: 50, duration: nil, rpe: 7)
          exercise.sets.append(set)
          workout.exercises.append(exercise)
          
          return workout
      }
  }
  ```

---

**5. Acceptance Criteria for Module Completion**

- ✅ Watch app can start, track, pause, resume, and end workouts
- ✅ Real-time heart rate and calorie monitoring during workouts
- ✅ Exercise and set logging on Apple Watch with haptic feedback
- ✅ Workout data saves to HealthKit and syncs to iPhone
- ✅ iOS app displays workout history with detailed views
- ✅ AI-powered post-workout analysis generation
- ✅ Exercise library with search and filtering
- ✅ Workout templates for quick starts
- ✅ Personal records tracking
- ✅ Weekly statistics and muscle group distribution
- ✅ CloudKit backup for data resilience
- ✅ Performance: Watch UI updates < 16ms
- ✅ Test coverage ≥ 80%

**6. Module Dependencies**

- **Requires Completion Of:** Modules 1, 2, 4, 5
- **Must Be Completed Before:** Final app assembly
- **Can Run In Parallel With:** Module 8 (Food Tracking)

**7. Performance Requirements**

- Watch workout start: < 500ms
- Heart rate updates: Real-time (< 1s delay)
- Set logging: < 100ms response
- Sync to iPhone: < 5s after workout end
- AI analysis generation: < 10s
- UI animations: 60fps on both platforms
