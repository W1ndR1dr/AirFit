# Phase 2: ConversationManager Database Query Optimization

**Actual Problem**: Current `getRecentMessages` fetches ALL database messages then filters in memory. This is genuinely terrible for performance.

**Solution**: Fix the database queries and add simple message classification. No over-engineering.

**EXECUTION PRIORITY: Phase 2 - Infrastructure foundation for scale after Phase 1 user fixes.**

## 1. Core Issues to Fix

1. **Database Query Disaster**: `getRecentMessages` fetches every message in the database, then filters
2. **Repeated Pattern**: All methods (`getConversationStats`, `pruneOldConversations`, etc.) do the same thing
3. **No Message Classification**: Quick commands get the same treatment as conversations

## 2. Implementation

### CRITICAL: Database Index Strategy

**Before implementing predicates, add composite indexes:**

```swift
// Add to CoachMessage model
@Model
final class CoachMessage {
    // ... existing properties ...
    
    // CRITICAL: Add composite index for query performance
    @Attribute(.unique) var id: UUID
    @Attribute(.indexed) var timestamp: Date  // Single index
    
    // COMPOSITE INDEX: Most queries filter by (user.id, conversationID, timestamp)
    // SwiftData automatically creates composite index for commonly queried combinations
    var user: User?
    var conversationID: UUID?
    
    // Add index hint for message type classification  
    @Attribute(.indexed) var messageType: String = MessageType.conversation.rawValue
}
```

**Query Performance Targets:**
- User + ConversationID queries: <10ms for 10K+ messages
- User-only queries: <25ms for 50K+ messages  
- Message type filtering: <5ms additional overhead

### Fix Database Queries (Primary Issue)

**File:** `AirFit/Modules/AI/ConversationManager.swift`

```swift
// Replace the terrible fetch-all-then-filter pattern
func getRecentMessages(
    for user: User,
    conversationId: UUID,
    limit: Int = 20
) async throws -> [AIChatMessage] {
    
    // Use proper SwiftData predicate instead of filtering in memory
    let descriptor = FetchDescriptor<CoachMessage>(
        predicate: #Predicate<CoachMessage> { message in
            message.user?.id == user.id && message.conversationID == conversationId
        },
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    
    let messages = try modelContext.fetch(descriptor)
    
    // Convert and return in chronological order
    let aiMessages = messages.compactMap { message -> AIChatMessage? in
        guard let role = AIMessageRole(rawValue: message.role) else { return nil }
        return AIChatMessage(
            id: message.id,
            role: role,
            content: message.content,
            name: nil,
            functionCall: message.functionCall.map { call in
                AIFunctionCall(name: call.name, arguments: call.arguments.mapValues { $0.value })
            },
            timestamp: message.timestamp
        )
    }
    
    return Array(aiMessages.reversed())
}

func getConversationStats(
    for user: User,
    conversationId: UUID
) async throws -> ConversationStats {
    
    // Use predicate instead of fetching all messages
    let descriptor = FetchDescriptor<CoachMessage>(
        predicate: #Predicate<CoachMessage> { message in
            message.user?.id == user.id && message.conversationID == conversationId
        }
    )
    
    let messages = try modelContext.fetch(descriptor)
    
    let userMessages = messages.filter { $0.role == MessageRole.user.rawValue }
    let assistantMessages = messages.filter { $0.role == MessageRole.assistant.rawValue }
    let totalTokens = messages.compactMap { $0.totalTokens }.reduce(0, +)
    let totalCost = messages.compactMap { $0.estimatedCost }.reduce(0, +)
    
    return ConversationStats(
        totalMessages: messages.count,
        userMessages: userMessages.count,
        assistantMessages: assistantMessages.count,
        totalTokens: totalTokens,
        estimatedCost: totalCost,
        firstMessageDate: messages.min { $0.timestamp < $1.timestamp }?.timestamp,
        lastMessageDate: messages.max { $0.timestamp < $1.timestamp }?.timestamp
    )
}

func getConversationIds(for user: User) async throws -> [UUID] {
    
    // Get distinct conversation IDs with proper query
    let descriptor = FetchDescriptor<CoachMessage>(
        predicate: #Predicate<CoachMessage> { message in
            message.user?.id == user.id && message.conversationID != nil
        }
    )
    
    let messages = try modelContext.fetch(descriptor)
    let conversationIds = Set(messages.compactMap { $0.conversationID })
    
    return Array(conversationIds).sorted { id1, id2 in
        let date1 = messages.filter { $0.conversationID == id1 }.max { $0.timestamp < $1.timestamp }?.timestamp ?? Date.distantPast
        let date2 = messages.filter { $0.conversationID == id2 }.max { $0.timestamp < $1.timestamp }?.timestamp ?? Date.distantPast
        return date1 > date2
    }
}

func pruneOldConversations(
    for user: User,
    keepLast: Int = 5
) async throws {
    
    // Get user's conversation IDs efficiently
    let conversationIds = try await getConversationIds(for: user)
    let idsToDelete = conversationIds.dropFirst(keepLast)
    
    if idsToDelete.isEmpty { return }
    
    // Delete messages from old conversations
    for conversationId in idsToDelete {
        let descriptor = FetchDescriptor<CoachMessage>(
            predicate: #Predicate<CoachMessage> { message in
                message.user?.id == user.id && message.conversationID == conversationId
            }
        )
        
        let messages = try modelContext.fetch(descriptor)
        for message in messages {
            modelContext.delete(message)
        }
    }
    
    try modelContext.save()
    
    AppLogger.info(
        "Pruned \(idsToDelete.count) old conversations for user \(user.id)",
        category: .ai
    )
}
```

