import SwiftUI
import SwiftData
import HealthKit

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var serverStatus: ServerStatus = .checking
    @State private var healthContext: HealthContext?
    @State private var healthAuthorized = false
    @State private var isInitializing = true
    @State private var hasInitialized = false  // Prevent re-init on reappear
    @State private var cachedNutritionContext: APIClient.NutritionContext?  // Cache to avoid blocking
    @FocusState private var isInputFocused: Bool

    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()

    enum ServerStatus {
        case checking, connected, disconnected
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status banners
                serverStatusBanner
                healthContextBanner

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(messages) { message in
                                MessageView(message: message)
                                    .id(message.id)
                            }

                            if isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                    Text("Thinking...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                inputArea
            }
            .navigationTitle("AirFit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await startNewChat() }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .disabled(messages.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshHealthData() }
                    } label: {
                        Image(systemName: "heart.circle")
                            .foregroundColor(healthAuthorized ? .pink : .gray)
                    }
                }
            }
        }
        .task {
            await initialize()
        }
        .overlay {
            if isInitializing {
                InitializingView()
            }
        }
    }

    // MARK: - Health Context Banner

    private var healthContextBanner: some View {
        Group {
            if let context = healthContext {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        HealthPill(icon: "figure.walk", value: "\(context.steps)", label: "steps")
                        HealthPill(icon: "flame", value: "\(context.activeCalories)", label: "cal")
                        if let sleep = context.sleepHours {
                            HealthPill(icon: "moon.fill", value: String(format: "%.1f", sleep), label: "hrs")
                        }
                        if let hr = context.restingHeartRate {
                            HealthPill(icon: "heart.fill", value: "\(hr)", label: "bpm")
                        }
                        if !context.recentWorkouts.isEmpty {
                            HealthPill(icon: "dumbbell.fill", value: "\(context.recentWorkouts.count)", label: "workouts")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
            }
        }
    }

    private var serverStatusBanner: some View {
        Group {
            switch serverStatus {
            case .checking:
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Connecting...")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))

            case .disconnected:
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Server offline")
                        .font(.caption)
                    Button("Retry") {
                        Task { await checkServer() }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.2))

            case .connected:
                EmptyView()
            }
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            VoiceMicButton(text: $inputText)

            TextField("Message", text: $inputText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textContentType(.none)
                .textInputAutocapitalization(.sentences)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    Task { await sendMessage() }
                }

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !isLoading
        && serverStatus == .connected
    }

    // MARK: - Actions

    private func initialize() async {
        // Only initialize once - prevent re-init on view reappear
        guard !hasInitialized else { return }
        hasInitialized = true

        // Request HealthKit authorization first (this shows a system dialog)
        healthAuthorized = await healthKit.requestAuthorization()

        // Fetch initial health data
        if healthAuthorized {
            await refreshHealthData()
        }

        // Now check server - first attempt triggers local network permission dialog
        // If it fails, wait and retry (user might be responding to permission prompt)
        await checkServerWithRetry()

        // Pre-fetch nutrition context in background (non-blocking)
        await refreshNutritionContext()

        // Done initializing
        withAnimation {
            isInitializing = false
        }
    }

    private func refreshNutritionContext() async {
        // SwiftData ModelContext is main-actor isolated, so fetch runs on main
        // This is fine since SwiftData fetches are fast (SQLite)
        cachedNutritionContext = Self.fetchNutritionContext(from: modelContext)
    }

    private static func fetchNutritionContext(from modelContext: ModelContext) -> APIClient.NutritionContext? {
        // Fetch last 3 days of nutrition
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<NutritionEntry>(
            predicate: #Predicate { $0.timestamp >= threeDaysAgo },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let allEntries = try? modelContext.fetch(descriptor), !allEntries.isEmpty else {
            return nil
        }

        // Split into today vs recent days
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let todayEntries = allEntries.filter { $0.timestamp >= startOfToday }
        let recentEntries = allEntries.filter { $0.timestamp < startOfToday }

        // Build today's entry summaries
        let todaySummaries = todayEntries.map { entry in
            APIClient.NutritionEntryContext(
                name: entry.name,
                calories: entry.calories,
                protein: entry.protein
            )
        }

        // Build recent days summaries (limit to 15)
        let recentSummaries = recentEntries.prefix(15).map { entry in
            APIClient.NutritionEntryContext(
                name: entry.name,
                calories: entry.calories,
                protein: entry.protein
            )
        }

        // Calculate today's totals
        let totalCalories = todayEntries.reduce(0) { $0 + $1.calories }
        let totalProtein = todayEntries.reduce(0) { $0 + $1.protein }
        let totalCarbs = todayEntries.reduce(0) { $0 + $1.carbs }
        let totalFat = todayEntries.reduce(0) { $0 + $1.fat }

        return APIClient.NutritionContext(
            total_calories: totalCalories,
            total_protein: totalProtein,
            total_carbs: totalCarbs,
            total_fat: totalFat,
            entry_count: todayEntries.count,
            entries: Array(todaySummaries),
            recent_entries: Array(recentSummaries)
        )
    }

    private func checkServerWithRetry() async {
        serverStatus = .checking

        // First attempt - this triggers the local network permission dialog on first launch
        var isHealthy = await apiClient.checkHealth()

        if !isHealthy {
            // Wait for user to respond to permission dialog, then retry
            try? await Task.sleep(for: .seconds(2))
            isHealthy = await apiClient.checkHealth()
        }

        if !isHealthy {
            // One more retry
            try? await Task.sleep(for: .seconds(1))
            isHealthy = await apiClient.checkHealth()
        }

        serverStatus = isHealthy ? .connected : .disconnected
    }

    private func checkServer() async {
        serverStatus = .checking
        let isHealthy = await apiClient.checkHealth()
        serverStatus = isHealthy ? .connected : .disconnected
    }

    private func refreshHealthData() async {
        guard healthAuthorized else { return }
        healthContext = await healthKit.getTodayContext()
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Dismiss keyboard
        isInputFocused = false

        // Add user message
        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // Refresh nutrition context in background before sending
        // (picks up any new entries since last refresh)
        await refreshNutritionContext()

        // Get AI response with health + nutrition context (use cached, non-blocking)
        isLoading = true
        do {
            let response = try await apiClient.sendMessage(
                text,
                healthContext: healthContext?.toDictionary(),
                nutritionContext: cachedNutritionContext
            )
            let aiMessage = Message(content: response, isUser: false)
            messages.append(aiMessage)
        } catch {
            let errorMessage = Message(
                content: "Error: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        }
        isLoading = false
    }

    private func startNewChat() async {
        // Clear server-side session (conversation memory)
        try? await apiClient.clearChatSession()

        // Clear local messages with animation
        withAnimation {
            messages = []
        }
    }
}

// MARK: - Health Pill Component

struct HealthPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
    }
}

