# Conversation System Rightsizing Implementation Plan

## Purpose
This document expands upon `CONVERSATION_SYSTEM_RIGHTSIZING_ANALYSIS.md`. It
outlines concrete refactoring steps to align the codebase with the Domain 3
optimization goals from `AI_ARCHITECTURE_OPTIMIZATION_FRAMEWORK.md`.

---

## 1. Review of Current Implementation
The existing `ConversationManager` persists **every** message to `SwiftData`.
Relevant code snippets illustrate the behavior:

```swift
// ConversationManager.swift
await conversationManager.saveUserMessage(
    text,
    for: user,
    conversationId: conversationId
)
```

```swift
func getRecentMessages(..., limit: Int = 20) async throws -> [AIChatMessage] {
    var descriptor = FetchDescriptor<CoachMessage>()
    descriptor.sortBy = [SortDescriptor(\.timestamp, order: .reverse)]
    let allMessages = try modelContext.fetch(descriptor)
    let filteredMessages = allMessages
        .filter { message in
            message.user?.id == user.id &&
            message.conversationID == conversationId
        }
        .prefix(limit)
    // converted to AIChatMessage
}
```

These snippets show that messages are always written to persistent storage
and the retrieval path loads all data then filters in memory. The manager does
provide pruning via `pruneOldConversations`, but no ephemeral path.

## 2. Alignment With Rightsizing Goals
The analysis identified the need for **selective persistence** and **hybrid
interaction handling**. Current code partially addresses history management via
`pruneOldConversations(for:keepLast:)` and performance tests in
`ConversationManagerPerformanceTests`. However, there is no
`InteractionType` to differentiate chat sessions from transactional commands, and
the persistence layer is used for all flows.

Areas that align with the plan:
- Clear API for saving and retrieving messages (`saveUserMessage`,
  `createAssistantMessage`, `getRecentMessages`).
- Pruning and archiving APIs for long‑term storage management.
- Performance tests ensuring operations stay under 100–200 ms.

Areas that diverge:
- No ephemeral or in-memory storage for transactional commands.
- `getRecentMessages` fetches **all** messages then filters in memory,
  causing overhead for large histories.
- `CoachEngine` always assigns a new conversation ID but never classifies
  interaction type.

## 3. Proposed Refactoring Steps
To realize the rightsizing strategy, the following incremental changes are
recommended:

1. **Introduce `InteractionType`**
   - Add an enum (`chat`, `transaction`, `hybrid`) in the AI module.
   - Extend `CoachEngine.processUserMessage` and `ConversationManager` APIs to
     accept this type.
   - Default to `.chat` for existing calls to preserve behavior.

2. **Add Ephemeral In‑Memory Buffer**
   - Within `ConversationManager`, maintain an in-memory array of recent
     `CoachMessage` instances for `.transaction` interactions.
   - Skip `modelContext.insert` for ephemeral saves.
   - Provide a helper `getEphemeralMessages()` used by
     `getRecentMessages` when the interaction is non-chat.

3. **Optimize Retrieval**
   - Replace the current "fetch all then filter" approach with a compound
     `FetchDescriptor` that queries by `conversationID` and `user.id` directly
     using SwiftData predicates. This reduces memory pressure for long histories.

4. **ContextAssembler Helper**
   - Create a lightweight `ContextAssembler` extension to gather the latest
     health snapshot and last few ephemeral messages without hitting persistent
     storage.

5. **Instrumentation**
   - Log the `InteractionType` for every request and measure average retrieved
     message count. Compare performance of in-memory vs persistent modes.
   - Add unit tests verifying that ephemeral messages are discarded after
     completion and that performance improves for large datasets.

6. **Migration and Backwards Compatibility**
   - Provide a migration script that leaves existing conversations intact but
     starts new conversations with a flagged interaction type.
   - Document API changes in the developer guide.

## 4. Expected Outcomes
Implementing the above steps should achieve the metrics defined in the analysis:

- **Selective Complexity** – only chat sessions incur full persistence cost.
- **Context Preservation** – transactional flows still receive dynamic health
  snapshots via `ContextAssembler`.
- **Storage Efficiency** – fewer messages persisted, reducing CoreData size.
- **Performance Optimization** – targeted fetches and ephemeral mode speed up
  context retrieval.

Progress toward these outcomes should be validated through existing performance
 tests and new ephemeral‑mode unit tests.

---

*Prepared for the Module 8.5 refactoring initiative.*
