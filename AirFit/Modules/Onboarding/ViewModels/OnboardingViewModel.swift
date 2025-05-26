import Foundation
import SwiftData
import Observation
import Combine

// MARK: - HealthKit Prefill Protocol
protocol HealthKitPrefillProviding: AnyObject, Sendable {
    func fetchTypicalSleepWindow() async throws -> (bed: Date, wake: Date)?
}

// MARK: - ViewModel
@MainActor
@Observable
final class OnboardingViewModel {
    // MARK: - Navigation State
    private(set) var currentScreen: OnboardingScreen = .openingScreen
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Collected Data
    var lifeContext = LifeContext()
    var goal = Goal()
    private(set) var structuredGoal: StructuredGoal?
    var blend = Blend()
    var engagementPreferences = EngagementPreferences()
    var sleepWindow = SleepWindow()
    var motivationalStyle = MotivationalStyle()
    var timezone: String = TimeZone.current.identifier
    var baselineModeEnabled = true

    // MARK: - Voice Input
    private(set) var isTranscribing = false

    // MARK: - HealthKit Integration
    var hasHealthKitIntegration: Bool {
        healthPrefillProvider != nil
    }

    // MARK: - Dependencies
    private let aiService: AIServiceProtocol
    private let onboardingService: OnboardingServiceProtocol
    private let modelContext: ModelContext
    private let speechService: WhisperServiceWrapperProtocol?
    private let healthPrefillProvider: HealthKitPrefillProviding?

    // MARK: - Initialization
    init(
        aiService: AIServiceProtocol,
        onboardingService: OnboardingServiceProtocol,
        modelContext: ModelContext,
        speechService: WhisperServiceWrapperProtocol? = nil,
        healthPrefillProvider: HealthKitPrefillProviding? = nil
    ) {
        self.aiService = aiService
        self.onboardingService = onboardingService
        self.modelContext = modelContext
        self.speechService = speechService
        self.healthPrefillProvider = healthPrefillProvider

        Task { await prefillFromHealthKit() }
    }

    // MARK: - Navigation
    func navigateToNextScreen() {
        guard let index = OnboardingScreen.allCases.firstIndex(of: currentScreen),
              index < OnboardingScreen.allCases.count - 1 else { return }
        currentScreen = OnboardingScreen.allCases[index + 1]
        AppLogger.info("Navigated to \(currentScreen)", category: .onboarding)
    }

    func navigateToPreviousScreen() {
        guard let index = OnboardingScreen.allCases.firstIndex(of: currentScreen),
              index > 0 else { return }
        currentScreen = OnboardingScreen.allCases[index - 1]
        AppLogger.info("Navigated back to \(currentScreen)", category: .onboarding)
    }

    // MARK: - Voice Input
    func startVoiceCapture() {
        guard let speechService else { return }
        speechService.requestPermission { [weak self] granted in
            guard let self else { return }
            guard granted else { return }
            self.isTranscribing = true
            speechService.startTranscription { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    switch result {
                    case .success(let transcript):
                        self.goal.rawText = transcript
                    case .failure(let error):
                        self.error = error
                        AppLogger.error("Voice transcription failed", error: error, category: .onboarding)
                    }
                }
            }
        }
    }

    func stopVoiceCapture() {
        speechService?.stopTranscription()
        isTranscribing = false
    }

    // MARK: - Business Logic
    func analyzeGoalText() async {
        guard !goal.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            structuredGoal = try await aiService.analyzeGoal(goal.rawText)
            AppLogger.info("Goal analysis completed", category: .ai)
        } catch {
            self.error = error
            AppLogger.error("Goal analysis failed", error: error, category: .ai)
        }
    }

    func completeOnboarding() async throws {
        isLoading = true
        defer { isLoading = false }

        let profileBlob = buildUserProfile()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(profileBlob)

        let profile = OnboardingProfile(
            personaPromptData: data,
            communicationPreferencesData: data,
            rawFullProfileData: data
        )
        modelContext.insert(profile)
        try await onboardingService.saveProfile(profile)
        try modelContext.save()

        AppLogger.info("Onboarding completed", category: .onboarding)
    }

    func validateBlend() {
        blend.normalize()
    }

    // MARK: - Private Helpers
    private func prefillFromHealthKit() async {
        guard let provider = healthPrefillProvider else { return }
        do {
            if let window = try await provider.fetchTypicalSleepWindow() {
                sleepWindow.bedTime = Self.formatTime(window.bed)
                sleepWindow.wakeTime = Self.formatTime(window.wake)
            }
        } catch {
            AppLogger.error("HealthKit prefill failed", error: error, category: .health)
        }
    }

    private func buildUserProfile() -> UserProfileJsonBlob {
        UserProfileJsonBlob(
            lifeContext: lifeContext,
            goal: goal,
            blend: blend,
            engagementPreferences: engagementPreferences,
            sleepWindow: sleepWindow,
            motivationalStyle: motivationalStyle,
            timezone: timezone,
            baselineModeEnabled: baselineModeEnabled
        )
    }

    private static func formatTime(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = comps.hour ?? 0
        let minute = comps.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}
