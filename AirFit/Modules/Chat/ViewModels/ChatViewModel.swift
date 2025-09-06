import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject, ErrorHandling {
    // MARK: - Dependencies
    private let chatHistoryRepository: ChatHistoryRepositoryProtocol
    let user: User
    private let coachEngine: CoachEngineProtocol
    private let aiService: AIServiceProtocol
    var voiceManager: VoiceInputManager
    private let coordinator: ChatCoordinator

    // MARK: - Published State
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var currentSession: ChatSession?
    @Published private(set) var isLoading = false
    @Published private(set) var isStreaming = false
    @Published var error: AppError?
    @Published var isShowingError = false

    // MARK: - Composer State
    @Published var composerText = ""
    @Published var isRecording = false
    @Published var voiceWaveform: [Float] = []
    @Published var attachments: [ChatAttachment] = []

    // MARK: - Suggestions
    @Published private(set) var quickSuggestions: [QuickSuggestion] = []
    @Published private(set) var contextualActions: [ContextualAction] = []

    // MARK: - Stream State
    private var streamTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    @Published var streamingText: String = ""

    // MARK: - Initialization
    init(
        chatHistoryRepository: ChatHistoryRepositoryProtocol,
        user: User,
        coachEngine: CoachEngineProtocol,
        aiService: AIServiceProtocol,
        coordinator: ChatCoordinator,
        voiceManager: VoiceInputManager,
        streamStore: ChatStreamingStore? = nil
    ) {
        self.chatHistoryRepository = chatHistoryRepository
        self.user = user
        self.coachEngine = coachEngine
        self.aiService = aiService
        self.coordinator = coordinator
        self.voiceManager = voiceManager

        setupVoiceManager()

        // Observe coach assistant message creations and append to messages
        NotificationCenter.default.publisher(for: .coachAssistantMessageCreated)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                Task { @MainActor in
                    guard let self = self, let session = self.currentSession else { return }
                    if let coach = notification.object as? CoachMessage, coach.userID == self.user.id {
                        // Note: CoachMessage persistence handled by CoachEngine
                        // Just reload messages to get the latest state
                        await self.loadMessages(for: session)
                    } else {
                        // Fallback: reload messages
                        await self.loadMessages(for: session)
                    }
                    self.isStreaming = false
                    self.streamTask?.cancel()
                    self.streamingText = ""
                }
            }
            .store(in: &cancellables)

        // Note: Notification-based streaming removed in favor of ChatStreamingStore events

        // Optional: subscribe to typed ChatStreamingStore events (bridged from notifications)
        if let streamStore {
            streamStore.events
                .receive(on: RunLoop.main)
                .sink { [weak self] event in
                    guard let self = self else { return }
                    guard let session = self.currentSession,
                          event.conversationId == session.id else { return }
                    switch event.kind {
                    case .started:
                        self.isStreaming = true
                        self.streamingText = ""
                    case .delta(let text):
                        self.streamingText += text
                    case .finished:
                        // Keep streamingText until assistant message is saved
                        self.isStreaming = false
                    }
                }
                .store(in: &cancellables)
        }
    }

    deinit {
        streamTask?.cancel()
        // Combine cancellables auto-cancel on deinit
    }

    // MARK: - Session Management
    func loadOrCreateSession() async {
        do {
            // Try to get active session from repository
            if let existing = try await chatHistoryRepository.getActiveSession(userId: user.id) {
                currentSession = existing
                await loadMessages(for: existing)
            } else {
                // Note: Session creation might need to be moved to a write repository
                // For now, we'll need to handle this through a service
                AppLogger.warning("No active session found, session creation needs write repository", category: .chat)
                // TODO: Create session through a write service
            }
        } catch {
            handleError(error)
            AppLogger.error("Failed to load chat session", error: error, category: .chat)
        }
    }

    private func loadMessages(for session: ChatSession) async {
        do {
            messages = try await chatHistoryRepository.getMessages(
                sessionId: session.id,
                limit: nil,
                offset: nil
            )
        } catch {
            AppLogger.error("Failed to load messages", error: error, category: .chat)
        }
    }

    // MARK: - Message Sending
    func sendMessage() async {
        guard !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let session = currentSession else { return }

        // Note: Message creation requires write operations
        // This should be handled by a write service/repository
        // For now, we'll delegate to CoachEngine which handles persistence
        let messageText = composerText
        composerText = ""
        attachments = []

        await generateAIResponse(for: messageText, session: session)
        
        // Reload messages to get the complete conversation state
        await loadMessages(for: session)
    }

    private func generateAIResponse(for userInput: String, session: ChatSession) async {
        // Process message through actual CoachEngine
        // Note: streaming state is managed through ChatStreamingStore events
        streamTask?.cancel() // Cancel any existing task
        streamTask = Task {
            await coachEngine.processUserMessage(userInput, for: user)
            // CoachEngine will save the assistant message and post notification; no local placeholder
            await refreshSuggestions()
        }
    }

    // MARK: - Voice Input
    private func setupVoiceManager() {
        voiceManager.onTranscription = { [weak self] text in
            Task { @MainActor in
                self?.composerText += text
            }
        }

        voiceManager.onWaveformUpdate = { [weak self] levels in
            Task { @MainActor in
                self?.voiceWaveform = levels
            }
        }

        voiceManager.onError = { [weak self] error in
            Task { @MainActor in
                self?.handleError(error)
                self?.isRecording = false
            }
        }
    }

    func toggleVoiceRecording() async {
        if isRecording {
            if let transcription = await voiceManager.stopRecording() {
                composerText += transcription
                HapticService.play(.success)
            }
            isRecording = false
        } else {
            do {
                try await voiceManager.startRecording()
                isRecording = true
                HapticService.play(.dataUpdated)
            } catch {
                handleError(error)
                HapticService.play(.error)
            }
        }
    }

    // MARK: - Suggestions
    private func refreshSuggestions() async {
        // Placeholder until ChatSuggestionsEngine is implemented
        quickSuggestions = [
            QuickSuggestion(text: "How was my workout today?", autoSend: true),
            QuickSuggestion(text: "Plan my next workout", autoSend: false),
            QuickSuggestion(text: "Analyze my nutrition", autoSend: true)
        ]
        contextualActions = []
    }

    // MARK: - Streaming Controls
    func stopStreaming() async {
        guard isStreaming else { return }
        streamTask?.cancel()
        isStreaming = false
        defer { streamingText = "" }

        let content = streamingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, let session = currentSession else { return }

        // Note: Partial content persistence should be handled by write service
        // For now, just reload messages to maintain consistency
        await loadMessages(for: session)
    }

    func selectSuggestion(_ suggestion: QuickSuggestion) {
        composerText = suggestion.text
        if suggestion.autoSend {
            Task { await sendMessage() }
        }
    }

    // MARK: - Message Actions
    func deleteMessage(_ message: ChatMessage) async {
        // Note: Message deletion requires write operations
        // This should be handled by a write service/repository
        AppLogger.warning("Message deletion requires write service implementation", category: .chat)
        
        // For now, just reload to maintain consistency
        if let session = currentSession {
            await loadMessages(for: session)
        }
    }

    func copyMessage(_ message: ChatMessage) {
        UIPasteboard.general.string = message.content
        HapticService.play(.success)
    }

    func regenerateResponse(for message: ChatMessage) async {
        guard message.roleEnum == .assistant,
              let index = messages.firstIndex(where: { $0.id == message.id }),
              index > 0 else { return }

        let userMessage = messages[index - 1]
        // Note: Regeneration requires write operations for proper implementation
        if let session = currentSession {
            await generateAIResponse(for: userMessage.content, session: session)
            await loadMessages(for: session)
        }
    }

    func searchMessages(query: String) async -> [ChatMessage] {
        do {
            return try await chatHistoryRepository.searchMessages(
                userId: user.id,
                query: query,
                limit: nil
            )
        } catch {
            AppLogger.error("Search failed", error: error, category: .chat)
            return []
        }
    }

    func exportChat() async throws -> URL {
        guard let session = currentSession else {
            throw ChatError.noActiveSession
        }
        let exporter = ChatExporter()
        return try await exporter.export(
            session: session,
            messages: messages,
            format: .markdown
        )
    }

    // MARK: - Function Calls
    private func handleFunctionCall(name: String, arguments: [String: Any], message: ChatMessage) async {
        switch name {
        case "showWorkout":
            break
        case "updateGoal":
            if let goal = arguments["goal"] as? String {
                // Simplified goal handling for now
                message.recordFunctionCall(name: name, args: goal)
            }
        case "scheduleReminder":
            break
        default:
            AppLogger.warning("Unknown function call: \(name)", category: .chat)
        }
    }

    // MARK: - Advanced Message Actions
    func scheduleWorkout(from message: ChatMessage) async {
        // Check if this message contains workout-related function call
        guard let functionName = message.functionCallName,
              functionName.contains("workout") || functionName.contains("exercise") else {
            // Create a generic workout if no specific data
            await createGenericWorkout()
            return
        }

        // Handle specific workout scheduling based on function call
        AppLogger.info("Scheduling workout from message: \(message.id)", category: .chat)
        HapticService.play(.success)
    }

    func setReminder(from message: ChatMessage) async {
        // Check if this message contains reminder-related function call
        guard let functionName = message.functionCallName,
              functionName.contains("reminder") || functionName.contains("schedule") else {
            // Create a generic reminder
            await createGenericReminder()
            return
        }

        // Handle specific reminder creation based on function call
        AppLogger.info("Setting reminder from message: \(message.id)", category: .chat)
        HapticService.play(.success)
    }

    private func createGenericWorkout() async {
        // Placeholder for workout creation
        AppLogger.info("Creating generic workout", category: .chat)
    }

    private func createGenericReminder() async {
        // Placeholder for reminder creation
        AppLogger.info("Creating generic reminder", category: .chat)
    }
}
