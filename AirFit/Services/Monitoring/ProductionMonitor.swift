import Foundation
import os

/// Production monitoring for AI persona system
@MainActor
final class ProductionMonitor: ObservableObject {
    static let shared = ProductionMonitor()
    
    // MARK: - Properties
    @Published private(set) var metrics = ProductionMetrics()
    @Published private(set) var alerts: [MonitoringAlert] = []
    
    private let logger = Logger(subsystem: "com.airfit", category: "monitoring")
    private var metricsTimer: Timer?
    private let metricsQueue = DispatchQueue(label: "com.airfit.monitoring", qos: .utility)
    
    // Thresholds
    private let performanceThresholds = PerformanceThresholds(
        personaGenerationMax: 5.0,
        conversationResponseMax: 2.0,
        apiCallMax: 3.0,
        cacheHitRateMin: 0.7,
        errorRateMax: 0.05
    )
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Public API
    
    /// Track persona generation performance
    func trackPersonaGeneration(duration: TimeInterval, success: Bool, model: String? = nil) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.metrics.personaGeneration.count += 1
                self.metrics.personaGeneration.totalDuration += duration
                
                if success {
                    self.metrics.personaGeneration.successCount += 1
                } else {
                    self.metrics.personaGeneration.failureCount += 1
                }
                
                // Check threshold
                if duration > self.performanceThresholds.personaGenerationMax {
                    self.createAlert(
                        type: .performanceDegradation,
                        severity: .warning,
                        message: "Persona generation took \(String(format: "%.1f", duration))s (threshold: \(self.performanceThresholds.personaGenerationMax)s)",
                        metadata: ["duration": duration, "model": model ?? "unknown"]
                    )
                }
                
                self.logger.info("Persona generation: \(duration)s, success: \(success)")
            }
        }
    }
    
    /// Track conversation response time
    func trackConversationResponse(duration: TimeInterval, nodeId: String, tokenCount: Int) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.metrics.conversationFlow.responseCount += 1
                self.metrics.conversationFlow.totalResponseTime += duration
                self.metrics.conversationFlow.totalTokens += tokenCount
                
                if duration > self.performanceThresholds.conversationResponseMax {
                    self.createAlert(
                        type: .performanceDegradation,
                        severity: .warning,
                        message: "Slow conversation response: \(String(format: "%.1f", duration))s at node \(nodeId)",
                        metadata: ["duration": duration, "nodeId": nodeId, "tokens": tokenCount]
                    )
                }
            }
        }
    }
    
    /// Track API call performance
    func trackAPICall(provider: String, model: String, duration: TimeInterval, success: Bool, cost: Double) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.metrics.apiPerformance.callCount += 1
                self.metrics.apiPerformance.totalDuration += duration
                self.metrics.apiPerformance.totalCost += cost
                
                if !success {
                    self.metrics.apiPerformance.errorCount += 1
                }
                
                // Track by provider
                if self.metrics.apiPerformance.byProvider[provider] == nil {
                    self.metrics.apiPerformance.byProvider[provider] = ProviderMetrics()
                }
                
                self.metrics.apiPerformance.byProvider[provider]?.callCount += 1
                self.metrics.apiPerformance.byProvider[provider]?.totalDuration += duration
                self.metrics.apiPerformance.byProvider[provider]?.errorCount += success ? 0 : 1
                
                // Check error rate
                let errorRate = Double(self.metrics.apiPerformance.errorCount) / Double(self.metrics.apiPerformance.callCount)
                if errorRate > self.performanceThresholds.errorRateMax {
                    self.createAlert(
                        type: .highErrorRate,
                        severity: .critical,
                        message: "High API error rate: \(String(format: "%.1f%%", errorRate * 100))",
                        metadata: ["provider": provider, "errorRate": errorRate]
                    )
                }
            }
        }
    }
    
    /// Track cache performance
    func trackCacheHit(hit: Bool) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                if hit {
                    self.metrics.cachePerformance.hitCount += 1
                } else {
                    self.metrics.cachePerformance.missCount += 1
                }
                
                let total = self.metrics.cachePerformance.hitCount + self.metrics.cachePerformance.missCount
                if total > 100 { // Only check after sufficient data
                    let hitRate = Double(self.metrics.cachePerformance.hitCount) / Double(total)
                    if hitRate < self.performanceThresholds.cacheHitRateMin {
                        self.createAlert(
                            type: .lowCacheHitRate,
                            severity: .info,
                            message: "Low cache hit rate: \(String(format: "%.1f%%", hitRate * 100))",
                            metadata: ["hitRate": hitRate]
                        )
                    }
                }
            }
        }
    }
    
    /// Track error occurrence
    func trackError(_ error: Error, context: String) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.metrics.errors.append(ErrorRecord(
                    timestamp: Date(),
                    error: error,
                    context: context
                ))
                
                // Keep only recent errors
                let cutoff = Date().addingTimeInterval(-3600) // 1 hour
                self.metrics.errors.removeAll { $0.timestamp < cutoff }
                
                self.logger.error("Error in \(context): \(error.localizedDescription)")
            }
        }
    }
    
    /// Get current metrics snapshot
    func getMetricsSnapshot() -> ProductionMetrics {
        return metrics
    }
    
    /// Export metrics for analysis
    func exportMetrics() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(metrics)
    }
    
    /// Reset metrics
    func resetMetrics() {
        metrics = ProductionMetrics()
        alerts.removeAll()
        logger.info("Metrics reset")
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        // Periodic metrics reporting
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.reportMetrics()
            }
        }
        
        // Monitor system resources
        Task {
            await monitorSystemResources()
        }
    }
    
    private func reportMetrics() {
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
        let cutoff = Date().addingTimeInterval(-86400) // 24 hours
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
    var errors: [ErrorRecord] = []
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

struct ErrorRecord: Codable {
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