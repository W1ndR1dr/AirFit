import SwiftUI

// MARK: - Strength Detail View

/// Full drill-down view for strength tracking with exercise picker, chart, and PR display.
/// Pushed via NavigationLink from StrengthSummaryCard in the Dashboard Training section.
struct StrengthDetailView: View {
    let initialExercises: [APIClient.TrackedExercise]

    @State private var exercises: [APIClient.TrackedExercise] = []
    @State private var selectedExercise: APIClient.TrackedExercise?
    @State private var historyData: [ChartDataPoint] = []
    @State private var strengthHistory: APIClient.StrengthHistoryResponse?
    @State private var timeRange: ChartTimeRange = .sixMonths  // Default to 6M
    @State private var showEstimated1RM = true  // Toggle for e1RM vs raw weight
    @State private var isLoading = false

    // Sort option (time filtering now handled by single timeRange picker)
    @State private var sortOption: APIClient.ExerciseSortOption = .frequency

    /// Convert ChartTimeRange to server's TimeWindow for exercise filtering
    private var serverTimeWindow: APIClient.TimeWindow {
        switch timeRange {
        case .week: return .oneMonth  // Minimum server granularity
        case .month: return .oneMonth
        case .sixMonths: return .sixMonths
        case .year: return .oneYear
        case .all: return .allTime
        }
    }

    private let apiClient = APIClient()

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Aurora background for visual continuity
            BreathingMeshBackground(scrollProgress: 2.0)  // Coach tab colors
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Filter controls (sort only - time is unified below chart)
                    filterControls
                        .padding(.top, 8)

                    // Exercise picker (horizontal scroll)
                    ExercisePicker(exercises: exercises, selection: $selectedExercise)

                    // PR hero (simplified - stats moved below)
                    if let exercise = selectedExercise, let pr = exercise.current_pr {
                        PRHeroCompact(pr: pr)
                    }

                    // Stats row (moved up, replaces redundant hero data)
                    if let history = strengthHistory, !history.history.isEmpty {
                        statsRow(history)
                    }

