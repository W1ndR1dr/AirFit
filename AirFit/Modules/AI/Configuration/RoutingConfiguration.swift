import Foundation

// MARK: - Routing Configuration

/// Configuration for hybrid routing with A/B testing support
@MainActor
@Observable
final class RoutingConfiguration {
    
    // MARK: - Feature Flags
    
    /// Master toggle for hybrid routing system
    private(set) var hybridRoutingEnabled: Bool = true
    
    /// A/B testing percentage for hybrid routing (0.0 to 1.0)
    private(set) var hybridRoutingPercentage: Double = 1.0
    
    /// Force specific routing for testing/debugging
    private(set) var forcedRoute: ProcessingRoute?
    
    /// Performance monitoring enabled
    private(set) var performanceMonitoringEnabled: Bool = true
    
    /// Fallback to function calling on direct AI failures
    private(set) var enableIntelligentFallback: Bool = true
    
    // MARK: - Performance Thresholds
    
    /// Maximum allowed direct AI response time (ms)
    private(set) var directAITimeoutMs: Int = 5_000
    
    /// Token usage threshold for switching to direct AI
    private(set) var tokenEfficiencyThreshold: Int = 500
    
    /// Confidence threshold for nutrition parsing
    private(set) var nutritionConfidenceThreshold: Double = 0.7
    
    // MARK: - A/B Testing
    
    /// Determines if user should receive hybrid routing based on A/B test
    func shouldUseHybridRouting(for userId: UUID) -> Bool {
        guard hybridRoutingEnabled else { return false }
        
        if let forced = forcedRoute {
            AppLogger.info("Using forced routing: \(forced.description)", category: .ai)
            return forced != .functionCalling
        }
        
        // Consistent A/B testing based on user ID hash
        let userHash = abs(userId.hashValue) % 100
        let isInTestGroup = Double(userHash) < (hybridRoutingPercentage * 100)
        
        AppLogger.debug(
            "A/B routing decision for user \(userId.uuidString.prefix(8)): \(isInTestGroup ? "hybrid" : "function-only") (hash: \(userHash), threshold: \(Int(hybridRoutingPercentage * 100)))",
            category: .ai
        )
        
        return isInTestGroup
    }
    
    /// Determines routing strategy for a specific request
    func determineRoutingStrategy(
        userInput: String,
        conversationHistory: [AIChatMessage],
        userContext: UserContextSnapshot,
        userId: UUID
    ) -> RoutingStrategy {
        
        // Check if user is in hybrid routing A/B test
        let useHybridRouting = shouldUseHybridRouting(for: userId)
        
        if !useHybridRouting {
            return RoutingStrategy(
                route: .functionCalling,
                reason: "A/B test control group - function calling only",
                fallbackEnabled: false
            )
        }
        
        // Use context analyzer for hybrid routing group
        let recommendedRoute = ContextAnalyzer.determineOptimalRoute(
            userInput: userInput,
            conversationHistory: conversationHistory,
            userState: userContext
        )
        
        let strategy = RoutingStrategy(
            route: recommendedRoute,
            reason: "Context analysis recommendation",
            fallbackEnabled: enableIntelligentFallback
        )
        
        AppLogger.info(
            "Routing strategy: \(strategy.route.description) | Reason: \(strategy.reason) | Fallback: \(strategy.fallbackEnabled)",
            category: .ai
        )
        
        return strategy
    }
    
    // MARK: - Configuration Updates
    
