import UIKit

/// Protocol for haptic feedback services
protocol HapticServiceProtocol: ServiceProtocol {
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) async
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) async
    func selection() async
    func success() async
    func error() async
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

    // MARK: - Private Methods

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
}


