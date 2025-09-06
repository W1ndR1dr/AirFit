import Foundation
import Combine
import os

/// Legacy metrics adapter for ChatStreamingStore.
/// Note: Since ChatStreamingStore now handles metrics collection directly,
/// this adapter is deprecated but maintained for compatibility.
@MainActor
final class ChatStreamingMetricsAdapter {
    private var cancellable: AnyCancellable?
    private let logger = ObsCategories.streaming

    init(store: ChatStreamingStore) {
        // Subscribe to typed streaming events for additional metrics collection
        // The primary metrics collection is now handled directly in DefaultChatStreamingStore
        
        // Dynamic cast to an internal protocol that exposes events
        if let eventSource = store as? _ChatStreamingEventSource {
            cancellable = eventSource.events.sink { [weak self] event in
                self?.handle(event)
            }
        }
    }

    private func handle(_ event: ChatStreamingEvent) {
        // Additional legacy metrics handling if needed
        // Primary metrics collection is now in DefaultChatStreamingStore
        switch event.kind {
        case .started:
            // Legacy signpost handling - now handled in store
            break
        case .delta(_):
            // Legacy delta tracking - now handled in store
            break
        case .finished(_):
            // Legacy completion tracking - now handled in store
            break
        }
    }
}

// Internal protocol to allow the adapter to observe events without constraining ChatStreamingStore
protocol _ChatStreamingEventSource {
    var events: AnyPublisher<ChatStreamingEvent, Never> { get }
}

