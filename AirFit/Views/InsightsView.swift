import SwiftUI
import SwiftData
import UserNotifications

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var insights: [APIClient.InsightData] = []
    @State private var isLoading = false
    @State private var isSyncing = false
    @State private var lastSyncTime: Date?
    @State private var selectedInsight: APIClient.InsightData?
    @State private var showAllInsights = false

    // Undo support
    @State private var recentlyDismissed: APIClient.InsightData?
    @State private var showUndoToast = false
    @State private var undoWorkItem: DispatchWorkItem?

    // Action confirmation
    @State private var actionToast: ActionToastData?
    @State private var showActionToast = false

    // Provider selection
    @AppStorage("aiProvider") private var aiProvider = "claude"

    private let apiClient = APIClient()
    @State private var syncService = InsightsSyncService()
    private let localInsightEngine = LocalInsightEngine()
    private let geminiService = GeminiService()

    private var visibleInsights: [APIClient.InsightData] {
        showAllInsights ? insights : Array(insights.prefix(3))
    }

    private var hasMoreInsights: Bool {
        insights.count > 3 && !showAllInsights
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading && insights.isEmpty {
                    // Centered loading view within scroll
                    Spacer(minLength: 200)
                    ShimmerText(text: "Finding insights...")
                    Spacer(minLength: 200)
                } else if insights.isEmpty {
                    emptyStateView
                } else {
                    insightsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 160) // Extra padding to scroll above tab bar
            .frame(minHeight: UIScreen.main.bounds.height - 200)
        }
        .scrollIndicators(.visible)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollBounceBehavior(.always)
        .refreshable {
            await syncAndRefresh()
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSyncing {
                    ProgressView()
                        .tint(Theme.accent)
                } else {
                    Button {
                        Task { await syncAndRefresh() }
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
        .sheet(item: $selectedInsight) { insight in
            PremiumInsightChatSheet(insight: insight)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 12) {
                if showActionToast, let toast = actionToast {
                    ActionConfirmationToast(data: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if showUndoToast {
                    UndoToast(
                        message: "Insight dismissed",
                        onUndo: undoDismiss
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 100) // Above tab bar
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(visibleInsights.enumerated()), id: \.element.id) { index, insight in
                    PremiumInsightCard(
                        insight: insight,
                        onTellMeMore: {
                            selectedInsight = insight
                            Task { await trackEngagement(insight.id, action: "tapped") }
                        },
                        onDismiss: {
                            dismissInsight(insight)
                        },
                        onAction: { action in
                            handleAction(action, insightId: insight.id)
                        }
                    )
                    .contentShape(Rectangle())
                    .staggeredReveal(index: index)
                }

                // Show more button
                if hasMoreInsights {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAllInsights = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Show \(insights.count - 3) more")
                                .font(.labelMedium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.surface.opacity(0.5))
                        )
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
        }
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

                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
            }

            Text("No insights yet")
                .font(.titleMedium)
                .foregroundStyle(Theme.textPrimary)

            Text("As you log nutrition and workouts, the AI will find patterns and surface insights here.")
                .font(.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await syncAndRefresh() }
            } label: {
                Label("Sync Data", systemImage: "arrow.triangle.2.circlepath")
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
        await loadInsights()
        isLoading = false
    }

    private func loadInsights() async {
        // Route by provider
        if aiProvider == "gemini" {
            await loadInsightsViaGemini()
        } else {
            await loadInsightsViaServer()
        }
    }

    /// Load insights from server (Claude mode)
    private func loadInsightsViaServer() async {
        do {
            insights = try await apiClient.getInsights(limit: 10)

            // Check for high-tier insights and notify
            await NotificationManager.shared.checkAndNotifyForInsights(insights)
        } catch {
            print("[InsightsView] Failed to load insights from server: \(error)")
        }
    }

    /// Generate insights via Gemini on device
    private func loadInsightsViaGemini() async {
        do {
            insights = try await localInsightEngine.generateInsights(days: 7, modelContext: modelContext)

            // Check for high-tier insights and notify
            await NotificationManager.shared.checkAndNotifyForInsights(insights)
        } catch {
            print("[InsightsView] Failed to generate insights via Gemini: \(error)")
        }
    }

    private func syncAndRefresh() async {
        isSyncing = true

        // Sync data to server (if available) - useful for Hevy cache refresh in both modes
        do {
            try await syncService.syncRecentDays(7, modelContext: modelContext)
            lastSyncTime = Date()
        } catch {
            print("[InsightsView] Sync failed: \(error)")
        }

        // Route insight generation by provider
        if aiProvider == "gemini" {
            // Gemini mode: Just reload (generates fresh on device)
            await loadData()
        } else {
            // Claude mode: Trigger server-side insight generation first
            do {
                let result = try await apiClient.generateInsights(days: 90, force: false)
                if result.success {
                    print("[InsightsView] Generated \(result.insights_generated) insights (~\(result.token_estimate) tokens)")
                }
            } catch {
                print("[InsightsView] Server insight generation failed: \(error)")
            }

            // Then reload from server
            await loadData()
        }

        isSyncing = false
    }

    private func trackEngagement(_ id: String, action: String) async {
        do {
            try await apiClient.engageInsight(id: id, action: action)
        } catch {
            print("Failed to track engagement: \(error)")
        }
    }

    private func dismissInsight(_ insight: APIClient.InsightData) {
        // Cancel any pending undo expiration
        undoWorkItem?.cancel()

        // Store for potential undo
        recentlyDismissed = insight

        // Remove from list
        withAnimation(.airfit) {
            insights.removeAll { $0.id == insight.id }
            showUndoToast = true
        }

        // Auto-finalize after 4 seconds
        let workItem = DispatchWorkItem { [insight] in
            finalizeDismiss(insight)
        }
        undoWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
    }

    private func undoDismiss() {
        guard let insight = recentlyDismissed else { return }

        // Cancel finalization
        undoWorkItem?.cancel()

        // Restore insight
        withAnimation(.airfit) {
            insights.insert(insight, at: 0)
            showUndoToast = false
            recentlyDismissed = nil
        }
    }

    private func finalizeDismiss(_ insight: APIClient.InsightData) {
        // Track the dismissal server-side
        Task { await trackEngagement(insight.id, action: "dismissed") }

        withAnimation(.airfit) {
            showUndoToast = false
            recentlyDismissed = nil
        }
    }

    private func handleAction(_ action: String, insightId: String) {
        // Track the action
        Task { await trackEngagement(insightId, action: "acted:\(action)") }

        // Parse action string and determine smart behavior
        let lowercased = action.lowercased()
        let actionType = classifyAction(lowercased)

        switch actionType {
        case .logFood:
            // Navigate immediately to Nutrition tab
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            showConfirmation(icon: "fork.knife", message: "Opening nutrition log", color: Theme.protein)

        case .proteinReminder:
            // Schedule a smart protein reminder for later today
            Task {
                await scheduleProteinReminder(action: action)
            }
            showConfirmation(icon: "bell.fill", message: "Reminder set for this evening", color: Theme.protein)

        case .workoutReminder:
            // Schedule workout reminder
            Task {
                await scheduleWorkoutReminder(action: action)
            }
            showConfirmation(icon: "dumbbell.fill", message: "Workout reminder scheduled", color: Theme.accent)

        case .sleepGoal:
            // Set a bedtime reminder based on user's typical bedtime
            Task {
                let reminderTime = await scheduleBedtimeReminderAndGetTime()
                await MainActor.run {
                    showConfirmation(icon: "moon.fill", message: "Reminder set for \(reminderTime)", color: Theme.success)
                }
            }
            return // Don't show confirmation here - done in Task above

        case .reviewProgress:
            // Navigate to Dashboard
            NotificationCenter.default.post(name: .openDashboardTab, object: nil)
            showConfirmation(icon: "chart.bar.fill", message: "Opening dashboard", color: Theme.accent)

        case .updateGoals:
            // Navigate to Profile
            NotificationCenter.default.post(name: .openProfileTab, object: nil)
            showConfirmation(icon: "target", message: "Opening profile settings", color: Theme.warm)

        case .askCoach:
            // Navigate to Coach with context
            NotificationCenter.default.post(name: .openCoachTab, object: action)
            showConfirmation(icon: "bubble.left.fill", message: "Opening coach", color: Theme.accent)

        case .generic:
            // For unknown actions, create a general reminder
            Task {
                await scheduleGenericReminder(action: action)
            }
            showConfirmation(icon: "bell.badge.fill", message: "Reminder set", color: Theme.textMuted)
        }
    }

    // MARK: - Action Classification

    private enum ActionType {
        case logFood
        case proteinReminder
        case workoutReminder
        case sleepGoal
        case reviewProgress
        case updateGoals
        case askCoach
        case generic
    }

    private func classifyAction(_ action: String) -> ActionType {
        // Log food actions - immediate
        if action.contains("log") && (action.contains("meal") || action.contains("food") || action.contains("breakfast") || action.contains("lunch") || action.contains("dinner")) {
            return .logFood
        }

        // Protein-related reminders
        if action.contains("protein") || action.contains("eat more") || action.contains("high-protein") {
            // If it says "log" go there now, otherwise schedule reminder
            if action.contains("log") || action.contains("add") {
                return .logFood
            }
            return .proteinReminder
        }

        // Workout reminders
        if action.contains("workout") || action.contains("training") || action.contains("exercise") || action.contains("gym") || action.contains("lift") {
            return .workoutReminder
        }

        // Sleep goals
        if action.contains("sleep") || action.contains("bed") || action.contains("rest") || action.contains("recover") {
            return .sleepGoal
        }

        // Review/check progress
        if action.contains("review") || action.contains("check") || action.contains("track") || action.contains("progress") {
            return .reviewProgress
        }

        // Update goals/targets
        if action.contains("goal") || action.contains("target") || action.contains("update") || action.contains("adjust") || action.contains("profile") {
            return .updateGoals
        }

        // Ask coach
        if action.contains("ask") || action.contains("coach") || action.contains("discuss") || action.contains("talk") {
            return .askCoach
        }

        return .generic
    }

    // MARK: - Smart Reminders

    private func scheduleProteinReminder(action: String) async {
        // Schedule for 2 hours from now or 6pm, whichever is sooner
        let twoHours = Date().addingTimeInterval(2 * 60 * 60)
        let sixPM = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? twoHours
        let reminderTime = min(twoHours, sixPM)

        let content = UNMutableNotificationContent()
        content.title = "Protein Check 💪"
        content.body = "Time for a high-protein snack or meal to hit your target."
        content.sound = .default
        content.categoryIdentifier = "NUTRITION_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(60, reminderTime.timeIntervalSinceNow),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "protein-action-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWorkoutReminder(action: String) async {
        // Schedule for tomorrow morning at 8am if it's afternoon, or 4pm if morning
        let hour = Calendar.current.component(.hour, from: Date())
        var components = DateComponents()

        if hour >= 12 {
            // Afternoon - remind tomorrow morning
            components.hour = 8
            components.minute = 0
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 8
        } else {
            // Morning - remind this afternoon
            components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 16
            components.minute = 0
        }

        let content = UNMutableNotificationContent()
        content.title = "Workout Time 🏋️"
        content.body = "Ready to train? Your body is primed for a good session."
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "workout-action-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private func scheduleBedtimeReminderAndGetTime() async -> String {
        let calendar = Calendar.current

        // Try to get user's typical bedtime from HealthKit
        let healthKit = HealthKitManager()
        let typicalBedtime = await healthKit.getTypicalBedtime()

        var reminderHour: Int
        var reminderMinute: Int
        var isTomorrow = false

        if let bedtime = typicalBedtime, let hour = bedtime.hour, let minute = bedtime.minute {
            // Schedule reminder 2 hours before typical bedtime
            var totalMinutes = hour * 60 + minute - 120 // 2 hours before

            // Handle wrap-around (if bedtime is 11pm, reminder at 9pm)
            if totalMinutes < 0 {
                totalMinutes += 24 * 60
            }

            reminderHour = totalMinutes / 60
            reminderMinute = totalMinutes % 60
        } else {
            // Fallback to 9:30pm if no sleep data
            reminderHour = 21
            reminderMinute = 30
        }

        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = reminderHour
        components.minute = reminderMinute

        // If the reminder time has already passed today, schedule for tomorrow
        if let reminderDate = calendar.date(from: components), reminderDate < Date() {
            isTomorrow = true
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
                components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = reminderHour
                components.minute = reminderMinute
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "Wind Down 🌙"
        content.body = "Time to start your bedtime routine for better recovery."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "sleep-action-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)

        // Format time for display
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var displayComponents = DateComponents()
        displayComponents.hour = reminderHour
        displayComponents.minute = reminderMinute
        let displayDate = calendar.date(from: displayComponents) ?? Date()
        let timeString = formatter.string(from: displayDate)

        return isTomorrow ? "\(timeString) tomorrow" : timeString
    }

    private func scheduleGenericReminder(action: String) async {
        // Schedule for 2 hours from now
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = action.prefix(100).description
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60 * 60, repeats: false)

        let request = UNNotificationRequest(
            identifier: "action-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Confirmation Toast

    private func showConfirmation(icon: String, message: String, color: Color) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            actionToast = ActionToastData(icon: icon, message: message, color: color)
            showActionToast = true
        }

        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showActionToast = false
            }
        }
    }
}

// MARK: - Action Toast Data

private struct ActionToastData {
    let icon: String
    let message: String
    let color: Color
}

// MARK: - Premium Metric Tile

struct PremiumMetricTile: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)

            Text(value)
                .font(.metricSmall)
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.labelMicro)
                .tracking(1)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Premium Insight Card

