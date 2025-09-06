import SwiftUI
import HealthKit

struct WorkoutStartView: View {
    @State private var workoutManager = WatchWorkoutManager()
    @State private var workoutPlanReceiver: WatchWorkoutPlanReceiver?
    @State private var selectedActivity: HKWorkoutActivityType = .traditionalStrengthTraining
    @State private var showingActiveWorkout = false
    @State private var isRequestingPermission = false

    // Focus on strength training - users should use Apple's app for cardio
    private let activities: [HKWorkoutActivityType] = [
        .traditionalStrengthTraining,
        .functionalStrengthTraining,
        .coreTraining
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    // Show planned workout if available
                    if let receiver = workoutPlanReceiver,
                       receiver.hasAvailablePlannedWorkout,
                       let plan = receiver.availablePlannedWorkout {
                        PlannedWorkoutCard(
                            plan: plan,
                            onStart: startPlannedWorkout,
                            onDismiss: {
                                receiver.clearAvailablePlannedWorkout()
                            }
                        )
                        .padding(.bottom)
                        
                        Text("OR")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                    }
                    
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
                    
                    // Note about cardio workouts
                    Text("For running, cycling & swimming, use Apple Workout")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
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
            
            // Initialize workout plan receiver
            let receiver = WatchWorkoutPlanReceiver(workoutManager: workoutManager)
            await receiver.configure()
            workoutPlanReceiver = receiver
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
    
    private func startPlannedWorkout() {
        Task {
            do {
                try await workoutPlanReceiver?.startAvailablePlannedWorkout()
                showingActiveWorkout = true
            } catch {
                AppLogger.error("Failed to start planned workout", error: error, category: .health)
            }
        }
    }
}

// MARK: - Planned Workout Card

struct PlannedWorkoutCard: View {
    let plan: PlannedWorkoutData
    let onStart: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From iPhone")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    Text(plan.name)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                Label("\(plan.estimatedDuration)m", systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("\(plan.plannedExercises.count)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if plan.estimatedCalories > 0 {
                    Label("\(plan.estimatedCalories)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            Button(action: onStart) {
                Text("Start Plan")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
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
