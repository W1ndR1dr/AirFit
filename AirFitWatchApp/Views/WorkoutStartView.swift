import SwiftUI
import HealthKit

struct WorkoutStartView: View {
    @State private var workoutManager = WatchWorkoutManager()
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
