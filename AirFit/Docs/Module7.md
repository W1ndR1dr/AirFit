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
- Complete Implementation:
  ```swift
  import Foundation
  import HealthKit
  import Observation
  import WatchKit
  
  @MainActor
  @Observable
  final class WatchWorkoutManager: NSObject {
      // MARK: - Properties
      private let healthStore = HKHealthStore()
      private var session: HKWorkoutSession?
      private var builder: HKLiveWorkoutBuilder?
      
      // Session state
      private(set) var workoutState: WorkoutState = .idle
      private(set) var isPaused = false
      
      // Metrics
      private(set) var heartRate: Double = 0
      private(set) var activeCalories: Double = 0
      private(set) var totalCalories: Double = 0
      private(set) var distance: Double = 0
      private(set) var elapsedTime: TimeInterval = 0
      private(set) var currentPace: Double = 0
      
      // Workout data
      var selectedActivityType: HKWorkoutActivityType = .traditionalStrengthTraining
      private(set) var currentWorkoutData = WorkoutBuilderData()
      private var startTime: Date?
      private var elapsedTimer: Timer?
      
      // MARK: - Workout State
      enum WorkoutState: Equatable {
          case idle
          case starting
          case running
          case paused
          case ending
          case ended
          case error(String)
      }
      
      // MARK: - Authorization
      func requestAuthorization() async throws -> Bool {
          let typesToShare: Set = [
              HKQuantityType.workoutType()
          ]
          
          let typesToRead: Set = [
              HKQuantityType(.heartRate),
              HKQuantityType(.activeEnergyBurned),
              HKQuantityType(.distanceWalkingRunning),
              HKQuantityType(.distanceCycling),
              HKObjectType.activitySummaryType()
          ]
          
          return try await withCheckedThrowingContinuation { continuation in
              healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                  if let error = error {
                      continuation.resume(throwing: error)
                  } else {
                      continuation.resume(returning: success)
                  }
              }
          }
      }
      
      // MARK: - Workout Control
      func startWorkout(activityType: HKWorkoutActivityType) async throws {
          workoutState = .starting
          selectedActivityType = activityType
          
          // Configure workout
          let configuration = HKWorkoutConfiguration()
          configuration.activityType = activityType
          configuration.locationType = activityType.isIndoor ? .indoor : .outdoor
          
          // Create session and builder
          do {
              session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
              builder = session?.associatedWorkoutBuilder()
              
              // Setup builder
              builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
              )
              
              // Set delegates
              session?.delegate = self
              builder?.delegate = self
              
              // Start activity
              let startDate = Date()
              session?.startActivity(with: startDate)
              try await builder?.beginCollection(withStart: startDate)
              
              startTime = startDate
              workoutState = .running
              startElapsedTimer()
              
              // Haptic feedback
              WKInterfaceDevice.current().play(.start)
              
              AppLogger.info("Workout started: \(activityType.name)", category: .health)
              
          } catch {
              workoutState = .error(error.localizedDescription)
              throw error
          }
      }
      
      func pauseWorkout() {
          guard workoutState == .running else { return }
          
          session?.pause()
          isPaused = true
          workoutState = .paused
          elapsedTimer?.invalidate()
          
          WKInterfaceDevice.current().play(.stop)
          AppLogger.info("Workout paused", category: .health)
      }
      
      func resumeWorkout() {
          guard workoutState == .paused else { return }
          
          session?.resume()
          isPaused = false
          workoutState = .running
          startElapsedTimer()
          
          WKInterfaceDevice.current().play(.start)
          AppLogger.info("Workout resumed", category: .health)
      }
      
      func endWorkout() async {
          guard workoutState == .running || workoutState == .paused else { return }
          
          workoutState = .ending
          elapsedTimer?.invalidate()
          
          do {
              // End collection
              session?.end()
              try await builder?.endCollection(withEnd: Date())
              
              // Save workout
              guard let workout = try await builder?.finishWorkout() else {
                  throw WorkoutError.saveFailed
              }
              
              // Process and sync data
              await processCompletedWorkout(workout)
              
              workoutState = .ended
              
              // Success haptic
              WKInterfaceDevice.current().play(.success)
              
              AppLogger.info("Workout ended and saved", category: .health)
              
          } catch {
              workoutState = .error(error.localizedDescription)
              AppLogger.error("Failed to end workout", error: error, category: .health)
          }
      }
      
      // MARK: - Exercise Tracking
      func startNewExercise(name: String, muscleGroups: [String]) {
          let exercise = ExerciseBuilderData(
              id: UUID(),
              name: name,
              muscleGroups: muscleGroups,
              startTime: Date()
          )
          
          currentWorkoutData.exercises.append(exercise)
          
          WKInterfaceDevice.current().play(.click)
          AppLogger.info("Started exercise: \(name)", category: .health)
      }
      
      func logSet(reps: Int?, weight: Double?, duration: TimeInterval?, rpe: Double?) {
          guard let currentExercise = currentWorkoutData.exercises.last else { return }
          
          let set = SetBuilderData(
              reps: reps,
              weightKg: weight,
              duration: duration,
              rpe: rpe,
              completedAt: Date()
          )
          
          currentWorkoutData.exercises[currentWorkoutData.exercises.count - 1].sets.append(set)
          
          // Haptic feedback based on performance
          if let lastSet = currentExercise.sets.dropLast().last,
             let currentWeight = weight,
             let lastWeight = lastSet.weightKg,
             currentWeight > lastWeight {
              WKInterfaceDevice.current().play(.success)
          } else {
              WKInterfaceDevice.current().play(.click)
          }
          
          AppLogger.info("Logged set: \(set)", category: .health)
      }
      
      // MARK: - Private Methods
      private func startElapsedTimer() {
          elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
              if let startTime = self.startTime {
                  self.elapsedTime = Date().timeIntervalSince(startTime)
              }
          }
      }
      
      private func processCompletedWorkout(_ workout: HKWorkout) async {
          // Prepare workout data for sync
          currentWorkoutData.workoutType = selectedActivityType.rawValue
          currentWorkoutData.startTime = workout.startDate
          currentWorkoutData.endTime = workout.endDate
          currentWorkoutData.totalCalories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
          currentWorkoutData.totalDistance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
          currentWorkoutData.duration = workout.duration
          
          // Send to iPhone
          await WorkoutSyncService.shared.sendWorkoutData(currentWorkoutData)
      }
  }
  
  // MARK: - HKWorkoutSessionDelegate
  extension WatchWorkoutManager: HKWorkoutSessionDelegate {
      nonisolated func workoutSession(
          _ workoutSession: HKWorkoutSession,
          didChangeTo toState: HKWorkoutSessionState,
          from fromState: HKWorkoutSessionState,
          date: Date
      ) {
          Task { @MainActor in
              switch toState {
              case .running:
                  workoutState = .running
              case .paused:
                  workoutState = .paused
              case .ended:
                  workoutState = .ended
              default:
                  break
              }
          }
      }
      
      nonisolated func workoutSession(
          _ workoutSession: HKWorkoutSession,
          didFailWithError error: Error
      ) {
          Task { @MainActor in
              workoutState = .error(error.localizedDescription)
              AppLogger.error("Workout session error", error: error, category: .health)
          }
      }
  }
  
  // MARK: - HKLiveWorkoutBuilderDelegate
  extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
      nonisolated func workoutBuilder(
          _ workoutBuilder: HKLiveWorkoutBuilder,
          didCollectDataOf collectedTypes: Set<HKSampleType>
      ) {
          Task { @MainActor in
              for type in collectedTypes {
                  guard let quantityType = type as? HKQuantityType else { continue }
                  
                  let statistics = workoutBuilder.statistics(for: quantityType)
                  
                  switch quantityType {
                  case HKQuantityType(.heartRate):
                      let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                      heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                      
                  case HKQuantityType(.activeEnergyBurned):
                      activeCalories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                      
                  case HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling):
                      distance = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                      updatePace()
                      
                  default:
                      break
                  }
              }
          }
      }
      
      nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
          // Handle workout events
      }
  }
  
  // MARK: - Supporting Types
  struct WorkoutBuilderData: Codable {
      var id = UUID()
      var workoutType: Int = 0
      var startTime: Date?
      var endTime: Date?
      var exercises: [ExerciseBuilderData] = []
      var totalCalories: Double = 0
      var totalDistance: Double = 0
      var duration: TimeInterval = 0
  }
  
  struct ExerciseBuilderData: Codable {
      let id: UUID
      let name: String
      let muscleGroups: [String]
      let startTime: Date
      var sets: [SetBuilderData] = []
  }
  
  struct SetBuilderData: Codable {
      let reps: Int?
      let weightKg: Double?
      let duration: TimeInterval?
      let rpe: Double?
      let completedAt: Date
  }
  
  enum WorkoutError: LocalizedError {
      case saveFailed
      case syncFailed
      
      var errorDescription: String? {
          switch self {
          case .saveFailed: return "Failed to save workout"
          case .syncFailed: return "Failed to sync workout data"
          }
      }
  }
  
  // MARK: - Extensions
  private extension WatchWorkoutManager {
      func updatePace() {
          guard elapsedTime > 0, distance > 0 else {
              currentPace = 0
              return
          }
          
          // Pace in minutes per kilometer
          let kilometers = distance / 1000
          let minutes = elapsedTime / 60
          currentPace = minutes / kilometers
      }
  }
  
  private extension HKWorkoutActivityType {
      var name: String {
          switch self {
          case .traditionalStrengthTraining: return "Strength Training"
          case .running: return "Running"
          case .cycling: return "Cycling"
          case .walking: return "Walking"
          case .swimming: return "Swimming"
          case .yoga: return "Yoga"
          case .functionalStrengthTraining: return "Functional Training"
          case .coreTraining: return "Core Training"
          default: return "Workout"
          }
      }
      
      var isIndoor: Bool {
          // Simplified logic - could be expanded
          return self == .traditionalStrengthTraining || self == .yoga || self == .coreTraining
      }
  }
  ```

