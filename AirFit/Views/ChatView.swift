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
    @State private var isOnboarding = false  // True if user needs onboarding
    @State private var isFinalizingOnboarding = false
    @FocusState private var isInputFocused: Bool

    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()

    enum ServerStatus {
        case checking, connected, disconnected
    }

    var body: some View {
        ZStack {
            // Ethereal background
            EtherealBackground(currentTab: 2)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Status banners
                serverStatusBanner
                onboardingBanner
                healthContextBanner

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 32) {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                PremiumMessageView(message: message)
                                    .id(message.id)
                                    .scrollReveal()
                                    .transition(.breezeIn)
                            }

                            if isLoading {
                                typingIndicator
                                    .transition(.breezeIn)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Space for input
                    }
                    .background(Color.clear)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation(.airfit) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Floating input area
            VStack {
                Spacer()
                inputArea
            }
        }
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Task { await startNewChat() }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(AirFitSubtleButtonStyle())
                .disabled(messages.isEmpty)
                .sensoryFeedback(.impact(weight: .light), trigger: messages.isEmpty)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refreshHealthData() }
                } label: {
                    Image(systemName: "heart.circle.fill")
                        .foregroundStyle(healthAuthorized ? Theme.secondary : Theme.textMuted)
                }
                .buttonStyle(AirFitSubtleButtonStyle())
            }
        }
        .task {
            await initialize()
        }
        .overlay {
            if isInitializing {
                PremiumInitializingView()
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 12) {
            StreamingWave()

            Text("Thinking")
                .font(.labelMedium)
                .foregroundStyle(Theme.textMuted)

            Spacer()
        }
        .padding(.vertical, 16)
    }

    // MARK: - Health Context Banner

    private var healthContextBanner: some View {
        Group {
            if let context = healthContext {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        StatPill(
                            icon: "figure.walk",
                            value: "\(context.steps)",
                            label: "steps",
                            color: Theme.tertiary
                        )

                        StatPill(
                            icon: "flame.fill",
                            value: "\(context.activeCalories)",
                            label: "cal",
                            color: Theme.calories
                        )

                        if let sleep = context.sleepHours {
                            StatPill(
                                icon: "moon.fill",
                                value: String(format: "%.1f", sleep),
                                label: "hrs",
                                color: Color.indigo
                            )
                        }

                        if let hr = context.restingHeartRate {
                            StatPill(
                                icon: "heart.fill",
                                value: "\(hr)",
                                label: "bpm",
                                color: Theme.secondary
                            )
                        }

                        if !context.recentWorkouts.isEmpty {
                            StatPill(
                                icon: "dumbbell.fill",
                                value: "\(context.recentWorkouts.count)",
                                label: "workouts",
                                color: Theme.accent
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var serverStatusBanner: some View {
        Group {
            switch serverStatus {
            case .checking:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.accent)
                    Text("Connecting")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)

            case .disconnected:
                HStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(Theme.error)
                    Text("Server offline")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button {
                        Task { await checkServer() }
                    } label: {
                        Text("Retry")
                            .font(.labelMedium)
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.error.opacity(0.1))

            case .connected:
                EmptyView()
            }
        }
    }

    private var onboardingBanner: some View {
        Group {
            if isOnboarding {
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(Theme.accent)

                    Text("Getting to know you...")
                        .font(.labelLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Button {
                        Task { await finalizeOnboarding() }
                    } label: {
                        HStack(spacing: 6) {
                            if isFinalizingOnboarding {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.white)
                            }
                            Text(isFinalizingOnboarding ? "Creating" : "Done")
                                .font(.labelLarge)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accentGradient)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(AirFitButtonStyle())
                    .disabled(isFinalizingOnboarding)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.accent.opacity(0.08))
            }
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            VoiceMicButton(text: $inputText)

            TextField("Message", text: $inputText)
                .font(.bodyMedium)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textContentType(.none)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    Task { await sendMessage() }
                }

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(canSend ? Theme.accentGradient : LinearGradient(colors: [Theme.textMuted], startPoint: .top, endPoint: .bottom))
                    .symbolEffect(.bounce, value: canSend)
            }
            .buttonStyle(AirFitButtonStyle())
            .disabled(!canSend)
            .sensoryFeedback(.impact(weight: .medium), trigger: canSend)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
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

        // Check if user needs onboarding
        await checkOnboardingStatus()

        // Pre-fetch nutrition context in background (non-blocking)
        await refreshNutritionContext()

        // Done initializing
        withAnimation(.airfit) {
            isInitializing = false
        }
    }

    private func checkOnboardingStatus() async {
        do {
            let profile = try await apiClient.getProfile()
            withAnimation(.airfit) {
                isOnboarding = profile.needsOnboarding
            }
        } catch {
            // If we can't get profile, assume no onboarding needed
            isOnboarding = false
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
        withAnimation(.airfit) {
            messages.append(userMessage)
        }
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
            withAnimation(.airfit) {
                messages.append(aiMessage)
            }
        } catch {
            let errorMessage = Message(
                content: "Error: \(error.localizedDescription)",
                isUser: false
            )
            withAnimation(.airfit) {
                messages.append(errorMessage)
            }
        }
        isLoading = false
    }

    private func finalizeOnboarding() async {
        isFinalizingOnboarding = true

        do {
            let result = try await apiClient.finalizeOnboarding()
            if result.status == "onboarding_complete" {
                withAnimation(.airfit) {
                    isOnboarding = false
                }
                // Clear chat to start fresh with new personality
                await startNewChat()
                // Add welcome message
                let welcomeMessage = Message(
                    content: "Profile created! I now know you better. Let's get to work.",
                    isUser: false
                )
                withAnimation(.airfit) {
                    messages.append(welcomeMessage)
                }
            }
        } catch {
            // Show error in chat
            let errorMessage = Message(
                content: "Couldn't complete setup: \(error.localizedDescription). Try again?",
                isUser: false
            )
            withAnimation(.airfit) {
                messages.append(errorMessage)
            }
        }

        isFinalizingOnboarding = false
    }

    private func startNewChat() async {
        // Clear server-side session (conversation memory)
        try? await apiClient.clearChatSession()

        // Clear local messages with animation
        withAnimation(.airfit) {
            messages = []
        }
    }
}

// MARK: - Premium Message View

struct PremiumMessageView: View {
    let message: Message

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with role indicator
            HStack(spacing: 8) {
                if message.isUser {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.accent)
                    Text("You")
                        .font(.labelMedium)
                        .tracking(0.5)
                        .foregroundStyle(Theme.textMuted)
                } else {
                    BreathingDot()
                    Text("Coach")
                        .font(.labelMedium)
                        .tracking(0.5)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
            }

            // Rich markdown content
            if message.isUser {
                Text(message.content)
                    .font(.bodyLarge)
                    .foregroundStyle(Theme.textPrimary)
            } else {
                MarkdownText(message.content)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(message.isUser ? Theme.accent.opacity(0.08) : Theme.surface)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
                .shadow(color: .black.opacity(0.02), radius: 16, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    message.isUser ? Theme.accent.opacity(0.15) : Color.clear,
                    lineWidth: 1
                )
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
        VStack(alignment: .leading, spacing: 16) {
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
                    .font(.titleLarge)
                    .foregroundStyle(Theme.textPrimary)
            case .heading2:
                Text(block.content)
                    .font(.titleMedium)
                    .foregroundStyle(Theme.textPrimary)
            case .heading3:
                Text(block.content)
                    .font(.headlineMedium)
                    .foregroundStyle(Theme.textPrimary)
            case .bulletList:
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(block.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 6, height: 6)
                                .offset(y: 7)
                            Text(parseInlineMarkdown(item))
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
            case .numberedList:
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(block.items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .font(.labelLarge)
                                .foregroundStyle(Theme.accent)
                                .frame(width: 24, alignment: .trailing)
                            Text(parseInlineMarkdown(item))
                                .font(.bodyMedium)
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                }
            case .codeBlock:
                Text(block.content)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            case .paragraph:
                Text(parseInlineMarkdown(block.content))
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .lineSpacing(4)
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

// MARK: - Premium Initializing View

struct PremiumInitializingView: View {
    @State private var opacity: Double = 0.4
    @State private var scale: CGFloat = 0.95

    var body: some View {
        ZStack {
            // Transparent - let ethereal background show through
            Color.clear
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated logo/icon
                ZStack {
                    Circle()
                        .fill(Theme.accentGradient)
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .opacity(opacity)
                        .scaleEffect(scale)

                    Image(systemName: "figure.run")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }

                VStack(spacing: 8) {
                    Text("AirFit")
                        .font(.titleLarge)
                        .foregroundStyle(Theme.textPrimary)

                    Text("Preparing your coach")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                opacity = 0.8
                scale = 1.05
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
