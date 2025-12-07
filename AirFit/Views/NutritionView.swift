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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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

                // Summary section - different for retrospective vs current
                if viewMode == .day {
                    macroGauges
                        .padding()
                } else {
                    retrospectiveSummary
                        .padding()
                }

                Divider()

                // Content based on view mode
                if viewMode == .day {
                    entriesList
                } else {
                    summaryList
                }

                // Input area (only for today in day view)
                if viewMode == .day && isToday {
                    inputArea
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isToday || viewMode != .day {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                selectedDate = Date()
                                viewMode = .day
                            }
                        } label: {
                            Text("Today")
                                .font(.subheadline.bold())
                        }
                    }
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

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(NutritionViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Date Navigation

    private var dateNavigationHeader: some View {
        HStack {
            Button {
                navigateDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Button {
                // Tap label to go to today
                selectedDate = Date()
            } label: {
                Text(dateRangeLabel)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
                navigateDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .disabled(cannotGoForward)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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

    // MARK: - Summary List (Week/Month)

    private var summaryList: some View {
        List {
            if dailySummaries.isEmpty {
                Text("No meals logged")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(dailySummaries) { summary in
                    DailySummaryRow(summary: summary, targets: targets)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Drill down to that day
                            selectedDate = summary.date
                            viewMode = .day
                        }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Retrospective Summary (Week/Month)

    private var retrospectiveSummary: some View {
        VStack(spacing: 12) {
            // Daily averages
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(dailyAverages.cal)")
                        .font(.title2.bold())
                    Text("avg cal/day")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(dailyAverages.protein)g")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                    Text("avg protein")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(daysWithEntries)/\(viewMode == .week ? 7 : daysInPeriod)")
                        .font(.title2.bold())
                    Text("days tracked")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Compliance stats
            if daysWithEntries > 0 {
                HStack(spacing: 16) {
                    CompliancePill(
                        label: "Protein target",
                        hit: proteinCompliance.hit,
                        total: proteinCompliance.total,
                        color: .blue
                    )

                    CompliancePill(
                        label: "Calorie range",
                        hit: calorieCompliance.hit,
                        total: calorieCompliance.total,
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Day Toggle

    private var dayToggle: some View {
        HStack {
            Picker("Day Type", selection: $isTrainingDay) {
                Text("Training").tag(true)
                Text("Rest").tag(false)
            }
            .pickerStyle(.segmented)

            if let workout = workoutName {
                Text(workout)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Live Balance Card

    private var liveBalanceCard: some View {
        HStack(spacing: 16) {
            // Calories In
            VStack(spacing: 2) {
                Text("\(totals.cal)")
                    .font(.title3.bold())
                Text("In")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Net indicator
            VStack(spacing: 4) {
                Text(netCalories >= 0 ? "+\(netCalories)" : "\(netCalories)")
                    .font(.title2.bold())
                    .foregroundColor(netStatusColor)

                Text(netStatusLabel)
                    .font(.caption)
                    .foregroundColor(netStatusColor)

                if let updated = energyTracker.lastUpdated {
                    Text("Updated \(updated, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            // Calories Out (TDEE)
            VStack(spacing: 2) {
                Text("\(energyTracker.todayTDEE)")
                    .font(.title3.bold())
                Text("Out")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var netStatusColor: Color {
        if netCalories < -200 { return .green }
        if netCalories > 200 { return .red }
        return .yellow
    }

    private var netStatusLabel: String {
        if netCalories < -200 { return "Deficit" }
        if netCalories > 200 { return "Surplus" }
        return "Balanced"
    }

    // MARK: - Macro Gauges

    private var macroGauges: some View {
        VStack(spacing: 12) {
            MacroGauge(
                label: "Calories",
                current: totals.cal,
                target: targets.cal,
                color: .orange
            )
            MacroGauge(
                label: "Protein",
                current: totals.protein,
                target: targets.protein,
                unit: "g",
                color: .blue
            )
            MacroGauge(
                label: "Carbs",
                current: totals.carbs,
                target: targets.carbs,
                unit: "g",
                color: .red
            )
            MacroGauge(
                label: "Fat",
                current: totals.fat,
                target: targets.fat,
                unit: "g",
                color: .yellow,
                isCap: true
            )
        }
    }

    // MARK: - Entries List

    private var entriesList: some View {
        let dayEntries = filteredEntries.sorted { $0.timestamp > $1.timestamp }

        return List {
            if dayEntries.isEmpty {
                Text(isToday ? "No meals logged today" : "No meals logged")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(dayEntries) { entry in
                    NutritionEntryRow(
                        entry: entry,
                        isExpanded: expandedEntryId == entry.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedEntryId == entry.id {
                                expandedEntryId = nil
                            } else {
                                expandedEntryId = entry.id
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingEntry = entry
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: 12) {
            // TODO: Voice input disabled - threading crash needs fix
            // VoiceMicButton(text: $inputText)

            TextField("Log food...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...3)
                .focused($isInputFocused)

            if isLoading {
                PulsingLoader()
                    .frame(width: 32, height: 32)
            } else {
                Button {
                    Task { await logFood() }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(inputText.isEmpty ? .gray : .green)
                }
                .disabled(inputText.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
                modelContext.insert(entry)
            }
        } catch {
            print("Failed to parse nutrition: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Pulsing Loader

struct PulsingLoader: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(Color.green.opacity(0.6))
            .scaleEffect(isPulsing ? 1.0 : 0.6)
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - Macro Gauge Component

struct MacroGauge: View {
    let label: String
    let current: Int
    let target: Int
    var unit: String = ""
    var color: Color = .blue
    var isCap: Bool = false

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.5)
    }

    private var remaining: Int {
        target - current
    }

    private var statusText: String {
        if isCap {
            return remaining >= 0 ? "\(remaining)\(unit) left" : "\(abs(remaining))\(unit) over"
        } else {
            return remaining > 0 ? "\(remaining)\(unit) to go" : "Hit!"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(current)/\(target)\(unit)")
                    .font(.caption.bold())
                Text(statusText)
                    .font(.caption2)
                    .foregroundColor(statusColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geo.size.width * min(progress, 1.0))

                    if progress > 1.0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.opacity(0.6))
                            .frame(width: geo.size.width * (progress - 1.0))
                            .offset(x: geo.size.width)
                    }
                }
            }
            .frame(height: 8)
        }
    }

    private var progressColor: Color {
        if isCap && progress > 1.0 {
            return .red
        }
        return color
    }

    private var statusColor: Color {
        if isCap {
            return remaining >= 0 ? .green : .red
        } else {
            return remaining <= 0 ? .green : .secondary
        }
    }
}

// MARK: - Daily Summary Row (for Week/Month views)

struct DailySummaryRow: View {
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
            case .good: return .green
            case .partial: return .yellow
            case .missed: return .red
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
        HStack(spacing: 12) {
            // Status indicator
            Image(systemName: overallStatus.icon)
                .font(.title3)
                .foregroundColor(overallStatus.color)

            VStack(alignment: .leading, spacing: 6) {
                // Date header
                HStack {
                    Text(summary.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.subheadline.bold())

                    Spacer()

                    Text("\(summary.entryCount) meal\(summary.entryCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Macro summary
                HStack(spacing: 12) {
                    Text("\(summary.calories) cal")
                        .font(.subheadline)
                        .foregroundColor(caloriesInRange ? .primary : (calorieProgress > 1.1 ? .red : .orange))

                    MacroPill(value: summary.protein, label: "P", color: hitProtein ? .blue : .gray)
                    MacroPill(value: summary.carbs, label: "C", color: .red)
                    MacroPill(value: summary.fat, label: "F", color: .yellow)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Entry Row

struct NutritionEntryRow: View {
    let entry: NutritionEntry
    let isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main row
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(entry.calories) cal")
                        .font(.subheadline.bold())
                    if !entry.components.isEmpty {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    MacroPill(value: entry.protein, label: "P", color: .blue)
                    MacroPill(value: entry.carbs, label: "C", color: .red)
                    MacroPill(value: entry.fat, label: "F", color: .yellow)

                    Spacer()

                    Text(entry.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Expanded components
            if isExpanded && !entry.components.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.components) { component in
                        HStack {
                            Text(component.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(component.calories)")
                                .font(.caption.monospacedDigit())
                            Text("P\(component.protein)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("C\(component.carbs)")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text("F\(component.fat)")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MacroPill: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(value)g")
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Compliance Pill (for retrospective summary)

struct CompliancePill: View {
    let label: String
    let hit: Int
    let total: Int
    let color: Color

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int(Double(hit) / Double(total) * 100)
    }

    private var statusColor: Color {
        if percentage >= 80 { return .green }
        if percentage >= 50 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("\(hit)/\(total)")
                    .font(.subheadline.bold())
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        VStack(spacing: 16) {
            // Current entry summary
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.name)
                    .font(.headline)

                HStack(spacing: 16) {
                    Text("\(entry.calories) cal")
                        .font(.subheadline.bold())
                    Text("P\(entry.protein)g")
                        .foregroundColor(.blue)
                    Text("C\(entry.carbs)g")
                        .foregroundColor(.red)
                    Text("F\(entry.fat)g")
                        .foregroundColor(.yellow)
                }
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            // Correction input
            VStack(alignment: .leading, spacing: 8) {
                Text("What needs to change?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextField("e.g., \"that was a large portion\" or \"add cheese\"",
                          text: $correctionText,
                          axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .lineLimit(2...4)
            }
            .padding(.horizontal)

            // Apply button
            Button {
                Task { await applyCorrection() }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Apply Correction")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(correctionText.isEmpty || isLoading)
            .padding(.horizontal)

            Spacer()

            // Manual edit option
            Button {
                showManualEdit = true
            } label: {
                Text("Enter exact values instead")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom)
        }
        .padding(.top)
    }

    // MARK: - Manual Edit View

    private var manualEditView: some View {
        Form {
            Section("Name") {
                TextField("Food name", text: $name)
            }

            Section("Macros") {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("0", text: $calories)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("Protein (g)")
                    Spacer()
                    TextField("0", text: $protein)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("0", text: $carbs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Text("Fat (g)")
                    Spacer()
                    TextField("0", text: $fat)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section {
                Button("Save") {
                    saveManualChanges()
                    dismiss()
                }
                .frame(maxWidth: .infinity)

                Button("Back to AI correction") {
                    showManualEdit = false
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.secondary)
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
    NutritionView()
        .modelContainer(for: NutritionEntry.self, inMemory: true)
}
