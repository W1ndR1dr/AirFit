import Foundation
import os

/// Protocol for tracking streaming chat performance metrics
/// Provides comprehensive observability for TTFT, tokens/sec, and provider performance
@MainActor
protocol ChatStreamingStore: AnyObject {
    
    /// Track the start of a streaming request
    /// - Parameters:
    ///   - requestId: Unique identifier for this request
    ///   - provider: AI provider (OpenAI, Anthropic, etc.)
    ///   - model: Model identifier
    ///   - inputTokens: Estimated input token count
    func trackStreamingStart(
        requestId: String,
        provider: String,
        model: String,
        inputTokens: Int
    )
    
    /// Track when first token is received (TTFT)
    /// - Parameters:
    ///   - requestId: Request identifier
    ///   - timeToFirstToken: Time elapsed since request start in milliseconds
    func trackFirstToken(
        requestId: String,
        timeToFirstToken: TimeInterval
    )
    
    /// Track streaming token delta
    /// - Parameters:
    ///   - requestId: Request identifier
    ///   - tokenDelta: New token received
    ///   - tokensPerSecond: Current streaming rate
    func trackTokenDelta(
        requestId: String,
        tokenDelta: String,
        tokensPerSecond: Double
    )
    
    /// Track completion of streaming request
    /// - Parameters:
    ///   - requestId: Request identifier
    ///   - totalTokens: Final token count (input + output)
    ///   - outputTokens: Generated tokens count
    ///   - totalDuration: Total request duration
    ///   - cost: Estimated cost for this request
    ///   - success: Whether request completed successfully
    func trackStreamingComplete(
        requestId: String,
        totalTokens: Int,
        outputTokens: Int,
        totalDuration: TimeInterval,
        cost: Double,
        success: Bool
    )
    
    /// Track streaming error
    /// - Parameters:
    ///   - requestId: Request identifier
    ///   - error: Error that occurred
    ///   - context: Additional context about the error
    func trackStreamingError(
        requestId: String,
        error: Error,
        context: String
    )
    
    /// Track cache operation related to streaming
    /// - Parameters:
    ///   - hit: Whether cache was hit or missed
    ///   - cacheKey: Cache key used
    ///   - provider: Provider for the cached content
    func trackCacheOperation(
        hit: Bool,
        cacheKey: String,
        provider: String
    )
    
    /// Get current streaming metrics snapshot
    func getStreamingMetrics() -> StreamingPerformanceSnapshot
}

/// Snapshot of current streaming performance metrics
struct StreamingPerformanceSnapshot: Codable {
    let timestamp: Date
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let averageTTFT: Double?
    let averageTokensPerSecond: Double?
    let totalTokensProcessed: Int
    let totalCost: Double
    let errorRate: Double
    let cacheHitRate: Double
    
    // Provider-specific metrics
    let providerMetrics: [String: ProviderStreamingMetrics]
    
    // Model-specific metrics
    let modelMetrics: [String: ModelStreamingMetrics]
}

struct ProviderStreamingMetrics: Codable {
    let requests: Int
    let averageTTFT: Double?
    let averageTokensPerSecond: Double?
    let errorRate: Double
    let totalCost: Double
}

struct ModelStreamingMetrics: Codable {
    let requests: Int
    let averageTTFT: Double?
    let averageTokensPerSecond: Double?
    let totalTokens: Int
    let averageCostPerToken: Double?
}

/// Default implementation of ChatStreamingStore integrated with MonitoringService
@MainActor
final class DefaultChatStreamingStore: ChatStreamingStore {
    
    // MARK: - Properties
    
    private let monitoringService: MonitoringService
    private let logger = Logger(subsystem: "com.airfit", category: "streaming-store")
    
    // Active streaming requests
    private var activeRequests: [String: StreamingRequestState] = [:]
    
    // Performance metrics
    private var metrics = StreamingStoreMetrics()
    
    // MARK: - Initialization
    
    init(monitoringService: MonitoringService) {
        self.monitoringService = monitoringService
        
        logger.info("ChatStreamingStore initialized")
    }
    
    // MARK: - ChatStreamingStore Implementation
    
