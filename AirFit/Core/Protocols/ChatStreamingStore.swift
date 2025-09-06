import Foundation
import Combine

// MARK: - Chat Streaming Store Protocol

/// Typed wrapper around chat streaming lifecycle to reduce NotificationCenter coupling.
/// Initial implementation bridges existing notifications to a strongly-typed stream.
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
}

// MARK: - Default Implementation

final class DefaultChatStreamingStore: ChatStreamingStore, _ChatStreamingEventSource {
    private let subject = PassthroughSubject<ChatStreamingEvent, Never>()
    var events: AnyPublisher<ChatStreamingEvent, Never> { subject.eraseToAnyPublisher() }

    init() {}

    func publish(_ event: ChatStreamingEvent) {
        subject.send(event)
    }
}
