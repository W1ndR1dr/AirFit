import SwiftUI
import SwiftData
import HealthKit
import PhotosUI

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var serverStatus: ServerStatus = .checking
    @State private var healthContext: HealthContext?
    @State private var healthAuthorized = false
    @State private var isInitializing = true
    @State private var isOnboarding = false  // True if user needs onboarding
    @State private var isFinalizingOnboarding = false
    @State private var editingMessageIndex: Int?  // For editing user messages
    @State private var editingText: String = ""
    @State private var feedbackSheetMessageIndex: Int?  // For feedback elaboration
    @State private var isNearBottom: Bool = true  // For jump-to-bottom button
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showPhotoFeatureGate = false  // Photo feature permission prompt
    @State private var showingPhotoPicker = false  // Photo picker for food logging
    @State private var selectedPhoto: PhotosPickerItem?  // Selected photo from picker
    @State private var isAnalyzingPhoto = false  // Photo analysis in progress
    @State private var isVoiceInputActive = false  // Voice input recording state
    @State private var showVoiceOverlay = false  // Voice input overlay
    @State private var speechManager = SpeechTranscriptionManager()
    @State private var pendingSeed: ConversationSeed?  // Conversation seed waiting to start
    @State private var activeSeed: ConversationSeed?  // Currently active seed (nil = normal coaching)
    @FocusState private var isInputFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()

    // Provider selection (persisted)
    @AppStorage("aiProvider") private var aiProvider = "claude"
    @AppStorage("geminiParanoidMode") private var geminiParanoidMode = false
    @AppStorage("geminiThinkingLevel") private var geminiThinkingLevelRaw = ThinkingLevel.medium.rawValue

    /// User's preferred thinking level for Gemini
    private var thinkingLevel: ThinkingLevel {
        ThinkingLevel(rawValue: geminiThinkingLevelRaw) ?? .medium
    }

    /// Effective provider for text chat.
    /// - "claude" → use Claude via server
    /// - "both" → use Claude for text, Gemini for photo features (Phase 4)
    /// - "gemini" → use Gemini directly (unless paranoid mode)
    private var effectiveProvider: String {
        // "both" mode uses Claude for text conversations (privacy)
        if aiProvider == "both" {
            return "claude"
        }
        // Paranoid mode override: force Claude even if Gemini selected
        if aiProvider == "gemini" && geminiParanoidMode {
            return "claude"
        }
        return aiProvider
    }

    /// Whether photo features should use Gemini (true for "both" or "gemini" modes)
    private var canUseGeminiForPhotos: Bool {
        (aiProvider == "both" || aiProvider == "gemini") && geminiReady
    }

    // Gemini direct mode state
    @State private var geminiConversationHistory: [ConversationMessage] = []
    @State private var pendingMemoryMarkers: [MemoryMarker] = []
    @State private var lastUserMessage: String = ""
    @State private var geminiReady = false

    // Streaming state (Gemini-only mode)
    @State private var isStreaming = false
    @State private var streamingContent = ""
    @State private var streamingMessageId: UUID?

    private let apiClient = APIClient()
    private let healthKit = HealthKitManager()
    private let geminiService = GeminiService()
    private let contextManager = ContextManager.shared
    private let memorySyncService = MemorySyncService()
    private let profileEvolutionService = ProfileEvolutionService.shared

    enum ServerStatus {
        case checking, connected, disconnected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Status banners
            serverStatusBanner
            onboardingBanner
            healthContextBanner

            // Messages
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                messageView(for: message, at: index)
                                    .id(message.id)
                                    .scrollReveal()
                                    .transition(.breezeIn)
                            }

                            if isLoading {
                                typingIndicator
                                    .transition(.breezeIn)
                            }

                            // Invisible anchor at bottom for scroll detection
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                                .onAppear { isNearBottom = true }
                                .onDisappear { isNearBottom = false }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    }
                    .background(Color.clear)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: messages.count) {
                        // Auto-scroll to bottom when new messages arrive
                        withAnimation(.airfit) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }

                // Jump to bottom button
                if !isNearBottom && messages.count > 3 {
                    Button {
                        withAnimation(.airfit) {
                            scrollProxy?.scrollTo("bottom", anchor: .bottom)
                        }
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.accent)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(AirFitButtonStyle())
                    .padding(.bottom, 8)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Input area at bottom (moves up with keyboard)
            inputArea
                .padding(.bottom, keyboard.keyboardHeight > 0 ? keyboard.keyboardHeight - 50 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: keyboard.keyboardHeight)
        }
        .background(Color.clear)
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await initialize()
        }
        .overlay {
            if isInitializing {
                PremiumInitializingView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .conversationSeedSelected)) { notification in
            if let seed = notification.userInfo?["seed"] as? ConversationSeed {
                pendingSeed = seed
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onAppear {
            // Check for pending seed conversation
            if let seed = pendingSeed {
                startSeedConversation(seed)
                pendingSeed = nil
            }
        }
        .sheet(isPresented: Binding(
            get: { editingMessageIndex != nil },
            set: { if !$0 { editingMessageIndex = nil } }
        )) {
            EditMessageSheet(
                text: $editingText,
                onSubmit: { Task { await submitEdit() } },
                onCancel: { editingMessageIndex = nil }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: Binding(
            get: { feedbackSheetMessageIndex != nil },
            set: { if !$0 { feedbackSheetMessageIndex = nil } }
        )) {
            FeedbackReasonSheet(
                onSubmit: { reason in
                    if let index = feedbackSheetMessageIndex {
                        provideFeedback(messageIndex: index, isPositive: false, reason: reason)
                    }
                    feedbackSheetMessageIndex = nil
                },
                onCancel: { feedbackSheetMessageIndex = nil }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPhotoFeatureGate) {
            PhotoFeatureGateSheet(
                onEnablePhotos: {
                    // Switch to "both" mode to enable photo features
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

    // MARK: - Message View Builder

    @ViewBuilder
    private func messageView(for message: Message, at index: Int) -> some View {
        let isLastAI = !message.isUser && index == messages.count - 1
        let isStreamingThisMessage = message.id == streamingMessageId

        PremiumMessageView(
            message: message,
            isLastAIMessage: isLastAI,
            isStreaming: isStreamingThisMessage,
            streamingContent: isStreamingThisMessage ? streamingContent : nil,
            onEdit: message.isUser ? { startEditing(messageIndex: index) } : nil,
            onRegenerate: !message.isUser ? { Task { await regenerateResponse(fromIndex: index) } } : nil,
            onFeedback: !message.isUser ? { isPositive, reason in
                provideFeedback(messageIndex: index, isPositive: isPositive, reason: reason)
            } : nil
        )
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
            if effectiveProvider == "gemini" {
                geminiStatusBanner
            } else {
                claudeStatusBanner
            }
        }
    }

    /// Status banner for Gemini mode - shows API key status and sync indicator
    private var geminiStatusBanner: some View {
        Group {
            if !geminiReady {
                // No API key configured
                HStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(Theme.warning)
                    Text("Gemini API key required")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Text("Settings")
                            .font(.labelMedium)
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.warning.opacity(0.1))
            } else {
                // Ready - show subtle provider indicator with optional sync status
                HStack(spacing: 6) {
                    Image("GeminiLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                    Text("Gemini")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)

                    // Show server sync indicator when connected (for Hevy/profile sync)
                    if serverStatus == .connected {
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(Theme.textMuted.opacity(0.4))
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.tertiary.opacity(0.7))
                        Text("syncing")
                            .font(.labelMicro)
                            .foregroundStyle(Theme.textMuted.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
    }

    /// Status banner for Claude mode - shows server connection status
    private var claudeStatusBanner: some View {
        Group {
            switch serverStatus {
            case .checking:
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.accent)
                    Text("Connecting to server")
                        .font(.labelMedium)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)

            case .disconnected:
                HStack(spacing: 12) {
                    Image(systemName: "server.rack")
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
                // Ready - show subtle provider indicator
                HStack(spacing: 6) {
                    Image("ClaudeLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                    Text("Claude")
                        .font(.labelMicro)
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Text field with voice input
                HStack(spacing: 8) {
                    TextField("Message", text: $inputText)
                        .font(.bodyMedium)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textContentType(.none)
                        .textInputAutocapitalization(.sentences)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            Task { await sendMessage() }
                        }

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

                // Send button - only visible when there's text
                if canSend {
                    Button {
                        Task { await sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.accentGradient)
                    }
                    .buttonStyle(AirFitButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                    .sensoryFeedback(.impact(weight: .medium), trigger: canSend)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, keyboard.keyboardHeight > 0 ? 12 : 80) // More space from tab bar when keyboard hidden
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSend)
        }
        .background(.ultraThinMaterial)
        .zIndex(1) // Ensure input area stays above background content
    }

    /// Handle camera button tap - show feature gate if Gemini not available
    private func handleCameraButtonTap() {
        if canUseGeminiForPhotos {
            showingPhotoPicker = true
        } else {
            // Show feature gate prompt
            showPhotoFeatureGate = true
        }
    }

    /// Start voice input for speech-to-text
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

    /// Process a selected photo for food analysis
    private func processSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        // Reset selection for next pick
        selectedPhoto = nil

        // Load the image data
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            let errorMessage = Message(
                content: "Couldn't load that photo. Please try another one.",
                isUser: false
            )
            await MainActor.run {
                withAnimation(.airfit) {
                    messages.append(errorMessage)
                }
            }
            return
        }

        // Prepare image (resize and compress)
        guard let preparedData = await geminiService.prepareImage(image) else {
            let errorMessage = Message(
                content: "Couldn't process that photo. Please try a different one.",
                isUser: false
            )
            await MainActor.run {
                withAnimation(.airfit) {
                    messages.append(errorMessage)
                }
            }
            return
        }

        // Add user message indicating photo analysis
        let userMessage = Message(content: "📷 Analyzing food photo...", isUser: true)
        await MainActor.run {
            withAnimation(.airfit) {
                messages.append(userMessage)
                isAnalyzingPhoto = true
                isLoading = true
            }
        }

        // Analyze with Gemini (use user's thinking level for photo analysis too)
        do {
            let analysis = try await geminiService.analyzeImage(
                imageData: preparedData,
                prompt: Self.foodAnalysisPrompt,
                systemPrompt: Self.foodAnalysisSystemPrompt,
                thinkingLevel: thinkingLevel
            )

            // Parse nutrition data from the response
            let nutritionResult = parseFoodAnalysis(analysis)

            // Create response message with nutrition card if parsed
            let aiMessage: Message
            if let nutrition = nutritionResult {
                // Format response with parsed nutrition
                let formattedResponse = formatFoodAnalysisResponse(analysis: analysis, nutrition: nutrition)
                aiMessage = Message(content: formattedResponse, isUser: false)
            } else {
                // Just show the raw analysis
                aiMessage = Message(content: analysis, isUser: false)
            }

            await MainActor.run {
                withAnimation(.airfit) {
                    messages.append(aiMessage)
                    isAnalyzingPhoto = false
                    isLoading = false
                }
            }

        } catch {
            let errorMessage = Message(
                content: "Couldn't analyze that photo: \(error.localizedDescription)",
                isUser: false
            )
            await MainActor.run {
                withAnimation(.airfit) {
                    messages.append(errorMessage)
                    isAnalyzingPhoto = false
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Food Analysis Helpers

    /// System prompt for food photo analysis
    private static let foodAnalysisSystemPrompt = """
    You are a nutrition analyst for a fitness coaching app. Analyze food photos accurately and helpfully.

    Be conversational but precise. Estimate portions based on visual cues.
    If you're uncertain, say so and provide a range.
    """

    /// Prompt for analyzing food photos
    private static let foodAnalysisPrompt = """
    Analyze this food photo and provide:

    1. **What I see**: Identify all visible foods with estimated portions
    2. **Nutrition estimate**:
       - Calories: [number] kcal
       - Protein: [number]g
       - Carbs: [number]g
       - Fat: [number]g
    3. **Confidence**: high/medium/low based on how clearly you can see the food

    End with a JSON summary on a single line:
    {"name": "Food name", "calories": 000, "protein": 00, "carbs": 00, "fat": 00, "confidence": "high/medium/low"}
    """

    /// Parse nutrition data from food analysis response
    private func parseFoodAnalysis(_ response: String) -> NutritionParseResult? {
        // Look for JSON at the end of the response
        guard let jsonStart = response.lastIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else {
            return nil
        }

        let jsonString = String(response[jsonStart...jsonEnd])
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(NutritionParseResult.self, from: jsonData)
    }

    /// Format the analysis response with a nutrition summary card
    private func formatFoodAnalysisResponse(analysis: String, nutrition: NutritionParseResult) -> String {
        // Strip the JSON from the end for cleaner display
        var cleanAnalysis = analysis
        if let jsonStart = analysis.lastIndex(of: "{") {
            cleanAnalysis = String(analysis[..<jsonStart]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Add a formatted summary
        let summary = """

        ---

        **Quick Log**: \(nutrition.name)
        • \(nutrition.calories) cal | \(nutrition.protein)g protein | \(nutrition.carbs)g carbs | \(nutrition.fat)g fat

        *Tap the + button in Nutrition to log this meal.*
        """

        return cleanAnalysis + summary
    }

    private var canSend: Bool {
        let hasText = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let notLoading = !isLoading

        // Gemini mode: can send if we have API key (geminiReady)
        // Claude mode: can send if server is connected
        // Uses effectiveProvider to respect paranoid mode override
        let providerReady = effectiveProvider == "gemini" ? geminiReady : serverStatus == .connected

        return hasText && notLoading && providerReady
    }

    // MARK: - Actions

    private func initialize() async {
        // Only initialize once - isInitializing starts true, becomes false after init
        guard isInitializing else { return }

        // Request HealthKit authorization first (this shows a system dialog)
        healthAuthorized = await healthKit.requestAuthorization()

        // Fetch initial health data
        if healthAuthorized {
            await refreshHealthData()
        }

        // Check Gemini API key availability
        let keychainManager = KeychainManager.shared
        geminiReady = await keychainManager.hasGeminiAPIKey()

        // Now check server - first attempt triggers local network permission dialog
        // If it fails, wait and retry (user might be responding to permission prompt)
        await checkServerWithRetry()

        // Check if user needs onboarding
        await checkOnboardingStatus()

        // Pre-fetch context for Gemini mode (in background)
        if aiProvider == "gemini" && geminiReady {
            Task {
                _ = await contextManager.getContext()
            }
        }

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
        lastUserMessage = text

        // Route to appropriate provider (respects paranoid mode)
        // Use streaming for Gemini-only mode, regular for Hybrid/Claude
        if effectiveProvider == "gemini" && aiProvider == "gemini" {
            // Pure Gemini mode - use streaming for premium feel
            await sendGeminiMessageStreaming(text)
        } else if effectiveProvider == "gemini" {
            // Hybrid mode uses Gemini but not streaming
            await sendGeminiMessage(text)
        } else {
            await sendClaudeMessage(text)
        }
    }

    /// Send message via Claude (server-based, existing path)
    private func sendClaudeMessage(_ text: String) async {
        // Fetch fresh nutrition context (SwiftData queries are fast)
        let nutritionContext = Self.fetchNutritionContext(from: modelContext)

        // Use seed system prompt if in a seed conversation, otherwise let server decide
        let systemPrompt = activeSeed != nil ? ConversationSeed.seedConversationSystemPrompt : nil

        // Get AI response with health + nutrition context
        isLoading = true
        do {
            let response = try await apiClient.sendMessage(
                text,
                systemPrompt: systemPrompt,
                healthContext: healthContext?.toDictionary(),
                nutritionContext: nutritionContext
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

    /// Send message via Gemini (direct API call with context caching)
    private func sendGeminiMessage(_ text: String) async {
        isLoading = true

        do {
            // Get context with smart refresh based on message intent
            let intent = ContextManager.detectIntent(from: text)
            let context = await contextManager.getContext(for: intent)

            // Use seed system prompt if in a seed conversation, otherwise use normal coaching prompt
            let systemPromptToUse = activeSeed != nil
                ? ConversationSeed.seedConversationSystemPrompt
                : context.systemPrompt

            // Build data context including local health/nutrition
            var dataContext = context.dataContext
            if let healthDict = healthContext?.toDictionary() {
                let healthStr = healthDict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                dataContext += "\n\nToday's health data: \(healthStr)"
            }
            if let nutritionContext = Self.fetchNutritionContext(from: modelContext) {
                dataContext += "\n\nToday's nutrition: \(nutritionContext.total_calories) cal, \(nutritionContext.total_protein)g protein"
            }

            // Call Gemini with context caching for improved latency
            // Cache is automatically created on first call and reused for subsequent calls
            // NOTE: Seed conversations use a different system prompt for organic context gathering
            let rawResponse = try await geminiService.chatWithCache(
                message: text,
                history: geminiConversationHistory,
                systemPrompt: systemPromptToUse,
                dataContext: dataContext.isEmpty ? nil : dataContext,
                thinkingLevel: thinkingLevel,
                createCacheIfNeeded: activeSeed == nil  // Don't cache seed conversation prompts
            )

            // Extract memory markers before displaying
            let (cleanResponse, markers) = MemoryMarkerProcessor.extractAndStrip(rawResponse)

            // Store markers locally in SwiftData (device-first)
            if !markers.isEmpty {
                await memorySyncService.storeMarkers(markers, modelContext: modelContext)
                pendingMemoryMarkers.append(contentsOf: markers)  // Keep for server sync
            }

            // Update conversation history for next message
            geminiConversationHistory.append(ConversationMessage(role: "user", content: text))
            geminiConversationHistory.append(ConversationMessage(role: "model", content: rawResponse))

            // Display clean response
            let aiMessage = Message(content: cleanResponse, isUser: false)
            withAnimation(.airfit) {
                messages.append(aiMessage)
            }

            // Sync to server for profile evolution if we have enough markers
            if pendingMemoryMarkers.count >= 5 {
                await syncPendingMarkersToServer()
            }

            // Trigger profile evolution asynchronously (non-blocking, runs on MainActor)
            let userMsg = text
            let aiMsg = rawResponse
            Task {
                await profileEvolutionService.extractAndUpdateProfile(
                    userMessage: userMsg,
                    aiResponse: aiMsg,
                    modelContext: modelContext
                )
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

    /// Send message via Gemini with streaming response (premium animated text reveal)
    /// Only used in pure Gemini mode for that "AI typing" effect
    private func sendGeminiMessageStreaming(_ text: String) async {
        // Create placeholder AI message immediately for instant feedback
        let placeholderMessage = Message(content: "", isUser: false)
        let messageId = placeholderMessage.id

        await MainActor.run {
            withAnimation(.airfit) {
                messages.append(placeholderMessage)
                isStreaming = true
                streamingContent = ""
                streamingMessageId = messageId
            }
        }

        do {
            // Get context with smart refresh based on message intent
            let intent = ContextManager.detectIntent(from: text)
            let context = await contextManager.getContext(for: intent)

            // Use seed system prompt if in a seed conversation, otherwise use normal coaching prompt
            let systemPromptToUse = activeSeed != nil
                ? ConversationSeed.seedConversationSystemPrompt
                : context.systemPrompt

            // Build data context including local health/nutrition
            var dataContext = context.dataContext
            if let healthDict = healthContext?.toDictionary() {
                let healthStr = healthDict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                dataContext += "\n\nToday's health data: \(healthStr)"
            }
            if let nutritionContext = Self.fetchNutritionContext(from: modelContext) {
                dataContext += "\n\nToday's nutrition: \(nutritionContext.total_calories) cal, \(nutritionContext.total_protein)g protein"
            }

            // Stream the response (seed conversations use different system prompt for organic context gathering)
            let stream = try await geminiService.streamChat(
                message: text,
                history: geminiConversationHistory,
                systemPrompt: systemPromptToUse,
                dataContext: dataContext.isEmpty ? nil : dataContext,
                thinkingLevel: thinkingLevel
            )

            var fullResponse = ""

            // Consume the stream, updating content as chunks arrive
            for try await chunk in stream {
                fullResponse += chunk
                await MainActor.run {
                    streamingContent = fullResponse
                    // Update the message content in place
                    if let index = messages.firstIndex(where: { $0.id == messageId }) {
                        messages[index].content = fullResponse
                    }
                }
            }

            // Stream complete - extract memory markers
            let (cleanResponse, markers) = MemoryMarkerProcessor.extractAndStrip(fullResponse)

            // Store markers locally in SwiftData (device-first)
            if !markers.isEmpty {
                await memorySyncService.storeMarkers(markers, modelContext: modelContext)
                pendingMemoryMarkers.append(contentsOf: markers)  // Keep for server sync
            }

            // Update conversation history for next message
            geminiConversationHistory.append(ConversationMessage(role: "user", content: text))
            geminiConversationHistory.append(ConversationMessage(role: "model", content: fullResponse))

            // Finalize the message with clean content
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[index].content = cleanResponse
                }
                isStreaming = false
                streamingMessageId = nil
                streamingContent = ""
            }

            // Sync to server for profile evolution if we have enough markers
            if pendingMemoryMarkers.count >= 5 {
                await syncPendingMarkersToServer()
            }

            // Trigger profile evolution asynchronously (non-blocking, runs on MainActor)
            let userMsg = text
            let aiMsg = fullResponse
            Task {
                await profileEvolutionService.extractAndUpdateProfile(
                    userMessage: userMsg,
                    aiResponse: aiMsg,
                    modelContext: modelContext
                )
            }

        } catch {
            // Handle error - update the placeholder message with error
            await MainActor.run {
                if let index = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[index].content = "Error: \(error.localizedDescription)"
                }
                isStreaming = false
                streamingMessageId = nil
                streamingContent = ""
            }
        }
    }

    /// Sync pending memory markers and last conversation to server
    private func syncPendingMarkersToServer() async {
        guard !pendingMemoryMarkers.isEmpty || !lastUserMessage.isEmpty else { return }

        // Get the last AI response (with markers for server processing)
        let lastAIResponse = geminiConversationHistory.last(where: { $0.role == "model" })?.content ?? ""

        do {
            try await apiClient.processConversation(
                userMessage: lastUserMessage,
                aiResponse: lastAIResponse
            )
            // Clear pending markers after successful sync
            pendingMemoryMarkers.removeAll()
        } catch {
            print("Profile evolution sync failed: \(error.localizedDescription)")
        }
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
        // Sync any pending markers before clearing
        if effectiveProvider == "gemini" && !pendingMemoryMarkers.isEmpty {
            await syncPendingMarkersToServer()
        }

        // Clear server-side session (conversation memory)
        try? await apiClient.clearChatSession()

        // Clear local state on main actor
        await MainActor.run {
            geminiConversationHistory.removeAll()
            pendingMemoryMarkers.removeAll()
            lastUserMessage = ""
            activeSeed = nil  // Clear seed conversation mode (return to normal coaching)

            withAnimation(.airfit) {
                messages = []
            }
        }

        // Clear context cache to get fresh persona on next message
        await contextManager.clearCache()

        // Invalidate Gemini context cache (will be recreated with fresh context)
        await geminiService.invalidateCache()
    }

    // MARK: - Seed Conversations

    /// Start a seed-initiated conversation with a warm AI opener.
    /// These are fun, lighthearted chats designed to organically gather context
    /// without feeling like an interview.
    private func startSeedConversation(_ seed: ConversationSeed) {
        // Clear any existing conversation for a fresh start
        Task {
            await startNewChat()

            // Small delay to let the clear animation complete
            try? await Task.sleep(for: .milliseconds(300))

            // Add the AI opener as the first message
            await MainActor.run {
                let openerMessage = Message(
                    content: seed.aiOpener,
                    isUser: false
                )

                withAnimation(.airfit) {
                    messages.append(openerMessage)
                    activeSeed = seed  // Track which seed is active for system prompt

                    // Add to Gemini history so it knows what it "said" to start the conversation
                    geminiConversationHistory.append(
                        ConversationMessage(role: "model", content: seed.aiOpener)
                    )
                }

                // Scroll to show the message
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.airfit) {
                        scrollProxy?.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message Actions

    private func startEditing(messageIndex: Int) {
        guard messageIndex < messages.count, messages[messageIndex].isUser else { return }
        editingText = messages[messageIndex].content
        editingMessageIndex = messageIndex
    }

    private func submitEdit() async {
        guard let index = editingMessageIndex else { return }
        let newText = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newText.isEmpty else { return }

        // Update the message content
        messages[index].content = newText

        // Remove all messages after the edited one (will regenerate)
        if index + 1 < messages.count {
            withAnimation(.airfit) {
                messages.removeSubrange((index + 1)...)
            }
            // Also truncate Gemini history
            let historyIndex = index * 2 + 2  // user messages are at even indices in history
            if historyIndex < geminiConversationHistory.count {
                geminiConversationHistory.removeSubrange(historyIndex...)
            }
        }

        // Reset editing state
        editingMessageIndex = nil
        editingText = ""

        // Regenerate response for the edited message
        if effectiveProvider == "gemini" {
            await sendGeminiMessage(newText)
        } else {
            await sendClaudeMessage(newText)
        }
    }

    private func regenerateResponse(fromIndex index: Int) async {
        guard index > 0, !messages[index].isUser else { return }

        // Find the user message that triggered this response
        let userMessageIndex = index - 1
        guard userMessageIndex >= 0, messages[userMessageIndex].isUser else { return }
        let userMessage = messages[userMessageIndex].content

        // Remove this AI response (and any after it)
        withAnimation(.airfit) {
            messages.removeSubrange(index...)
        }

        // Also truncate Gemini history
        let historyIndex = userMessageIndex * 2 + 1  // AI responses are at odd indices
        if historyIndex < geminiConversationHistory.count {
            geminiConversationHistory.removeSubrange(historyIndex...)
        }

        // Regenerate
        if effectiveProvider == "gemini" {
            await sendGeminiMessage(userMessage)
        } else {
            await sendClaudeMessage(userMessage)
        }
    }

    private func provideFeedback(messageIndex: Int, isPositive: Bool, reason: String?) {
        guard messageIndex < messages.count, !messages[messageIndex].isUser else { return }

        withAnimation(.airfit) {
            if isPositive {
                messages[messageIndex].feedback = .positive
            } else {
                messages[messageIndex].feedback = .negative(reason: reason)
            }
        }

        // Could sync this feedback to server for profile evolution
        // For now, just track locally
    }

    private func requestNegativeFeedbackReason(messageIndex: Int) {
        feedbackSheetMessageIndex = messageIndex
    }
}

// MARK: - Scene Phase Observer Extension

extension ChatView {
    /// Watch for app backgrounding to sync pending data
    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .background && effectiveProvider == "gemini" {
            Task {
                await syncPendingMarkersToServer()
            }
        }
        // Re-check Gemini API key when returning from Settings
        if newPhase == .active {
            Task {
                let keychainManager = KeychainManager.shared
                geminiReady = await keychainManager.hasGeminiAPIKey()
            }
        }
    }
}

// MARK: - Premium Message View

struct PremiumMessageView: View {
    let message: Message
    var isLastAIMessage: Bool = false
    var isStreaming: Bool = false
    var streamingContent: String?
    var onEdit: (() -> Void)?
    var onRegenerate: (() -> Void)?
    var onFeedback: ((Bool, String?) -> Void)?  // (isPositive, reason)

    @State private var showFeedbackReason = false
    @State private var feedbackReason = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

                // Edit button for user messages
                if message.isUser, let onEdit = onEdit {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())
                }
            }

            // Rich markdown content (with streaming animation for AI)
            if message.isUser {
                Text(message.content)
                    .font(.bodyMedium)
                    .foregroundStyle(Theme.textPrimary)
            } else if isStreaming, let content = streamingContent {
                // Streaming: use animated text reveal
                StreamingTextView(
                    fullText: content,
                    isComplete: false,
                    charactersPerSecond: 60
                )
            } else {
                MarkdownText(message.content)
            }

            // Action buttons for AI messages
            if !message.isUser {
                HStack(spacing: 16) {
                    // Regenerate button (only for last AI message)
                    if isLastAIMessage, let onRegenerate = onRegenerate {
                        Button {
                            onRegenerate()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(AirFitSubtleButtonStyle())
                    }

                    Spacer()

                    // Feedback buttons
                    if let onFeedback = onFeedback {
                        HStack(spacing: 12) {
                            // Thumbs up
                            Button {
                                onFeedback(true, nil)
                            } label: {
                                Image(systemName: message.feedback == .positive ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .font(.caption)
                                    .foregroundStyle(message.feedback == .positive ? Theme.success : Theme.textMuted)
                            }
                            .buttonStyle(AirFitSubtleButtonStyle())

                            // Thumbs down
                            Button {
                                if case .negative = message.feedback {
                                    // Already negative, no action
                                } else {
                                    showFeedbackReason = true
                                }
                            } label: {
                                Image(systemName: isNegativeFeedback ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                                    .font(.caption)
                                    .foregroundStyle(isNegativeFeedback ? Theme.error : Theme.textMuted)
                            }
                            .buttonStyle(AirFitSubtleButtonStyle())
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(message.isUser ? Theme.accent.opacity(0.08) : Theme.surface)
                .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    message.isUser ? Theme.accent.opacity(0.12) : Color.clear,
                    lineWidth: 1
                )
        )
        .sheet(isPresented: $showFeedbackReason) {
            FeedbackReasonSheet(
                onSubmit: { reason in
                    onFeedback?(false, reason)
                    showFeedbackReason = false
                },
                onCancel: { showFeedbackReason = false }
            )
            .presentationDetents([.medium])
        }
    }

    private var isNegativeFeedback: Bool {
        if case .negative = message.feedback { return true }
        return false
    }
}

// MARK: - Markdown Renderer

struct MarkdownText: View {
    let content: String
    private let blocks: [MarkdownBlock]  // Cached at init - no re-parsing on render

    init(_ content: String) {
        self.content = content
        self.blocks = Self.parseBlocks(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(blocks, id: \.id) { block in
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

    private static func parseBlocks(_ content: String) -> [MarkdownBlock] {
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

// MARK: - Edit Message Sheet

struct EditMessageSheet: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Edit your message and the coach will respond again")
                    .font(.labelMedium)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                TextEditor(text: $text)
                    .font(.bodyMedium)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 100)
                    .focused($isFocused)

                Button {
                    onSubmit()
                } label: {
                    Text("Resend")
                        .font(.headlineMedium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Feedback Reason Sheet

struct FeedbackReasonSheet: View {
    let onSubmit: (String?) -> Void
    let onCancel: () -> Void
    @State private var reason = ""
    @FocusState private var isFocused: Bool

    private let quickReasons = [
        "Not helpful",
        "Incorrect information",
        "Too long",
        "Didn't understand my question",
        "Tone was off"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What could be better?")
                    .font(.headlineMedium)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 8)

                // Quick reason buttons
                FlowLayout(spacing: 8) {
                    ForEach(quickReasons, id: \.self) { quickReason in
                        Button {
                            onSubmit(quickReason)
                        } label: {
                            Text(quickReason)
                                .font(.labelMedium)
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.surface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(AirFitSubtleButtonStyle())
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                // Custom reason
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or tell us more (optional)")
                        .font(.labelMicro)
                        .tracking(1)
                        .foregroundStyle(Theme.textMuted)

                    TextField("What went wrong?", text: $reason, axis: .vertical)
                        .font(.bodyMedium)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .lineLimit(2...4)
                        .focused($isFocused)
                }

                HStack(spacing: 12) {
                    Button {
                        onSubmit(nil)
                    } label: {
                        Text("Skip")
                            .font(.labelLarge)
                            .foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(AirFitSubtleButtonStyle())

                    Button {
                        onSubmit(reason.isEmpty ? nil : reason)
                    } label: {
                        Text("Submit")
                            .font(.labelLarge)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

// MARK: - Flow Layout (for quick reason buttons)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Photo Feature Gate Sheet

/// Shown when user taps camera in Claude-only mode.
/// Prompts to enable "Both" mode for photo features.
struct PhotoFeatureGateSheet: View {
    let onEnablePhotos: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
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
                Text("Photo Features")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                // Explanation
                VStack(spacing: 12) {
                    Text("Photo food logging requires Gemini.")
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)

                    Text("Your text conversations will stay private through your server. Photos are processed by Gemini for food recognition.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)

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
                    .buttonStyle(AirFitButtonStyle())

                    Button(action: onDismiss) {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