### Add Simple Message Classification

**File:** `AirFit/Core/Enums/MessageType.swift`

```swift
enum MessageType: String, Sendable, Codable, CaseIterable {
    case conversation = "conversation"
    case command = "command"
    
    var requiresHistory: Bool {
        switch self {
        case .conversation: return true
        case .command: return false
        }
    }
}
```

**File:** `AirFit/Data/Models/CoachMessage.swift`

```swift
// Add to existing CoachMessage model
var messageType: String = MessageType.conversation.rawValue

var isCommand: Bool {
    messageType == MessageType.command.rawValue
}
```

### Update CoachEngine Classification

**File:** `AirFit/Modules/AI/CoachEngine.swift`

```swift
private func classifyMessage(_ text: String) -> MessageType {
    // Simple heuristics - commands are typically short and action-oriented
    let lowercased = text.lowercased()
    
    // Check for common command patterns
    if lowercased.starts(with: "log ") ||
       lowercased.starts(with: "add ") ||
       lowercased.starts(with: "track ") ||
       lowercased.starts(with: "record ") ||
       lowercased.contains("calories") && text.count < 50 ||
       lowercased.contains("protein") && text.count < 50 {
        return .command
    }
    
    // Short messages are likely commands
    if text.count < 20 {
        return .command
    }
    
    return .conversation
}

// Update processUserMessage
public func processUserMessage(
    _ text: String,
    for user: User,
    conversationId: UUID? = nil
) async throws -> AsyncThrowingStream<CoachEngineResponse, Error> {
    
    let actualConversationId = conversationId ?? UUID()
    let messageType = classifyMessage(text)
    
    // Save user message with classification
    let savedMessage = try await conversationManager.saveUserMessage(
        text,
        for: user,
        conversationId: actualConversationId
    )
    
    // Update message type
    savedMessage.messageType = messageType.rawValue
    try await modelContext.save()
    
    // For commands, use minimal history
    let historyLimit = messageType.requiresHistory ? 20 : 5
    
    let conversationHistory = try await conversationManager.getRecentMessages(
        for: user,
        conversationId: actualConversationId,
        limit: historyLimit
    )
    
    // Continue with existing AI processing...
    return try await streamAIResponse(
        for: user,
        conversationId: actualConversationId,
        history: conversationHistory
    )
}
```

## 3. Testing

**File:** `AirFitTests/AI/ConversationManagerPerformanceTests.swift`

```swift
func test_getRecentMessages_performance_withLargeDataset() async throws {
    // Create 1000 messages across 10 conversations
    for i in 0..<1000 {
        let conversationId = i < 100 ? testConversationId : UUID()
        _ = try await sut.saveUserMessage(
            "Message \(i)",
            for: testUser,
            conversationId: conversationId
        )
    }
    
    let startTime = CFAbsoluteTimeGetCurrent()
    let messages = try await sut.getRecentMessages(
        for: testUser,
        conversationId: testConversationId,
        limit: 20
    )
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    
    XCTAssertEqual(messages.count, 20)
    XCTAssertLessThan(duration, 0.05) // 50ms target
    
    print("Query completed in \(Int(duration * 1000))ms")
}

func test_classifyMessage_detectsCommands() {
    let engine = CoachEngine(/* ... */)
    
    XCTAssertEqual(engine.classifyMessage("Log 500 calories"), .command)
    XCTAssertEqual(engine.classifyMessage("Add protein shake"), .command)
    XCTAssertEqual(engine.classifyMessage("Help me with my workout plan"), .conversation)
    XCTAssertEqual(engine.classifyMessage("How are you feeling today?"), .conversation)
}
```

## 4. Performance Targets

- **Query Speed**: `getRecentMessages` under 50ms for 1000+ message datasets
- **Database Efficiency**: No more fetch-all-then-filter patterns
- **Classification Accuracy**: 90%+ correct command vs conversation detection
- **Memory Usage**: 10x reduction from eliminating full database scans

## 5. Rollout

1. **Week 1**: Deploy database query fixes (low risk, pure optimization)
2. **Week 2**: Deploy message classification (monitor accuracy)
3. **Week 3**: Optimize history limits based on message type

**Rollback**: Remove classification, revert to original queries if needed.

This focuses on the actual performance disaster in the current code and adds simple, working classification without over-engineering. 