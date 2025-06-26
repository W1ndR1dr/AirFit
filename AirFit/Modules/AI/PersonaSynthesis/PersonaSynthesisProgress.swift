import Foundation

/// Real-time progress tracking for persona synthesis
public enum PersonaSynthesisPhase: String, CaseIterable, Sendable {
    case preparing = "Preparing synthesis..."
    case analyzingPersonality = "Analyzing your personality..."
    case understandingGoals = "Understanding your goals..."
    case craftingVoice = "Crafting your unique voice..."
    case buildingStrategies = "Building coaching strategies..."
    case generatingContent = "Generating personalized content..."
    case finalizing = "Finalizing your experience..."

    var displayName: String { rawValue }

    var progressRange: ClosedRange<Double> {
        switch self {
        case .preparing: return 0.0...0.05
        case .analyzingPersonality: return 0.05...0.20
        case .understandingGoals: return 0.20...0.35
        case .craftingVoice: return 0.35...0.55
        case .buildingStrategies: return 0.55...0.75
        case .generatingContent: return 0.75...0.95
        case .finalizing: return 0.95...1.0
        }
    }
}

/// Progress update for persona synthesis
public struct PersonaSynthesisProgress: Sendable {
    public let phase: PersonaSynthesisPhase
    public let progress: Double // 0.0 to 1.0
    public let message: String?
    public let isComplete: Bool

    public init(
        phase: PersonaSynthesisPhase,
        progress: Double,
        message: String? = nil,
        isComplete: Bool = false
    ) {
        self.phase = phase
        self.progress = min(1.0, max(0.0, progress))
        self.message = message
        self.isComplete = isComplete
    }
}

/// Protocol for progress reporting
public protocol PersonaSynthesisProgressReporting: Sendable {
    func reportProgress(_ progress: PersonaSynthesisProgress) async
}

/// AsyncStream-based progress reporter
public actor PersonaSynthesisProgressReporter: PersonaSynthesisProgressReporting {
    private var continuation: AsyncStream<PersonaSynthesisProgress>.Continuation?

    public func makeProgressStream() -> AsyncStream<PersonaSynthesisProgress> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    public func reportProgress(_ progress: PersonaSynthesisProgress) async {
        continuation?.yield(progress)

        if progress.isComplete {
            continuation?.finish()
        }
    }

    public func cancel() {
        continuation?.finish()
    }
}