                    // Metric toggle
                    Picker("Metric", selection: $showEstimated1RM) {
                        Text("Est. 1RM").tag(true)
                        Text("Weight").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // Chart
                    if isLoading {
                        ProgressView()
                            .frame(height: 240)
                    } else if historyData.isEmpty {
                        emptyChartState
                    } else {
                        InteractiveChartView(
                            data: filteredData,
                            color: Theme.accent,
                            unit: "lbs",
                            showSmoothing: true,
                            formatValue: { "\(Int($0)) lbs" }
                        )
                        .frame(height: 240)
                        .padding(.horizontal, 20)
                    }

                    // Time range picker (single unified control)
                    ChartTimeRangePicker(selection: $timeRange)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle(selectedExercise?.name ?? "Strength")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            if exercises.isEmpty {
                exercises = initialExercises
            }
            if selectedExercise == nil {
                selectedExercise = exercises.first
            }
        }
        .onChange(of: selectedExercise) { _, newExercise in
            if let exercise = newExercise {
                Task { await loadHistory(for: exercise.name) }
            }
        }
        .onChange(of: showEstimated1RM) { _, _ in
            updateChartData()
        }
        .onChange(of: sortOption) { _, _ in
            Task { await loadExercises() }
        }
        .onChange(of: timeRange) { _, _ in
            // Reload exercises when time range changes (unified picker)
            Task { await loadExercises() }
        }
        .task {
            if let exercise = selectedExercise ?? exercises.first {
                selectedExercise = exercise
                await loadHistory(for: exercise.name)
            }
        }
    }

    private var filterControls: some View {
        // Sort option picker (time filtering moved to chart picker below)
        HStack(spacing: 8) {
            ForEach(APIClient.ExerciseSortOption.allCases, id: \.self) { option in
                FilterChip(
                    label: option.displayName,
                    isSelected: sortOption == option
                ) {
                    withAnimation(.airfit) { sortOption = option }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func loadExercises() async {
        do {
            let response = try await apiClient.getTrackedExercises(
                limit: 20,
                sortBy: sortOption,
                timeWindow: serverTimeWindow
            )
            await MainActor.run {
                exercises = response.exercises
                // Keep selection if still in list, otherwise pick first
                if let current = selectedExercise,
                   !exercises.contains(where: { $0.name == current.name }) {
                    selectedExercise = exercises.first
                }
            }
        } catch {
            print("Failed to load exercises: \(error)")
        }
    }

    private var filteredData: [ChartDataPoint] {
        guard let days = timeRange.days else { return historyData }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return historyData.filter { $0.date >= cutoff }
    }

    private var emptyChartState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(Theme.textMuted)

            Text("No data yet")
                .font(.labelLarge)
                .foregroundStyle(Theme.textSecondary)

            Text("Keep training and your progress will appear here.")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(height: 240)
        .padding(.horizontal, 40)
    }

    /// Compact stats row - positioned below hero, replaces redundant hero data
    private func statsRow(_ history: APIClient.StrengthHistoryResponse) -> some View {
        HStack(spacing: 0) {
            // Sessions
            StatTile(
                value: "\(history.history.count)",
                label: "Sessions"
            )

            // Best e1RM
            if let pr = history.current_pr {
                StatTile(
                    value: "\(Int(pr.e1rm))",
                    label: "Best e1RM",
                    unit: "lbs"
                )
            }

            // Monthly trend
            if let trend = history.trend {
                StatTile(
                    value: String(format: "%+.1f", trend),
                    label: "Monthly",
                    unit: "lbs",
                    color: trend >= 0 ? Theme.success : Theme.warning
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
    }

    private func loadHistory(for exerciseName: String) async {
        isLoading = true
        do {
            let response = try await apiClient.getStrengthHistory(exercise: exerciseName, days: 365)
            await MainActor.run {
                strengthHistory = response
                updateChartData()
                isLoading = false
            }
        } catch {
            print("Failed to load strength history: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func updateChartData() {
        guard let history = strengthHistory else {
            historyData = []
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        historyData = history.history.compactMap { point -> ChartDataPoint? in
            guard let date = dateFormatter.date(from: point.date) else { return nil }
            let value = showEstimated1RM ? point.e1rm : point.weight_lbs
            return ChartDataPoint(date: date, value: value)
        }
    }
}

// MARK: - Exercise Picker

struct ExercisePicker: View {
    let exercises: [APIClient.TrackedExercise]
    @Binding var selection: APIClient.TrackedExercise?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(exercises.prefix(15)) { exercise in
                    ExercisePill(
                        name: exercise.name,
                        isSelected: selection?.name == exercise.name
                    )
                    .onTapGesture {
                        withAnimation(.airfit) {
                            selection = exercise
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Exercise Pill

struct ExercisePill: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        Text(shortenedName)
            .font(.labelMedium)
            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.ultraThinMaterial))
            )
            .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var shortenedName: String {
        // Shorten long exercise names
        let shortened = name
            .replacingOccurrences(of: "(Barbell)", with: "")
            .replacingOccurrences(of: "(Dumbbell)", with: "DB")
            .replacingOccurrences(of: "(Machine)", with: "")
            .replacingOccurrences(of: "(Cable)", with: "Cable")
            .trimmingCharacters(in: .whitespaces)

        if shortened.count > 20 {
            return String(shortened.prefix(18)) + "..."
        }
        return shortened
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.labelMicro)
                .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.ultraThinMaterial))
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - PR Hero View

struct PRHeroView: View {
    let pr: APIClient.ExercisePR
    let trend: Double?
    var improvement: Double? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Main PR display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(pr.weight_lbs))")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Text("LBS")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textMuted)
            }

            Text("@ \(pr.reps) reps")
                .font(.labelLarge)
                .foregroundStyle(Theme.textSecondary)

            // e1RM badge
            HStack(spacing: 6) {
                Text("Est. 1RM:")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textMuted)
                Text("\(Int(pr.e1rm)) lbs")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.accent.opacity(0.1))
            .clipShape(Capsule())

            // Improvement indicator (from filtered data)
            if let imp = improvement {
                HStack(spacing: 4) {
                    Image(systemName: imp >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(String(format: "%+.1f lbs/mo", imp))
                        .font(.labelMicro)
                }
                .foregroundStyle(imp >= 0 ? Theme.success : Theme.warning)
                .padding(.top, 4)
            }
            // Fallback to chart trend if no improvement data
            else if let trend = trend {
                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(String(format: "%+.1f lbs/month", trend))
                        .font(.labelMicro)
                }
                .foregroundStyle(trend >= 0 ? Theme.success : Theme.warning)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 16)
    }
}

// MARK: - PR Hero Compact

/// Simplified PR display - just weight and reps, no redundant stats
struct PRHeroCompact: View {
    let pr: APIClient.ExercisePR

    var body: some View {
        VStack(spacing: 8) {
            // Main PR display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(pr.weight_lbs))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Text("LBS")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textMuted)
            }

            Text("@ \(pr.reps) reps")
                .font(.labelLarge)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let value: String
    let label: String
    var unit: String? = nil
    var color: Color = Theme.textPrimary

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.metricSmall)
                    .foregroundStyle(color)
                if let unit = unit {
                    Text(unit)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            Text(label)
                .font(.labelMicro)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Strength Summary Card (for Dashboard inline display)

struct StrengthSummaryCard: View {
    let exercises: [APIClient.TrackedExercise]

    var body: some View {
        NavigationLink(destination: StrengthDetailView(initialExercises: exercises)) {
            VStack(spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                        Text("STRENGTH PROGRESS")
                            .font(.labelHero)
                            .tracking(2)
                            .foregroundStyle(Theme.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                VStack(spacing: 12) {
                    ForEach(exercises.prefix(3)) { exercise in
                        StrengthMiniRow(exercise: exercise)
                    }
                }

                if exercises.count > 3 {
                    Text("+\(exercises.count - 3) more exercises")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Strength Mini Row

struct StrengthMiniRow: View {
    let exercise: APIClient.TrackedExercise

    var body: some View {
        HStack {
            Text(exercise.name)
                .font(.labelMedium)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Mini sparkline
            if !exercise.recent_trend.isEmpty {
                MiniSparkline(data: exercise.recent_trend, color: Theme.accent)
                    .frame(width: 48, height: 20)
            }

            // Current PR
            if let pr = exercise.current_pr {
                Text("\(Int(pr.weight_lbs)) lbs")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.accent)
                    .frame(minWidth: 60, alignment: .trailing)
            }
        }
    }
}

// MARK: - Preview

#Preview("Strength Detail View") {
    NavigationStack {
        StrengthDetailView(initialExercises: [
            APIClient.TrackedExercise(
                name: "Bench Press",
                workout_count: 28,
                current_pr: APIClient.ExercisePR(
                    weight_lbs: 225,
                    reps: 5,
                    date: "2025-12-14",
                    e1rm: 253
                ),
                recent_trend: [220, 225, 228, 230, 235, 240, 245, 253],
                improvement: 2.5
            ),
            APIClient.TrackedExercise(
                name: "Squat",
                workout_count: 25,
                current_pr: APIClient.ExercisePR(
                    weight_lbs: 315,
                    reps: 3,
                    date: "2025-12-10",
                    e1rm: 346
                ),
                recent_trend: [300, 305, 310, 320, 325, 330, 340, 346],
                improvement: 4.2
            )
        ])
    }
}

#Preview("Strength Summary Card") {
    StrengthSummaryCard(exercises: [
        APIClient.TrackedExercise(
            name: "Bench Press",
            workout_count: 28,
            current_pr: APIClient.ExercisePR(
                weight_lbs: 225,
                reps: 5,
                date: "2025-12-14",
                e1rm: 253
            ),
            recent_trend: [220, 225, 228, 230, 235, 240, 245, 253],
            improvement: 2.5
        ),
        APIClient.TrackedExercise(
            name: "Squat",
            workout_count: 25,
            current_pr: APIClient.ExercisePR(
                weight_lbs: 315,
                reps: 3,
                date: "2025-12-10",
                e1rm: 346
            ),
            recent_trend: [300, 305, 310, 320, 325, 330, 340, 346],
            improvement: 4.2
        ),
        APIClient.TrackedExercise(
            name: "Deadlift",
            workout_count: 22,
            current_pr: APIClient.ExercisePR(
                weight_lbs: 405,
                reps: 2,
                date: "2025-12-08",
                e1rm: 432
            ),
            recent_trend: [380, 385, 390, 400, 405, 415, 420, 432],
            improvement: -1.5
        )
    ])
    .padding(20)
    .background(Theme.background)
}
