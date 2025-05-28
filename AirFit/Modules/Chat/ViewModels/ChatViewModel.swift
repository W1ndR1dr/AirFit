import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class ChatViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let user: User
    private let coachEngine: CoachEngine
    private let aiService: AIServiceProtocol
    var voiceManager: VoiceInputManager
    private let coordinator: ChatCoordinator

    // MARK: - Published State
    private(set) var messages: [ChatMessage] = []
    private(set) var currentSession: ChatSession?
    private(set) var isLoading = false
    private(set) var isStreaming = false
    private(set) var error: Error?

    // MARK: - Composer State
    var composerText = ""
    var isRecording = false
    var voiceWaveform: [Float] = []
    var attachments: [ChatAttachment] = []

    // MARK: - Suggestions
    private(set) var quickSuggestions: [QuickSuggestion] = []
    private(set) var contextualActions: [ContextualAction] = []

    // MARK: - Stream State
    private var streamBuffer = ""
    private var streamTask: Task<Void, Never>?

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        user: User,
        coachEngine: CoachEngine,
        aiService: AIServiceProtocol,
        coordinator: ChatCoordinator
    ) {
        self.modelContext = modelContext
        self.user = user
        self.coachEngine = coachEngine
        self.aiService = aiService
        self.coordinator = coordinator
        self.voiceManager = VoiceInputManager()

        setupVoiceManager()
    }

    // MARK: - Session Management
    func loadOrCreateSession() async {
        do {
            let descriptor = FetchDescriptor<ChatSession>(
                predicate: #Predicate { $0.isActive && $0.user?.id == user.id }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                currentSession = existing
                await loadMessages(for: existing)
            } else {
                let newSession = ChatSession(user: user)
                modelContext.insert(newSession)
                try modelContext.save()
                currentSession = newSession
            }
        } catch {
            self.error = error
            AppLogger.error("Failed to load chat session", error: error, category: .chat)
        }
    }

    private func loadMessages(for session: ChatSession) async {
        guard let sessionId = session.id else { return }
        do {
            let descriptor = FetchDescriptor<ChatMessage>(
                predicate: #Predicate { $0.session?.id == sessionId },
                sortBy: [SortDescriptor(\.timestamp)]
            )
            messages = try modelContext.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to load messages", error: error, category: .chat)
        }
    }

    // MARK: - Message Sending
    func sendMessage() async {
        guard !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let session = currentSession else { return }

        let userMessage = ChatMessage(
            role: MessageRole.user.rawValue,
            content: composerText,
            session: session
        )
        userMessage.attachments = attachments

        modelContext.insert(userMessage)
        messages.append(userMessage)

        let messageText = composerText
        composerText = ""
        attachments = []

        do {
            try modelContext.save()
        } catch {
            AppLogger.error("Failed to save user message", error: error, category: .chat)
        }

        await generateAIResponse(for: messageText, session: session)
    }

    private func generateAIResponse(for userInput: String, session: ChatSession) async {
        isStreaming = true
        streamBuffer = ""

        let assistantMessage = ChatMessage(
            role: MessageRole.assistant.rawValue,
            content: "",
            session: session
        )
        modelContext.insert(assistantMessage)
        messages.append(assistantMessage)

        // Build context via coach engine and stream response via AI service
        do {
            let context = try await coachEngine.buildContext(
                input: userInput,
                user: user,
                recentMessages: Array(messages.suffix(10))
            )

            streamTask = Task {
                do {
                    for try await chunk in aiService.sendRequest(context) {
                        guard !Task.isCancelled else { break }
                        switch chunk {
                        case .text(let text), .textDelta(let text):
                            streamBuffer += text
                            assistantMessage.content = streamBuffer
                        case .functionCall(let call):
                            await handleFunctionCall(name: call.name, arguments: call.arguments.mapValues { $0.value }, message: assistantMessage)
                        case .done:
                            assistantMessage.content = streamBuffer
                            try? modelContext.save()
                            await refreshSuggestions()
                        case .error(let err):
                            self.error = err
                        }
                    }
                } catch {
                    assistantMessage.content = "I apologize, but I encountered an error. Please try again."
                    self.error = error
                }

                isStreaming = false
                streamBuffer = ""
            }
        } catch {
            isStreaming = false
            self.error = error
            assistantMessage.content = "Failed to generate response. Please check your settings."
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
                self?.error = error
                self?.isRecording = false
            }
        }
    }

    func toggleVoiceRecording() async {
        if isRecording {
            if let transcription = await voiceManager.stopRecording() {
                composerText += transcription
                await HapticManager.shared.notification(.success)
            }
            isRecording = false
        } else {
            do {
                try await voiceManager.startRecording()
                isRecording = true
                await HapticManager.shared.impact(.medium)
            } catch {
                self.error = error
                await HapticManager.shared.notification(.error)
            }
        }
    }

    // MARK: - Suggestions
    private func refreshSuggestions() async {
        // Placeholder until ChatSuggestionsEngine is implemented
        quickSuggestions = []
        contextualActions = []
    }

    func selectSuggestion(_ suggestion: QuickSuggestion) {
        composerText = suggestion.text
        if suggestion.autoSend {
            Task { await sendMessage() }
        }
    }

    // MARK: - Message Actions
    func deleteMessage(_ message: ChatMessage) async {
        messages.removeAll { $0.id == message.id }
        modelContext.delete(message)
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    func regenerateResponse(for message: ChatMessage) async {
        guard message.role == MessageRole.assistant.rawValue,
              let index = messages.firstIndex(where: { $0.id == message.id }),
              index > 0 else { return }

        let userMessage = messages[index - 1]
        await deleteMessage(message)
        if let session = currentSession {
            await generateAIResponse(for: userMessage.content, session: session)
        }
    }

    func searchMessages(query: String) async -> [ChatMessage] {
        do {
            let descriptor = FetchDescriptor<ChatMessage>(
                predicate: #Predicate { msg in
                    msg.content.localizedStandardContains(query) &&
                    msg.session?.user?.id == user.id
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
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
                user.goals.append(Goal(description: goal, createdAt: Date()))
                try? modelContext.save()
            }
        case "scheduleReminder":
            break
        default:
            AppLogger.warning("Unknown function call: \(name)", category: .chat)
        }
    }
}

// MARK: - Supporting Types
struct QuickSuggestion: Identifiable, Sendable {
    let id = UUID()
    let text: String
    let autoSend: Bool
}

struct ContextualAction: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let icon: String?
}

enum ChatError: LocalizedError {
    case noActiveSession
    case exportFailed(String)
    case voiceRecognitionUnavailable

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active chat session"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .voiceRecognitionUnavailable:
            return "Voice recognition is not available"
        }
    }
}
