import Foundation
import SwiftData

// MARK: - User Settings Extensions
extension User {
    // MARK: - Settings Properties (Transient - stored in UserDefaults)

    /// Appearance mode preference
    var appearanceMode: AppearanceMode? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey("appearanceMode")) else { return nil }
            return AppearanceMode(rawValue: raw)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value.rawValue, forKey: userDefaultsKey("appearanceMode"))
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey("appearanceMode"))
            }
        }
    }

    /// Haptic feedback enabled
    var hapticFeedbackEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: userDefaultsKey("hapticFeedback")) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey("hapticFeedback"))
        }
    }

    /// Analytics enabled
    var analyticsEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: userDefaultsKey("analytics")) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey("analytics"))
        }
    }

    /// Selected AI provider
    var selectedAIProvider: AIProvider? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey("aiProvider")) else { return nil }
            return AIProvider(rawValue: raw)
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value.rawValue, forKey: userDefaultsKey("aiProvider"))
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey("aiProvider"))
            }
        }
    }

    /// Selected AI model
    var selectedAIModel: String? {
        get {
            UserDefaults.standard.string(forKey: userDefaultsKey("aiModel"))
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: userDefaultsKey("aiModel"))
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey("aiModel"))
            }
        }
    }

    /// Biometric lock enabled
    var biometricLockEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: userDefaultsKey("biometricLock")) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey("biometricLock"))
        }
    }

    /// Coach persona data
    var coachPersonaData: Data? {
        get {
            UserDefaults.standard.data(forKey: userDefaultsKey("coachPersona"))
        }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: userDefaultsKey("coachPersona"))
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey("coachPersona"))
            }
        }
    }

    /// Notification preferences
    var notificationPreferences: NotificationPreferences? {
        get {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey("notificationPrefs")) else { return nil }
            return try? JSONDecoder().decode(NotificationPreferences.self, from: data)
        }
        set {
            if let value = newValue,
               let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey("notificationPrefs"))
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey("notificationPrefs"))
            }
        }
    }

    /// Quiet hours settings
    var quietHours: QuietHours? {
        get {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey("quietHours")) else { return nil }
            return try? JSONDecoder().decode(QuietHours.self, from: data)
        }
        set {
            if let value = newValue,
               let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey("quietHours"))
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey("quietHours"))
            }
        }
    }

    /// Data export history
    var dataExports: [DataExport] {
        get {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey("dataExports")) else { return [] }
            return (try? JSONDecoder().decode([DataExport].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey("dataExports"))
            }
        }
    }

    /// Current context for AI
    var currentContext: String {
        // Build context from recent activity
        let recentWorkouts = getRecentWorkouts(days: 3).count
        let recentMeals = getRecentMeals(days: 1).count
        let todayLog = getTodaysLog()

        var context = "User has logged \(recentWorkouts) workouts in the last 3 days"
        context += " and \(recentMeals) meals today."

        if let mood = todayLog?.mood {
            context += " Current mood: \(mood)."
        }

        if let energy = todayLog?.subjectiveEnergyLevel {
            context += " Energy level: \(energy)/5."
        }

        return context
    }

    // MARK: - Helper Methods

    private func userDefaultsKey(_ key: String) -> String {
        "airfit.user.\(id.uuidString).\(key)"
    }

    /// Update preferred units with proper type
    func updatePreferredUnits(_ system: MeasurementSystem) {
        self.preferredUnits = system.rawValue
    }

    /// Get preferred units as enum
    var preferredUnitsEnum: MeasurementSystem {
        MeasurementSystem(rawValue: preferredUnits) ?? .imperial
    }
}
