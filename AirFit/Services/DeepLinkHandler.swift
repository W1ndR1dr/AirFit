import Foundation
import SwiftUI

/// Handles deep links from widgets and other sources.
/// URL scheme: airfit://
///
/// Supported paths:
/// - airfit://log/voice - Open voice food logging
/// - airfit://log/camera - Open camera food logging
/// - airfit://nutrition - Open nutrition tab
/// - airfit://dashboard - Open dashboard tab
/// - airfit://coach - Open coach/chat tab
/// - airfit://insights - Open insights tab
/// - airfit://insights/{id} - Open specific insight
/// - airfit://profile - Open profile tab
/// - airfit://sync/hevy - Trigger Hevy sync
/// - airfit://toggle-training-day/{true|false} - Toggle training day mode
/// - airfit://morning - Context: morning brief
/// - airfit://preWorkout - Context: pre-workout
/// - airfit://postWorkout - Context: post-workout
/// - airfit://afternoon - Context: afternoon
/// - airfit://evening - Context: evening
/// - airfit://night - Context: night insights
@MainActor
final class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    // Published state for triggering UI actions
    @Published var showVoiceInput = false
    @Published var showCameraInput = false
    @Published var selectedInsightId: String?
    @Published var pendingAction: DeepLinkAction?

    enum DeepLinkAction: Equatable {
        case openTab(Int)
        case openVoiceLog
        case openCameraLog
        case openInsight(String)
        case syncHevy
        case toggleTrainingDay(Bool)
    }

    private init() {}

    /// Handle an incoming URL.
    /// Returns true if the URL was handled.
    @discardableResult
    func handle(_ url: URL) -> Bool {
        guard url.scheme == "airfit" else { return false }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        print("[DeepLink] Handling: \(url.absoluteString)")

        switch host {
        case "log":
            return handleLog(pathComponents: pathComponents)

        case "nutrition":
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true

        case "dashboard":
            NotificationCenter.default.post(name: .openDashboardTab, object: nil)
            return true

        case "coach":
            NotificationCenter.default.post(name: .openCoachTab, object: nil)
            return true

        case "insights":
            if let insightId = pathComponents.first {
                selectedInsightId = insightId
            }
            NotificationCenter.default.post(name: .openInsightsTab, object: nil)
            return true

        case "profile":
            NotificationCenter.default.post(name: .openProfileTab, object: nil)
            return true

        case "sync":
            return handleSync(pathComponents: pathComponents)

        case "toggle-training-day":
            if let valueStr = pathComponents.first, let value = Bool(valueStr) {
                handleTrainingDayToggle(isTrainingDay: value)
                return true
            }
            return false

        // Context-based navigation (from MorningBrief widget)
        case "morning":
            showVoiceInput = true
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true

        case "preWorkout":
            NotificationCenter.default.post(name: .openDashboardTab, object: nil)
            return true

        case "postWorkout":
            handleSync(pathComponents: ["hevy"])
            NotificationCenter.default.post(name: .openDashboardTab, object: nil)
            return true

        case "afternoon":
            showVoiceInput = true
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true

        case "evening":
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true

        case "night":
            NotificationCenter.default.post(name: .openInsightsTab, object: nil)
            return true

        case "training":
            NotificationCenter.default.post(name: .openDashboardTab, object: nil)
            return true

        default:
            print("[DeepLink] Unknown host: \(host)")
            return false
        }
    }

    private func handleLog(pathComponents: [String]) -> Bool {
        guard let mode = pathComponents.first else {
            // Default to voice
            showVoiceInput = true
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true
        }

        switch mode {
        case "voice":
            showVoiceInput = true
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true

        case "camera":
            showCameraInput = true
            NotificationCenter.default.post(name: .openNutritionTab, object: nil)
            return true

        default:
            return false
        }
    }

    @discardableResult
    private func handleSync(pathComponents: [String]) -> Bool {
        guard let target = pathComponents.first else { return false }

        switch target {
        case "hevy":
            // Trigger Hevy sync
            NotificationCenter.default.post(name: .triggerHevySync, object: nil)
            return true

        default:
            return false
        }
    }

    private func handleTrainingDayToggle(isTrainingDay: Bool) {
        // Post notification to toggle training day
        // The NutritionView will handle this
        NotificationCenter.default.post(
            name: .toggleTrainingDay,
            object: nil,
            userInfo: ["isTrainingDay": isTrainingDay]
        )

        // Also update widgets immediately
        Task {
            await WidgetSyncService.shared.updateContextBasedOnTime(
                isTrainingDay: isTrainingDay,
                hasWorkoutToday: false
            )
        }
    }

    /// Reset transient state after handling
    func clearState() {
        showVoiceInput = false
        showCameraInput = false
        selectedInsightId = nil
        pendingAction = nil
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let triggerHevySync = Notification.Name("triggerHevySync")
    static let toggleTrainingDay = Notification.Name("toggleTrainingDay")
    static let insightsGenerated = Notification.Name("insightsGenerated")
}
