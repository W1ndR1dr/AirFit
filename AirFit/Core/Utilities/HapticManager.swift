import CoreHaptics
import UIKit

/// Manages haptic feedback throughout the app
@MainActor
final class HapticManager {
    // MARK: - Singleton
    static let shared = HapticManager()

    // MARK: - Properties
    private var engine: CHHapticEngine?
    private let impactFeedback = UIImpactFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // MARK: - Initialization
    private init() {
        setupHapticEngine()
        prepareGenerators()
    }

    // MARK: - Public Methods

    /// Play impact haptic feedback
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        Task { @MainActor in
            shared.impactFeedback.impactOccurred(intensity: style.intensity)
        }
    }

    /// Play notification haptic feedback
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        Task { @MainActor in
            shared.notificationFeedback.notificationOccurred(type)
        }
    }

    /// Play selection haptic feedback
    static func selection() {
        Task { @MainActor in
            shared.selectionFeedback.selectionChanged()
        }
    }

    // MARK: - Private Methods

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            AppLogger.info("Device does not support haptics", category: .ui)
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    do {
                        try self?.engine?.start()
                    } catch {
                        AppLogger.error("Failed to restart haptic engine", error: error, category: .ui)
                    }
                }
            }
        } catch {
            AppLogger.error("Failed to setup haptic engine", error: error, category: .ui)
        }
    }

    private func prepareGenerators() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
}

// MARK: - Extensions
private extension UIImpactFeedbackGenerator.FeedbackStyle {
    var intensity: CGFloat {
        switch self {
        case .light: return 0.5
        case .medium: return 0.7
        case .heavy: return 1.0
        case .soft: return 0.4
        case .rigid: return 0.9
        @unknown default: return 0.7
        }
    }
}
