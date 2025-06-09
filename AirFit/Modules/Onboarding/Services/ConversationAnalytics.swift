import Foundation

// MARK: - Analytics Event Types
enum ConversationAnalyticsEvent {
    case sessionStarted(userId: UUID)
    case sessionResumed(userId: UUID, nodeId: String)
    case nodeViewed(nodeId: String, nodeType: ConversationNode.NodeType)
    case responseSubmitted(nodeId: String, responseType: String, processingTime: TimeInterval)
    case nodeSkipped(nodeId: String)
    case sessionCompleted(userId: UUID, duration: TimeInterval, completionPercentage: Double)
    case sessionAbandoned(userId: UUID, lastNodeId: String, completionPercentage: Double)
    case errorOccurred(nodeId: String?, error: Error)
}

// MARK: - Analytics Metrics
struct ConversationMetrics {
    let averageCompletionTime: TimeInterval
    let completionRate: Double
    let mostCommonDropOffNode: String?
    let averageResponseTime: [String: TimeInterval] // nodeId -> avg time
    let skipRates: [String: Double] // nodeId -> skip rate
}

// MARK: - Analytics Service
actor ConversationAnalytics: ServiceProtocol {
    // MARK: - ServiceProtocol
    nonisolated let serviceIdentifier = "conversation-analytics"
    private var _isConfigured = false
    nonisolated var isConfigured: Bool { true } // Always ready
    
    private var events: [AnalyticsEventRecord] = []
    private let maxEventsInMemory = 1000
    
    // MARK: - Event Tracking
    func track(_ event: ConversationAnalyticsEvent) {
        let record = AnalyticsEventRecord(
            event: event,
            timestamp: Date(),
            sessionId: UUID() // In real app, would track actual session
        )
        
        events.append(record)
        
        // Prevent unbounded memory growth
        if events.count > maxEventsInMemory {
            events.removeFirst(events.count - maxEventsInMemory)
        }
        
        // In production, would send to analytics service
        #if DEBUG
        logEvent(event)
        #endif
    }
    
    // MARK: - Metrics Calculation
    func calculateMetrics() -> ConversationMetrics {
        let completedSessions = events.compactMap { record -> TimeInterval? in
            if case .sessionCompleted(_, let duration, _) = record.event {
                return duration
            }
            return nil
        }
        
        let allSessions = events.filter { record in
            if case .sessionStarted = record.event { return true }
            return false
        }.count
        
        let abandonedSessions = events.compactMap { record -> String? in
            if case .sessionAbandoned(_, let nodeId, _) = record.event {
                return nodeId
            }
            return nil
        }
        
        // Calculate metrics
        let avgCompletionTime = completedSessions.isEmpty ? 0 : completedSessions.reduce(0, +) / Double(completedSessions.count)
        let completionRate = allSessions > 0 ? Double(completedSessions.count) / Double(allSessions) : 0
        
        // Find most common drop-off node
        let dropOffCounts = abandonedSessions.reduce(into: [:]) { counts, nodeId in
            counts[nodeId, default: 0] += 1
        }
        let mostCommonDropOff = dropOffCounts.max(by: { $0.value < $1.value })?.key
        
        // Calculate response times
        var responseTimes: [String: [TimeInterval]] = [:]
        events.forEach { record in
            if case .responseSubmitted(let nodeId, _, let time) = record.event {
                responseTimes[nodeId, default: []].append(time)
            }
        }
        
        let avgResponseTimes = responseTimes.mapValues { times in
            times.reduce(0, +) / Double(times.count)
        }
        
        // Calculate skip rates
        var nodeViews: [String: Int] = [:]
        var nodeSkips: [String: Int] = [:]
        
        events.forEach { record in
            switch record.event {
            case .nodeViewed(let nodeId, _):
                nodeViews[nodeId, default: 0] += 1
            case .nodeSkipped(let nodeId):
                nodeSkips[nodeId, default: 0] += 1
            default:
                break
            }
        }
        
        let skipRates: [String: Double] = nodeViews.reduce(into: [:]) { rates, item in
            let (nodeId, views) = item
            let skips = nodeSkips[nodeId] ?? 0
            rates[nodeId] = views > 0 ? Double(skips) / Double(views) : 0
        }
        
        return ConversationMetrics(
            averageCompletionTime: avgCompletionTime,
            completionRate: completionRate,
            mostCommonDropOffNode: mostCommonDropOff,
            averageResponseTime: avgResponseTimes,
            skipRates: skipRates
        )
    }
    
    // MARK: - Funnel Analysis
    func calculateFunnel() -> [ConversationNode.NodeType: Double] {
        var funnel: [ConversationNode.NodeType: Double] = [:]
        let nodeTypes = ConversationNode.NodeType.allCases
        
        // Count unique users who reached each node type
        var usersPerNodeType: [ConversationNode.NodeType: Set<UUID>] = [:]
        
        events.forEach { record in
            if case .nodeViewed(_, let nodeType) = record.event {
                // In real app, would track actual user ID
                usersPerNodeType[nodeType, default: []].insert(record.sessionId)
            }
        }
        
        // Calculate conversion rates
        let totalUsers = Double(usersPerNodeType[.opening]?.count ?? 1)
        
        for nodeType in nodeTypes {
            let usersAtNode = Double(usersPerNodeType[nodeType]?.count ?? 0)
            funnel[nodeType] = totalUsers > 0 ? usersAtNode / totalUsers : 0
        }
        
        return funnel
    }
    
    // MARK: - Performance Monitoring
    func getSlowNodes(threshold: TimeInterval = 5.0) -> [String] {
        let metrics = calculateMetrics()
        return metrics.averageResponseTime.compactMap { nodeId, avgTime in
            avgTime > threshold ? nodeId : nil
        }
    }
    
    // MARK: - Error Tracking
    func getErrorRate() -> Double {
        let totalEvents = events.count
        let errorEvents = events.filter { record in
            if case .errorOccurred = record.event { return true }
            return false
        }.count
        
        return totalEvents > 0 ? Double(errorEvents) / Double(totalEvents) : 0
    }
    
    // MARK: - Private Helpers
    private func logEvent(_ event: ConversationAnalyticsEvent) {
        let eventDescription: String
        
        switch event {
        case .sessionStarted(let userId):
            eventDescription = "Session started for user: \(userId)"
        case .sessionResumed(let userId, let nodeId):
            eventDescription = "Session resumed for user: \(userId) at node: \(nodeId)"
        case .nodeViewed(let nodeId, let nodeType):
            eventDescription = "Node viewed: \(nodeId) (type: \(nodeType))"
        case .responseSubmitted(let nodeId, let responseType, let time):
            eventDescription = "Response submitted for node: \(nodeId), type: \(responseType), time: \(time)s"
        case .nodeSkipped(let nodeId):
            eventDescription = "Node skipped: \(nodeId)"
        case .sessionCompleted(let userId, let duration, let completion):
            eventDescription = "Session completed for user: \(userId), duration: \(duration)s, completion: \(completion * 100)%"
        case .sessionAbandoned(let userId, let lastNodeId, let completion):
            eventDescription = "Session abandoned by user: \(userId) at node: \(lastNodeId), completion: \(completion * 100)%"
        case .errorOccurred(let nodeId, let error):
            eventDescription = "Error at node: \(nodeId ?? "unknown"), error: \(error.localizedDescription)"
        }
        
        AppLogger.debug("[ConversationAnalytics] \(eventDescription)", category: .onboarding)
    }
    
    // MARK: - ServiceProtocol Methods
    
    func configure() async throws {
        guard !_isConfigured else { return }
        _isConfigured = true
        AppLogger.info("\(serviceIdentifier) configured", category: .services)
    }
    
    func reset() async {
        events.removeAll()
        _isConfigured = false
        AppLogger.info("\(serviceIdentifier) reset", category: .services)
    }
    
    func healthCheck() async -> ServiceHealth {
        let metrics = calculateMetrics()
        let errorRate = getErrorRate()
        
        return ServiceHealth(
            status: errorRate < 0.1 ? .healthy : .degraded,
            lastCheckTime: Date(),
            responseTime: nil,
            errorMessage: nil,
            metadata: [
                "eventCount": "\(events.count)",
                "completionRate": String(format: "%.2f%%", metrics.completionRate * 100),
                "errorRate": String(format: "%.2f%%", errorRate * 100),
                "avgCompletionTime": String(format: "%.1fs", metrics.averageCompletionTime)
            ]
        )
    }
}

// MARK: - Supporting Types
private struct AnalyticsEventRecord {
    let event: ConversationAnalyticsEvent
    let timestamp: Date
    let sessionId: UUID
}

// MARK: - Node Type Extension
extension ConversationNode.NodeType: CaseIterable {
    static var allCases: [ConversationNode.NodeType] {
        [.opening, .goals, .lifestyle, .personality, .preferences, .confirmation]
    }
}