import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var insights: [APIClient.InsightData] = []
    @State private var context: APIClient.ContextSummary?
    @State private var isLoading = false
    @State private var isSyncing = false
    @State private var lastSyncTime: Date?
    @State private var selectedInsight: APIClient.InsightData?
    @State private var showingChat = false

    private let apiClient = APIClient()
    @State private var syncService = InsightsSyncService()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Context Summary Card
                if let ctx = context {
                    contextSummaryCard(ctx)
                        .scrollReveal()
                }

                // Insights Section
                if insights.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    insightsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Insights")
        .refreshable {
            await syncAndRefresh()
        }
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
        .sheet(isPresented: $showingChat) {
            if let insight = selectedInsight {
                PremiumInsightChatSheet(insight: insight)
            }
        }
    }

    // MARK: - Context Summary Card

    private func contextSummaryCard(_ ctx: APIClient.ContextSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THIS WEEK")
                .font(.labelHero)
                .tracking(2)
                .foregroundStyle(Theme.textMuted)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                PremiumMetricTile(
                    icon: "flame.fill",
                    color: Theme.calories,
                    value: "\(ctx.avg_calories)",
                    label: "AVG CAL"
                )

                PremiumMetricTile(
                    icon: "p.circle.fill",
                    color: Theme.protein,
                    value: "\(ctx.avg_protein)g",
                    label: "AVG PROTEIN"
                )

                if let weight = ctx.avg_weight {
                    PremiumMetricTile(
                        icon: "scalemass.fill",
                        color: Theme.accent,
                        value: String(format: "%.1f", weight),
                        label: "LBS"
                    )
                }

                if let sleep = ctx.avg_sleep {
                    PremiumMetricTile(
                        icon: "moon.fill",
                        color: Color.indigo,
                        value: String(format: "%.1f", sleep),
                        label: "HRS SLEEP"
                    )
                }

                if let proteinComp = ctx.protein_compliance {
                    PremiumMetricTile(
                        icon: "checkmark.circle.fill",
                        color: proteinComp >= 0.8 ? Theme.success : (proteinComp >= 0.5 ? Theme.warning : Theme.error),
                        value: "\(Int(proteinComp * 100))%",
                        label: "PROTEIN HIT"
                    )
                }

                if ctx.total_workouts > 0 {
                    PremiumMetricTile(
                        icon: "dumbbell.fill",
                        color: Theme.secondary,
                        value: "\(ctx.total_workouts)",
                        label: "WORKOUTS"
                    )
                }
            }

            // Weight change callout
            if let change = ctx.weight_change {
                HStack(spacing: 8) {
                    Image(systemName: change < 0 ? "arrow.down.right" : "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(change < 0 ? Theme.success : Theme.warning)
                    Text(String(format: "%.1f lbs this week", abs(change)))
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI INSIGHTS")
                .font(.labelHero)
                .tracking(2)
                .foregroundStyle(Theme.textMuted)

            if isLoading && insights.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Theme.accent)
                        Text("Analyzing patterns...")
                            .font(.labelMedium)
                            .foregroundStyle(Theme.textMuted)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                ForEach(Array(insights.enumerated()), id: \.element.id) { index, insight in
                    PremiumInsightCard(
                        insight: insight,
                        onTellMeMore: {
                            selectedInsight = insight
                            showingChat = true
                            Task { await trackEngagement(insight.id, action: "tapped") }
                        },
                        onDismiss: {
                            Task { await trackEngagement(insight.id, action: "dismissed") }
                            withAnimation(.airfit) {
                                insights.removeAll { $0.id == insight.id }
                            }
                        }
                    )
                    .staggeredReveal(index: index)
                }
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

        // Load context and insights in parallel
        async let contextTask: () = loadContext()
        async let insightsTask: () = loadInsights()

        await contextTask
        await insightsTask

        isLoading = false
    }

    private func loadContext() async {
        do {
            context = try await apiClient.getInsightsContext(range: "week")
        } catch {
            print("Failed to load context: \(error)")
        }
    }

    private func loadInsights() async {
        do {
            insights = try await apiClient.getInsights(limit: 10)
        } catch {
            print("Failed to load insights: \(error)")
        }
    }

    private func syncAndRefresh() async {
        isSyncing = true

        // Sync data to server
        do {
            try await syncService.syncRecentDays(7, modelContext: modelContext)
            lastSyncTime = Date()
        } catch {
            print("Sync failed: \(error)")
        }

        // Generate fresh insights from all data (uses CLI, no API cost)
        do {
            let result = try await apiClient.generateInsights(days: 90, force: false)
            if result.success {
                print("Generated \(result.insights_generated) insights (~\(result.token_estimate) tokens)")
            }
        } catch {
            print("Insight generation failed: \(error)")
        }

        // Reload data
        await loadData()

        isSyncing = false
    }

    private func trackEngagement(_ id: String, action: String) async {
        do {
            try await apiClient.engageInsight(id: id, action: action)
        } catch {
            print("Failed to track engagement: \(error)")
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headlineMedium)
                        .foregroundStyle(Theme.textPrimary)

                    Text(insight.category.uppercased())
                        .font(.labelMicro)
                        .tracking(1.5)
                        .foregroundStyle(categoryColor)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                        .padding(8)
                        .background(Circle().fill(Theme.background))
                }
                .buttonStyle(AirFitSubtleButtonStyle())
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
                        Button(action) {
                            // TODO: Handle action
                        }
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
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
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
                .shadow(color: .black.opacity(0.02), radius: 16, x: 0, y: 4)
        )
    }
}

// MARK: - Premium Insight Chat Sheet

struct PremiumInsightChatSheet: View {
    let insight: APIClient.InsightData
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isLoading = false

    private let apiClient = APIClient()

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

                // Input
                HStack(spacing: 12) {
                    TextField("Ask about this insight...", text: $inputText)
                        .font(.bodyMedium)
                        .textFieldStyle(.plain)
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
        }
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

        // Build context-aware prompt
        let contextPrompt = """
        The user is asking about this insight:
        Title: \(insight.title)
        Body: \(insight.body)
        Category: \(insight.category)

        User question: \(text)

        Respond conversationally, referencing the insight and any relevant data.
        """

        do {
            let response = try await apiClient.sendMessage(contextPrompt)
            withAnimation(.airfit) {
                messages.append(Message(content: response, isUser: false))
            }
        } catch {
            withAnimation(.airfit) {
                messages.append(Message(content: "Sorry, I couldn't process that. Try again?", isUser: false))
            }
        }

        isLoading = false
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

#Preview {
    NavigationStack {
        InsightsView()
            .modelContainer(for: NutritionEntry.self, inMemory: true)
    }
}
