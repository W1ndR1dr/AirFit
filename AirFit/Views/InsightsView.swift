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
            if showUndoToast {
                UndoToast(
                    message: "Insight dismissed",
                    onUndo: undoDismiss
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 100) // Above tab bar
            }
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

    /// Load insights from local storage (Gemini Direct mode).
    /// Uses existing LocalInsight entries rather than regenerating each time.
    private func loadInsightsViaGemini() async {
        // First, try to load existing insights from LocalInsight storage
        let existingInsights = await localInsightEngine.getActiveInsights(modelContext: modelContext, limit: 10)

        if !existingInsights.isEmpty {
            // Convert LocalInsight to InsightData for display
            insights = existingInsights.map { localInsight in
                APIClient.InsightData(
                    id: localInsight.id.uuidString,
                    category: localInsight.category,
                    tier: localInsight.tier,
                    title: localInsight.title,
                    body: localInsight.body,
                    importance: localInsight.importance,
                    created_at: ISO8601DateFormatter().string(from: localInsight.createdAt),
                    suggested_actions: localInsight.suggestedActions,
                    supporting_data: localInsight.metricName.map { metric in
                        APIClient.SupportingData(
                            metric: metric,
                            values: localInsight.values.isEmpty ? nil : localInsight.values,
                            dates: nil,
                            target: localInsight.targetValue,
                            trend_slope: localInsight.trendSlope,
                            current_value: localInsight.currentValue,
                            previous_value: localInsight.previousValue,
                            change_pct: localInsight.changePct
                        )
                    }
                )
            }

            // Check for high-tier insights and notify
            await NotificationManager.shared.checkAndNotifyForInsights(insights)
            return
        }

        // No existing insights - generate fresh ones
        do {
            let newInsights = try await localInsightEngine.generateAndSaveInsights(days: 7, modelContext: modelContext)
            insights = newInsights.map { localInsight in
                APIClient.InsightData(
                    id: localInsight.id.uuidString,
                    category: localInsight.category,
                    tier: localInsight.tier,
                    title: localInsight.title,
                    body: localInsight.body,
                    importance: localInsight.importance,
                    created_at: ISO8601DateFormatter().string(from: localInsight.createdAt),
                    suggested_actions: localInsight.suggestedActions,
                    supporting_data: nil
                )
            }

            // Check for high-tier insights and notify
            await NotificationManager.shared.checkAndNotifyForInsights(insights)
        } catch {
            print("[InsightsView] Failed to generate insights via Gemini: \(error)")
        }
    }

    private func syncAndRefresh() async {
        isSyncing = true

        // Route by provider to avoid unnecessary server calls
        if aiProvider == "gemini" {
            // Gemini Direct mode: Generate fresh insights locally, no server sync
            do {
                _ = try await localInsightEngine.generateAndSaveInsights(days: 7, modelContext: modelContext)
                lastSyncTime = Date()
            } catch {
                print("[InsightsView] Local insight generation failed: \(error)")
            }
            await loadData()
        } else {
            // Claude/Server mode: Sync to server, then trigger server-side generation
            do {
                try await syncService.syncRecentDays(7, modelContext: modelContext)
                lastSyncTime = Date()
            } catch {
                print("[InsightsView] Sync failed: \(error)")
            }

            // Trigger server-side insight generation
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
        // In Gemini Direct mode, track locally via LocalInsight model
        if aiProvider == "gemini" {
            if let uuid = UUID(uuidString: id) {
                let descriptor = FetchDescriptor<LocalInsight>(
                    predicate: #Predicate { $0.id == uuid }
                )
                if let insight = try? modelContext.fetch(descriptor).first {
                    insight.engagement = action
                    insight.surfacedAt = Date()
                    try? modelContext.save()
                }
            }
            return
        }

        // Claude/Server mode: track via API
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
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Discuss")
                    }
                    .font(.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(categoryColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(AirFitButtonStyle())

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
    @State private var showModelRequired = false
    @State private var speechManager = WhisperTranscriptionService.shared

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

                        // Voice input button (disabled - WhisperKit crash investigation)
                        // VoiceInputButton(isRecording: isVoiceInputActive) {
                        //     startVoiceInput()
                        // }
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
            // MARK: - Voice Input Disabled (WhisperKit crash investigation)
            // .fullScreenCover(isPresented: $showVoiceOverlay) {
            //     VoiceInputOverlay(
            //         speechManager: speechManager,
            //         onComplete: { transcript in
            //             inputText = transcript
            //             showVoiceOverlay = false
            //             isVoiceInputActive = false
            //             Task { await sendMessage() }
            //         },
            //         onCancel: {
            //             showVoiceOverlay = false
            //             isVoiceInputActive = false
            //         }
            //     )
            //     .background(ClearBackgroundView())
            // }
            // .sheet(isPresented: $showModelRequired) {
            //     ModelRequiredSheet {
            //         startVoiceInput()
            //     }
            // }
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

#Preview {
    NavigationStack {
        InsightsView()
            .modelContainer(for: NutritionEntry.self, inMemory: true)
    }
}