**Agent Task 7.0.2: Create Workout Sync Service**
- File: `AirFit/Services/WorkoutSyncService.swift`
- Complete Implementation:
  ```swift
  import Foundation
  import WatchConnectivity
  import CloudKit
  import SwiftData
  
  @MainActor
  final class WorkoutSyncService: NSObject {
      static let shared = WorkoutSyncService()
      
      private let session: WCSession
      private var pendingWorkouts: [WorkoutBuilderData] = []
      private let container = CKContainer.default()
      
      private override init() {
          self.session = WCSession.default
          super.init()
          
          if WCSession.isSupported() {
              session.delegate = self
              session.activate()
          }
      }
      
      // MARK: - Watch -> iPhone
      func sendWorkoutData(_ data: WorkoutBuilderData) async {
          guard session.isReachable else {
              // Queue for later
              pendingWorkouts.append(data)
              await syncToCloudKit(data)
              return
          }
          
          do {
              let encoded = try JSONEncoder().encode(data)
              try await session.sendMessageData(encoded)
              AppLogger.info("Workout data sent to iPhone", category: .sync)
          } catch {
              pendingWorkouts.append(data)
              await syncToCloudKit(data)
              AppLogger.error("Failed to send workout data", error: error, category: .sync)
          }
      }
      
      // MARK: - CloudKit Sync
      private func syncToCloudKit(_ data: WorkoutBuilderData) async {
          let record = CKRecord(recordType: "WorkoutSync")
          record["workoutId"] = data.id.uuidString
          record["data"] = try? JSONEncoder().encode(data)
          record["timestamp"] = Date()
          
          do {
              _ = try await container.privateCloudDatabase.save(record)
              AppLogger.info("Workout synced to CloudKit", category: .sync)
          } catch {
              AppLogger.error("CloudKit sync failed", error: error, category: .sync)
          }
      }
      
      // MARK: - Process Received Data
      func processReceivedWorkout(_ data: WorkoutBuilderData, modelContext: ModelContext) async throws {
          // Create workout entity
          let workout = Workout(
              type: HKWorkoutActivityType(rawValue: UInt(data.workoutType)) ?? .traditionalStrengthTraining,
              startTime: data.startTime ?? Date(),
              endTime: data.endTime ?? Date(),
              totalCalories: data.totalCalories,
              totalDistance: data.totalDistance
          )
          
          // Process exercises
          for exerciseData in data.exercises {
              let exercise = Exercise(
                  name: exerciseData.name,
                  muscleGroups: exerciseData.muscleGroups
              )
              
              // Process sets
              for setData in exerciseData.sets {
                  let set = ExerciseSet(
                      reps: setData.reps,
                      weightKg: setData.weightKg,
                      duration: setData.duration,
                      rpe: setData.rpe
                  )
                  exercise.sets.append(set)
              }
              
              workout.exercises.append(exercise)
          }
          
          modelContext.insert(workout)
          try modelContext.save()
          
          AppLogger.info("Workout processed and saved", category: .sync)
      }
  }
  
  // MARK: - WCSessionDelegate
  extension WorkoutSyncService: WCSessionDelegate {
      nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
          if let error = error {
              AppLogger.error("WCSession activation failed", error: error, category: .sync)
          }
      }
      
      #if os(iOS)
      nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
      nonisolated func sessionDidDeactivate(_ session: WCSession) {
          session.activate()
      }
      #endif
      
      nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
          Task { @MainActor in
              do {
                  let workoutData = try JSONDecoder().decode(WorkoutBuilderData.self, from: messageData)
                  // Notify view models or process directly
                  NotificationCenter.default.post(
                      name: .workoutDataReceived,
                      object: nil,
                      userInfo: ["data": workoutData]
                  )
              } catch {
                  AppLogger.error("Failed to decode workout data", error: error, category: .sync)
              }
          }
      }
  }
  
  extension Notification.Name {
      static let workoutDataReceived = Notification.Name("workoutDataReceived")
  }
  ```