    /// Updates configuration from remote config or user preferences
    func updateConfiguration(
        hybridRoutingEnabled: Bool? = nil,
        hybridRoutingPercentage: Double? = nil,
        forcedRoute: ProcessingRoute? = nil,
        performanceMonitoringEnabled: Bool? = nil,
        enableIntelligentFallback: Bool? = nil,
        directAITimeoutMs: Int? = nil,
        tokenEfficiencyThreshold: Int? = nil,
        nutritionConfidenceThreshold: Double? = nil
    ) {
        if let enabled = hybridRoutingEnabled {
            self.hybridRoutingEnabled = enabled
            AppLogger.info("Updated hybrid routing enabled: \(enabled)", category: .ai)
        }
        
        if let percentage = hybridRoutingPercentage {
            self.hybridRoutingPercentage = max(0.0, min(1.0, percentage))
            AppLogger.info("Updated hybrid routing percentage: \(self.hybridRoutingPercentage * 100)%", category: .ai)
        }
        
        if let forced = forcedRoute {
            self.forcedRoute = forced
            AppLogger.info("Updated forced route: \(forced.description)", category: .ai)
        }
        
        if let monitoring = performanceMonitoringEnabled {
            self.performanceMonitoringEnabled = monitoring
        }
        
        if let fallback = enableIntelligentFallback {
            self.enableIntelligentFallback = fallback
        }
        
        if let timeout = directAITimeoutMs {
            self.directAITimeoutMs = max(1_000, min(30_000, timeout))
        }
        
        if let threshold = tokenEfficiencyThreshold {
            self.tokenEfficiencyThreshold = max(100, threshold)
        }
        
        if let confidence = nutritionConfidenceThreshold {
            self.nutritionConfidenceThreshold = max(0.1, min(1.0, confidence))
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// Records routing performance metrics
    func recordRoutingMetrics(_ metrics: RoutingMetrics) {
        guard performanceMonitoringEnabled else { return }
        
        AppLogger.info(
            "Routing metrics: \(metrics.route.description) | \(metrics.executionTimeMs)ms | Success: \(metrics.success) | Tokens: \(metrics.tokenUsage ?? 0) | Confidence: \(String(format: "%.2f", metrics.confidence ?? 0.0)) | Fallback: \(metrics.fallbackUsed)",
            category: .ai
        )
        
        // Track performance degradation
        if metrics.executionTimeMs > directAITimeoutMs {
            AppLogger.warning(
                "Routing performance degradation: \(metrics.executionTimeMs)ms exceeds \(directAITimeoutMs)ms threshold",
                category: .ai
            )
        }
    }
    
    // MARK: - Singleton Access
    
    static let shared = RoutingConfiguration()
    
    private init() {
        // Load configuration from UserDefaults or remote config
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        // Load from UserDefaults for persistence across app launches
        let defaults = UserDefaults.standard
        
        hybridRoutingEnabled = defaults.object(forKey: "HybridRoutingEnabled") as? Bool ?? true
        hybridRoutingPercentage = defaults.object(forKey: "HybridRoutingPercentage") as? Double ?? 1.0
        performanceMonitoringEnabled = defaults.object(forKey: "PerformanceMonitoringEnabled") as? Bool ?? true
        enableIntelligentFallback = defaults.object(forKey: "EnableIntelligentFallback") as? Bool ?? true
        directAITimeoutMs = defaults.object(forKey: "DirectAITimeoutMs") as? Int ?? 5_000
        tokenEfficiencyThreshold = defaults.object(forKey: "TokenEfficiencyThreshold") as? Int ?? 500
        nutritionConfidenceThreshold = defaults.object(forKey: "NutritionConfidenceThreshold") as? Double ?? 0.7
        
        if let forcedRouteString = defaults.string(forKey: "ForcedRoute") {
            forcedRoute = ProcessingRoute(rawValue: forcedRouteString)
        }
        
        AppLogger.info(
            "Loaded routing configuration: hybrid=\(hybridRoutingEnabled), percentage=\(hybridRoutingPercentage * 100)%, monitoring=\(performanceMonitoringEnabled)",
            category: .ai
        )
    }
    
    private func saveConfiguration() {
        let defaults = UserDefaults.standard
        
        defaults.set(hybridRoutingEnabled, forKey: "HybridRoutingEnabled")
        defaults.set(hybridRoutingPercentage, forKey: "HybridRoutingPercentage")
        defaults.set(performanceMonitoringEnabled, forKey: "PerformanceMonitoringEnabled")
        defaults.set(enableIntelligentFallback, forKey: "EnableIntelligentFallback")
        defaults.set(directAITimeoutMs, forKey: "DirectAITimeoutMs")
        defaults.set(tokenEfficiencyThreshold, forKey: "TokenEfficiencyThreshold")
        defaults.set(nutritionConfidenceThreshold, forKey: "NutritionConfidenceThreshold")
        defaults.set(forcedRoute?.rawValue, forKey: "ForcedRoute")
    }
}

// MARK: - Routing Strategy

/// Strategy for processing a specific request
struct RoutingStrategy: Sendable {
    let route: ProcessingRoute
    let reason: String
    let fallbackEnabled: Bool
    let timestamp: Date
    
    init(route: ProcessingRoute, reason: String, fallbackEnabled: Bool) {
        self.route = route
        self.reason = reason
        self.fallbackEnabled = fallbackEnabled
        self.timestamp = Date()
    }
}

// MARK: - Routing Metrics

/// Performance metrics for routing decisions
struct RoutingMetrics: Sendable {
    let route: ProcessingRoute
    let executionTimeMs: Int
    let success: Bool
    let tokenUsage: Int?
    let confidence: Double?
    let fallbackUsed: Bool
    let timestamp: Date
    
    init(
        route: ProcessingRoute,
        executionTimeMs: Int,
        success: Bool,
        tokenUsage: Int? = nil,
        confidence: Double? = nil,
        fallbackUsed: Bool = false
    ) {
        self.route = route
        self.executionTimeMs = executionTimeMs
        self.success = success
        self.tokenUsage = tokenUsage
        self.confidence = confidence
        self.fallbackUsed = fallbackUsed
        self.timestamp = Date()
    }
} 