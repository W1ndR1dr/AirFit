import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation

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

    // Provider selection (persisted)
    @AppStorage("aiProvider") private var aiProvider = "claude"
    @AppStorage("waterTrackingEnabled") private var waterTrackingEnabled = false

    // Photo food logging
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isAnalyzingPhoto = false
    @State private var showPhotoFeatureGate = false

    // Camera capture
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var showCameraPermissionAlert = false

    // Workout auto-switch
    @State private var workoutSwitchBanner = false

    // Voice input
    @State private var isVoiceInputActive = false
    @State private var showVoiceOverlay = false
    @State private var showModelRequired = false
    @State private var speechManager = WhisperTranscriptionService.shared

    private let apiClient = APIClient()
    private let geminiService = GeminiService()

    /// Whether Gemini is available for photo features
    private var canUseGeminiForPhotos: Bool {
        aiProvider == "both" || aiProvider == "gemini"
    }

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

    // Net calories (consumed - projected burn) - uses predictive model
    private var projectedNetCalories: Int {
        totals.cal - energyTracker.projectedEndOfDayTDEE
    }

    // Confidence level for the projection (0-100%)
    private var projectionConfidence: Int {
        Int(energyTracker.projectedConfidence * 100)
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

    @StateObject private var keyboard = KeyboardObserver()

    var body: some View {
        VStack(spacing: 0) {
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

                    // Water tracking card (only shown in day view for today when enabled)
                    if waterTrackingEnabled && viewMode == .day && isToday {
                        WaterTrackingCard()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }

                    // Content based on view mode
                    if viewMode == .day {
                        dayEntriesContent
                    } else {
                        summaryListContent
                    }
                }
                .padding(.bottom, viewMode == .day ? 20 : 100) // Reduced when input visible
            }
            .coordinateSpace(name: "scroll")
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(Color.clear)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                scrollOffset = offset
            }
            .onTapGesture {
                isInputFocused = false
            }

            // Input area at bottom (moves up with keyboard) - works for any day in day view
            if viewMode == .day {
                premiumInputArea
                    .padding(.bottom, keyboard.keyboardHeight > 0 ? keyboard.keyboardHeight - 50 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: keyboard.keyboardHeight)
            }
        }
        .background(Color.clear)
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
            await observeWorkoutNotifications()
        }
        .sheet(item: $editingEntry) { entry in
            EditNutritionSheet(entry: entry)
        }
        .sheet(isPresented: $showPhotoFeatureGate) {
            NutritionPhotoFeatureGateSheet(
                onEnablePhotos: {
                    aiProvider = "both"
                    showPhotoFeatureGate = false
                },
                onDismiss: {
                    showPhotoFeatureGate = false
                }
            )
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhoto) { _, newItem in
            Task { await processSelectedPhoto(newItem) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { _, newImage in
            if let image = newImage {
                Task { await processCapturedPhoto(image) }
                capturedImage = nil
            }
        }
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to use food photo analysis.")
        }
        .fullScreenCover(isPresented: $showVoiceOverlay) {
            VoiceInputOverlay(
                speechManager: speechManager,
                onComplete: { transcript in
                    inputText = transcript
                    showVoiceOverlay = false
                    isVoiceInputActive = false
                    Task { await logFood() }
                },
                onCancel: {
                    showVoiceOverlay = false
                    isVoiceInputActive = false
                }
            )
            .background(ClearBackgroundView())
        }
        .sheet(isPresented: $showModelRequired) {
            ModelRequiredSheet {
                startVoiceInput()
            }
        }
    }

    // MARK: - Scrollytelling Macro Hero
    // Transforms from big hero numbers to compact bar as you scroll

    @ViewBuilder
    private var scrollytellingMacroHero: some View {
        VStack(spacing: 0) {
            // Calorie ring gauge that scales on scroll
            CalorieRingGauge(current: totals.cal, target: targets.cal)
                .scaleEffect(1.0 - heroProgress * 0.3)
                .opacity(1.0 - heroProgress * 0.3)

            // Macro bars that fade in as ring shrinks
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
        VStack(spacing: 12) {
            // Main stats row
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

                // Projected net indicator
                VStack(spacing: 6) {
                    Text(projectedNetCalories >= 0 ? "+\(projectedNetCalories)" : "\(projectedNetCalories)")
                        .font(.metricMedium)
                        .foregroundStyle(netStatusColor)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .contentTransition(.numericText(value: Double(projectedNetCalories)))

                    Text("EST. \(netStatusLabel.uppercased())")
                        .font(.labelHero)
                        .tracking(2)
                        .foregroundStyle(netStatusColor.opacity(0.8))
                }
                .frame(maxWidth: .infinity)

                // Projected Calories Out
                VStack(spacing: 4) {
                    Text("\(energyTracker.projectedEndOfDayTDEE)")
                        .font(.metricSmall)
                        .foregroundStyle(Theme.textPrimary)
                    Text("PROJ. OUT")
                        .font(.labelMicro)
                        .tracking(1.5)
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
            }

            // Confidence bar and current burn
            HStack(spacing: 12) {
                // Current actual burn
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 6, height: 6)
                    Text("Now: \(energyTracker.todayTDEE) cal burned")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Confidence indicator
                HStack(spacing: 4) {
                    // Mini confidence bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.textMuted.opacity(0.2))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(confidenceColor)
                                .frame(width: geo.size.width * energyTracker.projectedConfidence)
                        }
                    }
                    .frame(width: 40, height: 4)

                    Text("\(projectionConfidence)% conf")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            // Last updated
            if let updated = energyTracker.lastUpdated {
                Text("Updated \(updated, style: .relative)")
                    .font(.labelMicro)
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onChange(of: totals.cal) { _, newValue in
            // Update projection when calories consumed changes
            energyTracker.updateProjection(caloriesConsumed: newValue)
        }
    }

    private var confidenceColor: Color {
        if projectionConfidence >= 70 { return Theme.success }
        if projectionConfidence >= 40 { return Theme.warning }
        return Theme.error
    }

    private var netStatusColor: Color {
        if projectedNetCalories < -200 { return Theme.success }
        if projectedNetCalories > 200 { return Theme.error }
        return Theme.warning
    }

    private var netStatusLabel: String {
        if projectedNetCalories < -200 { return "Deficit" }
        if projectedNetCalories > 200 { return "Surplus" }
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

    /// Whether the input has text that can be submitted
    private var canSubmitFood: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading && !isAnalyzingPhoto
    }

    private var premiumInputArea: some View {
        VStack(spacing: 0) {
            // Show date indicator when logging for a past day
            if !isToday {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                    Text("Logging for \(selectedDate, format: .dateTime.month(.abbreviated).day())")
                        .font(.labelMedium)
                }
                .foregroundStyle(Theme.warning)
                .padding(.vertical, 8)
            }

            HStack(spacing: 12) {
                // Camera button for photo food logging
                Button {
                    handleCameraButtonTap()
                } label: {
                    Image(systemName: "camera")
                        .font(.system(size: 18))
                        .foregroundStyle(canUseGeminiForPhotos ? Theme.textSecondary : Theme.textMuted)
                        .frame(width: 36, height: 36)
                        .background(Theme.surface)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Theme.textMuted.opacity(0.2), lineWidth: 1)
                        )
                }
                .disabled(isLoading || isAnalyzingPhoto)

                // Text field with voice input
                HStack(spacing: 8) {
                    TextField(isToday ? "Log food..." : "Log food for \(selectedDate, format: .dateTime.weekday(.abbreviated))...", text: $inputText, axis: .vertical)
                        .font(.bodyMedium)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)
                        .focused($isInputFocused)

                    // Voice input button
                    VoiceInputButton(isRecording: isVoiceInputActive) {
                        startVoiceInput()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Theme.textMuted.opacity(0.2), lineWidth: 1)
                )

                // Show loader when processing, submit button only when there's text
                if isLoading || isAnalyzingPhoto {
                    PremiumPulsingLoader()
                        .frame(width: 36, height: 36)
                } else if canSubmitFood {
                    Button {
                        Task { await logFood() }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(colors: [Theme.success, Theme.tertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                    .buttonStyle(AirFitButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                    .sensoryFeedback(.impact(weight: .medium), trigger: canSubmitFood)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, keyboard.keyboardHeight > 0 ? 12 : 70) // Less padding when keyboard is up
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSubmitFood)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Photo Handling

    /// Handle camera button tap - open camera directly for food photo analysis
    private func handleCameraButtonTap() {
        guard canUseGeminiForPhotos else {
            showPhotoFeatureGate = true
            return
        }

        // Check camera availability
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            // Fallback to photo library if no camera
            showingPhotoPicker = true
            return
        }

        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if granted {
                        showCamera = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showingPhotoPicker = true
        }
    }

    /// Process captured camera image for AI analysis
    private func processCapturedPhoto(_ image: UIImage) async {
        isAnalyzingPhoto = true

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Prepare image (resize and compress)
        guard let preparedData = await geminiService.prepareImage(image) else {
            isAnalyzingPhoto = false
            return
        }

        // Analyze with Gemini
        do {
            let analysis = try await geminiService.analyzeImage(
                imageData: preparedData,
                prompt: Self.foodAnalysisPrompt,
                systemPrompt: Self.foodAnalysisSystemPrompt
            )

            // Try to parse nutrition from the analysis
            if let parsed = try? await geminiService.parseNutrition(analysis) {
                let entry = NutritionEntry(
                    name: parsed.name,
                    calories: parsed.calories,
                    protein: parsed.protein,
                    carbs: parsed.carbs,
                    fat: parsed.fat,
                    timestamp: isToday ? Date() : Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                )

                await MainActor.run {
                    modelContext.insert(entry)
                    try? modelContext.save()
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)

                // Push updated macros to Watch
                await WatchConnectivityHandler.shared.pushMacrosToWatch(context: modelContext)
            }
        } catch {
            // Silent fail - photo analysis is best-effort
        }

        isAnalyzingPhoto = false
    }

    // MARK: - Voice Input

    /// Start voice input for speech-to-text food logging
    private func startVoiceInput() {
        Task {
            // Check if WhisperKit models are installed
            await ModelManager.shared.load()
            let hasModels = await ModelManager.shared.hasRequiredModels()

            guard hasModels else {
                showModelRequired = true
                return
            }

            do {
                isVoiceInputActive = true
                try await speechManager.startListening()
                showVoiceOverlay = true
            } catch WhisperTranscriptionService.TranscriptionError.modelsNotInstalled {
                isVoiceInputActive = false
                showModelRequired = true
            } catch {
                isVoiceInputActive = false
                print("Failed to start voice input: \(error)")
                if String(describing: error).lowercased().contains("model") {
                    showModelRequired = true
                }
            }
        }
    }

    /// Process a selected photo for food analysis
    private func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        selectedPhoto = nil
        isAnalyzingPhoto = true

        // Load the image data
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            isAnalyzingPhoto = false
            return
        }

        // Prepare image (resize and compress)
        guard let preparedData = await geminiService.prepareImage(image) else {
            isAnalyzingPhoto = false
            return
        }

        // Analyze with Gemini
        do {
            let analysis = try await geminiService.analyzeImage(
                imageData: preparedData,
                prompt: Self.foodAnalysisPrompt,
                systemPrompt: Self.foodAnalysisSystemPrompt
            )

            // Try to parse nutrition from the analysis
            if let parsed = try? await geminiService.parseNutrition(analysis) {
                // Create entry from photo analysis
                let entry = NutritionEntry(
                    name: parsed.name,
                    calories: parsed.calories,
                    protein: parsed.protein,
                    carbs: parsed.carbs,
                    fat: parsed.fat,
                    timestamp: isToday ? Date() : Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                )

                await MainActor.run {
                    modelContext.insert(entry)
                    try? modelContext.save()

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }

                // Sync to HealthKit
                let healthKit = HealthKitManager()
                try? await healthKit.saveNutritionEntry(entry)

                // Push updated macros to Watch
                await WatchConnectivityHandler.shared.pushMacrosToWatch(context: modelContext)
            }
        } catch {
            print("[NutritionView] Photo analysis failed: \(error)")
        }

        isAnalyzingPhoto = false
    }

    /// System prompt for food photo analysis
    private static let foodAnalysisSystemPrompt = """
    You are a nutrition analyst for a fitness coaching app. Analyze food photos accurately.
    Be precise with portion estimates. If uncertain, provide a reasonable middle estimate.
    Format your response as a food log entry that can be parsed for macros.
    """

    /// Prompt for analyzing food photos
    private static let foodAnalysisPrompt = """
    Analyze this food photo and estimate the nutrition.

    Respond with ONLY a single line in this format:
    [Food name], [calories] cal, [protein]g protein, [carbs]g carbs, [fat]g fat

    Example: "Grilled chicken salad with ranch, 450 cal, 35g protein, 15g carbs, 28g fat"

    Be specific about portions based on visual cues (plate size, utensils for scale).
    """

    // MARK: - Actions

    private func checkTrainingDay() async {
        let result = await apiClient.checkTrainingDay()
        isTrainingDay = result.isTraining
        workoutName = result.workoutName
    }

    /// Observe workout notifications to auto-switch training day
    private func observeWorkoutNotifications() async {
        // Observe Hevy cache updates (primary source for workout detection)
        for await _ in NotificationCenter.default.notifications(named: .hevyCacheUpdated) {
            await handleWorkoutDetected()
        }
    }

    /// Handle workout detection - auto-switch to training day if meaningful workout logged
    private func handleWorkoutDetected() async {
        let result = await apiClient.checkTrainingDay()

        // Only auto-switch if server detected a meaningful workout and we're not already on training day
        if result.isTraining && !isTrainingDay {
            withAnimation(.airfit) {
                isTrainingDay = true
                workoutName = result.workoutName
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if result.isTraining {
            // Update workout name even if already on training day
            workoutName = result.workoutName
        }
    }

    private func logFood() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Dismiss keyboard
        isInputFocused = false

        isLoading = true
        inputText = ""

        // Route by provider: Gemini parses directly, Claude uses server
        if aiProvider == "gemini" {
            await logFoodViaGemini(text)
        } else {
            await logFoodViaClaude(text)
        }

        isLoading = false
    }

    /// Parse nutrition via Gemini API (direct, no server needed)
    private func logFoodViaGemini(_ text: String) async {
        do {
            let result = try await geminiService.parseNutrition(text)

            // Use selected date for past days, current time for today
            let entryTimestamp: Date
            if isToday {
                entryTimestamp = Date()
            } else {
                entryTimestamp = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            }

            let entry = NutritionEntry(
                name: result.name,
                calories: result.calories,
                protein: result.protein,
                carbs: result.carbs,
                fat: result.fat,
                confidence: result.confidence,
                timestamp: entryTimestamp,
                components: []  // Gemini parsing doesn't return components yet
            )
            withAnimation(.airfit) {
                modelContext.insert(entry)
            }

            // Push updated macros to Watch
            await WatchConnectivityHandler.shared.pushMacrosToWatch(context: modelContext)
        } catch {
            print("[NutritionView] Gemini parsing failed: \(error)")
        }
    }

    /// Parse nutrition via Claude server (existing path)
    private func logFoodViaClaude(_ text: String) async {
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

                // Use selected date for past days, current time for today
                let entryTimestamp: Date
                if isToday {
                    entryTimestamp = Date()
                } else {
                    // For past days, set to noon of that day
                    entryTimestamp = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                }

                let entry = NutritionEntry(
                    name: result.name ?? text,
                    calories: result.calories ?? 0,
                    protein: result.protein ?? 0,
                    carbs: result.carbs ?? 0,
                    fat: result.fat ?? 0,
                    confidence: result.confidence ?? "low",
                    timestamp: entryTimestamp,
                    components: components
                )
                withAnimation(.airfit) {
                    modelContext.insert(entry)
                }

                // Push updated macros to Watch
                await WatchConnectivityHandler.shared.pushMacrosToWatch(context: modelContext)
            }
        } catch {
            print("[NutritionView] Claude parsing failed: \(error)")
        }
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
                    // Always show caret so users can access edit/delete
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
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

            // Expanded section - always show actions, optionally show components
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    // Show components if available
                    if !entry.components.isEmpty {
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
                    }

                    // Action buttons - always show when expanded
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
                    .padding(.top, entry.components.isEmpty ? 0 : 8)
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

    // Provider selection (persisted)
    @AppStorage("aiProvider") private var aiProvider = "claude"

    @State private var correctionText: String = ""
    @State private var isLoading = false
    @State private var showManualEdit = false

    // Voice input state
    @State private var isVoiceInputActive = false
    @State private var showVoiceOverlay = false
    @State private var showModelRequired = false
    @State private var speechManager = WhisperTranscriptionService.shared

    // Manual edit fields
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    @State private var timestamp: Date = Date()
    @State private var originalTimestamp: Date = Date()  // Track if date changed

    private let apiClient = APIClient()
    private let geminiService = GeminiService()

    // Check if any changes were made
    private var hasChanges: Bool {
        let hasTextCorrection = !correctionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDateChange = timestamp != originalTimestamp
        return hasTextCorrection || hasDateChange
    }

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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
            }
            .onAppear {
                name = entry.name
                calories = String(entry.calories)
                protein = String(entry.protein)
                carbs = String(entry.carbs)
                fat = String(entry.fat)
                timestamp = entry.timestamp
                originalTimestamp = entry.timestamp
            }
            .overlay {
                if showVoiceOverlay {
                    VoiceInputOverlay(speechManager: speechManager) { transcript in
                        correctionText = transcript
                        isVoiceInputActive = false
                        showVoiceOverlay = false
                    } onCancel: {
                        isVoiceInputActive = false
                        showVoiceOverlay = false
                    }
                    .background(ClearBackgroundView())
                }
            }
            .sheet(isPresented: $showModelRequired) {
                ModelRequiredSheet {
                    startVoiceInput()
                }
            }
        }
    }

    // MARK: - Voice Input

    private func startVoiceInput() {
        Task {
            // Check if WhisperKit models are installed
            await ModelManager.shared.load()
            let hasModels = await ModelManager.shared.hasRequiredModels()

            guard hasModels else {
                showModelRequired = true
                return
            }

            do {
                isVoiceInputActive = true
                try await speechManager.startListening()
                showVoiceOverlay = true
            } catch WhisperTranscriptionService.TranscriptionError.modelsNotInstalled {
                isVoiceInputActive = false
                showModelRequired = true
            } catch {
                isVoiceInputActive = false
                print("Failed to start voice input: \(error)")
                if String(describing: error).lowercased().contains("model") {
                    showModelRequired = true
                }
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

                // Quick date picker - always visible
                Divider()
                    .padding(.vertical, 4)

                DatePicker(
                    "Logged",
                    selection: $timestamp,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.labelMedium)
                .datePickerStyle(.compact)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 20)

            // Correction input (optional - for AI-based macro adjustments)
            VStack(alignment: .leading, spacing: 8) {
                Text("FIX THE MACROS (OPTIONAL)")
                    .font(.labelMicro)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textMuted)

                HStack(spacing: 8) {
                    TextField("e.g., \"that was a large portion\" or \"add cheese\"",
                              text: $correctionText,
                              axis: .vertical)
                        .font(.bodyMedium)
                        .textFieldStyle(.plain)
                        .lineLimit(2...4)

                    VoiceInputButton(isRecording: isVoiceInputActive) {
                        startVoiceInput()
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 20)

            // Apply button - enabled when ANY change was made (date or text)
            Button {
                Task { await applyChanges() }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Apply")
                        .font(.headlineMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(hasChanges ? Theme.accent : Theme.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(!hasChanges || isLoading)
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

            Section("Date & Time") {
                DatePicker(
                    "When",
                    selection: $timestamp,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
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

    private func applyChanges() async {
        isLoading = true

        // Always apply date change if it changed
        if timestamp != originalTimestamp {
            entry.timestamp = timestamp
        }

        // Apply text correction if provided
        let text = correctionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            // Route by provider
            if aiProvider == "gemini" {
                await applyCorrectionViaGemini(text)
            } else {
                await applyCorrectionViaClaude(text)
            }
        } else {
            // No text correction, just dismiss (date already saved)
            dismiss()
        }

        isLoading = false
    }

    /// Apply correction via Gemini (re-parse with context)
    private func applyCorrectionViaGemini(_ correction: String) async {
        do {
            // Build a contextual prompt that includes the correction
            let contextualDescription = "\(entry.name), but \(correction)"
            let result = try await geminiService.parseNutrition(contextualDescription)

            entry.name = result.name
            entry.calories = result.calories
            entry.protein = result.protein
            entry.carbs = result.carbs
            entry.fat = result.fat
            entry.confidence = "corrected"
            // Keep user's selected timestamp (already set in applyChanges)
            dismiss()
        } catch {
            print("[EditNutritionSheet] Gemini correction failed: \(error)")
        }
    }

    /// Apply correction via Claude server
    private func applyCorrectionViaClaude(_ correction: String) async {
        do {
            let result = try await apiClient.correctNutrition(
                originalName: entry.name,
                originalCalories: entry.calories,
                originalProtein: entry.protein,
                originalCarbs: entry.carbs,
                originalFat: entry.fat,
                correction: correction
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
            print("[EditNutritionSheet] Claude correction failed: \(error)")
        }
    }

    private func saveManualChanges() {
        entry.name = name
        entry.calories = Int(calories) ?? entry.calories
        entry.protein = Int(protein) ?? entry.protein
        entry.carbs = Int(carbs) ?? entry.carbs
        entry.fat = Int(fat) ?? entry.fat
        entry.timestamp = timestamp
        entry.confidence = "manual"
    }
}

// MARK: - Photo Feature Gate Sheet (Nutrition)

/// Shown when user taps camera in Claude-only mode.
/// Prompts to enable "Both" mode for photo features.
struct NutritionPhotoFeatureGateSheet: View {
    let onEnablePhotos: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)
                }

                // Title
                Text("Photo Food Logging")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                // Description
                Text("Snap a photo of your meal and AI will estimate the nutrition for you.\n\nThis feature uses Gemini's vision capabilities.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: onEnablePhotos) {
                        HStack {
                            Image(systemName: "camera.on.rectangle.fill")
                            Text("Enable Photo Features")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient)
                        .clipShape(Capsule())
                    }

                    Button(action: onDismiss) {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Theme.background)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        NutritionView()
            .modelContainer(for: NutritionEntry.self, inMemory: true)
    }
}