---

**Task 7.1: Watch UI Implementation**

**Agent Task 7.1.1: Create Workout Start View**
- File: `AirFitWatchApp/Views/WorkoutStartView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import HealthKit
  
  struct WorkoutStartView: View {
      @StateObject private var workoutManager = WatchWorkoutManager()
      @State private var selectedActivity: HKWorkoutActivityType = .traditionalStrengthTraining
      @State private var showingActiveWorkout = false
      @State private var isRequestingPermission = false
      
      private let activities: [HKWorkoutActivityType] = [
          .traditionalStrengthTraining,
          .functionalStrengthTraining,
          .running,
          .walking,
          .cycling,
          .swimming,
          .yoga,
          .coreTraining
      ]
      
      var body: some View {
          NavigationStack {
              ScrollView {
                  VStack(spacing: 8) {
                      // Activity selection
                      ForEach(activities, id: \.self) { activity in
                          ActivityRow(
                              activity: activity,
                              isSelected: selectedActivity == activity
                          ) {
                              selectedActivity = activity
                          }
                      }
                      
                      // Start button
                      Button(action: startWorkout) {
                          Label("Start Workout", systemImage: "play.fill")
                              .frame(maxWidth: .infinity)
                      }
                      .buttonStyle(.borderedProminent)
                      .controlSize(.large)
                      .padding(.top)
                      .disabled(isRequestingPermission)
                  }
                  .padding(.horizontal)
              }
              .navigationTitle("Workout")
              .navigationBarTitleDisplayMode(.large)
              .fullScreenCover(isPresented: $showingActiveWorkout) {
                  ActiveWorkoutView(workoutManager: workoutManager)
              }
          }
          .task {
              await requestPermissions()
          }
      }
      
      private func requestPermissions() async {
          isRequestingPermission = true
          defer { isRequestingPermission = false }
          
          do {
              _ = try await workoutManager.requestAuthorization()
          } catch {
              // Handle error
              AppLogger.error("Failed to request HealthKit permissions", error: error, category: .health)
          }
      }
      
      private func startWorkout() {
          Task {
              do {
                  try await workoutManager.startWorkout(activityType: selectedActivity)
                  showingActiveWorkout = true
              } catch {
                  // Show error
                  AppLogger.error("Failed to start workout", error: error, category: .health)
              }
          }
      }
  }
  
  struct ActivityRow: View {
      let activity: HKWorkoutActivityType
      let isSelected: Bool
      let action: () -> Void
      
      var body: some View {
          Button(action: action) {
              HStack {
                  Image(systemName: activity.symbolName)
                      .font(.title3)
                      .foregroundStyle(isSelected ? .white : .primary)
                      .frame(width: 30)
                  
                  Text(activity.name)
                      .font(.body)
                      .foregroundStyle(isSelected ? .white : .primary)
                  
                  Spacer()
                  
                  if isSelected {
                      Image(systemName: "checkmark.circle.fill")
                          .foregroundStyle(.white)
                  }
              }
              .padding(.vertical, 10)
              .padding(.horizontal, 12)
              .background(isSelected ? Color.accent : Color.gray.opacity(0.2))
              .clipShape(RoundedRectangle(cornerRadius: 10))
          }
          .buttonStyle(.plain)
      }
  }
  
  private extension HKWorkoutActivityType {
      var symbolName: String {
          switch self {
          case .traditionalStrengthTraining: return "dumbbell.fill"
          case .functionalStrengthTraining: return "figure.strengthtraining.functional"
          case .running: return "figure.run"
          case .walking: return "figure.walk"
          case .cycling: return "bicycle"
          case .swimming: return "figure.pool.swim"
          case .yoga: return "figure.yoga"
          case .coreTraining: return "figure.core.training"
          default: return "figure.mixed.cardio"
          }
      }
  }
  ```

