# ChatStreamingStore Unified Architecture

## Overview

The ChatStreamingStore provides a unified, typed streaming architecture for real-time chat events in AirFit. This system replaces the previous NotificationCenter-based approach with a clean, observable, and metrics-integrated solution.

## Architecture Components

### Core Protocol

```swift
protocol ChatStreamingStore: AnyObject, Sendable {
    var events: AnyPublisher<ChatStreamingEvent, Never> { get }
    func publish(_ event: ChatStreamingEvent)
}
```

### Event Model

```swift
struct ChatStreamingEvent: Sendable {
    enum Kind: Sendable {
        case started
        case delta(String)
        case finished(usage: AITokenUsage?)
    }
    
    let conversationId: UUID
    let kind: Kind
    let timestamp: Date
}
```

### Implementation

The `DefaultChatStreamingStore` provides:

- **Typed Events**: Strongly-typed streaming events with automatic timestamp generation
- **Metrics Collection**: Built-in OSLog signposts for performance monitoring
- **Performance Analytics**: Token count tracking, streaming duration, tokens-per-second calculation
- **Memory Management**: Automatic cleanup of active stream tracking

## Integration Points

### Producers

**CoachOrchestrator** publishes streaming events:

```swift
// Start streaming
streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .started))

// Delta events
streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .delta(token)))

// Completion
streamStore?.publish(ChatStreamingEvent(conversationId: conversationId, kind: .finished(usage: usage)))
```

### Consumers

**ChatViewModel** subscribes to events:

```swift
streamStore.events
    .receive(on: RunLoop.main)
    .sink { event in
        guard let session = self.currentSession,
              event.conversationId == session.id else { return }
        switch event.kind {
        case .started:
            self.isStreaming = true
            self.streamingText = ""
        case .delta(let text):
            self.streamingText += text
        case .finished:
            self.isStreaming = false
        }
    }
    .store(in: &cancellables)
```

## Dependency Injection

### Registration

```swift
// Chat Streaming Store (typed events)
container.register(ChatStreamingStore.self, lifetime: .singleton) { _ in
    DefaultChatStreamingStore()
}

// Legacy metrics adapter (deprecated but maintained for compatibility)
container.register(ChatStreamingMetricsAdapter.self, lifetime: .singleton) { resolver in
    let store = try await resolver.resolve(ChatStreamingStore.self)
    return await MainActor.run {
        ChatStreamingMetricsAdapter(store: store)
    }
}
```

### Usage

ViewModels receive the ChatStreamingStore through dependency injection:

```swift
func makeChatViewModel(user: User) async throws -> ChatViewModel {
    // ... other dependencies
    async let streamStore = container.resolve(ChatStreamingStore.self)
    
    return try await ChatViewModel(
        // ... other parameters
        streamStore: streamStore
    )
}
```

## Metrics and Observability

### OSLog Signposts

The system automatically emits OSLog signposts for:

- **Stream Start**: `stream.start` with conversation ID
- **Token Deltas**: `stream.delta` with token count and character length
- **Stream Completion**: `stream.complete` with duration, token count, and tokens-per-second

### Performance Metrics

Each streaming session tracks:

- Start time
- Token count
- Duration
- Tokens per second
- Total token usage (from AI provider)

### Usage in Instruments

Use the following signpost categories in Instruments:

- **Subsystem**: `com.airfit`
- **Category**: `streaming`
- **Signpost Names**: `stream.start`, `stream.delta`, `stream.complete`

## Migration Notes

### From NotificationCenter

The previous NotificationCenter-based streaming has been largely replaced, with one exception:

- **Stream Events**: Now use ChatStreamingStore events
- **Message Completion**: Still uses `.coachAssistantMessageCreated` notification for persistence coordination

### Legacy Support

The `ChatStreamingMetricsAdapter` remains for compatibility but is deprecated. All primary metrics collection is now handled directly in `DefaultChatStreamingStore`.

## Benefits

### Type Safety
- Compile-time verification of event structure
- No string-based notification names
- Clear event lifecycle

### Performance
- Built-in performance monitoring
- Automatic metrics collection
- Low-overhead event distribution

### Testability
- Injectable dependency
- Observable event stream
- Mockable for unit tests

### Maintainability
- Single source of truth for streaming events
- Clear producer/consumer relationships
- Centralized metrics collection

## Usage Examples

### Basic Event Publishing

```swift
// In AI processing components
let event = ChatStreamingEvent(conversationId: sessionId, kind: .started)
streamStore.publish(event)

// Token streaming
for token in streamedTokens {
    let deltaEvent = ChatStreamingEvent(conversationId: sessionId, kind: .delta(token))
    streamStore.publish(deltaEvent)
}

// Completion
let finishedEvent = ChatStreamingEvent(conversationId: sessionId, kind: .finished(usage: tokenUsage))
streamStore.publish(finishedEvent)
```

### Event Subscription

```swift
// In UI ViewModels
private func setupStreamingObservation() {
    streamStore.events
        .receive(on: RunLoop.main)
        .sink { [weak self] event in
            self?.handleStreamingEvent(event)
        }
        .store(in: &cancellables)
}
```

### Testing

```swift
class MockChatStreamingStore: ChatStreamingStore {
    private let subject = PassthroughSubject<ChatStreamingEvent, Never>()
    var events: AnyPublisher<ChatStreamingEvent, Never> { subject.eraseToAnyPublisher() }
    
    func publish(_ event: ChatStreamingEvent) {
        subject.send(event)
    }
}
```

## Future Considerations

1. **Extended Metrics**: Consider adding more detailed performance metrics
2. **Error Events**: Add error event types for failed streams
3. **Multi-Session**: Optimize for concurrent streaming sessions
4. **Backpressure**: Add backpressure handling for high-frequency streams
5. **Replay**: Consider adding replay capabilities for reconnection scenarios