import Foundation

// MARK: - Measurement System
enum MeasurementSystem: String, Codable, CaseIterable, Identifiable {
    case imperial
    case metric
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .imperial: return "Imperial (US)"
        case .metric: return "Metric"
        }
    }
    
    var description: String {
        switch self {
        case .imperial: return "Pounds, feet, miles, Fahrenheit"
        case .metric: return "Kilograms, meters, kilometers, Celsius"
        }
    }
}

// MARK: - Appearance Mode
enum AppearanceMode: String, Codable, CaseIterable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

// MARK: - NotificationPreferences is defined in Modules/Notifications/Models/NotificationModels.swift

// MARK: - Quiet Hours
struct QuietHours: Codable, Equatable {
    var enabled: Bool = false
    var startTime: Date
    var endTime: Date
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        
        // Default quiet hours: 10 PM to 7 AM
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = 22
        startComponents.minute = 0
        self.startTime = calendar.date(from: startComponents) ?? now
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = 7
        endComponents.minute = 0
        self.endTime = calendar.date(from: endComponents) ?? now
    }
}

// MARK: - Data Export
struct DataExport: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let size: Int64
    let format: ExportFormat
    
    enum ExportFormat: String, Codable {
        case json
        case csv
    }
}

// MARK: - Persona Evolution
struct PersonaEvolutionTracker {
    var adaptationLevel: Int = 0
    var lastUpdateDate: Date = Date()
    var recentAdaptations: [PersonaAdaptation] = []
    
    init(user: User) {
        // Initialize from user data if available
        self.lastUpdateDate = user.lastActiveAt ?? Date()
    }
}

struct PersonaAdaptation: Identifiable {
    let id = UUID()
    let date: Date
    let type: AdaptationType
    let description: String
    let icon: String
    
    enum AdaptationType {
        case naturalLanguage
        case behaviorLearning
        case feedbackBased
    }
}

// MARK: - Preview Scenario
enum PreviewScenario {
    case morningGreeting
    case workoutMotivation
    case nutritionGuidance
    case recoveryCheck
    case goalSetting
    
    static func randomScenario() -> PreviewScenario {
        let scenarios: [PreviewScenario] = [
            .morningGreeting,
            .workoutMotivation,
            .nutritionGuidance,
            .recoveryCheck,
            .goalSetting
        ]
        return scenarios.randomElement() ?? .morningGreeting
    }
}

// MARK: - Persona Preview Request
struct PersonaPreviewRequest {
    let persona: CoachPersona
    let scenario: PreviewScenario
    let userContext: String?
}

// MARK: - Settings Error
enum SettingsError: LocalizedError {
    case missingAPIKey(AIProvider)
    case invalidAPIKey
    case apiKeyTestFailed
    case biometricsNotAvailable
    case exportFailed(String)
    case personaNotConfigured
    case personaAdjustmentFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "Please add an API key for \(provider.displayName)"
        case .invalidAPIKey:
            return "Invalid API key format"
        case .apiKeyTestFailed:
            return "API key validation failed. Please check your key."
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .personaNotConfigured:
            return "Coach persona not configured. Please complete onboarding."
        case .personaAdjustmentFailed(let reason):
            return "Failed to adjust persona: \(reason)"
        }
    }
}

// MARK: - Settings Destination
enum SettingsDestination: Hashable {
    case aiPersona
    case apiConfiguration
    case notifications
    case privacy
    case appearance
    case units
    case dataManagement
    case about
    case debug
}
