import SwiftUI

/// Sheet showing recent workout details from Hevy
struct WorkoutDetailSheet: View {
    let workouts: [APIClient.WorkoutSummary]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary header
                    summaryHeader

                    // Recent workouts list
                    if !workouts.isEmpty {
                        workoutsList
                    } else {
                        emptyState
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("This Week's Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            // Workout count hero
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(workouts.count)")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.secondary)
                    Text("WORKOUTS")
                        .font(.labelMicro)
                        .tracking(1)
                        .foregroundStyle(Theme.textMuted)
                }

                Divider()
                    .frame(height: 60)

                VStack(spacing: 4) {
                    Text("\(totalDuration)")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("TOTAL MINS")
                        .font(.labelMicro)
                        .tracking(1)
                        .foregroundStyle(Theme.textMuted)
                }

                Divider()
                    .frame(height: 60)

                VStack(spacing: 4) {
                    Text(formattedVolume)
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("VOLUME")
                        .font(.labelMicro)
                        .tracking(1)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.vertical, 16)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private var totalDuration: Int {
        workouts.reduce(0) { $0 + $1.duration_minutes }
    }

    private var totalVolume: Double {
        workouts.reduce(0) { $0 + $1.total_volume_lbs }
    }

    private var formattedVolume: String {
        if totalVolume >= 10000 {
            return String(format: "%.1fK", totalVolume / 1000)
        }
        return String(format: "%.0f", totalVolume)
    }

    // MARK: - Workouts List

    private var workoutsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT SESSIONS")
                .font(.labelHero)
                .tracking(2)
                .foregroundStyle(Theme.textMuted)

            ForEach(workouts) { workout in
                workoutCard(workout)
            }
        }
    }

    private func workoutCard(_ workout: APIClient.WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(.titleMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Text(formatDate(workout.date))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                // Duration badge
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(workout.duration_minutes) min")
                        .font(.labelMicro)
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Theme.surface.opacity(0.5))
                )
            }

            // Exercises list
            if !workout.exercises.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(workout.exercises.prefix(4).enumerated()), id: \.offset) { index, exercise in
                        if index > 0 {
                            Text(" · ")
                                .font(.labelMicro)
                                .foregroundStyle(Theme.textMuted)
                        }
                        Text(shortenExerciseName(exercise))
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    if workout.exercises.count > 4 {
                        Text(" +\(workout.exercises.count - 4)")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            // Volume
            if workout.total_volume_lbs > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .font(.caption2)
                    Text(String(format: "%.0f lbs total volume", workout.total_volume_lbs))
                        .font(.labelMicro)
                }
                .foregroundStyle(Theme.accent.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private func formatDate(_ dateString: String) -> String {
        // Parse ISO date and format nicely
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEEE, MMM d"
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func shortenExerciseName(_ name: String) -> String {
        // Shorten common exercise names
        let replacements = [
            "Barbell": "BB",
            "Dumbbell": "DB",
            "Cable": "Cbl",
            "Machine": "Mch",
            "Incline": "Inc",
            "Decline": "Dec",
            "Bench Press": "Bench",
            "Shoulder Press": "OHP",
            "Romanian Deadlift": "RDL",
            "Lat Pulldown": "Lat PD"
        ]

        var shortened = name
        for (long, short) in replacements {
            shortened = shortened.replacingOccurrences(of: long, with: short)
        }

        // Truncate if still too long
        if shortened.count > 15 {
            return String(shortened.prefix(14)) + "…"
        }
        return shortened
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textMuted)

            Text("No workouts this week")
                .font(.titleMedium)
                .foregroundStyle(Theme.textSecondary)

            Text("Your Hevy workouts will appear here")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

#Preview {
    WorkoutDetailSheet(workouts: [
        APIClient.WorkoutSummary(
            id: "1",
            title: "Push Day",
            date: "2024-12-12",
            days_ago: 2,
            duration_minutes: 65,
            exercises: ["Bench Press", "Incline DB Press", "Cable Flyes", "Tricep Pushdown", "Lateral Raises"],
            total_volume_lbs: 12500
        ),
        APIClient.WorkoutSummary(
            id: "2",
            title: "Pull Day",
            date: "2024-12-10",
            days_ago: 4,
            duration_minutes: 58,
            exercises: ["Deadlift", "Barbell Row", "Lat Pulldown", "Face Pulls", "Bicep Curls"],
            total_volume_lbs: 15200
        )
    ])
}
