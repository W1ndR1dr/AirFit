import Foundation

/// Protocol for formatting health context into LLM-optimized text
/// Provides concurrency-safe abstraction over ContextSerializer actor
protocol ContextFormattingProtocol: Sendable {
    /// Serializes health context with configurable detail levels
    func serializeContext(
        _ healthContext: HealthContextSnapshot,
        detailLevel: ContextFormattingDetailLevel,
        focusArea: String?
    ) async -> String

    /// Quick context for simple responses - optimized for token efficiency
    func serializeQuickContext(_ healthContext: HealthContextSnapshot) async -> String

    /// Workout-optimized context for AI workout generation
    func serializeWorkoutContext(
        _ healthContext: HealthContextSnapshot,
        workoutType: String?
    ) async -> String
}

/// Detail levels for context formatting with token optimization
enum ContextFormattingDetailLevel: Sendable {
    case minimal    // ~50 tokens - basic stats only
    case standard   // ~150 tokens - patterns and trends
    case detailed   // ~300 tokens - full coaching context
    case workout    // ~400 tokens - optimized for workout generation
}

/// Main Actor wrapper for ContextSerializer actor
/// Bridges actor isolation boundaries for @MainActor services
@MainActor
final class MainActorContextFormatter: ContextFormattingProtocol {
    private let contextSerializer: ContextSerializer

    init(contextSerializer: ContextSerializer) {
        self.contextSerializer = contextSerializer
    }

    func serializeContext(
        _ healthContext: HealthContextSnapshot,
        detailLevel: ContextFormattingDetailLevel,
        focusArea: String? = nil
    ) async -> String {
        // Convert protocol enum to internal enum
        let internalDetailLevel: ContextSerializer.DetailLevel
        switch detailLevel {
        case .minimal:
            internalDetailLevel = .minimal
        case .standard:
            internalDetailLevel = .standard
        case .detailed:
            internalDetailLevel = .detailed
        case .workout:
            internalDetailLevel = .workout
        }

        return await contextSerializer.serializeContext(
            healthContext,
            detailLevel: internalDetailLevel,
            focusArea: focusArea
        )
    }

    func serializeQuickContext(_ healthContext: HealthContextSnapshot) async -> String {
        return await contextSerializer.serializeQuickContext(healthContext)
    }

    func serializeWorkoutContext(
        _ healthContext: HealthContextSnapshot,
        workoutType: String? = nil
    ) async -> String {
        return await contextSerializer.serializeWorkoutContext(
            healthContext,
            workoutType: workoutType
        )
    }
}
