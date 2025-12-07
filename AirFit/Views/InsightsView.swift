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
    private let syncService = InsightsSyncService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Context Summary Card
                    if let ctx = context {
                        contextSummaryCard(ctx)
                    }

                    // Insights Section
                    if insights.isEmpty && !isLoading {
                        emptyStateView
                    } else {
                        insightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .refreshable {
                await syncAndRefresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isSyncing {
                        ProgressView()
                    } else {
                        Button {
                            Task { await syncAndRefresh() }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingChat) {
                if let insight = selectedInsight {
                    InsightChatSheet(insight: insight)
                }
            }
        }
    }

    // MARK: - Context Summary Card

    private func contextSummaryCard(_ ctx: APIClient.ContextSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                metricTile(
                    icon: "flame.fill",
                    color: .orange,
                    value: "\(ctx.avg_calories)",
                    label: "avg cal"
                )

                metricTile(
                    icon: "p.circle.fill",
                    color: .blue,
                    value: "\(ctx.avg_protein)g",
                    label: "avg protein"
                )

                if let weight = ctx.avg_weight {
                    metricTile(
                        icon: "scalemass.fill",
                        color: .purple,
                        value: String(format: "%.1f", weight),
                        label: "lbs"
                    )
                }

                if let sleep = ctx.avg_sleep {
                    metricTile(
                        icon: "moon.fill",
                        color: .indigo,
                        value: String(format: "%.1f", sleep),
                        label: "hrs sleep"
                    )
                }

                if let proteinComp = ctx.protein_compliance {
                    metricTile(
                        icon: "checkmark.circle.fill",
                        color: proteinComp >= 0.8 ? .green : (proteinComp >= 0.5 ? .yellow : .red),
                        value: "\(Int(proteinComp * 100))%",
                        label: "protein hit"
                    )
                }

                if ctx.total_workouts > 0 {
                    metricTile(
                        icon: "dumbbell.fill",
                        color: .pink,
                        value: "\(ctx.total_workouts)",
                        label: "workouts"
                    )
                }
            }

            // Weight change callout
            if let change = ctx.weight_change {
                HStack {
                    Image(systemName: change < 0 ? "arrow.down.right" : "arrow.up.right")
                        .foregroundColor(change < 0 ? .green : .orange)
                    Text(String(format: "%.1f lbs this week", abs(change)))
                        .font(.subheadline)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func metricTile(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
                .foregroundColor(.secondary)

            if isLoading && insights.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else {
                ForEach(insights) { insight in
                    InsightCard(
                        insight: insight,
                        onTellMeMore: {
                            selectedInsight = insight
                            showingChat = true
                            Task { await trackEngagement(insight.id, action: "tapped") }
                        },
                        onDismiss: {
                            Task { await trackEngagement(insight.id, action: "dismissed") }
                            withAnimation {
                                insights.removeAll { $0.id == insight.id }
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No insights yet")
                .font(.headline)

            Text("As you log nutrition and workouts, the AI will find patterns and surface insights here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await syncAndRefresh() }
            } label: {
                Label("Sync Data", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
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

// MARK: - Insight Card

struct InsightCard: View {
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
        case "correlation": return .purple
        case "trend": return .blue
        case "anomaly": return .orange
        case "milestone": return .yellow
        case "nudge": return .green
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
                Text(insight.title)
                    .font(.headline)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Body
            Text(insight.body)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Actions
            HStack(spacing: 12) {
                Button {
                    onTellMeMore()
                } label: {
                    Text("Tell me more")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(categoryColor)

                if !insight.suggested_actions.isEmpty {
                    ForEach(insight.suggested_actions.prefix(2), id: \.self) { action in
                        Button(action) {
                            // TODO: Handle action
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Insight Chat Sheet

struct InsightChatSheet: View {
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
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(.headline)
                    Text(insight.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))

                Divider()

                // Messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }

                        if isLoading {
                            HStack {
                                ProgressView()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }

                // Input
                HStack(spacing: 12) {
                    TextField("Ask about this insight...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(inputText.isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        messages.append(Message(content: text, isUser: true))
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
            messages.append(Message(content: response, isUser: false))
        } catch {
            messages.append(Message(content: "Sorry, I couldn't process that. Try again?", isUser: false))
        }

        isLoading = false
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: NutritionEntry.self, inMemory: true)
}
