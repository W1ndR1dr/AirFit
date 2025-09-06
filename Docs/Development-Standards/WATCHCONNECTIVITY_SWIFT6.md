# WatchConnectivity with Swift 6 Concurrency

**Created**: 2025-01-06  
**Status**: Active Standard  
**Focus**: Swift 6 strict concurrency compliance for WatchConnectivity

## Overview

WatchConnectivity presents unique challenges with Swift 6's strict concurrency checking because:
1. `WCSessionDelegate` methods are nonisolated and run on background threads
2. The framework uses `[String: Any]` dictionaries which are not Sendable
3. Delegate callbacks need to communicate with @MainActor isolated code

This document defines the standard patterns for handling these challenges.

## The Problem

```swift
// ❌ BAD - This causes data race warnings
nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    Task { @MainActor in
        // Error: Capture of 'message' with non-sendable type '[String : Any]'
        handleMessage(message)
    }
}
```

## Solution: Type-Safe Message Wrappers

### 1. Define Sendable Message Types

Create type-safe wrappers for all WatchConnectivity messages:

```swift
// Request structure (Sendable by default as a struct with Sendable properties)
struct WorkoutTransferMessage: Sendable {
    let planData: Data
    let planId: UUID
    let timestamp: Date
    
    /// Convert to dictionary for WatchConnectivity
    var dictionary: [String: Any] {
        return [
            "type": "plannedWorkout",
            "planData": planData,
            "planId": planId.uuidString,
            "timestamp": timestamp.timeIntervalSince1970
        ]
    }
}

// Response structure
struct WorkoutTransferResponse: Sendable {
    let success: Bool
    let errorMessage: String?
    
    /// Initialize from WatchConnectivity reply dictionary
    init?(dictionary: [String: Any]) {
        guard let success = dictionary["success"] as? Bool else {
            return nil
        }
        self.success = success
        self.errorMessage = dictionary["error"] as? String
    }
}
```

### 2. Create Type-Safe Async Wrappers

Wrap WCSession methods with type-safe async functions:

```swift
/// Type-safe async wrapper for sendMessage
private func sendTransferMessage(_ message: WorkoutTransferMessage) async throws -> WorkoutTransferResponse {
    return try await withCheckedThrowingContinuation { continuation in
        session.sendMessage(message.dictionary, replyHandler: { @Sendable reply in
            guard let response = WorkoutTransferResponse(dictionary: reply) else {
                continuation.resume(throwing: AppError.invalidResponse)
                return
            }
            continuation.resume(returning: response)
        }, errorHandler: { @Sendable error in
            continuation.resume(throwing: error)
        })
    }
}
```

### 3. Handle Delegate Methods Properly

Extract only Sendable data before crossing isolation boundaries:

```swift
nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    // Extract only Sendable data before crossing isolation boundary
    let isReachable = session.isReachable
    
    Task { @MainActor [weak service] in
        await service?.handleSessionReachabilityChange(isReachable: isReachable)
    }
}

nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    // For complex data, serialize/deserialize to create Sendable copy
    guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
          let messageCopy = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        return
    }
    
    Task { @MainActor in
        handleReceivedMessage(messageCopy)
    }
}
```

## Delegate Handler Pattern

Use a separate NSObject subclass for WCSessionDelegate:

```swift
/// Separate delegate handler to manage WCSession callbacks
final class WorkoutPlanTransferDelegateHandler: NSObject, WCSessionDelegate {
    private weak var service: WorkoutPlanTransferService?
    
    func configure(with service: WorkoutPlanTransferService) {
        self.service = service
    }
    
    // Delegate methods here...
}
```

## Key Principles

1. **Never pass [String: Any] across isolation boundaries** - Always convert to type-safe Sendable types
2. **Use @Sendable closures** - Mark continuation closures as @Sendable
3. **Extract primitive values** - For simple data, extract primitives (Bool, String, Int) before Task creation
4. **Weak references in Tasks** - Use `[weak service]` to avoid retain cycles
5. **Serialize for complex data** - Use JSON serialization to create Sendable copies when needed

## Common Patterns

### Sending Data
```swift
// 1. Create type-safe message
let message = MyMessage(data: someData)

// 2. Use async wrapper
let response = try await sendMessage(message)

// 3. Handle response
if response.success {
    // Success handling
}
```

### Receiving Data
```swift
// 1. In delegate method, extract Sendable data
let sendableData = extractSendableData(from: dictionary)

// 2. Pass to MainActor
Task { @MainActor in
    await handleData(sendableData)
}
```

## Testing Considerations

1. Mock WCSession for unit tests
2. Test serialization/deserialization of message types
3. Verify proper error handling for malformed messages
4. Test behavior when watch is not reachable

## Migration Checklist

When updating WatchConnectivity code for Swift 6:

- [ ] Replace all [String: Any] parameters with type-safe structs
- [ ] Add @Sendable to continuation closures
- [ ] Extract Sendable data before creating Tasks
- [ ] Use weak references in Task closures
- [ ] Test with strict concurrency checking enabled
- [ ] Verify no runtime crashes with Swift 6 mode

## References

- [Apple Developer Forums: WatchConnectivity Swift 6](https://developer.apple.com/forums/thread/771525)
- [Swift Evolution: Sendable Types](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [WWDC: Migrate to Swift 6](https://developer.apple.com/videos/play/wwdc2024/10169/)