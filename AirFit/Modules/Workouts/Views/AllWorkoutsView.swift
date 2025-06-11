import SwiftUI
import SwiftData

struct AllWorkoutsView: View {
    @State var viewModel: WorkoutViewModel
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter: WorkoutFilter = .all
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var animateIn = false

    enum WorkoutFilter: String, CaseIterable {
        case all = "All"
        case strength = "Strength"
        case cardio = "Cardio"
        case flexibility = "Flexibility"
        case sports = "Sports"

        var displayName: String { rawValue }
    }

    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case duration = "Duration"
        case exercises = "Exercise Count"

        var displayName: String { rawValue }
    }

    var filteredWorkouts: [Workout] {
        let filtered = viewModel.workouts.filter { workout in
            // Search filter
            let matchesSearch = searchText.isEmpty ||
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.exercises.contains { $0.name.localizedCaseInsensitiveContains(searchText) }

            // Type filter
            let matchesType = selectedFilter == .all ||
                workout.workoutType == selectedFilter.rawValue.lowercased()

            return matchesSearch && matchesType
        }

        // Sort
        return filtered.sorted(by: { lhs, rhs in
            switch sortOrder {
            case .dateDescending:
                return (lhs.completedDate ?? lhs.plannedDate ?? Date()) >
                    (rhs.completedDate ?? rhs.plannedDate ?? Date())
            case .dateAscending:
                return (lhs.completedDate ?? lhs.plannedDate ?? Date()) <
                    (rhs.completedDate ?? rhs.plannedDate ?? Date())
            case .duration:
                return (lhs.duration ?? 0) > (rhs.duration ?? 0)
            case .exercises:
                return lhs.exercises.count > rhs.exercises.count
            }
        })
    }

    var groupedWorkouts: [(String, [Workout])] {
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            let date = workout.completedDate ?? workout.plannedDate ?? Date()
            return date.formatted(.dateTime.month(.wide).year())
        }

        return grouped.sorted { lhs, rhs in
            // Sort sections by date
            guard let lhsDate = lhs.value.first?.completedDate ?? lhs.value.first?.plannedDate,
                  let rhsDate = rhs.value.first?.completedDate ?? rhs.value.first?.plannedDate else {
                return false
            }
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        BaseScreen {
            VStack(spacing: 0) {
                // Header with search
                VStack(spacing: AppSpacing.sm) {
                    CascadeText("Workout History")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                    
                    // Search bar
                    GlassCard {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: gradientManager.active.colors(for: colorScheme),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.system(size: 18))
                            
                            TextField("Search workouts or exercises...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16, weight: .medium))
                                .onTapGesture {
                                    HapticService.impact(.light)
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    HapticService.impact(.light)
                                    withAnimation(MotionToken.microAnimation) {
                                        searchText = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.secondary.opacity(0.6))
                                        .font(.system(size: 16))
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(AppSpacing.sm)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(MotionToken.standardSpring.delay(0.1), value: animateIn)
                }
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Stats Summary
                        if !filteredWorkouts.isEmpty {
                            WorkoutHistoryStats(workouts: filteredWorkouts)
                                .environmentObject(gradientManager)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.top, AppSpacing.sm)
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 20)
                                .animation(MotionToken.standardSpring.delay(0.2), value: animateIn)
                        }

                        // Filters
                        VStack(spacing: AppSpacing.md) {
                            // Type Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    ForEach(Array(WorkoutFilter.allCases.enumerated()), id: \.element) { index, filter in
                                        FilterChip(
                                            title: filter.displayName,
                                            isSelected: selectedFilter == filter,
                                            index: index
                                        ) {
                                            HapticService.impact(.light)
                                            withAnimation(MotionToken.microAnimation) {
                                                selectedFilter = filter
                                            }
                                        }
                                        .environmentObject(gradientManager)
                                    }
                                }
                                .padding(.horizontal, AppSpacing.md)
                            }
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(MotionToken.standardSpring.delay(0.3), value: animateIn)

                            // Sort Options
                            HStack {
                                Text("Sort by:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.secondary)

                                Menu {
                                    ForEach(SortOrder.allCases, id: \.self) { order in
                                        Button(order.displayName) {
                                            HapticService.impact(.light)
                                            withAnimation(MotionToken.microAnimation) {
                                                sortOrder = order
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(sortOrder.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: gradientManager.active.colors(for: colorScheme),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                }

                                Spacer()
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .opacity(animateIn ? 1 : 0)
                            .animation(MotionToken.standardSpring.delay(0.35), value: animateIn)
                        }

                        // Workouts List
                        if groupedWorkouts.isEmpty {
                            EmptyStateView(
                                icon: "figure.strengthtraining.traditional",
                                title: "No Workouts Found",
                                message: searchText.isEmpty ? "Start logging workouts to see them here" : "Try adjusting your search or filters"
                            )
                            .padding(.top, AppSpacing.xl)
                            .opacity(animateIn ? 1 : 0)
                            .animation(MotionToken.standardSpring.delay(0.4), value: animateIn)
                        } else {
                            VStack(spacing: AppSpacing.lg) {
                                ForEach(Array(groupedWorkouts.enumerated()), id: \.element.0) { sectionIndex, section in
                                    let (monthYear, workouts) = section
                                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                                        HStack {
                                            CascadeText(monthYear)
                                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                                .foregroundStyle(Color.secondary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, AppSpacing.md)

                                        VStack(spacing: AppSpacing.sm) {
                                            ForEach(Array(workouts.enumerated()), id: \.element.id) { workoutIndex, workout in
                                                NavigationLink(value: WorkoutCoordinator.WorkoutDestination.workoutDetail(workout)) {
                                                    WorkoutHistoryRow(workout: workout, index: sectionIndex * 10 + workoutIndex)
                                                        .environmentObject(gradientManager)
                                                }
                                                .buttonStyle(.plain)
                                                .padding(.horizontal, AppSpacing.md)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, AppSpacing.xl)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.workouts.isEmpty {
                await viewModel.loadWorkouts()
            }
            withAnimation(MotionToken.standardSpring) {
                animateIn = true
            }
        }
    }
}

// MARK: - History Stats
private struct WorkoutHistoryStats: View {
    let workouts: [Workout]
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateStats = false

    var totalWorkouts: Int { workouts.count }
    var totalDuration: TimeInterval {
        workouts.compactMap(\.duration).reduce(0, +)
    }
    var totalCalories: Double {
        workouts.compactMap(\.caloriesBurned).reduce(0, +)
    }
    var averageDuration: TimeInterval {
        guard totalWorkouts > 0 else { return 0 }
        return totalDuration / Double(totalWorkouts)
    }

    var body: some View {
        GlassCard {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        CascadeText("All Time Stats")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                    StatCard(
                        value: "\(totalWorkouts)",
                        label: "Workouts",
                        icon: "number",
                        index: 0,
                        animate: animateStats
                    )
                    .environmentObject(gradientManager)
                    
                    StatCard(
                        value: totalDuration.formattedDuration(),
                        label: "Total Time",
                        icon: "timer",
                        index: 1,
                        animate: animateStats
                    )
                    .environmentObject(gradientManager)
                    
                    StatCard(
                        value: "\(Int(totalCalories))",
                        label: "Calories",
                        icon: "flame.fill",
                        index: 2,
                        animate: animateStats
                    )
                    .environmentObject(gradientManager)
                    
                    StatCard(
                        value: averageDuration.formattedDuration(),
                        label: "Avg Duration",
                        icon: "chart.xyaxis.line",
                        index: 3,
                        animate: animateStats
                    )
                    .environmentObject(gradientManager)
                }
            }
            .padding(AppSpacing.md)
        }
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.1)) {
                animateStats = true
            }
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let index: Int
    let animate: Bool
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    
    private var gradientColors: [Color] {
        switch index {
        case 0: return [Color(hex: "#667EEA"), Color(hex: "#764BA2")]
        case 1: return [Color(hex: "#52B788"), Color(hex: "#40916C")]
        case 2: return [Color(hex: "#F8961E"), Color(hex: "#F3722C")]
        case 3: return [Color(hex: "#00B4D8"), Color(hex: "#0077B6")]
        default: return gradientManager.active.colors(for: colorScheme)
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animate ? 1 : 0.8)
                    .opacity(animate ? 1 : 0)
                    .animation(MotionToken.standardSpring.delay(Double(index) * 0.1), value: animate)
                
                GradientNumber(value: Double(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 10)
                    .animation(MotionToken.standardSpring.delay(Double(index) * 0.1 + 0.1), value: animate)
            }
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .opacity(animate ? 1 : 0)
                .animation(MotionToken.standardSpring.delay(Double(index) * 0.1 + 0.2), value: animate)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .foregroundStyle(
                    isSelected ?
                    AnyShapeStyle(Color.white) :
                    AnyShapeStyle(LinearGradient(
                        colors: gradientManager.active.colors(for: colorScheme),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                )
                .background {
                    if isSelected {
                        LinearGradient(
                            colors: gradientManager.active.colors(for: colorScheme),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.primary.opacity(0.08)
                    }
                }
                .clipShape(Capsule())
                .overlay {
                    if !isSelected {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .shadow(color: isSelected ? gradientManager.active.colors(for: colorScheme).first?.opacity(0.3) ?? .clear : .clear, radius: 8, y: 4)
        }
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(Double(index) * 0.05)) {
                animateIn = true
            }
        }
    }
}

// MARK: - History Row
private struct WorkoutHistoryRow: View {
    let workout: Workout
    let index: Int
    @EnvironmentObject private var gradientManager: GradientManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false
    @State private var animateIn = false

    private var dateText: String {
        let date = workout.completedDate ?? workout.plannedDate ?? Date()
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }

    private var timeText: String {
        let date = workout.completedDate ?? workout.plannedDate ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    // Workout type icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme).map { $0.opacity(0.1) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: workout.workoutTypeEnum?.systemImage ?? "figure.strengthtraining.traditional")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        HStack(spacing: AppSpacing.xs) {
                            Text(dateText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))

                            Text("•")
                                .foregroundStyle(Color.secondary.opacity(0.4))

                            Text(timeText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary.opacity(0.8))
                        }
                    }

                    Spacer()

                    if workout.aiAnalysis != nil {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradientManager.active.colors(for: colorScheme),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                }

                // Exercise preview
                if !workout.exercises.isEmpty {
                    Text(workout.exercises.prefix(3).map(\.name).joined(separator: ", ") +
                            (workout.exercises.count > 3 ? " +\(workout.exercises.count - 3) more" : ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .lineLimit(1)
                }

                // Stats row
                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                        Text(workout.formattedDuration ?? "0m")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.secondary.opacity(0.7))

                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11))
                        Text("\(workout.exercises.count) exercises")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.secondary.opacity(0.7))

                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 11))
                        Text("\(workout.totalSets) sets")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.secondary.opacity(0.7))

                    if let calories = workout.caloriesBurned, calories > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                            Text("\(Int(calories)) cal")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#F8961E"), Color(hex: "#F3722C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
            }
            .padding(AppSpacing.sm)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(MotionToken.microAnimation, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(MotionToken.microAnimation) {
                isPressed = pressing
            }
        }, perform: {})
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(MotionToken.standardSpring.delay(0.4 + Double(index % 5) * 0.1)) {
                animateIn = true
            }
        }
    }
}