    func trackStreamingStart(
        requestId: String,
        provider: String,
        model: String,
        inputTokens: Int
    ) {
        let state = StreamingRequestState(
            requestId: requestId,
            provider: provider,
            model: model,
            inputTokens: inputTokens,
            startTime: CFAbsoluteTimeGetCurrent()
        )
        
        activeRequests[requestId] = state
        metrics.totalRequests += 1
        
        logger.debug("Streaming started", metadata: [
            "requestId": "\(requestId)",
            "provider": "\(provider)",
            "model": "\(model)",
            "inputTokens": "\(inputTokens)"
        ])
    }
    
    func trackFirstToken(
        requestId: String,
        timeToFirstToken: TimeInterval
    ) {
        guard let state = activeRequests[requestId] else {
            logger.warning("Cannot track TTFT - unknown request", metadata: ["requestId": "\(requestId)"])
            return
        }
        
        activeRequests[requestId]?.timeToFirstToken = timeToFirstToken
        
        // Update metrics
        metrics.ttftMeasurements.append(timeToFirstToken)
        
        // Track in monitoring service
        Task {
            await monitoringService.trackTTFT(
                timeToFirstToken,
                provider: state.provider,
                model: state.model
            )
        }
        
        logger.info("TTFT tracked", metadata: [
            "requestId": "\(requestId)",
            "ttftMs": "\(Int(timeToFirstToken * 1000))",
            "provider": "\(state.provider)",
            "model": "\(state.model)"
        ])
    }
    
    func trackTokenDelta(
        requestId: String,
        tokenDelta: String,
        tokensPerSecond: Double
    ) {
        guard let state = activeRequests[requestId] else {
            logger.warning("Cannot track token delta - unknown request", metadata: ["requestId": "\(requestId)"])
            return
        }
        
        activeRequests[requestId]?.outputTokens += 1
        activeRequests[requestId]?.currentTokensPerSecond = tokensPerSecond
        
        // Update streaming rate metrics
        metrics.tokensPerSecondMeasurements.append(tokensPerSecond)
        
        logger.debug("Token delta tracked", metadata: [
            "requestId": "\(requestId)",
            "tokensPerSec": "\(String(format: "%.1f", tokensPerSecond))",
            "outputTokens": "\(state.outputTokens + 1)"
        ])
    }
    
    func trackStreamingComplete(
        requestId: String,
        totalTokens: Int,
        outputTokens: Int,
        totalDuration: TimeInterval,
        cost: Double,
        success: Bool
    ) {
        guard let state = activeRequests[requestId] else {
            logger.warning("Cannot complete tracking - unknown request", metadata: ["requestId": "\(requestId)"])
            return
        }
        
        // Update metrics
        if success {
            metrics.successfulRequests += 1
        } else {
            metrics.failedRequests += 1
        }
        
        metrics.totalTokensProcessed += totalTokens
        metrics.totalCost += cost
        
        // Update provider metrics
        updateProviderMetrics(
            provider: state.provider,
            ttft: state.timeToFirstToken,
            tokensPerSec: state.currentTokensPerSecond,
            success: success,
            cost: cost
        )
        
        // Update model metrics
        updateModelMetrics(
            model: state.model,
            ttft: state.timeToFirstToken,
            tokensPerSec: state.currentTokensPerSecond,
            totalTokens: totalTokens,
            cost: cost
        )
        
        // Track in monitoring service
        Task {
            await monitoringService.trackStreamingLatency(
                totalDuration,
                provider: state.provider,
                model: state.model,
                tokenCount: totalTokens
            )
            
            await monitoringService.trackTokenUsage(
                promptTokens: state.inputTokens,
                completionTokens: outputTokens,
                totalTokens: totalTokens,
                cost: cost,
                provider: state.provider,
                model: state.model
            )
        }
        
        // Clean up
        activeRequests.removeValue(forKey: requestId)
        
        logger.info("Streaming completed", metadata: [
            "requestId": "\(requestId)",
            "success": "\(success)",
            "totalTokens": "\(totalTokens)",
            "durationMs": "\(Int(totalDuration * 1000))",
            "cost": "\(String(format: "%.4f", cost))",
            "provider": "\(state.provider)",
            "model": "\(state.model)"
        ])
    }
    
