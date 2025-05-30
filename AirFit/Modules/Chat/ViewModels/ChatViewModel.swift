import SwiftUI
import SwiftData
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    // MARK: - Dependencies
    private let modelContext: ModelContext
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
    @Published private(set) var error: Error?

    // MARK: - Composer State
    @Published var composerText = ""
    @Published var isRecording = false
    @Published var voiceWaveform: [Float] = []
    @Published var attachments: [ChatAttachment] = []

    // MARK: - Suggestions
    @Published private(set) var quickSuggestions: [QuickSuggestion] = []
    @Published private(set) var contextualActions: [ContextualAction] = []

    // MARK: - Stream State
    private var streamBuffer = ""
    private var streamTask: Task<Void, Never>?

    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        user: User,
        coachEngine: CoachEngineProtocol,
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
            // Use simpler predicate to avoid UUID comparison issues
            let sessions = try modelContext.fetch(FetchDescriptor<ChatSession>())
            let existing = sessions.first { session in
                session.isActive && session.user?.id == user.id
            }

            if let existing = existing {
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
        do {
            // Use simpler approach to avoid Predicate issues
            let allMessages = try modelContext.fetch(FetchDescriptor<ChatMessage>(
                sortBy: [SortDescriptor(\.timestamp)]
            ))
            messages = allMessages.filter { $0.session?.id == session.id }
        } catch {
            AppLogger.error("Failed to load messages", error: error, category: .chat)
        }
    }

    // MARK: - Message Sending
    func sendMessage() async {
        guard !composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let session = currentSession else { return }

        let userMessage = ChatMessage(
            session: session,
            content: composerText,
            role: .user,
            attachments: attachments
        )

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
            session: session,
            content: "",
            role: .assistant
        )
        modelContext.insert(assistantMessage)
        messages.append(assistantMessage)

        // Simplified AI response generation for now
        streamTask = Task {
            do {
                // Simulate streaming response
                let response = "I understand you're asking about: \(userInput). Let me help you with that."
                for char in response {
                    guard !Task.isCancelled else { break }
                    streamBuffer += String(char)
                    assistantMessage.content = streamBuffer
                    try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                }
                
                try? modelContext.save()
                await refreshSuggestions()
            } catch {
                assistantMessage.content = "I apologize, but I encountered an error. Please try again."
                assistantMessage.recordError(error.localizedDescription)
                self.error = error
            }

            isStreaming = false
            streamBuffer = ""
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
                HapticManager.notification(.success)
            }
            isRecording = false
        } else {
            do {
                try await voiceManager.startRecording()
                isRecording = true
                HapticManager.impact(.medium)
            } catch {
                self.error = error
                HapticManager.notification(.error)
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

    func copyMessage(_ message: ChatMessage) {
        UIPasteboard.general.string = message.content
        HapticManager.notification(.success)
    }

    func regenerateResponse(for message: ChatMessage) async {
        guard message.roleEnum == .assistant,
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
            // Use simpler approach to avoid Predicate issues
            let allMessages = try modelContext.fetch(FetchDescriptor<ChatMessage>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            ))
            return allMessages.filter { message in
                message.content.localizedStandardContains(query) &&
                message.session?.user?.id == user.id
            }
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
        HapticManager.notification(.success)
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
        HapticManager.notification(.success)
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

enum ChatError: LocalizedError, Equatable, Sendable {
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
