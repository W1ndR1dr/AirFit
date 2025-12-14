import SwiftUI
import SwiftData

enum NutritionViewMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: NutritionEntry.recentHistory, sort: \NutritionEntry.timestamp, order: .reverse)
    private var allEntries: [NutritionEntry]

    @State private var inputText = ""
    @State private var isLoading = false
    @State private var isTrainingDay = true
    @State private var workoutName: String?
    @State private var expandedEntryId: UUID?
    @State private var energyTracker = EnergyTracker()
    @State private var editingEntry: NutritionEntry?
    @FocusState private var isInputFocused: Bool

    // View mode and date navigation
    @State private var viewMode: NutritionViewMode = .day
    @State private var selectedDate: Date = Date()

    // Scrollytelling
    @State private var scrollOffset: CGFloat = 0

    private let apiClient = APIClient()

    // Filter entries based on view mode and selected date
    private var filteredEntries: [NutritionEntry] {
        let start: Date
        let end: Date

        switch viewMode {
        case .day:
            start = selectedDate.startOfDay
            end = selectedDate.endOfDay
        case .week:
            start = selectedDate.startOfWeek
            end = selectedDate.endOfWeek.endOfDay
        case .month:
            start = selectedDate.startOfMonth
            end = selectedDate.endOfMonth.endOfDay
        }

        return allEntries.filter { $0.timestamp >= start && $0.timestamp <= end }
    }

    // Group entries by day for week/month views
    private var dailySummaries: [DailySummary] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            entry.timestamp.startOfDay
        }
        return grouped.map { DailySummary(date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }

    // Is viewing today?
    private var isToday: Bool {
        selectedDate.isSameDay(as: Date())
    }

    // Targets based on training/rest day
    private var targets: (cal: Int, protein: Int, carbs: Int, fat: Int) {
        isTrainingDay ? (2600, 175, 330, 67) : (2200, 175, 250, 57)
    }

    // Totals for current view
    private var totals: (cal: Int, protein: Int, carbs: Int, fat: Int) {
        filteredEntries.reduce((0, 0, 0, 0)) { result, entry in
            (result.0 + entry.calories,
             result.1 + entry.protein,
             result.2 + entry.carbs,
             result.3 + entry.fat)
        }
    }

    // Net calories (consumed - burned) - only meaningful for today
    private var netCalories: Int {
        totals.cal - energyTracker.todayTDEE
    }

    // Date range label
    private var dateRangeLabel: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .day:
            if isToday {
                return "Today"
            }
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        case .week:
            formatter.dateFormat = "MMM d"
            let start = formatter.string(from: selectedDate.startOfWeek)
            let end = formatter.string(from: selectedDate.endOfWeek)
            return "\(start) - \(end)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Retrospective Stats

    private var daysInPeriod: Int {
        switch viewMode {
        case .day: return 1
        case .week: return 7
        case .month:
            let calendar = Calendar.current
            let range = calendar.range(of: .day, in: .month, for: selectedDate)
            return range?.count ?? 30
        }
    }

    private var daysWithEntries: Int {
        dailySummaries.count
    }

    // Daily averages (only for days with entries)
    private var dailyAverages: (cal: Int, protein: Int, carbs: Int, fat: Int) {
        guard daysWithEntries > 0 else { return (0, 0, 0, 0) }
        return (
            totals.cal / daysWithEntries,
            totals.protein / daysWithEntries,
            totals.carbs / daysWithEntries,
            totals.fat / daysWithEntries
        )
    }

    // Compliance: days where protein >= 90% of target
    private var proteinCompliance: (hit: Int, total: Int) {
        let threshold = Int(Double(targets.protein) * 0.9)
        let hit = dailySummaries.filter { $0.protein >= threshold }.count
        return (hit, daysWithEntries)
    }

    // Compliance: days where calories were within range (90-110% of target)
    private var calorieCompliance: (hit: Int, total: Int) {
        let low = Int(Double(targets.cal) * 0.9)
        let high = Int(Double(targets.cal) * 1.1)
        let hit = dailySummaries.filter { $0.calories >= low && $0.calories <= high }.count
        return (hit, daysWithEntries)
    }

    // Is this period in the past (for retrospective view)?
    private var isRetrospective: Bool {
        if viewMode == .day { return !isToday }
        return true // Week/month are always retrospective-style
    }

    // Scrollytelling progress (0 = expanded, 1 = collapsed)
    private var heroProgress: CGFloat {
        min(1, max(0, scrollOffset / 120))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Scroll offset tracker
                    ScrollOffsetReader()

                    // View mode picker
                    viewModePicker

                    // Date navigation
                    dateNavigationHeader

                    // Day type toggle (only show for today in day view)
                    if viewMode == .day && isToday {
                        dayToggle
                    }

                    // Live energy balance (only for today in day view)
                    if viewMode == .day && isToday && energyTracker.todayTDEE > 0 {
                        liveBalanceCard
                    }

                    // SCROLLYTELLING HERO: Macro summary that transforms on scroll
                    if viewMode == .day {
                        scrollytellingMacroHero
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    } else {
                        retrospectiveSummary
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }

                    // Content based on view mode
                    if viewMode == .day {
                        dayEntriesContent
                    } else {
                        summaryListContent
                    }
                }
                .padding(.bottom, viewMode == .day && isToday ? 100 : 20)
            }
            .coordinateSpace(name: "scroll")
            .scrollIndicators(.hidden)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                scrollOffset = offset
            }

            // Floating input area (only for today in day view)
            if viewMode == .day && isToday {
                VStack {
                    Spacer()
                    premiumInputArea
                }
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isToday || viewMode != .day {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.airfit) {
                            selectedDate = Date()
                            viewMode = .day
                        }
                    } label: {
                        Text("Today")
                            .font(.labelLarge)
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
            }
        }
        .task {
            await checkTrainingDay()
        }
        .sheet(item: $editingEntry) { entry in
            EditNutritionSheet(entry: entry)
        }
    }

    // MARK: - Scrollytelling Macro Hero
    // Transforms from big hero numbers to compact bar as you scroll

    @ViewBuilder
    private var scrollytellingMacroHero: some View {
        let heroCalories: Text = Text("\(totals.cal)")
            .font(.system(size: 64, weight: .bold, design: .rounded))
        let subtitleText: Text = Text("OF \(targets.cal) CALORIES")
            .font(.system(size: 11, weight: .semibold))
            .tracking(2)

        VStack(spacing: 0) {
            // Hero calorie number that scales on scroll
            heroCalories
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.calories, Theme.calories.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(1.0 - heroProgress * 0.4)
                .contentTransition(.numericText(value: Double(totals.cal)))
                .animation(.bloomWater, value: totals.cal)

            subtitleText
                .foregroundStyle(Theme.textMuted)
                .opacity(1.0 - heroProgress * 0.5)
                .scaleEffect(1.0 - heroProgress * 0.2)

            // Macro bars that fade in as hero shrinks
            VStack(spacing: 12) {
                HeroProgressBar(
                    label: "Protein",
                    current: totals.protein,
                    target: targets.protein,
                    unit: "g",
                    color: Theme.protein
                )
                HeroProgressBar(
                    label: "Carbs",
                    current: totals.carbs,
                    target: targets.carbs,
                    unit: "g",
                    color: Theme.carbs
                )
                HeroProgressBar(
                    label: "Fat",
                    current: totals.fat,
                    target: targets.fat,
                    unit: "g",
                    color: Theme.fat
                )
            }
            .padding(.top, 16.0 - (heroProgress * 8.0))
            .opacity(0.6 + heroProgress * 0.4)
        }
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(NutritionViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Date Navigation

    private var dateNavigationHeader: some View {
        HStack {
            Button {
                withAnimation(.airfit) {
                    navigateDate(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(AirFitSubtleButtonStyle())

            Spacer()

            Button {
                withAnimation(.airfit) {
                    selectedDate = Date()
                }
            } label: {
                Text(dateRangeLabel)
                    .font(.headlineMedium)
                    .foregroundStyle(Theme.textPrimary)
            }

            Spacer()

            Button {
                withAnimation(.airfit) {
                    navigateDate(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(cannotGoForward ? Theme.textMuted : Theme.accent)
            }
            .buttonStyle(AirFitSubtleButtonStyle())
            .disabled(cannotGoForward)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var cannotGoForward: Bool {
        switch viewMode {
        case .day:
            return selectedDate.isSameDay(as: Date())
        case .week:
            return selectedDate.startOfWeek >= Date().startOfWeek
        case .month:
            return selectedDate.startOfMonth >= Date().startOfMonth
        }
    }

    private func navigateDate(by amount: Int) {
        let calendar = Calendar.current
        switch viewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: amount, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: amount, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: amount, to: selectedDate) ?? selectedDate
        }
    }

    // MARK: - Summary List Content (for unified ScrollView)

    private var summaryListContent: some View {
        LazyVStack(spacing: 12) {
            if dailySummaries.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(dailySummaries.enumerated()), id: \.element.id) { index, summary in
                    PremiumDailySummaryRow(summary: summary, targets: targets)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.airfit) {
                                selectedDate = summary.date
                                viewMode = .day
                            }
                        }
                        .staggeredReveal(index: index)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Retrospective Summary (Week/Month)

    private var retrospectiveSummary: some View {
        VStack(spacing: 16) {
            // Daily averages - Hero numbers
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(dailyAverages.cal)")
                        .font(.metricMedium)
                        .foregroundStyle(Theme.calories)
                    Text("AVG CAL/DAY")
                        .font(.labelMicro)
                        .tracking(1.5)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("\(dailyAverages.protein)g")
                        .font(.metricMedium)
                        .foregroundStyle(Theme.protein)
                    Text("AVG PROTEIN")
                        .font(.labelMicro)
                        .tracking(1.5)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("\(daysWithEntries)/\(viewMode == .week ? 7 : daysInPeriod)")
                        .font(.metricMedium)
                        .foregroundStyle(Theme.accent)
                    Text("DAYS TRACKED")
                        .font(.labelMicro)
                        .tracking(1.5)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
            }

            // Compliance stats
            if daysWithEntries > 0 {
                HStack(spacing: 12) {
                    PremiumCompliancePill(
                        label: "Protein target",
                        hit: proteinCompliance.hit,
                        total: proteinCompliance.total,
                        color: Theme.protein
                    )

                    PremiumCompliancePill(
                        label: "Calorie range",
                        hit: calorieCompliance.hit,
                        total: calorieCompliance.total,
                        color: Theme.calories
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Day Toggle

    private var dayToggle: some View {
        HStack(spacing: 12) {
            Picker("Day Type", selection: $isTrainingDay) {
                Text("Training").tag(true)
                Text("Rest").tag(false)
            }
            .pickerStyle(.segmented)

            if let workout = workoutName {
                Text(workout)
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Live Balance Card

    private var liveBalanceCard: some View {
        HStack(spacing: 0) {
            // Calories In
            VStack(spacing: 4) {
                Text("\(totals.cal)")
                    .font(.metricSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text("IN")
                    .font(.labelMicro)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity)

            // Net indicator
            VStack(spacing: 6) {
                Text(netCalories >= 0 ? "+\(netCalories)" : "\(netCalories)")
                    .font(.metricLarge)
                    .foregroundStyle(netStatusColor)
                    .contentTransition(.numericText(value: Double(netCalories)))

                Text(netStatusLabel.uppercased())
                    .font(.labelHero)
                    .tracking(2)
                    .foregroundStyle(netStatusColor.opacity(0.8))

                if let updated = energyTracker.lastUpdated {
                    Text("Updated \(updated, style: .relative)")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)

            // Calories Out (TDEE)
            VStack(spacing: 4) {
                Text("\(energyTracker.todayTDEE)")
                    .font(.metricSmall)
                    .foregroundStyle(Theme.textPrimary)
                Text("OUT")
                    .font(.labelMicro)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var netStatusColor: Color {
        if netCalories < -200 { return Theme.success }
        if netCalories > 200 { return Theme.error }
        return Theme.warning
    }

    private var netStatusLabel: String {
        if netCalories < -200 { return "Deficit" }
        if netCalories > 200 { return "Surplus" }
        return "Balanced"
    }

    // MARK: - Premium Macro Gauges

    private var premiumMacroGauges: some View {
        VStack(spacing: 16) {
            HeroProgressBar(
                label: "Calories",
                current: totals.cal,
                target: targets.cal,
                color: Theme.calories
            )
            HeroProgressBar(
                label: "Protein",
                current: totals.protein,
                target: targets.protein,
                unit: "g",
                color: Theme.protein
            )
            HeroProgressBar(
                label: "Carbs",
                current: totals.carbs,
                target: targets.carbs,
                unit: "g",
                color: Theme.carbs
            )
            HeroProgressBar(
                label: "Fat",
                current: totals.fat,
                target: targets.fat,
                unit: "g",
                color: Theme.fat
            )
        }
    }

    // MARK: - Day Entries Content (for unified ScrollView)

    private var dayEntriesContent: some View {
        let dayEntries = filteredEntries.sorted { $0.timestamp > $1.timestamp }

        return LazyVStack(spacing: 12) {
            if dayEntries.isEmpty {
                emptyStateView
            } else {
                ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, entry in
                    PremiumNutritionEntryRow(
                        entry: entry,
                        isExpanded: expandedEntryId == entry.id,
                        onTap: {
                            withAnimation(.airfit) {
                                if expandedEntryId == entry.id {
                                    expandedEntryId = nil
                                } else {
                                    expandedEntryId = entry.id
                                }
                            }
                        },
                        onEdit: {
                            editingEntry = entry
                        },
                        onDelete: {
                            withAnimation(.airfit) {
                                modelContext.delete(entry)
                            }
                        }
                    )
                    .staggeredReveal(index: index)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(Theme.textMuted)

            Text(isToday ? "No meals logged today" : "No meals logged")
                .font(.headlineMedium)
                .foregroundStyle(Theme.textSecondary)

            if isToday {
                Text("Log your first meal below")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Premium Input Area

    private var premiumInputArea: some View {
        HStack(spacing: 12) {
            TextField("Log food...", text: $inputText, axis: .vertical)
                .font(.bodyMedium)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .lineLimit(1...3)
                .focused($isInputFocused)

            if isLoading {
                PremiumPulsingLoader()
                    .frame(width: 36, height: 36)
            } else {
                Button {
                    Task { await logFood() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            inputText.isEmpty
                                ? LinearGradient(colors: [Theme.textMuted], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Theme.success, Theme.tertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .symbolEffect(.bounce, value: !inputText.isEmpty)
                }
                .buttonStyle(AirFitButtonStyle())
                .disabled(inputText.isEmpty)
                .sensoryFeedback(.impact(weight: .medium), trigger: inputText.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    // MARK: - Actions

    private func checkTrainingDay() async {
        let result = await apiClient.checkTrainingDay()
        isTrainingDay = result.isTraining
        workoutName = result.workoutName
    }

    private func logFood() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Dismiss keyboard
        isInputFocused = false

        isLoading = true
        inputText = ""

        do {
            let result = try await apiClient.parseNutrition(text)

            if result.success {
                let components = (result.components ?? []).map { c in
                    NutritionComponent(
                        name: c.name,
                        calories: c.calories,
                        protein: c.protein,
                        carbs: c.carbs,
                        fat: c.fat
                    )
                }

                let entry = NutritionEntry(
                    name: result.name ?? text,
                    calories: result.calories ?? 0,
                    protein: result.protein ?? 0,
                    carbs: result.carbs ?? 0,
                    fat: result.fat ?? 0,
                    confidence: result.confidence ?? "low",
                    components: components
                )
                withAnimation(.airfit) {
                    modelContext.insert(entry)
                }
            }
        } catch {
            print("Failed to parse nutrition: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Premium Pulsing Loader

struct PremiumPulsingLoader: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.success.opacity(0.3))
                .scaleEffect(isPulsing ? 1.2 : 0.8)

            Circle()
                .fill(Theme.success)
                .scaleEffect(isPulsing ? 0.6 : 0.4)
        }
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear { isPulsing = true }
    }
}

// MARK: - Premium Daily Summary Row (for Week/Month views)

struct PremiumDailySummaryRow: View {
    let summary: DailySummary
    let targets: (cal: Int, protein: Int, carbs: Int, fat: Int)

    private var calorieProgress: Double {
        guard targets.cal > 0 else { return 0 }
        return Double(summary.calories) / Double(targets.cal)
    }

    private var proteinProgress: Double {
        guard targets.protein > 0 else { return 0 }
        return Double(summary.protein) / Double(targets.protein)
    }

    // Compliance checks
    private var hitProtein: Bool {
        summary.protein >= Int(Double(targets.protein) * 0.9)
    }

    private var caloriesInRange: Bool {
        let low = Int(Double(targets.cal) * 0.9)
        let high = Int(Double(targets.cal) * 1.1)
        return summary.calories >= low && summary.calories <= high
    }

    private var overallStatus: DayStatus {
        if hitProtein && caloriesInRange { return .good }
        if hitProtein || caloriesInRange { return .partial }
        return .missed
    }

    enum DayStatus {
        case good, partial, missed

        var color: Color {
            switch self {
            case .good: return Theme.success
            case .partial: return Theme.warning
            case .missed: return Theme.error
            }
        }

        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .partial: return "minus.circle.fill"
            case .missed: return "xmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Image(systemName: overallStatus.icon)
                .font(.title2)
                .foregroundStyle(overallStatus.color)

            VStack(alignment: .leading, spacing: 8) {
                // Date header
                HStack {
                    Text(summary.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.labelLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Text("\(summary.entryCount) meal\(summary.entryCount == 1 ? "" : "s")")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }

                // Macro summary
                HStack(spacing: 12) {
                    Text("\(summary.calories)")
                        .font(.metricSmall)
                        .foregroundStyle(caloriesInRange ? Theme.textPrimary : (calorieProgress > 1.1 ? Theme.error : Theme.warning))

                    PremiumMacroPill(value: summary.protein, label: "P", color: hitProtein ? Theme.protein : Theme.textMuted)
                    PremiumMacroPill(value: summary.carbs, label: "C", color: Theme.carbs)
                    PremiumMacroPill(value: summary.fat, label: "F", color: Theme.fat)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Premium Entry Row

struct PremiumNutritionEntryRow: View {
    let entry: NutritionEntry
    let isExpanded: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(entry.name)
                        .font(.labelLarge)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(entry.calories)")
                        .font(.metricSmall)
                        .foregroundStyle(Theme.calories)
                    if !entry.components.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                HStack(spacing: 10) {
                    PremiumMacroPill(value: entry.protein, label: "P", color: Theme.protein)
                    PremiumMacroPill(value: entry.carbs, label: "C", color: Theme.carbs)
                    PremiumMacroPill(value: entry.fat, label: "F", color: Theme.fat)

                    Spacer()

                    Text(entry.timestamp, style: .time)
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            // Expanded components
            if isExpanded && !entry.components.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.components) { component in
                        HStack {
                            Text(component.name)
                                .font(.labelMedium)
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text("\(component.calories)")
                                .font(.labelMedium)
                                .monospacedDigit()
                            HStack(spacing: 4) {
                                Text("P\(component.protein)")
                                    .foregroundStyle(Theme.protein)
                                Text("C\(component.carbs)")
                                    .foregroundStyle(Theme.carbs)
                                Text("F\(component.fat)")
                                    .foregroundStyle(Theme.fat)
                            }
                            .font(.labelMicro)
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.labelMedium)
                                .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(AirFitSubtleButtonStyle())

                        Button {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.labelMedium)
                                .foregroundStyle(Theme.error)
                        }
                        .buttonStyle(AirFitSubtleButtonStyle())

                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(.top, 8)
                .padding(.leading, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Premium Macro Pill

struct PremiumMacroPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.labelMicro)
                .foregroundStyle(color)
            Text("\(value)g")
                .font(.labelMicro)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Premium Compliance Pill (for retrospective summary)

struct PremiumCompliancePill: View {
    let label: String
    let hit: Int
    let total: Int
    let color: Color

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(hit) / Double(total) * 100)
    }

    private var statusColor: Color {
        if percentage >= 80 { return Theme.success }
        if percentage >= 50 { return Theme.warning }
        return Theme.error
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("\(hit)/\(total)")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label.uppercased())
                .font(.labelMicro)
                .tracking(1)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Edit Sheet

struct EditNutritionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: NutritionEntry

    @State private var correctionText: String = ""
    @State private var isLoading = false
    @State private var showManualEdit = false

    // Manual edit fields
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    private let apiClient = APIClient()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !showManualEdit {
                    aiCorrectionView
                } else {
                    manualEditView
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .onAppear {
                name = entry.name
                calories = String(entry.calories)
                protein = String(entry.protein)
                carbs = String(entry.carbs)
                fat = String(entry.fat)
            }
        }
    }

    // MARK: - AI Correction View

    private var aiCorrectionView: some View {
        VStack(spacing: 20) {
            // Current entry summary
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.name)
                    .font(.headlineMedium)
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 16) {
                    Text("\(entry.calories)")
                        .font(.metricSmall)
                        .foregroundStyle(Theme.calories)
                    PremiumMacroPill(value: entry.protein, label: "P", color: Theme.protein)
                    PremiumMacroPill(value: entry.carbs, label: "C", color: Theme.carbs)
                    PremiumMacroPill(value: entry.fat, label: "F", color: Theme.fat)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 20)

            // Correction input
            VStack(alignment: .leading, spacing: 8) {
                Text("WHAT NEEDS TO CHANGE?")
                    .font(.labelMicro)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMuted)

                TextField("e.g., \"that was a large portion\" or \"add cheese\"",
                          text: $correctionText,
                          axis: .vertical)
                    .font(.bodyMedium)
                    .textFieldStyle(.plain)
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .lineLimit(2...4)
            }
            .padding(.horizontal, 20)

            // Apply button
            Button {
                Task { await applyCorrection() }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Apply Correction")
                        .font(.headlineMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(correctionText.isEmpty ? Theme.textMuted : Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(correctionText.isEmpty || isLoading)
            .padding(.horizontal, 20)

            Spacer()

            // Manual edit option
            Button {
                showManualEdit = true
            } label: {
                Text("Enter exact values instead")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(AirFitSubtleButtonStyle())
            .padding(.bottom, 20)
        }
        .padding(.top, 20)
    }

    // MARK: - Manual Edit View

    private var manualEditView: some View {
        Form {
            Section("Name") {
                TextField("Food name", text: $name)
                    .font(.bodyMedium)
            }

            Section("Macros") {
                HStack {
                    Text("Calories")
                        .font(.bodyMedium)
                    Spacer()
                    TextField("0", text: $calories)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .font(.bodyMedium)
                }

                HStack {
                    Text("Protein (g)")
                        .font(.bodyMedium)
                    Spacer()
                    TextField("0", text: $protein)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .font(.bodyMedium)
                }

                HStack {
                    Text("Carbs (g)")
                        .font(.bodyMedium)
                    Spacer()
                    TextField("0", text: $carbs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .font(.bodyMedium)
                }

                HStack {
                    Text("Fat (g)")
                        .font(.bodyMedium)
                    Spacer()
                    TextField("0", text: $fat)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .font(.bodyMedium)
                }
            }

            Section {
                Button {
                    saveManualChanges()
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.headlineMedium)
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                }

                Button {
                    showManualEdit = false
                } label: {
                    Text("Back to AI correction")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Actions

    private func applyCorrection() async {
        let text = correctionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isLoading = true

        do {
            let result = try await apiClient.correctNutrition(
                originalName: entry.name,
                originalCalories: entry.calories,
                originalProtein: entry.protein,
                originalCarbs: entry.carbs,
                originalFat: entry.fat,
                correction: text
            )

            if result.success {
                entry.name = result.name ?? entry.name
                entry.calories = result.calories ?? entry.calories
                entry.protein = result.protein ?? entry.protein
                entry.carbs = result.carbs ?? entry.carbs
                entry.fat = result.fat ?? entry.fat
                entry.confidence = "corrected"
                dismiss()
            }
        } catch {
            print("Correction failed: \(error)")
        }

        isLoading = false
    }

    private func saveManualChanges() {
        entry.name = name
        entry.calories = Int(calories) ?? entry.calories
        entry.protein = Int(protein) ?? entry.protein
        entry.carbs = Int(carbs) ?? entry.carbs
        entry.fat = Int(fat) ?? entry.fat
        entry.confidence = "manual"
    }
}

#Preview {
    NavigationStack {
        NutritionView()
            .modelContainer(for: NutritionEntry.self, inMemory: true)
    }
}
