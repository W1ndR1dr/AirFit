import Foundation
import Combine
import os

@MainActor
final class ChatStreamingMetricsAdapter {
    private var cancellable: AnyCancellable?
    private let logger = ObsCategories.streaming

    init(store: ChatStreamingStore) {
        // Subscribe to typed streaming events if available
        // This adapter assumes the store exposes a Combine publisher of events
        // and will no-op if such a publisher is not present at runtime.

        // Dynamic cast to an internal protocol that exposes events
        if let eventSource = store as? _ChatStreamingEventSource {
            cancellable = eventSource.events.sink { [weak self] event in
                self?.handle(event)
            }
        }
    }

    private func handle(_ event: ChatStreamingEvent) {
        switch event.kind {
        case .started:
            var id = OSSignpostID(log: logger)
            spBegin(logger, StaticString(SignpostNames.streamStart), &id)
            active[event.conversationId] = id
        case .delta(let token):
            // Emit a signpost for deltas to enable token/sec sampling
            if let id = active[event.conversationId] {
                os_signpost(.event, log: logger, name: StaticString(SignpostNames.streamDelta), signpostID: id, "len=%d", token.count)
            }
        case .finished:
            if let id = active.removeValue(forKey: event.conversationId) {
                spEnd(logger, StaticString(SignpostNames.streamComplete), id)
            }
        }
    }

    // Keep track of active streams to pair begin/end
    private var active: [UUID: OSSignpostID] = [:]
}

// Internal protocol to allow the adapter to observe events without constraining ChatStreamingStore
protocol _ChatStreamingEventSource {
    var events: AnyPublisher<ChatStreamingEvent, Never> { get }
}

