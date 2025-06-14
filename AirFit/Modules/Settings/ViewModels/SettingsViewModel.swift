import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class SettingsViewModel: ErrorHandling {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let user: User
    private let apiKeyManager: APIKeyManagementProtocol
    private let aiService: AIServiceProtocol
    private let notificationManager: NotificationManager
    private let coordinator: SettingsCoordinator
    
    // MARK: - Published State
    private(set) var isLoading = false
    var error: AppError?
    var isShowingError = false
    
    // MARK: - Public Access
    var currentUser: User { user }
    
    // MARK: - Coordinator Access
    func showAlert(_ alert: SettingsCoordinator.SettingsAlert) {
        coordinator.showAlert(alert)
    }
    
    // User Preferences
    var preferredUnits: MeasurementSystem
    var appearanceMode: AppearanceMode
    var hapticFeedback: Bool
    var analyticsEnabled: Bool
    
    // AI Configuration
    var selectedProvider: AIProvider
    var selectedModel: String
    var availableProviders: [AIProvider] = []
    var installedAPIKeys: Set<AIProvider> = []
    var isDemoModeEnabled: Bool = AppConstants.Configuration.isUsingDemoMode
    
    // Synthesized Persona
    var coachPersona: CoachPersona?
    var personaEvolution: PersonaEvolutionTracker
    var personaUniquenessScore: Double = 0.0
    
    // Communication Preferences
    var notificationPreferences: NotificationPreferences
    var quietHours: QuietHours
    
    // Privacy & Security
    var biometricLockEnabled: Bool
    var exportHistory: [DataExport] = []
    
    // MARK: - Initialization
    init(
        modelContext: ModelContext,
        user: User,
        apiKeyManager: APIKeyManagementProtocol,
        aiService: AIServiceProtocol,
        notificationManager: NotificationManager,
        coordinator: SettingsCoordinator
    ) {
        self.modelContext = modelContext
        self.user = user
        self.apiKeyManager = apiKeyManager
        self.aiService = aiService
        self.notificationManager = notificationManager
        self.coordinator = coordinator
        
        // Initialize with user's current preferences
        self.preferredUnits = user.preferredUnitsEnum
        self.appearanceMode = user.appearanceMode ?? .system
        self.hapticFeedback = user.hapticFeedbackEnabled
        self.analyticsEnabled = user.analyticsEnabled
        self.selectedProvider = user.selectedAIProvider ?? .openAI
        self.selectedModel = user.selectedAIModel ?? "gpt-4"
        self.notificationPreferences = user.notificationPreferences ?? NotificationPreferences()
        self.quietHours = user.quietHours ?? QuietHours()
        self.biometricLockEnabled = user.biometricLockEnabled
        self.personaEvolution = PersonaEvolutionTracker(user: user)
        self.exportHistory = user.dataExports
    }
    
    // MARK: - Data Loading
    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load available providers
            availableProviders = AIProvider.allCases
            
            // Check which providers have API keys
            var keysFound: [AIProvider] = []
            for provider in availableProviders {
                if await hasAPIKey(for: provider) {
                    keysFound.append(provider)
                }
            }
            installedAPIKeys = Set(keysFound)
            
            // Load notification status
            let authStatus = await notificationManager.getAuthorizationStatus()
            notificationPreferences.systemEnabled = authStatus == .authorized
            
            // Load coach persona
            try await loadCoachPersona()
            
            // Export history is already loaded from user
            
        } catch {
            handleError(error)
            AppLogger.error("Failed to load settings", error: error, category: .general)
        }
    }
    
    // MARK: - Preference Updates
    func updateUnits(_ units: MeasurementSystem) async throws {
        preferredUnits = units
        user.updatePreferredUnits(units)
        try modelContext.save()
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .unitsChanged,
            object: nil,
            userInfo: ["units": units]
        )
    }
    
    func updateAppearance(_ mode: AppearanceMode) async throws {
        appearanceMode = mode
        user.appearanceMode = mode
        try modelContext.save()
        
        // Update app appearance
        await MainActor.run {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            switch mode {
            case .light:
                window?.overrideUserInterfaceStyle = .light
            case .dark:
                window?.overrideUserInterfaceStyle = .dark
            case .system:
                window?.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    func updateHaptics(_ enabled: Bool) async throws {
        hapticFeedback = enabled
        user.hapticFeedbackEnabled = enabled
        try modelContext.save()
    }
    
    func updateAnalytics(_ enabled: Bool) async throws {
        analyticsEnabled = enabled
        user.analyticsEnabled = enabled
        try modelContext.save()
    }
    
    // MARK: - AI Configuration
    func updateAIProvider(_ provider: AIProvider, model: String) async throws {
        // Verify API key exists
        guard await hasAPIKey(for: provider) else {
            throw SettingsError.missingAPIKey(provider)
        }
        
        // Update selection
        selectedProvider = provider
        selectedModel = model
        user.selectedAIProvider = provider
        user.selectedAIModel = model
        try modelContext.save()
        
        // Configure AI service
        let apiKey = try await getAPIKey(for: provider)
        try await aiService.configure(provider: provider, apiKey: apiKey, model: model)
        
        AppLogger.info("AI provider updated to \(provider.displayName)", category: .general)
    }
    
    func saveAPIKey(_ key: String, for provider: AIProvider) async throws {
        // Validate key format
        guard isValidAPIKey(key, for: provider) else {
            throw SettingsError.invalidAPIKey
        }
        
        // Test key with provider
        let isValid = try await testAPIKey(key, provider: provider)
        guard isValid else {
            throw SettingsError.apiKeyTestFailed
        }
        
        // Save to keychain
        try await apiKeyManager.saveAPIKey(key, for: provider)
        installedAPIKeys.insert(provider)
        
        // If this is the selected provider, reconfigure
        if provider == selectedProvider {
            try await aiService.configure(provider: provider, apiKey: key, model: selectedModel)
        }
    }
    
    func deleteAPIKey(for provider: AIProvider) async throws {
        try await apiKeyManager.deleteAPIKey(for: provider)
        installedAPIKeys.remove(provider)
        
        // If deleting current provider's key, switch to another
        if provider == selectedProvider {
            if let alternativeProvider = installedAPIKeys.first {
                try await updateAIProvider(alternativeProvider, model: alternativeProvider.defaultModel)
            }
        }
    }
    
    // MARK: - Notification Preferences
    func updateNotificationPreferences(_ prefs: NotificationPreferences) async throws {
        notificationPreferences = prefs
        user.notificationPreferences = prefs
        try modelContext.save()
        
        // Update notification manager
        await notificationManager.updatePreferences(prefs)
    }
    
    func updateQuietHours(_ hours: QuietHours) async throws {
        quietHours = hours
        user.quietHours = hours
        try modelContext.save()
        
        // Reschedule notifications
        await notificationManager.rescheduleWithQuietHours(hours)
    }
    
    func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Privacy & Security
    func updateBiometricLock(_ enabled: Bool) async throws {
        // Verify biometric availability
        if enabled {
            let biometricManager = BiometricAuthManager()
            guard biometricManager.canUseBiometrics else {
                throw SettingsError.biometricsNotAvailable
            }
        }
        
        biometricLockEnabled = enabled
        user.biometricLockEnabled = enabled
        try modelContext.save()
    }
    
    // MARK: - Data Management
    func exportUserData() async throws -> URL {
        isLoading = true
        defer { isLoading = false }
        
        let exporter = UserDataExporter(modelContext: modelContext)
        let exportURL = try await exporter.exportAllData(for: user)
        
        // Record export
        let export = DataExport(
            date: Date(),
            size: try FileManager.default.attributesOfItem(atPath: exportURL.path)[.size] as? Int64 ?? 0,
            format: .json
        )
        user.dataExports.append(export)
        exportHistory = user.dataExports
        try modelContext.save()
        
        return exportURL
    }
    
    func deleteAllData() async throws {
        // Show confirmation first
        coordinator.showAlert(.confirmDelete {
            Task {
                try await self.performDataDeletion()
            }
        })
    }
    
    private func performDataDeletion() async throws {
        // Delete all user data
        // This would typically involve:
        // 1. Deleting all related entities
        // 2. Clearing keychain
        // 3. Resetting user defaults
        // 4. Signing out
        
        AppLogger.info("User data deletion requested", category: .general)
    }
    
    // MARK: - Demo Mode
    func setDemoMode(_ enabled: Bool) async {
        isDemoModeEnabled = enabled
        AppConstants.Configuration.isUsingDemoMode = enabled
        
        // Show alert to inform user about the change
        if enabled {
            coordinator.showAlert(.demoModeEnabled)
        } else {
            coordinator.showAlert(.demoModeDisabled)
        }
    }
    
    // MARK: - Helper Methods
    private func hasAPIKey(for provider: AIProvider) async -> Bool {
        return await apiKeyManager.hasAPIKey(for: provider)
    }
    
    private func getAPIKey(for provider: AIProvider) async throws -> String {
        return try await apiKeyManager.getAPIKey(for: provider)
    }
    
    private func isValidAPIKey(_ key: String, for provider: AIProvider) -> Bool {
        switch provider {
        case .openAI:
            return key.hasPrefix("sk-") && key.count > 20
        case .anthropic:
            return key.hasPrefix("sk-ant-") && key.count > 20
        case .gemini:
            return key.count > 20 // Google uses various formats
        }
    }
    
    private func testAPIKey(_ key: String, provider: AIProvider) async throws -> Bool {
        // Create a simple test request
        let testMessages = [
            AIChatMessage(role: .user, content: "Hello")
        ]
        
        let testRequest = AIRequest(
            systemPrompt: "You are a test assistant.",
            messages: testMessages,
            temperature: 0.7,
            user: "test"
        )
        
        // Configure service temporarily
        try await aiService.configure(provider: provider, apiKey: key, model: provider.defaultModel)
        
        // Try to get a response
        do {
            // Test the request
            for try await _ in aiService.sendRequest(testRequest) {
                // Just need to see if it works
                break
            }
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Persona Methods
    func loadCoachPersona() async throws {
        // Load synthesized persona from user's coach configuration
        if let personaData = user.coachPersonaData {
            coachPersona = try JSONDecoder().decode(CoachPersona.self, from: personaData)
            personaUniquenessScore = coachPersona?.uniquenessScore ?? 0
        }
    }
    
    func generatePersonaPreview(scenario: PreviewScenario) async throws -> String {
        guard let persona = coachPersona else {
            throw SettingsError.personaNotConfigured
        }
        
        // Create a contextual prompt for the preview
        let systemPrompt = """
        You are \(persona.identity.name), a fitness coach with this personality:
        \(persona.systemPrompt)
        
        Generate a brief response (2-3 sentences) for the following scenario: \(scenario)
        Be authentic to your personality and coaching style.
        """
        
        let request = AIRequest(
            systemPrompt: systemPrompt,
            messages: [AIChatMessage(role: .user, content: "Generate preview")],
            temperature: 0.8,
            maxTokens: 100,
            user: user.id.uuidString
        )
        
        // Get response from AI service
        var responseText = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                responseText = text
            case .textDelta(let delta):
                responseText += delta
            default:
                break
            }
        }
        if !responseText.isEmpty {
            return responseText
        }
        
        return "Let's make today count! Ready to push your limits?"
    }
    
    func applyNaturalLanguageAdjustment(_ adjustmentText: String) async throws {
        guard let currentPersona = coachPersona else {
            throw SettingsError.personaNotConfigured
        }
        
        // Create adjustment request
        let systemPrompt = """
        You are a persona adjustment system. Take the current coach persona and apply the following adjustment:
        "\(adjustmentText)"
        
        Return only the adjusted persona description, maintaining the same structure but incorporating the requested changes.
        """
        
        let currentPersonaJSON = try JSONEncoder().encode(currentPersona)
        let currentPersonaString = String(data: currentPersonaJSON, encoding: .utf8) ?? "{}"
        
        let request = AIRequest(
            systemPrompt: systemPrompt,
            messages: [
                AIChatMessage(role: .user, content: "Current persona: \(currentPersonaString)")
            ],
            temperature: 0.7,
            user: user.id.uuidString
        )
        
        // Get response from AI service
        var responseText = ""
        for try await chunk in aiService.sendRequest(request) {
            switch chunk {
            case .text(let text):
                responseText = text
            case .textDelta(let delta):
                responseText += delta
            default:
                break
            }
        }
        // Parse and save the adjusted persona
        if !responseText.isEmpty,
           let adjustedData = responseText.data(using: .utf8),
           let adjustedPersona = try? JSONDecoder().decode(CoachPersona.self, from: adjustedData) {
            
            coachPersona = adjustedPersona
            user.coachPersonaData = adjustedData
            try modelContext.save()
            
            // Track evolution
            await trackPersonaAdjustment(
                type: .naturalLanguage,
                description: adjustmentText,
                impact: adjustedPersona.calculateDifference(from: currentPersona)
            )
        } else {
            throw SettingsError.personaAdjustmentFailed("Failed to parse adjusted persona")
        }
    }
    
    private func trackPersonaAdjustment(type: PersonaAdaptation.AdaptationType, description: String, impact: Double) async {
        let adaptation = PersonaAdaptation(
            date: Date(),
            type: type,
            description: description,
            icon: type == .naturalLanguage ? "text.quote" : "sparkles"
        )
        
        personaEvolution.recentAdaptations.append(adaptation)
        if personaEvolution.recentAdaptations.count > 10 {
            personaEvolution.recentAdaptations.removeFirst()
        }
        
        personaEvolution.adaptationLevel = min(personaEvolution.adaptationLevel + 1, 5)
        personaEvolution.lastUpdateDate = Date()
    }
}

// MARK: - Array async extensions
extension Array {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var results: [T] = []
        for element in self {
            if let transformed = await transform(element) {
                results.append(transformed)
            }
        }
        return results
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let unitsChanged = Notification.Name("unitsChanged")
    static let themeChanged = Notification.Name("themeChanged")
}