    func trackStreamingError(
        requestId: String,
        error: Error,
        context: String
    ) {
        guard let state = activeRequests[requestId] else {
            logger.warning("Cannot track error - unknown request", metadata: ["requestId": "\(requestId)"])
            return
        }
        
        metrics.failedRequests += 1
        
        // Determine error type
        let errorType = classifyError(error)
        
        // Track in monitoring service
        Task {
            await monitoringService.trackError(
                error,
                type: errorType,
                context: "streaming_\(context)",
                provider: state.provider
            )
        }
        
        // Clean up
        activeRequests.removeValue(forKey: requestId)
        
        logger.error("Streaming error", metadata: [
            "requestId": "\(requestId)",
            "error": "\(error.localizedDescription)",
            "context": "\(context)",
            "provider": "\(state.provider)",
            "errorType": "\(errorType.rawValue)"
        ])
    }
    
    func trackCacheOperation(
        hit: Bool,
        cacheKey: String,
        provider: String
    ) {
        // Track in monitoring service
        Task {
            await monitoringService.trackCacheOperation(
                hit: hit,
                cacheType: .aiResponse,
                key: cacheKey
            )
        }
        
        logger.debug("Cache operation", metadata: [
            "hit": "\(hit)",
            "provider": "\(provider)",
            "keyPrefix": "\(String(cacheKey.prefix(20)))..."
        ])
    }
    
    func getStreamingMetrics() -> StreamingPerformanceSnapshot {
        let totalRequests = metrics.totalRequests
        let successRate = totalRequests > 0 ? Double(metrics.successfulRequests) / Double(totalRequests) : 0.0
        let errorRate = 1.0 - successRate
        
        let averageTTFT = metrics.ttftMeasurements.isEmpty ? nil : 
            metrics.ttftMeasurements.reduce(0, +) / Double(metrics.ttftMeasurements.count)
        
        let averageTokensPerSecond = metrics.tokensPerSecondMeasurements.isEmpty ? nil :
            metrics.tokensPerSecondMeasurements.reduce(0, +) / Double(metrics.tokensPerSecondMeasurements.count)
        
        let cacheHitRate = calculateCacheHitRate()
        
        return StreamingPerformanceSnapshot(
            timestamp: Date(),
            totalRequests: totalRequests,
            successfulRequests: metrics.successfulRequests,
            failedRequests: metrics.failedRequests,
            averageTTFT: averageTTFT,
            averageTokensPerSecond: averageTokensPerSecond,
            totalTokensProcessed: metrics.totalTokensProcessed,
            totalCost: metrics.totalCost,
            errorRate: errorRate,
            cacheHitRate: cacheHitRate,
            providerMetrics: buildProviderMetrics(),
            modelMetrics: buildModelMetrics()
        )
    }
    
    // MARK: - Private Helpers
    
    private func updateProviderMetrics(
        provider: String,
        ttft: TimeInterval?,
        tokensPerSec: Double?,
        success: Bool,
        cost: Double
    ) {
        if metrics.providerMetrics[provider] == nil {
            metrics.providerMetrics[provider] = ProviderMetricsInternal()
        }
        
        metrics.providerMetrics[provider]?.requests += 1
        if !success {
            metrics.providerMetrics[provider]?.errors += 1
        }
        metrics.providerMetrics[provider]?.totalCost += cost
        
        if let ttft = ttft {
            metrics.providerMetrics[provider]?.ttftMeasurements.append(ttft)
        }
        
        if let tokensPerSec = tokensPerSec {
            metrics.providerMetrics[provider]?.tokensPerSecondMeasurements.append(tokensPerSec)
        }
    }
    
    private func updateModelMetrics(
        model: String,
        ttft: TimeInterval?,
        tokensPerSec: Double?,
        totalTokens: Int,
        cost: Double
    ) {
        if metrics.modelMetrics[model] == nil {
            metrics.modelMetrics[model] = ModelMetricsInternal()
        }
        
        metrics.modelMetrics[model]?.requests += 1
        metrics.modelMetrics[model]?.totalTokens += totalTokens
        metrics.modelMetrics[model]?.totalCost += cost
        
        if let ttft = ttft {
            metrics.modelMetrics[model]?.ttftMeasurements.append(ttft)
        }
        
        if let tokensPerSec = tokensPerSec {
            metrics.modelMetrics[model]?.tokensPerSecondMeasurements.append(tokensPerSec)
        }
    }
    
