import SwiftUI

/// Main view for the Watch app.
/// Shows readiness, macros, and provides navigation to voice logging and workout tracking.
struct MainWatchView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var showingVoiceLog = false
    @State private var showingWorkoutView = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Connection status
                    if !connectivityManager.isPhoneReachable {
                        HStack {
                            Image(systemName: "iphone.slash")
                                .foregroundColor(.orange)
                            Text("iPhone not connected")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                    }

                    // Readiness card
                    ReadinessCard(readiness: connectivityManager.readinessData)

                    // Macro progress card
                    MacroCard(macros: connectivityManager.macroProgress)

                    // Volume tracker card
                    VolumeCard(volume: connectivityManager.volumeProgress)

                    // Quick actions
                    HStack(spacing: 12) {
                        // Voice log button
                        Button(action: { showingVoiceLog = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.title3)
                                Text("Log Food")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        // Workout tracking button
                        Button(action: { showingWorkoutView = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.title3)
                                Text("Workout")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
            }
            .navigationTitle("AirFit")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingVoiceLog) {
                VoiceLogView()
                    .environmentObject(connectivityManager)
            }
            .sheet(isPresented: $showingWorkoutView) {
                WorkoutHRRView()
            }
            .onAppear {
                connectivityManager.requestContextUpdate()
            }
        }
    }
}

// MARK: - Readiness Card

private struct ReadinessCard: View {
    let readiness: ReadinessData

    private var statusColor: Color {
        switch readiness.category {
        case "Great": return .green
        case "Good": return .blue
        case "Moderate": return .yellow
        case "Rest": return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: readiness.categoryIcon)
                    .foregroundColor(statusColor)
                Text("Readiness")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text(readiness.category)
                    .font(.title3.bold())
                    .foregroundColor(statusColor)
                Spacer()
                if readiness.isBaselineReady {
                    Text("\(readiness.positiveCount)/\(readiness.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if !readiness.isBaselineReady {
                Text("Building baseline...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

// MARK: - Macro Card

private struct MacroCard: View {
    let macros: MacroProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                Text(macros.isTrainingDay ? "Training Day" : "Rest Day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack(spacing: 16) {
                // Calories
                VStack(spacing: 2) {
                    Text("\(macros.calories)")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                    Text("cal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 24)

                // Protein
                VStack(spacing: 2) {
                    Text("\(macros.protein)g")
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                    Text("protein")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Remaining
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(macros.proteinRemaining)g")
                        .font(.caption.bold())
                    Text("to go")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bars
            HStack(spacing: 4) {
                ProgressView(value: min(1.0, macros.calorieProgress))
                    .tint(.orange)
                ProgressView(value: min(1.0, macros.proteinProgress))
                    .tint(.blue)
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

// MARK: - Volume Card

private struct VolumeCard: View {
    let volume: VolumeProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.green)
                Text("Weekly Volume")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            ForEach(volume.muscleGroups.prefix(4)) { group in
                HStack(spacing: 6) {
                    Text(group.name)
                        .font(.caption2)
                        .frame(width: 44, alignment: .leading)
                        .foregroundColor(.secondary)

                    ProgressView(value: group.progress)
                        .tint(statusColor(for: group.status))

                    if group.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else {
                        Text("\(group.currentSets)")
                            .font(.caption2.bold())
                            .foregroundColor(statusColor(for: group.status))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "in_zone": return .green
        case "above": return .blue
        case "below": return .yellow
        case "at_floor": return .red
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    MainWatchView()
        .environmentObject(WatchConnectivityManager.shared)
}
