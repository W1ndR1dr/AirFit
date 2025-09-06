import Foundation
import Combine
import os

// MARK: - Chat Streaming Store Protocol

/// Typed wrapper around chat streaming lifecycle to reduce NotificationCenter coupling.
/// Provides unified streaming events with integrated metrics collection and OSLog signposts.
protocol ChatStreamingStore: AnyObject, Sendable {
    var events: AnyPublisher<ChatStreamingEvent, Never> { get }
    func publish(_ event: ChatStreamingEvent)
}

struct ChatStreamingEvent: Sendable {
    enum Kind: Sendable {
        case started
        case delta(String)
        case finished(usage: AITokenUsage?)
    }

    let conversationId: UUID
    let kind: Kind
    let timestamp: Date
    
    init(conversationId: UUID, kind: Kind) {
        self.conversationId = conversationId
        self.kind = kind
        self.timestamp = Date()
    }
}

// MARK: - Default Implementation

final class DefaultChatStreamingStore: ChatStreamingStore, _ChatStreamingEventSource {
    private let subject = PassthroughSubject<ChatStreamingEvent, Never>()
    private let logger = OSLog(subsystem: "com.airfit", category: "streaming")
    private var activeStreams: [UUID: StreamMetrics] = [:]
    
    var events: AnyPublisher<ChatStreamingEvent, Never> { subject.eraseToAnyPublisher() }

    init() {}

    func publish(_ event: ChatStreamingEvent) {
        // Collect metrics and emit OSLog signposts
        handleMetricsCollection(for: event)
        
        // Forward event to subscribers
        subject.send(event)
    }
    
    // MARK: - Private Metrics Collection
    
    private func handleMetricsCollection(for event: ChatStreamingEvent) {
        switch event.kind {
        case .started:
            let signpostID = OSSignpostID(log: logger)
            os_signpost(.begin, log: logger, name: "stream.start", signpostID: signpostID, 
                       "conversationId=%{public}@", event.conversationId.uuidString)
            
            activeStreams[event.conversationId] = StreamMetrics(
                signpostID: signpostID,
                startTime: event.timestamp,
                tokenCount: 0
            )
            
        case .delta(let token):
            if let metrics = activeStreams[event.conversationId] {
                activeStreams[event.conversationId] = StreamMetrics(
                    signpostID: metrics.signpostID,
                    startTime: metrics.startTime,
                    tokenCount: metrics.tokenCount + 1
                )
                
                os_signpost(.event, log: logger, name: "stream.delta", 
                           signpostID: metrics.signpostID,
                           "len=%d tokenCount=%d", token.count, metrics.tokenCount + 1)
            }
            
        case .finished(let usage):
            if let metrics = activeStreams.removeValue(forKey: event.conversationId) {
                let duration = event.timestamp.timeIntervalSince(metrics.startTime)
                let tokensPerSecond = duration > 0 ? Double(metrics.tokenCount) / duration : 0
                
                os_signpost(.end, log: logger, name: "stream.complete", 
                           signpostID: metrics.signpostID,
                           "duration=%.3f tokenCount=%d tokensPerSec=%.1f totalTokens=%d",
                           duration, metrics.tokenCount, tokensPerSecond, usage?.totalTokens ?? 0)
                
                // Log performance metrics for monitoring
                AppLogger.info("Stream completed: duration=\(String(format: "%.3f", duration))s, tokens=\(metrics.tokenCount), tps=\(String(format: "%.1f", tokensPerSecond))", 
                              category: .ai)
            }
        }
    }
}

// MARK: - Supporting Types

private struct StreamMetrics {
    let signpostID: OSSignpostID
    let startTime: Date
    let tokenCount: Int
}