**Agent Task 7.1.2: Create Active Workout View**
- File: `AirFitWatchApp/Views/ActiveWorkoutView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import HealthKit
  
  struct ActiveWorkoutView: View {
      @ObservedObject var workoutManager: WatchWorkoutManager
      @State private var selectedTab = 0
      @Environment(\.dismiss) private var dismiss
      
      var body: some View {
          TabView(selection: $selectedTab) {
              // Metrics page
              WorkoutMetricsView(workoutManager: workoutManager)
                  .tag(0)
              
              // Exercise logging page
              ExerciseLoggingView(workoutManager: workoutManager)
                  .tag(1)
              
              // Controls page
              WorkoutControlsView(workoutManager: workoutManager) {
                  dismiss()
              }
              .tag(2)
          }
          .tabViewStyle(.verticalPage)
          .ignoresSafeArea()
          .onAppear {
              WKExtension.shared().isAutorotating = false
          }
      }
  }
  
  struct WorkoutMetricsView: View {
      @ObservedObject var workoutManager: WatchWorkoutManager
      
      var body: some View {
          VStack(spacing: 16) {
              // Time
              MetricRow(
                  icon: "timer",
                  value: workoutManager.elapsedTime.formattedDuration(),
                  label: "Duration",
                  color: .blue
              )
              
              // Heart rate
              MetricRow(
                  icon: "heart.fill",
                  value: "\(Int(workoutManager.heartRate))",
                  label: "BPM",
                  color: .red
              )
              
              // Calories
              MetricRow(
                  icon: "flame.fill",
                  value: "\(Int(workoutManager.activeCalories))",
                  label: "Cal",
                  color: .orange
              )
              
              // Distance (if applicable)
              if workoutManager.distance > 0 {
                  MetricRow(
                      icon: "location.fill",
                      value: workoutManager.distance.formattedDistance(),
                      label: "Distance",
                      color: .green
                  )
              }
          }
          .padding()
      }
  }
  
  struct MetricRow: View {
      let icon: String
      let value: String
      let label: String
      let color: Color
      
      var body: some View {
          HStack {
              Image(systemName: icon)
                  .font(.title3)
                  .foregroundStyle(color)
                  .frame(width: 30)
              
              VStack(alignment: .leading, spacing: 2) {
                  Text(value)
                      .font(.title2)
                      .fontWeight(.semibold)
                  
                  Text(label)
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              
              Spacer()
          }
      }
  }
  
  struct WorkoutControlsView: View {
      @ObservedObject var workoutManager: WatchWorkoutManager
      let onEnd: () -> Void
      @State private var showingEndConfirmation = false
      
      var body: some View {
          VStack(spacing: 20) {
              // Pause/Resume button
              if workoutManager.workoutState == .running {
                  Button(action: { workoutManager.pauseWorkout() }) {
                      Label("Pause", systemImage: "pause.fill")
                          .frame(maxWidth: .infinity)
                  }
                  .buttonStyle(.borderedProminent)
                  .tint(.orange)
              } else if workoutManager.workoutState == .paused {
                  Button(action: { workoutManager.resumeWorkout() }) {
                      Label("Resume", systemImage: "play.fill")
                          .frame(maxWidth: .infinity)
                  }
                  .buttonStyle(.borderedProminent)
                  .tint(.green)
              }
              
              // End button
              Button(action: { showingEndConfirmation = true }) {
                  Label("End", systemImage: "stop.fill")
                      .frame(maxWidth: .infinity)
              }
              .buttonStyle(.bordered)
              .tint(.red)
              
              Spacer()
          }
          .padding()
          .confirmationDialog(
              "End Workout?",
              isPresented: $showingEndConfirmation,
              titleVisibility: .visible
          ) {
              Button("End Workout", role: .destructive) {
                  Task {
                      await workoutManager.endWorkout()
                      onEnd()
                  }
              }
              Button("Continue", role: .cancel) {}
          }
      }
  }
  ```