struct PremiumInsightCard: View {
    let insight: APIClient.InsightData
    let onTellMeMore: () -> Void
    let onDismiss: () -> Void
    let onAction: (String) -> Void

    /// Whether this is a milestone worth celebrating
    private var isMilestone: Bool {
        insight.category == "milestone"
    }

    @State private var dragOffset: CGFloat = 0
    @State private var isDismissing = false
    @State private var showCelebration = false

    private var categoryIcon: String {
        switch insight.category {
        case "correlation": return "arrow.triangle.branch"
        case "trend": return "chart.line.uptrend.xyaxis"
        case "anomaly": return "exclamationmark.triangle"
        case "milestone": return "star.fill"
        case "nudge": return "hand.point.right"
        default: return "lightbulb"
        }
    }

    private var categoryColor: Color {
        switch insight.category {
        case "correlation": return Theme.accent
        case "trend": return Theme.protein
        case "anomaly": return Theme.warning
        case "milestone": return Theme.warm
        case "nudge": return Theme.success
        default: return Theme.textMuted
        }
    }

    private func formatValue(_ value: Double, metric: String?) -> String {
        switch metric?.lowercased() {
        case "weight":
            return String(format: "%.1f lbs", value)
        case "protein":
            return "\(Int(value))g"
        case "calories":
            return "\(Int(value))"
        case "sleep":
            return String(format: "%.1f hrs", value)
        case "steps":
            return "\(Int(value))"
        default:
            if value == floor(value) {
                return "\(Int(value))"
            }
            return String(format: "%.1f", value)
        }
    }

    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))%"
    }

    /// Check if we have chartable data
    private var hasChartData: Bool {
        guard let data = insight.supporting_data else { return false }
        return data.values != nil && (data.values?.count ?? 0) >= 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                        .font(.body)
                }

                Text(insight.title)
                    .font(.headlineMedium)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()
            }

            // Sparkline visualization (when data available)
            if hasChartData, let data = insight.supporting_data, let values = data.values {
                HStack(spacing: 16) {
                    // Expanded sparkline
                    MiniSparkline(data: values, color: categoryColor, showDots: true)
                        .frame(width: 120, height: 32)

                    // Metric summary
                    if let current = data.current_value {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatValue(current, metric: data.metric))
                                .font(.metricSmall)
                                .foregroundStyle(categoryColor)
                            if let change = data.change_pct {
                                Text(formatChange(change))
                                    .font(.labelMicro)
                                    .foregroundStyle(change >= 0 ? Theme.success : Theme.warning)
                            }
                        }
                    }

                    Spacer()

                    // Target indicator
                    if let target = data.target {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Target")
                                .font(.labelMicro)
                                .foregroundStyle(Theme.textMuted)
                            Text(formatValue(target, metric: data.metric))
                                .font(.labelMedium)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(categoryColor.opacity(0.05))
                )
            }

            // Body
            Text(insight.body)
                .font(.bodyMedium)
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(4)

            // Actions
            HStack(spacing: 12) {
                Button {
                    onTellMeMore()
                } label: {
                    Text("Tell me more")
                        .font(.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(categoryColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())

                if !insight.suggested_actions.isEmpty {
                    ForEach(insight.suggested_actions.prefix(1), id: \.self) { action in
                        Button {
                            onAction(action)
                        } label: {
                            Text(action)
                                .font(.labelMedium)
                                .foregroundStyle(categoryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(categoryColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(AirFitSubtleButtonStyle())
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
        .offset(x: dragOffset)
        .opacity(isDismissing ? 0 : 1.0 - Double(abs(dragOffset)) / 300.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Only respond to horizontal swipes (not vertical scrolls)
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.5
                    if isHorizontal && value.translation.width < 0 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    let threshold: CGFloat = -100
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.5
                    if isHorizontal && value.translation.width < threshold {
                        // Dismiss with animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isDismissing = true
                            dragOffset = -400
                        }
                        // Delay the actual removal to let animation complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onDismiss()
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: dragOffset < -100)
        .overlay {
            // Celebration effect for milestones
            if isMilestone && showCelebration {
                ZStack {
                    // Star burst in corner
                    StarBurst(color: categoryColor)
                        .position(x: 40, y: 40)

                    // Particle burst
                    CelebrationBurst(color: categoryColor)
                        .position(x: 60, y: 60)
                }
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            // Trigger celebration for milestones
            if isMilestone {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCelebration = true
                }
            }
        }
        .sensoryFeedback(.success, trigger: showCelebration)
    }
}

// MARK: - Premium Insight Chat Sheet

struct PremiumInsightChatSheet: View {
    let insight: APIClient.InsightData
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var hasAutoStarted = false

    // Voice input
    @State private var isVoiceInputActive = false
    @State private var showVoiceOverlay = false
    @State private var speechManager = SpeechTranscriptionManager()

    // Provider selection
    @AppStorage("aiProvider") private var aiProvider = "claude"

    private let apiClient = APIClient()
    private let geminiService = GeminiService()

    /// System prompt for insight discussions via Gemini
    private var insightSystemPrompt: String {
        """
        You are an expert fitness coach discussing an insight with your client.

        The insight being discussed:
        Title: \(insight.title)
        Category: \(insight.category)
        Body: \(insight.body)
        \(insight.suggested_actions.isEmpty ? "" : "Suggested actions: \(insight.suggested_actions.joined(separator: ", "))")

        Provide helpful, actionable advice based on this insight. Be conversational and supportive.
        Keep responses focused and practical - 2-3 paragraphs max.
        """
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Original insight card
                VStack(alignment: .leading, spacing: 12) {
                    Text(insight.title)
                        .font(.headlineMedium)
                        .foregroundStyle(Theme.textPrimary)
                    Text(insight.body)
                        .font(.bodyMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)

                // Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(messages) { message in
                            PremiumInsightMessageBubble(message: message)
                        }

                        if isLoading {
                            HStack(spacing: 12) {
                                BreathingDot()
                                StreamingWave()
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)

                // Input with voice
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        TextField("Ask about this insight...", text: $inputText)
                            .font(.bodyMedium)
                            .textFieldStyle(.plain)

                        // Voice input button
                        VoiceInputButton(isRecording: isVoiceInputActive) {
                            startVoiceInput()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(inputText.isEmpty ? Theme.textMuted : Theme.accent)
                    }
                    .buttonStyle(AirFitButtonStyle())
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding(20)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .task {
                // Auto-start conversation when sheet opens
                guard !hasAutoStarted else { return }
                hasAutoStarted = true
                await sendInitialPrompt()
            }
            .fullScreenCover(isPresented: $showVoiceOverlay) {
                VoiceInputOverlay(
                    speechManager: speechManager,
                    onComplete: { transcript in
                        inputText = transcript
                        showVoiceOverlay = false
                        isVoiceInputActive = false
                        Task { await sendMessage() }
                    },
                    onCancel: {
                        showVoiceOverlay = false
                        isVoiceInputActive = false
                    }
                )
                .background(ClearBackgroundView())
            }
        }
    }

    // MARK: - Voice Input

    private func startVoiceInput() {
        Task {
            do {
                isVoiceInputActive = true
                try await speechManager.startListening()
                showVoiceOverlay = true
            } catch {
                isVoiceInputActive = false
                print("Failed to start voice input: \(error)")
            }
        }
    }

    private func sendInitialPrompt() async {
        isLoading = true

        let initialMessage = "Tell me more about this insight. What's the full context and what should I do about it?"

        // Route by provider
        if aiProvider == "gemini" {
            await sendViaGemini(initialMessage, isInitial: true)
        } else {
            await sendViaClaude(initialMessage)
        }

        isLoading = false
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        withAnimation(.airfit) {
            messages.append(Message(content: text, isUser: true))
        }
        inputText = ""

        isLoading = true

        // Route by provider
        if aiProvider == "gemini" {
            await sendViaGemini(text, isInitial: false)
        } else {
            await sendViaClaude(text)
        }

        isLoading = false
    }

    /// Send message via Gemini API (direct, no server needed)
    private func sendViaGemini(_ text: String, isInitial: Bool) async {
        do {
            // Build history from previous messages
            let history = messages.map { msg in
                ConversationMessage(
                    role: msg.isUser ? "user" : "model",
                    content: msg.content
                )
            }

            let response = try await geminiService.chat(
                message: text,
                history: history,
                systemPrompt: insightSystemPrompt
            )

            withAnimation(.airfit) {
                messages.append(Message(content: response, isUser: false))
            }
        } catch {
            print("[InsightChatSheet] Gemini failed: \(error)")
            withAnimation(.airfit) {
                let fallback = isInitial
                    ? "I'd be happy to tell you more about this insight. What would you like to know?"
                    : "Sorry, I couldn't process that. Try again?"
                messages.append(Message(content: fallback, isUser: false))
            }
        }
    }

    /// Send message via Claude server
    private func sendViaClaude(_ text: String) async {
        do {
            let response = try await apiClient.discussInsight(id: insight.id, message: text)
            withAnimation(.airfit) {
                messages.append(Message(content: response, isUser: false))
            }
        } catch {
            print("[InsightChatSheet] Claude failed: \(error)")
            withAnimation(.airfit) {
                messages.append(Message(content: "Sorry, I couldn't process that. Try again?", isUser: false))
            }
        }
    }
}

// MARK: - Premium Insight Message Bubble

private struct PremiumInsightMessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if !message.isUser {
                    HStack(spacing: 6) {
                        BreathingDot()
                        Text("Coach")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Text(message.content)
                    .font(.bodyMedium)
                    .foregroundStyle(message.isUser ? .white : Theme.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(message.isUser ? Theme.accent : Theme.surface)
                            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                    )
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Undo Toast

private struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(message)
                .font(.labelMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Button {
                onUndo()
            } label: {
                Text("Undo")
                    .font(.labelLarge)
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(AirFitSubtleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Action Confirmation Toast

private struct ActionConfirmationToast: View {
    let data: ActionToastData

    var body: some View {
        HStack(spacing: 12) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(data.color.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: data.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(data.color)
            }

            Text(data.message)
                .font(.labelMedium)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.success)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .sensoryFeedback(.success, trigger: data.message)
    }
}

#Preview {
    NavigationStack {
        InsightsView()
            .modelContainer(for: NutritionEntry.self, inMemory: true)
    }
}
