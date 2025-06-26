import UIKit

/// Standardized haptic patterns for consistent user feedback
enum HapticPattern: CaseIterable {
    // UI Interactions
    case buttonTap
    case listSelection
    case toggle
    case swipe
    case longPress

    // State Changes
    case success
    case error
    case warning
    case refresh

    // Navigation
    case navigationPush
    case navigationPop
    case tabSwitch

    // Data Operations
    case dataAdded
    case dataDeleted
    case dataUpdated

    // Special Effects
    case levelUp
    case milestone
    case bounce

    /// Convert pattern to appropriate haptic feedback
    var feedbackComponents: [(type: HapticFeedbackType, intensity: Float, delay: TimeInterval)] {
        switch self {
        case .buttonTap:
            return [(.impact(.light), 1.0, 0)]
        case .listSelection:
            return [(.selection, 1.0, 0)]
        case .toggle:
            return [(.impact(.medium), 0.8, 0)]
        case .swipe:
            return [(.impact(.light), 0.6, 0)]
        case .longPress:
            return [(.impact(.heavy), 1.0, 0)]

        case .success:
            return [(.notification(.success), 1.0, 0)]
        case .error:
            return [(.notification(.error), 1.0, 0)]
        case .warning:
            return [(.notification(.warning), 1.0, 0)]
        case .refresh:
            return [(.impact(.light), 0.5, 0), (.impact(.light), 0.5, 0.1)]

        case .navigationPush:
            return [(.impact(.light), 0.7, 0)]
        case .navigationPop:
            return [(.impact(.light), 0.5, 0)]
        case .tabSwitch:
            return [(.selection, 0.8, 0)]

        case .dataAdded:
            return [(.impact(.medium), 0.9, 0), (.notification(.success), 0.7, 0.15)]
        case .dataDeleted:
            return [(.impact(.medium), 1.0, 0)]
        case .dataUpdated:
            return [(.impact(.light), 0.6, 0)]

        case .levelUp:
            return [
                (.impact(.light), 0.8, 0),
                (.impact(.medium), 0.9, 0.1),
                (.impact(.heavy), 1.0, 0.2),
                (.notification(.success), 1.0, 0.3)
            ]
        case .milestone:
            return [(.notification(.success), 1.0, 0), (.impact(.medium), 0.8, 0.2)]
        case .bounce:
            return [(.impact(.light), 0.6, 0), (.impact(.light), 0.4, 0.15)]
        }
    }
}

/// Type of haptic feedback
enum HapticFeedbackType {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
    case selection
}

/// Protocol for haptic feedback services
protocol HapticServiceProtocol: ServiceProtocol {
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) async
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) async
    func selection() async
    func success() async
    func error() async
    func play(_ pattern: HapticPattern, intensityMultiplier: Float) async
}

/// Manages haptic feedback throughout the app
@MainActor
final class HapticService: HapticServiceProtocol {
    // MARK: - Properties
    private let impactFeedback = UIImpactFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // MARK: - ServiceProtocol
    nonisolated var isConfigured: Bool { true }
    nonisolated var serviceIdentifier: String { "HapticService" }

    init() async {
        prepareGenerators()
    }

    func configure() async throws {
        // Haptics are always ready on iOS
    }

    func reset() async {
        // Nothing to reset for simple haptics
    }

    func healthCheck() async -> ServiceHealth {
        ServiceHealth(
            status: .healthy,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: ["available": "true"]
        )
    }

    // MARK: - HapticServiceProtocol Methods

    /// Play impact haptic feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) async {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Play notification haptic feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) async {
        notificationFeedback.notificationOccurred(type)
    }

    /// Play selection haptic feedback
    func selection() async {
        selectionFeedback.selectionChanged()
    }

    /// Play success haptic feedback (notification style)
    func success() async {
        notificationFeedback.notificationOccurred(.success)
    }

    /// Play error haptic feedback (notification style)
    func error() async {
        notificationFeedback.notificationOccurred(.error)
    }

    /// Play a haptic pattern with optional intensity multiplier
    func play(_ pattern: HapticPattern, intensityMultiplier: Float = 1.0) async {
        let components = pattern.feedbackComponents

        for (index, component) in components.enumerated() {
            // Apply delay if not the first component
            if component.delay > 0 && index > 0 {
                try? await Task.sleep(nanoseconds: UInt64(component.delay * 1_000_000_000))
            }

            let adjustedIntensity = min(component.intensity * intensityMultiplier, 1.0)

            switch component.type {
            case .impact(let style):
                playImpact(style, intensity: adjustedIntensity)
            case .notification(let type):
                playNotification(type, intensity: adjustedIntensity)
            case .selection:
                playSelection(intensity: adjustedIntensity)
            }
        }
    }

    // MARK: - Private Methods

    private func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: Float) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: CGFloat(intensity))
    }

    private func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType, intensity: Float) {
        // UINotificationFeedbackGenerator doesn't support intensity, but we prepare based on it
        if intensity > 0.5 {
            notificationFeedback.notificationOccurred(type)
        }
    }

    private func playSelection(intensity: Float) {
        // UISelectionFeedbackGenerator doesn't support intensity, but we prepare based on it
        if intensity > 0.3 {
            selectionFeedback.selectionChanged()
        }
    }

    private func prepareGenerators() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
}

// MARK: - Static Convenience for UI Components
extension HapticService {
    /// Quick haptic feedback for UI components
    /// Note: This creates a temporary generator for one-off haptics
    @MainActor
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    @MainActor
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    @MainActor
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    /// Play a haptic pattern without needing a service instance
    @MainActor
    static func play(_ pattern: HapticPattern, intensityMultiplier: Float = 1.0) {
        Task {
            let components = pattern.feedbackComponents

            for (index, component) in components.enumerated() {
                // Apply delay if not the first component
                if component.delay > 0 && index > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(component.delay * 1_000_000_000))
                }

                let adjustedIntensity = min(component.intensity * intensityMultiplier, 1.0)

                switch component.type {
                case .impact(let style):
                    let generator = UIImpactFeedbackGenerator(style: style)
                    generator.prepare()
                    generator.impactOccurred(intensity: CGFloat(adjustedIntensity))
                case .notification(let type):
                    if adjustedIntensity > 0.5 {
                        let generator = UINotificationFeedbackGenerator()
                        generator.prepare()
                        generator.notificationOccurred(type)
                    }
                case .selection:
                    if adjustedIntensity > 0.3 {
                        let generator = UISelectionFeedbackGenerator()
                        generator.prepare()
                        generator.selectionChanged()
                    }
                }
            }
        }
    }
}