// MARK: - Message View (Rich Markdown)

struct MessageView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with role indicator
            HStack(spacing: 6) {
                Image(systemName: message.isUser ? "person.fill" : "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(message.isUser ? .blue : .orange)
                Text(message.isUser ? "You" : "Coach")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }

            // Rich markdown content
            if message.isUser {
                Text(message.content)
                    .font(.body)
            } else {
                MarkdownText(message.content)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(message.isUser ? Color.blue.opacity(0.08) : Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(message.isUser ? Color.blue : Color.orange)
                .frame(width: 3),
            alignment: .leading
        )
    }
}

// MARK: - Markdown Renderer

struct MarkdownText: View {
    let content: String

    init(_ content: String) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseBlocks(), id: \.id) { block in
                blockView(for: block)
            }
        }
    }

    private func blockView(for block: MarkdownBlock) -> some View {
        Group {
            switch block.type {
            case .heading1:
                Text(block.content)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
            case .heading2:
                Text(block.content)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            case .heading3:
                Text(block.content)
                    .font(.headline)
                    .foregroundColor(.primary)
            case .bulletList:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(block.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.orange)
                                .fontWeight(.bold)
                            Text(parseInlineMarkdown(item))
                                .font(.body)
                        }
                    }
                }
            case .numberedList:
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(block.items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                                .frame(width: 20, alignment: .trailing)
                            Text(parseInlineMarkdown(item))
                                .font(.body)
                        }
                    }
                }
            case .codeBlock:
                Text(block.content)
                    .font(.system(.callout, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .paragraph:
                Text(parseInlineMarkdown(block.content))
                    .font(.body)
            }
        }
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        // Try to parse as AttributedString with markdown
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        return AttributedString(text)
    }

    private func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: "\n")
        var currentList: [String] = []
        var currentListType: MarkdownBlockType?
        var currentParagraph = ""

        func flushList() {
            if !currentList.isEmpty, let type = currentListType {
                blocks.append(MarkdownBlock(type: type, items: currentList))
                currentList = []
                currentListType = nil
            }
        }

        func flushParagraph() {
            let trimmed = currentParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(MarkdownBlock(type: .paragraph, content: trimmed))
            }
            currentParagraph = ""
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Headings
            if trimmed.hasPrefix("### ") {
                flushList()
                flushParagraph()
                blocks.append(MarkdownBlock(type: .heading3, content: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                flushList()
                flushParagraph()
                blocks.append(MarkdownBlock(type: .heading2, content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                flushList()
                flushParagraph()
                blocks.append(MarkdownBlock(type: .heading1, content: String(trimmed.dropFirst(2))))
            }
            // Bullet lists
            else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                flushParagraph()
                if currentListType != .bulletList {
                    flushList()
                    currentListType = .bulletList
                }
                currentList.append(String(trimmed.dropFirst(2)))
            }
            // Numbered lists
            else if let match = trimmed.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                flushParagraph()
                if currentListType != .numberedList {
                    flushList()
                    currentListType = .numberedList
                }
                currentList.append(String(trimmed[match.upperBound...]))
            }
            // Empty line - paragraph break
            else if trimmed.isEmpty {
                flushList()
                flushParagraph()
            }
            // Regular text
            else {
                flushList()
                if !currentParagraph.isEmpty {
                    currentParagraph += " "
                }
                currentParagraph += trimmed
            }
        }

        flushList()
        flushParagraph()

        return blocks
    }
}

private struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
    var content: String = ""
    var items: [String] = []
}

private enum MarkdownBlockType {
    case heading1, heading2, heading3
    case bulletList, numberedList
    case codeBlock, paragraph
}

// MARK: - Initializing View

struct InitializingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ChatView()
}