**Agent Task 7.1.3: Create Exercise Logging View**
- File: `AirFitWatchApp/Views/ExerciseLoggingView.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  
  struct ExerciseLoggingView: View {
      @ObservedObject var workoutManager: WatchWorkoutManager
      @State private var showingExercisePicker = false
      @State private var showingSetLogger = false
      
      var currentExercise: ExerciseBuilderData? {
          workoutManager.currentWorkoutData.exercises.last
      }
      
      var body: some View {
          ScrollView {
              VStack(spacing: 12) {
                  // Current exercise
                  if let exercise = currentExercise {
                      CurrentExerciseCard(exercise: exercise)
                      
                      // Log set button
                      Button(action: { showingSetLogger = true }) {
                          Label("Log Set", systemImage: "plus.circle.fill")
                              .frame(maxWidth: .infinity)
                      }
                      .buttonStyle(.borderedProminent)
                      
                      // Recent sets
                      if !exercise.sets.isEmpty {
                          RecentSetsView(sets: exercise.sets)
                      }
                  } else {
                      // No exercise started
                      Text("Start an exercise to begin logging")
                          .font(.caption)
                          .foregroundStyle(.secondary)
                          .multilineTextAlignment(.center)
                          .padding()
                  }
                  
                  // New exercise button
                  Button(action: { showingExercisePicker = true }) {
                      Label("New Exercise", systemImage: "figure.strengthtraining.traditional")
                          .frame(maxWidth: .infinity)
                  }
                  .buttonStyle(.bordered)
              }
              .padding()
          }
          .sheet(isPresented: $showingExercisePicker) {
              ExercisePickerView { exercise in
                  workoutManager.startNewExercise(
                      name: exercise.name,
                      muscleGroups: exercise.muscleGroups
                  )
                  showingExercisePicker = false
              }
          }
          .sheet(isPresented: $showingSetLogger) {
              SetLoggerView { reps, weight, duration, rpe in
                  workoutManager.logSet(
                      reps: reps,
                      weight: weight,
                      duration: duration,
                      rpe: rpe
                  )
                  showingSetLogger = false
              }
          }
      }
  }
  
  struct CurrentExerciseCard: View {
      let exercise: ExerciseBuilderData
      
      var body: some View {
          VStack(alignment: .leading, spacing: 6) {
              Text(exercise.name)
                  .font(.headline)
              
              HStack {
                  Image(systemName: "figure.strengthtraining.traditional")
                      .font(.caption)
                  Text(exercise.muscleGroups.joined(separator: ", "))
                      .font(.caption)
                      .foregroundStyle(.secondary)
              }
              
              if !exercise.sets.isEmpty {
                  Text("\(exercise.sets.count) sets completed")
                      .font(.caption2)
                      .foregroundStyle(.accent)
              }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
          .background(Color.gray.opacity(0.2))
          .clipShape(RoundedRectangle(cornerRadius: 10))
      }
  }
  
  struct RecentSetsView: View {
      let sets: [SetBuilderData]
      
      var recentSets: [SetBuilderData] {
          Array(sets.suffix(3))
      }
      
      var body: some View {
          VStack(alignment: .leading, spacing: 6) {
              Text("Recent Sets")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              
              ForEach(Array(recentSets.enumerated()), id: \.offset) { index, set in
                  HStack {
                      Text("Set \(sets.count - (recentSets.count - index - 1))")
                          .font(.caption2)
                          .foregroundStyle(.secondary)
                      
                      Spacer()
                      
                      if let reps = set.reps, let weight = set.weightKg {
                          Text("\(reps) × \(weight.formatted())kg")
                              .font(.caption)
                              .fontWeight(.medium)
                      }
                  }
              }
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
  }
  ```

