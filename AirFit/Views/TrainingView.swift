import SwiftUI

struct TrainingView: View {
    @State private var setTracker: APIClient.SetTrackerResponse?
    @State private var liftProgress: [APIClient.LiftData] = []
    @State private var recentWorkouts: [APIClient.WorkoutSummary] = []
    @State private var isLoading = true
    @State private var isSyncing = false

    private let apiClient = APIClient()

    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Set Tracker Section (Hero)
                    if let tracker = setTracker, !tracker.muscle_groups.isEmpty {
                        setTrackerSection(tracker)
                            .scrollReveal()
                    }

                    // Lift Progress Section
                    if !liftProgress.isEmpty {
                        liftProgressSection
                    }

                    // Recent Workouts Section
                    if !recentWorkouts.isEmpty {
                        recentWorkoutsSection
                    }

                    // Empty state
                    if setTracker?.muscle_groups.isEmpty ?? true && !isLoading {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .refreshable {
            await loadData()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSyncing {
                    ProgressView()
                        .tint(Theme.accent)
                } else {
                    Button {
                        Task { await syncHevy() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Set Tracker Section

    private func setTrackerSection(_ tracker: APIClient.SetTrackerResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text("ROLLING 7-DAY SETS")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                if let lastSync = tracker.last_sync {
                    Text(formatSyncTime(lastSync))
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            // Sort muscle groups by priority
            let sortedMuscles = sortMuscleGroups(tracker.muscle_groups)

            ForEach(sortedMuscles, id: \.0) { name, data in
                MuscleProgressBar(
                    name: name.capitalized,
                    current: data.current,
                    minSets: data.min,
                    maxSets: data.max,
                    status: data.status
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    private func sortMuscleGroups(_ groups: [String: APIClient.MuscleGroupData]) -> [(String, APIClient.MuscleGroupData)] {
        // Priority order: major muscle groups first
        let priority = ["chest", "back", "quads", "glutes", "hamstrings", "delts", "biceps", "triceps", "calves", "core"]

        return groups.sorted { a, b in
            let aIndex = priority.firstIndex(of: a.key) ?? priority.count
            let bIndex = priority.firstIndex(of: b.key) ?? priority.count
            return aIndex < bIndex
        }
    }

    // MARK: - Lift Progress Section

    private var liftProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(Theme.protein)
                Text("LIFT PROGRESS")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            ForEach(liftProgress) { lift in
                LiftProgressCard(lift: lift)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Recent Workouts Section

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundStyle(Theme.tertiary)
                Text("RECENT WORKOUTS")
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(Theme.textMuted)
            }

            ForEach(recentWorkouts) { workout in
                WorkoutCard(workout: workout)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .opacity(0.5)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
            }

            Text("No workout data")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            Text("Connect Hevy to see your training progress here.")
                .font(.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await syncHevy() }
            } label: {
                Label("Sync from Hevy", systemImage: "arrow.triangle.2.circlepath")
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accentGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(AirFitButtonStyle())
        }
        .padding(40)
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true

        // Load all data in parallel
        async let setTrackerTask: () = loadSetTracker()
        async let liftProgressTask: () = loadLiftProgress()
        async let workoutsTask: () = loadRecentWorkouts()

        await setTrackerTask
        await liftProgressTask
        await workoutsTask

        isLoading = false
    }

    private func loadSetTracker() async {
        do {
            setTracker = try await apiClient.getSetTracker()
        } catch {
            print("Failed to load set tracker: \(error)")
        }
    }

    private func loadLiftProgress() async {
        do {
            let response = try await apiClient.getLiftProgress()
            liftProgress = response.lifts
        } catch {
            print("Failed to load lift progress: \(error)")
        }
    }

    private func loadRecentWorkouts() async {
        do {
            recentWorkouts = try await apiClient.getRecentWorkouts()
        } catch {
            print("Failed to load recent workouts: \(error)")
        }
    }

    private func syncHevy() async {
        isSyncing = true

        // Trigger server-side Hevy sync
        let url = URL(string: "http://localhost:8080/scheduler/trigger-hevy-sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            _ = try await URLSession.shared.data(for: request)
            // Wait a moment then reload
            try? await Task.sleep(for: .seconds(1))
            await loadData()
        } catch {
            print("Failed to sync Hevy: \(error)")
        }

        isSyncing = false
    }

    private func formatSyncTime(_ isoDate: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: isoDate) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .abbreviated
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return ""
    }
}

// MARK: - Muscle Progress Bar

struct MuscleProgressBar: View {
    let name: String
    let current: Int
    let minSets: Int
    let maxSets: Int
    let status: String

    private var statusColor: Color {
        switch status {
        case "in_zone": return Theme.success
        case "above": return Theme.accent
        case "at_floor": return Theme.warning
        case "below": return Theme.error.opacity(0.8)
        default: return Theme.textMuted
        }
    }

    private var progress: Double {
        guard maxSets > 0 else { return 0 }
        return Double(current) / Double(maxSets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text("\(current)/\(minSets)-\(maxSets)")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.background)

                    // Optimal zone indicator (subtle line at min threshold)
                    let minPosition = geo.size.width * (Double(minSets) / Double(maxSets))
                    Rectangle()
                        .fill(Theme.textMuted.opacity(0.3))
                        .frame(width: 1)
                        .offset(x: minPosition)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(statusColor)
                        .frame(width: Swift.min(geo.size.width * progress, geo.size.width))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Lift Progress Card

struct LiftProgressCard: View {
    let lift: APIClient.LiftData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lift.name)
                        .font(.labelLarge)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text("\(lift.workout_count) sessions")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(lift.current_pr.weight_lbs)) lbs")
                        .font(.metricSmall)
                        .foregroundStyle(Theme.accent)

                    Text("PR @ \(lift.current_pr.reps) reps")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            // Sparkline
            if lift.history.count > 1 {
                TrainingSparkline(data: lift.history.map { $0.weight_lbs })
                    .frame(height: 32)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.background)
        )
    }
}

// MARK: - Training Sparkline View

private struct TrainingSparkline: View {
    let data: [Double]

    private var normalizedData: [Double] {
        guard let minVal = data.min(), let maxVal = data.max(), maxVal > minVal else {
            return data.map { _ in 0.5 }
        }
        return data.map { ($0 - minVal) / (maxVal - minVal) }
    }

    var body: some View {
        GeometryReader { geo in
            let stepX = geo.size.width / Double(max(data.count - 1, 1))

            Path { path in
                guard !normalizedData.isEmpty else { return }

                for (index, value) in normalizedData.enumerated() {
                    let x = Double(index) * stepX
                    let y = geo.size.height * (1 - value)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

            // Dots at each point
            ForEach(Array(normalizedData.enumerated()), id: \.offset) { index, value in
                let x = Double(index) * stepX
                let y = geo.size.height * (1 - value)

                Circle()
                    .fill(Theme.accent)
                    .frame(width: 4, height: 4)
                    .position(x: x, y: y)
            }
        }
    }
}

// MARK: - Workout Card

struct WorkoutCard: View {
    let workout: APIClient.WorkoutSummary

    private var timeAgo: String {
        if workout.days_ago == 0 {
            return "Today"
        } else if workout.days_ago == 1 {
            return "Yesterday"
        } else {
            return "\(workout.days_ago) days ago"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.title)
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                Text(timeAgo)
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundStyle(Theme.textMuted)
                    Text("\(workout.duration_minutes) min")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "scalemass")
                        .font(.caption2)
                        .foregroundStyle(Theme.textMuted)
                    Text("\(Int(workout.total_volume_lbs)) lbs")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Text(workout.exercises.prefix(4).joined(separator: ", "))
                .font(.labelMicro)
                .foregroundStyle(Theme.textMuted)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.background)
        )
    }
}

#Preview {
    NavigationStack {
        TrainingView()
    }
}
