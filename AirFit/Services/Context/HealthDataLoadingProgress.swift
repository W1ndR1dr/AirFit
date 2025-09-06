import Foundation

/// Progress tracking for health data loading with real milestones
public struct HealthDataLoadingProgress: Sendable {
    public enum Stage: String, CaseIterable, Sendable {
        case initializing = "Initializing..."
        case fetchingActivity = "Loading activity data..."
        case fetchingHeart = "Loading heart health data..."
        case fetchingBody = "Loading body metrics..."
        case fetchingSleep = "Loading sleep data..."
        case analyzingTrends = "Analyzing fitness patterns..."
        case assemblingContext = "Personalizing suggestions..."
        case complete = "Complete!"
        
        var weight: Double {
            switch self {
            case .initializing: return 0.05
            case .fetchingActivity: return 0.20
            case .fetchingHeart: return 0.15
            case .fetchingBody: return 0.15
            case .fetchingSleep: return 0.15
            case .analyzingTrends: return 0.20
            case .assemblingContext: return 0.10
            case .complete: return 0.0
            }
        }
        
        var cumulativeProgress: Double {
            let allCases = Stage.allCases
            guard let index = allCases.firstIndex(of: self) else { return 0.0 }
            
            var total = 0.0
            for i in 0..<index {
                total += allCases[i].weight
            }
            return total
        }
    }
    
    public let stage: Stage
    public let progress: Double
    public let message: String
    public let error: Error?
    
    public init(stage: Stage, subProgress: Double = 0.0, error: Error? = nil) {
        self.stage = stage
        self.message = stage.rawValue
        self.error = error
        
        // Calculate overall progress based on stage and sub-progress
        let baseProgress = stage.cumulativeProgress
        let stageProgress = stage.weight * min(1.0, max(0.0, subProgress))
        self.progress = min(1.0, baseProgress + stageProgress)
    }
    
    public static let initial = HealthDataLoadingProgress(stage: .initializing)
    public static let complete = HealthDataLoadingProgress(stage: .complete, subProgress: 1.0)
}

/// Protocol for reporting health data loading progress
public protocol HealthDataLoadingProgressReporting: Sendable {
    func reportProgress(_ progress: HealthDataLoadingProgress) async
}

/// Actor that manages progress reporting via AsyncStream
public actor HealthDataLoadingProgressReporter: HealthDataLoadingProgressReporting {
    private var continuation: AsyncStream<HealthDataLoadingProgress>.Continuation?
    
    public func makeProgressStream() -> AsyncStream<HealthDataLoadingProgress> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(.initial)
        }
    }
    
    public func reportProgress(_ progress: HealthDataLoadingProgress) async {
        continuation?.yield(progress)
        
        if progress.stage == .complete || progress.error != nil {
            continuation?.finish()
        }
    }
    
    public func cancel() {
        continuation?.finish()
        continuation = nil
    }
}