---

**Task 7.2: iOS Workout Management**

**Agent Task 7.2.1: Create Workout View Model**
- File: `AirFit/Modules/Workouts/ViewModels/WorkoutViewModel.swift`
- Complete Implementation:
  ```swift
  import SwiftUI
  import SwiftData
  import Observation
  
  @MainActor
  @Observable
  final class WorkoutViewModel {
      // MARK: - Dependencies
      private let modelContext: ModelContext
      private let user: User
      private let coachEngine: CoachEngine
      private let healthKitManager: HealthKitManager
      
      // MARK: - State
      private(set) var isLoading = false
      private(set) var error: Error?
      
      // Workouts
      private(set) var workouts: [Workout] = []
      private(set) var selectedWorkout: Workout?
      
      // Templates
      private(set) var workoutTemplates: [WorkoutTemplate] = []
      private(set) var selectedTemplate: WorkoutTemplate?
      
      // Analytics
      private(set) var weeklyStats = WeeklyWorkoutStats()
      private(set) var personalRecords: [PersonalRecord] = []
      
      // AI Analysis
      private(set) var aiWorkoutSummary: String?
      private(set) var isGeneratingAnalysis = false
      
      // Exercise library
      private(set) var exerciseLibrary: [ExerciseDefinition] = []
      private(set) var favoriteExercises: [ExerciseDefinition] = []
      
      // MARK: - Initialization
      init(
          modelContext: ModelContext,
          user: User,
          coachEngine: CoachEngine,
          healthKitManager: HealthKitManager
      ) {
          self.modelContext = modelContext
          self.user = user
          self.coachEngine = coachEngine
          self.healthKitManager = healthKitManager
          
          setupNotifications()
      }
      
      // MARK: - Data Loading
      func loadWorkouts() async {
          isLoading = true
          defer { isLoading = false }
          
          do {
              // Fetch workouts
              let descriptor = FetchDescriptor<Workout>(
                  predicate: #Predicate { workout in
                      workout.user?.id == user.id
                  },
                  sortBy: [SortDescriptor(\.startTime, order: .reverse)]
              )
              
              workouts = try modelContext.fetch(descriptor)
              
              // Load analytics
              await loadWeeklyStats()
              await loadPersonalRecords()
              
          } catch {
              self.error = error
              AppLogger.error("Failed to load workouts", error: error, category: .data)
          }
      }
      
      func loadExerciseLibrary() async {
          do {
              exerciseLibrary = try await ExerciseDatabase.shared.getAllExercises()
              favoriteExercises = exerciseLibrary.filter { exercise in
                  user.favoriteExerciseIds.contains(exercise.id)
              }
          } catch {
              AppLogger.error("Failed to load exercise library", error: error, category: .data)
          }
      }
      
      // MARK: - Workout Processing
      func processReceivedWorkout(data: WorkoutBuilderData) async {
          isLoading = true
          defer { isLoading = false }
          
          do {
              // Process via sync service
              try await WorkoutSyncService.shared.processReceivedWorkout(
                  data,
                  modelContext: modelContext
              )
              
              // Reload workouts
              await loadWorkouts()
              
              // Generate AI analysis for the new workout
              if let newWorkout = workouts.first(where: { $0.id == data.id }) {
                  await generateAIAnalysis(for: newWorkout)
              }
              
          } catch {
              self.error = error
              AppLogger.error("Failed to process workout", error: error, category: .data)
          }
      }
      
      // MARK: - AI Analysis
      func generateAIAnalysis(for workout: Workout) async {
          isGeneratingAnalysis = true
          defer { isGeneratingAnalysis = false }
          
          do {
              // Prepare analysis request
              let request = PostWorkoutAnalysisRequest(
                  workout: workout,
                  recentWorkouts: Array(workouts.prefix(5)),
                  personalRecords: personalRecords,
                  healthContext: await getHealthContext()
              )
              
              // Generate analysis
              aiWorkoutSummary = try await coachEngine.generatePostWorkoutAnalysis(request)
              
              // Save analysis to workout
              workout.aiAnalysis = aiWorkoutSummary
              try modelContext.save()
              
          } catch {
              AppLogger.error("Failed to generate AI analysis", error: error, category: .ai)
          }
      }
      
      // MARK: - Templates
      func createTemplate(from workout: Workout, name: String) async {
          do {
              let template = WorkoutTemplate(
                  name: name,
                  exercises: workout.exercises.map { exercise in
                      TemplateExercise(
                          name: exercise.name,
                          sets: exercise.sets.count,
                          targetReps: exercise.sets.first?.reps,
                          targetWeight: exercise.sets.first?.weightKg
                      )
                  }
              )
              
              user.workoutTemplates.append(template)
              modelContext.insert(template)
              try modelContext.save()
              
              await loadTemplates()
              
          } catch {
              self.error = error
              AppLogger.error("Failed to create template", error: error, category: .data)
          }
      }
      
      func startWorkoutFromTemplate(_ template: WorkoutTemplate) async -> Workout? {
          // This would typically open the workout logging interface
          // For now, create a placeholder workout
          let workout = Workout(
              type: .traditionalStrengthTraining,
              startTime: Date(),
              endTime: nil
          )
          
          // Pre-populate with template exercises
          for templateExercise in template.exercises {
              let exercise = Exercise(
                  name: templateExercise.name,
                  muscleGroups: [] // Would be fetched from exercise database
              )
              workout.exercises.append(exercise)
          }
          
          user.workouts.append(workout)
          modelContext.insert(workout)
          
          do {
              try modelContext.save()
              return workout
          } catch {
              self.error = error
              return nil
          }
      }
      
      // MARK: - Analytics
      private func loadWeeklyStats() async {
          let calendar = Calendar.current
          let endDate = Date()
          let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
          
          let thisWeekWorkouts = workouts.filter { workout in
              workout.startTime >= startDate && workout.startTime <= endDate
          }
          
          weeklyStats = WeeklyWorkoutStats(
              totalWorkouts: thisWeekWorkouts.count,
              totalDuration: thisWeekWorkouts.reduce(0) { $0 + ($1.duration ?? 0) },
              totalCalories: thisWeekWorkouts.reduce(0) { $0 + $1.totalCalories },
              averageIntensity: calculateAverageIntensity(thisWeekWorkouts),
              muscleGroupDistribution: calculateMuscleGroupDistribution(thisWeekWorkouts)
          )
      }
      
      private func loadPersonalRecords() async {
          // Calculate PRs from workout history
          var records: [String: PersonalRecord] = [:]
          
          for workout in workouts {
              for exercise in workout.exercises {
                  for set in exercise.sets {
                      guard let weight = set.weightKg, let reps = set.reps else { continue }
                      
                      let key = exercise.name
                      let oneRM = calculateOneRM(weight: weight, reps: reps)
                      
                      if let existingRecord = records[key] {
                          if oneRM > existingRecord.value {
                              records[key] = PersonalRecord(
                                  exercise: exercise.name,
                                  value: oneRM,
                                  unit: "kg",
                                  date: workout.startTime,
                                  reps: reps,
                                  weight: weight
                              )
                          }
                      } else {
                          records[key] = PersonalRecord(
                              exercise: exercise.name,
                              value: oneRM,
                              unit: "kg",
                              date: workout.startTime,
                              reps: reps,
                              weight: weight
                          )
                      }
                  }
              }
          }
          
          personalRecords = Array(records.values).sorted { $0.date > $1.date }
      }
      
      // MARK: - Private Helpers
      private func setupNotifications() {
          NotificationCenter.default.addObserver(
              self,
              selector: #selector(handleWorkoutDataReceived),
              name: .workoutDataReceived,
              object: nil
          )
      }
      
      @objc private func handleWorkoutDataReceived(_ notification: Notification) {
          guard let data = notification.userInfo?["data"] as? WorkoutBuilderData else { return }
          
          Task {
              await processReceivedWorkout(data: data)
          }
      }
      
      private func getHealthContext() async -> HealthContextSnapshot {
          // Get recent health metrics
          let heartRateData = try? await healthKitManager.fetchRecentHeartRateData(days: 7)
          let sleepData = try? await healthKitManager.fetchSleepData(days: 7)
          
          return HealthContextSnapshot(
              date: Date(),
              restingHeartRate: heartRateData?.average ?? 0,
              averageSleep: sleepData?.average ?? 0,
              recentStress: nil // Would be calculated from HRV
          )
      }
      
      private func calculateOneRM(weight: Double, reps: Int) -> Double {
          // Epley formula
          return weight * (1 + Double(reps) / 30)
      }
      
      private func calculateAverageIntensity(_ workouts: [Workout]) -> Double {
          guard !workouts.isEmpty else { return 0 }
          
          let totalIntensity = workouts.reduce(0.0) { total, workout in
              let avgRPE = workout.exercises.flatMap { $0.sets }.compactMap { $0.rpe }.reduce(0, +) / Double(max(workout.exercises.flatMap { $0.sets }.count, 1))
              return total + avgRPE
          }
          
          return totalIntensity / Double(workouts.count)
      }
      
      private func calculateMuscleGroupDistribution(_ workouts: [Workout]) -> [String: Int] {
          var distribution: [String: Int] = [:]
          
          for workout in workouts {
              for exercise in workout.exercises {
                  for muscle in exercise.muscleGroups {
                      distribution[muscle, default: 0] += 1
                  }
              }
          }
          
          return distribution
      }
      
      // MARK: - Templates Management
      private func loadTemplates() async {
          let descriptor = FetchDescriptor<WorkoutTemplate>(
              predicate: #Predicate { template in
                  template.user?.id == user.id
              }
          )
          
          do {
              workoutTemplates = try modelContext.fetch(descriptor)
          } catch {
              AppLogger.error("Failed to load templates", error: error, category: .data)
          }
      }
  }
  
  // MARK: - Supporting Types
  struct WeeklyWorkoutStats {
      var totalWorkouts: Int = 0
      var totalDuration: TimeInterval = 0
      var totalCalories: Double = 0
      var averageIntensity: Double = 0
      var muscleGroupDistribution: [String: Int] = [:]
  }
  
  struct PersonalRecord: Identifiable {
      let id = UUID()
      let exercise: String
      let value: Double
      let unit: String
      let date: Date
      let reps: Int
      let weight: Double
  }
  
  struct PostWorkoutAnalysisRequest {
      let workout: Workout
      let recentWorkouts: [Workout]
      let personalRecords: [PersonalRecord]
      let healthContext: HealthContextSnapshot
  }
  
  struct HealthContextSnapshot {
      let date: Date
      let restingHeartRate: Double
      let averageSleep: Double
      let recentStress: Double?
  }
  ```

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