    private func calculateCacheHitRate() -> Double {
        // This would integrate with actual cache metrics
        // For now, return a placeholder that could be hooked up to cache services
        return 0.0
    }
    
    private func buildProviderMetrics() -> [String: ProviderStreamingMetrics] {
        var result: [String: ProviderStreamingMetrics] = [:]
        
        for (provider, internal) in metrics.providerMetrics {
            let averageTTFT = internal.ttftMeasurements.isEmpty ? nil :
                internal.ttftMeasurements.reduce(0, +) / Double(internal.ttftMeasurements.count)
            
            let averageTokensPerSecond = internal.tokensPerSecondMeasurements.isEmpty ? nil :
                internal.tokensPerSecondMeasurements.reduce(0, +) / Double(internal.tokensPerSecondMeasurements.count)
            
            let errorRate = internal.requests > 0 ? Double(internal.errors) / Double(internal.requests) : 0.0
            
            result[provider] = ProviderStreamingMetrics(
                requests: internal.requests,
                averageTTFT: averageTTFT,
                averageTokensPerSecond: averageTokensPerSecond,
                errorRate: errorRate,
                totalCost: internal.totalCost
            )
        }
        
        return result
    }
    
    private func buildModelMetrics() -> [String: ModelStreamingMetrics] {
        var result: [String: ModelStreamingMetrics] = [:]
        
        for (model, internal) in metrics.modelMetrics {
            let averageTTFT = internal.ttftMeasurements.isEmpty ? nil :
                internal.ttftMeasurements.reduce(0, +) / Double(internal.ttftMeasurements.count)
            
            let averageTokensPerSecond = internal.tokensPerSecondMeasurements.isEmpty ? nil :
                internal.tokensPerSecondMeasurements.reduce(0, +) / Double(internal.tokensPerSecondMeasurements.count)
            
            let averageCostPerToken = internal.totalTokens > 0 ? internal.totalCost / Double(internal.totalTokens) : nil
            
            result[model] = ModelStreamingMetrics(
                requests: internal.requests,
                averageTTFT: averageTTFT,
                averageTokensPerSecond: averageTokensPerSecond,
                totalTokens: internal.totalTokens,
                averageCostPerToken: averageCostPerToken
            )
        }
        
        return result
    }
    
    private func classifyError(_ error: Error) -> ErrorType {
        let description = error.localizedDescription.lowercased()
        
        if description.contains("network") || description.contains("connection") {
            return .network
        } else if description.contains("timeout") {
            return .timeout
        } else if description.contains("unauthorized") || description.contains("401") {
            return .authentication
        } else if description.contains("rate limit") || description.contains("429") {
            return .rateLimit
        } else {
            return .aiProviderError
        }
    }
}

// MARK: - Internal Data Structures

private struct StreamingRequestState {
    let requestId: String
    let provider: String
    let model: String
    let inputTokens: Int
    let startTime: CFAbsoluteTime
    
    var timeToFirstToken: TimeInterval?
    var outputTokens: Int = 0
    var currentTokensPerSecond: Double?
}

private struct StreamingStoreMetrics {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var totalTokensProcessed: Int = 0
    var totalCost: Double = 0.0
    
    var ttftMeasurements: [TimeInterval] = []
    var tokensPerSecondMeasurements: [Double] = []
    
    var providerMetrics: [String: ProviderMetricsInternal] = [:]
    var modelMetrics: [String: ModelMetricsInternal] = [:]
}

private struct ProviderMetricsInternal {
    var requests: Int = 0
    var errors: Int = 0
    var totalCost: Double = 0.0
    var ttftMeasurements: [TimeInterval] = []
    var tokensPerSecondMeasurements: [Double] = []
}

private struct ModelMetricsInternal {
    var requests: Int = 0
    var totalTokens: Int = 0
    var totalCost: Double = 0.0
    var ttftMeasurements: [TimeInterval] = []
    var tokensPerSecondMeasurements: [Double] = []
}

// MARK: - Additional Error Classification

extension ErrorType {
    static let aiResponse = ErrorType.aiProviderError
}

extension CacheType {
    static let aiResponse = CacheType.general
}