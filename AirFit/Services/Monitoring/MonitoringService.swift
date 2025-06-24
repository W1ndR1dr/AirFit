import Foundation
import os

/// Production monitoring for AI persona system
actor MonitoringService: ServiceProtocol {
    // MARK: - Properties
    private var metrics = ProductionMetrics()
    private var alerts: [MonitoringAlert] = []
    
    private let logger = Logger(subsystem: "com.airfit", category: "monitoring")
    
    // Thresholds
    private let performanceThresholds = PerformanceThresholds(
        personaGenerationMax: 5.0,
        conversationResponseMax: 2.0,
        apiCallMax: 3.0,
        cacheHitRateMin: 0.7,
        errorRateMax: 0.05
    )
    
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "monitoring-service"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool {
        // For actors, we need async access but protocol requires sync
        // Return true as monitoring is always ready
        true
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialization handled in configure()
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        startMonitoring()
        _isConfigured = true
        logger.info("MonitoringService configured")
    }
    
    func reset() async {
        metrics = ProductionMetrics()
        alerts.removeAll()
        _isConfigured = false
        logger.info("MonitoringService reset")
    }
    
    func healthCheck() async -> ServiceHealth {
        let alertCount = alerts.count
        let recentAlerts = alerts.filter { alert in
            alert.timestamp.timeIntervalSinceNow > -300 // Last 5 minutes
        }.count
        
        let status: ServiceHealth.Status
        if recentAlerts > 10 {
            status = .unhealthy
        } else if recentAlerts > 5 {
            status = .degraded
        } else {
            status = .healthy
        }
        
        return ServiceHealth(
            status: status,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: status != .healthy ? "High alert rate detected" : nil,
            metadata: [
                "totalAlerts": "\(alertCount)",
                "recentAlerts": "\(recentAlerts)",
                "errorCount": "\(metrics.apiPerformance.errorCount)"
            ]
        )
    }
    
    // MARK: - Public API
    
    /// Track persona generation performance
    func trackPersonaGeneration(duration: TimeInterval, success: Bool, model: String? = nil) {
        metrics.personaGeneration.count += 1
        metrics.personaGeneration.totalDuration += duration
        
        if success {
            metrics.personaGeneration.successCount += 1
        } else {
            metrics.personaGeneration.failureCount += 1
        }
        
        // Check threshold
        if duration > performanceThresholds.personaGenerationMax {
            createAlert(
                type: .performanceDegradation,
                severity: .warning,
                message: "Persona generation took \(String(format: "%.1f", duration))s (threshold: \(performanceThresholds.personaGenerationMax)s)",
                metadata: ["duration": duration, "model": model ?? "unknown"]
            )
        }
        
        logger.info("Persona generation: \(duration)s, success: \(success)")
    }
    
    /// Track conversation response time
    func trackConversationResponse(duration: TimeInterval, nodeId: String, tokenCount: Int) {
        metrics.conversationFlow.responseCount += 1
        metrics.conversationFlow.totalResponseTime += duration
        metrics.conversationFlow.totalTokens += tokenCount
        
        if duration > performanceThresholds.conversationResponseMax {
            createAlert(
                type: .performanceDegradation,
                severity: .warning,
                message: "Slow conversation response: \(String(format: "%.1f", duration))s at node \(nodeId)",
                metadata: ["duration": duration, "nodeId": nodeId, "tokens": tokenCount]
            )
        }
    }
    
    /// Track API call performance
    func trackAPICall(provider: String, model: String, duration: TimeInterval, success: Bool, cost: Double) {
        metrics.apiPerformance.callCount += 1
        metrics.apiPerformance.totalDuration += duration
        metrics.apiPerformance.totalCost += cost
        
        if !success {
            metrics.apiPerformance.errorCount += 1
        }
        
        // Track by provider
        if metrics.apiPerformance.byProvider[provider] == nil {
            metrics.apiPerformance.byProvider[provider] = ProviderMetrics()
        }
        
        metrics.apiPerformance.byProvider[provider]?.callCount += 1
        metrics.apiPerformance.byProvider[provider]?.totalDuration += duration
        metrics.apiPerformance.byProvider[provider]?.errorCount += success ? 0 : 1
        
        // Check error rate
        let errorRate = Double(metrics.apiPerformance.errorCount) / Double(metrics.apiPerformance.callCount)
        if errorRate > performanceThresholds.errorRateMax {
            createAlert(
                type: .highErrorRate,
                severity: .critical,
                message: "High API error rate: \(String(format: "%.1f%%", errorRate * 100))",
                metadata: ["provider": provider, "errorRate": errorRate]
            )
        }
    }
    
    /// Track cache performance
    func trackCacheHit(hit: Bool) {
        if hit {
            metrics.cachePerformance.hitCount += 1
        } else {
            metrics.cachePerformance.missCount += 1
        }
        
        let total = metrics.cachePerformance.hitCount + metrics.cachePerformance.missCount
        if total > 100 { // Only check after sufficient data
            let hitRate = Double(metrics.cachePerformance.hitCount) / Double(total)
            if hitRate < performanceThresholds.cacheHitRateMin {
                createAlert(
                    type: .lowCacheHitRate,
                    severity: .info,
                    message: "Low cache hit rate: \(String(format: "%.1f%%", hitRate * 100))",
                    metadata: ["hitRate": hitRate]
                )
            }
        }
    }
    
    /// Track error occurrence
    func trackError(_ error: Error, context: String) {
        metrics.errors.append(MonitoringErrorRecord(
            timestamp: Date(),
            error: error,
            context: context
        ))
        
        // Keep only recent errors
        let cutoff = Date().addingTimeInterval(-3_600) // 1 hour
        metrics.errors.removeAll { $0.timestamp < cutoff }
        
        logger.error("Error in \(context): \(error.localizedDescription)")
    }
    
    /// Get current metrics snapshot
    func getMetricsSnapshot() async -> ProductionMetrics {
        return metrics
    }
    
    /// Get current alerts
    func getAlerts() async -> [MonitoringAlert] {
        return alerts
    }
    
    /// Export metrics for analysis
    func exportMetrics() async -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(metrics)
    }
    
    /// Reset metrics
    func resetMetrics() async {
        metrics = ProductionMetrics()
        alerts.removeAll()
        logger.info("Metrics reset")
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        // Periodic metrics reporting
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 300 seconds
                await reportMetrics()
            }
        }
        
        // Monitor system resources
        Task {
            await monitorSystemResources()
        }
    }
    
    private func reportMetrics() async {
        let snapshot = metrics
        
        // Log summary
        logger.info("""
            Metrics Summary:
            - Persona generations: \(snapshot.personaGeneration.count) (avg: \(String(format: "%.1f", snapshot.personaGeneration.averageDuration))s)
            - API calls: \(snapshot.apiPerformance.callCount) (errors: \(snapshot.apiPerformance.errorCount))
            - Cache hit rate: \(String(format: "%.1f%%", snapshot.cachePerformance.hitRate * 100))
            - Total cost: $\(String(format: "%.2f", snapshot.apiPerformance.totalCost))
            """)
        
        // Check for anomalies
        checkForAnomalies(in: snapshot)
    }
    
    private func checkForAnomalies(in metrics: ProductionMetrics) {
        // Check for sudden spike in errors
        let recentErrors = metrics.errors.filter {
            $0.timestamp > Date().addingTimeInterval(-300) // Last 5 minutes
        }
        
        if recentErrors.count > 10 {
            createAlert(
                type: .errorSpike,
                severity: .critical,
                message: "Error spike detected: \(recentErrors.count) errors in last 5 minutes",
                metadata: ["errorCount": recentErrors.count]
            )
        }
    }
    
    private func monitorSystemResources() async {
        // Monitor memory usage
        let memoryUsage = getMemoryUsage()
        if memoryUsage > 150_000_000 { // 150MB
            createAlert(
                type: .highMemoryUsage,
                severity: .warning,
                message: "High memory usage: \(memoryUsage / 1_000_000)MB",
                metadata: ["memoryBytes": memoryUsage]
            )
        }
    }
    
    private func createAlert(type: AlertType, severity: AlertSeverity, message: String, metadata: [String: Any]) {
        let alert = MonitoringAlert(
            id: UUID(),
            type: type,
            severity: severity,
            message: message,
            timestamp: Date(),
            metadata: metadata
        )
        
        alerts.append(alert)
        
        // Keep only recent alerts
        let cutoff = Date().addingTimeInterval(-86_400) // 24 hours
        alerts.removeAll { $0.timestamp < cutoff }
        
        // Log based on severity
        switch severity {
        case .info:
            logger.info("Alert: \(message)")
        case .warning:
            logger.warning("Alert: \(message)")
        case .critical:
            logger.error("Alert: \(message)")
        }
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Models

struct ProductionMetrics: Codable {
    var personaGeneration = PersonaGenerationMetrics()
    var conversationFlow = ConversationFlowMetrics()
    var apiPerformance = APIPerformanceMetrics()
    var cachePerformance = CachePerformanceMetrics()
    var errors: [MonitoringErrorRecord] = []
    var startTime = Date()
    
    struct PersonaGenerationMetrics: Codable {
        var count = 0
        var successCount = 0
        var failureCount = 0
        var totalDuration: TimeInterval = 0
        
        var averageDuration: TimeInterval {
            count > 0 ? totalDuration / Double(count) : 0
        }
        
        var successRate: Double {
            count > 0 ? Double(successCount) / Double(count) : 0
        }
    }
    
    struct ConversationFlowMetrics: Codable {
        var responseCount = 0
        var totalResponseTime: TimeInterval = 0
        var totalTokens = 0
        
        var averageResponseTime: TimeInterval {
            responseCount > 0 ? totalResponseTime / Double(responseCount) : 0
        }
        
        var averageTokensPerResponse: Double {
            responseCount > 0 ? Double(totalTokens) / Double(responseCount) : 0
        }
    }
    
    struct APIPerformanceMetrics: Codable {
        var callCount = 0
        var errorCount = 0
        var totalDuration: TimeInterval = 0
        var totalCost: Double = 0
        var byProvider: [String: ProviderMetrics] = [:]
        
        var averageLatency: TimeInterval {
            callCount > 0 ? totalDuration / Double(callCount) : 0
        }
        
        var errorRate: Double {
            callCount > 0 ? Double(errorCount) / Double(callCount) : 0
        }
    }
    
    struct CachePerformanceMetrics: Codable {
        var hitCount = 0
        var missCount = 0
        
        var hitRate: Double {
            let total = hitCount + missCount
            return total > 0 ? Double(hitCount) / Double(total) : 0
        }
    }
}

struct ProviderMetrics: Codable {
    var callCount = 0
    var errorCount = 0
    var totalDuration: TimeInterval = 0
}

struct MonitoringErrorRecord: Codable {
    let timestamp: Date
    let errorDescription: String
    let context: String
    
    init(timestamp: Date, error: Error, context: String) {
        self.timestamp = timestamp
        self.errorDescription = error.localizedDescription
        self.context = context
    }
}

struct MonitoringAlert: Identifiable, Codable {
    let id: UUID
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let timestamp: Date
    let metadata: [String: String]
    
    init(id: UUID, type: AlertType, severity: AlertSeverity, message: String, timestamp: Date, metadata: [String: Any]) {
        self.id = id
        self.type = type
        self.severity = severity
        self.message = message
        self.timestamp = timestamp
        
        // Convert metadata to strings
        self.metadata = metadata.reduce(into: [:]) { result, pair in
            result[pair.key] = String(describing: pair.value)
        }
    }
}

enum AlertType: String, Codable {
    case performanceDegradation
    case highErrorRate
    case lowCacheHitRate
    case errorSpike
    case highMemoryUsage
}

enum AlertSeverity: String, Codable {
    case info
    case warning
    case critical
}

struct PerformanceThresholds {
    let personaGenerationMax: TimeInterval
    let conversationResponseMax: TimeInterval
    let apiCallMax: TimeInterval
    let cacheHitRateMin: Double
    let errorRateMax: Double
}
