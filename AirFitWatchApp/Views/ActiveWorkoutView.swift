import SwiftUI
import HealthKit
import WatchKit

struct ActiveWorkoutView: View {
    let workoutManager: WatchWorkoutManager
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
    let workoutManager: WatchWorkoutManager

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
    let workoutManager: WatchWorkoutManager
    let onEnd: () -> Void
    @State private var showingEndConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            // Pause/Resume button
            if workoutManager.workoutState == .running {
                            Button {
                workoutManager.pauseWorkout()
            } label: {
                Label("Pause", systemImage: "pause.fill")
                    .frame(maxWidth: .infinity)
            }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else if workoutManager.workoutState == .paused {
                Button {
                    workoutManager.resumeWorkout()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

            // End button
            Button {
                showingEndConfirmation = true
            } label: {
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

#Preview {
    ActiveWorkoutView(workoutManager: WatchWorkoutManager())
}
