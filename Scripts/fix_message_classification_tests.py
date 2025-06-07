#!/usr/bin/env python3
"""Fix MessageClassificationTests.swift concurrency issues"""

import re

# Read the test file
file_path = '/Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests/Modules/AI/MessageClassificationTests.swift'
with open(file_path, 'r') as f:
    content = f.read()

# Fix 1: Make setUp async and add @MainActor to handle CoachEngine.createDefault
content = re.sub(
    r'override func setUp\(\) \{',
    '@MainActor\n    override func setUp() async {',
    content
)

# Fix 2: Call super.setUp() with await since it's now async
content = re.sub(
    r'super\.setUp\(\)',
    'await super.setUp()',
    content
)

# Fix 3: Make tearDown async and add @MainActor
content = re.sub(
    r'override func tearDown\(\) \{',
    '@MainActor\n    override func tearDown() async {',
    content
)

# Fix 4: Call super.tearDown() with await
content = re.sub(
    r'super\.tearDown\(\)',
    'await super.tearDown()',
    content
)

# Fix 5: Add @MainActor to test methods that access coachEngine properties
# First, let's fix the test_processUserMessage_usesOptimizedHistoryLimits method
content = re.sub(
    r'func test_processUserMessage_usesOptimizedHistoryLimits\(\) async throws \{',
    '@MainActor\n    func test_processUserMessage_usesOptimizedHistoryLimits() async throws {',
    content
)

# Fix 6: Fix line 205 - activeConversationId access (already fixed by @MainActor on method)
# Fix 7: Add @MainActor to helper methods that access coachEngine
content = re.sub(
    r'private func classifyTestMessage\(_ text: String\) async -> MessageType \{',
    '@MainActor\n    private func classifyTestMessage(_ text: String) async -> MessageType {',
    content
)

content = re.sub(
    r'private func getMessageCount\(\) async -> Int \{',
    '@MainActor\n    private func getMessageCount() async -> Int {',
    content
)

content = re.sub(
    r'private func getAllMessages\(\) async throws -> \[CoachMessage\] \{',
    '@MainActor\n    private func getAllMessages() async throws -> [CoachMessage] {',
    content
)

# Fix 8: Add @MainActor to test methods that use coachEngine
test_methods_needing_mainactor = [
    'test_classifyMessage_detectsShortCommands',
    'test_classifyMessage_detectsCommandStarters',
    'test_classifyMessage_detectsNutritionCommands',
    'test_classifyMessage_detectsPatternBasedCommands',
    'test_classifyMessage_detectsConversations',
    'test_classifyMessage_longMessagesAreConversations',
    'test_classifyMessage_edgeCases',
    'test_processUserMessage_storesCorrectClassification',
    'test_classifyMessage_performance',
    'test_classifyMessage_accuracyMetrics'
]

for method_name in test_methods_needing_mainactor:
    # Check if method already has @MainActor
    pattern = rf'(@MainActor\s+)?func {method_name}\('
    if not re.search(rf'@MainActor\s+func {method_name}\(', content):
        content = re.sub(
            rf'func {method_name}\(',
            f'@MainActor\n    func {method_name}(',
            content
        )

# Write the fixed content back
with open(file_path, 'w') as f:
    f.write(content)

print("Fixed MessageClassificationTests.swift")
print("Changes made:")
print("1. Made setUp and tearDown async with @MainActor")
print("2. Added @MainActor to test methods that access coachEngine")
print("3. Added @MainActor to helper methods")
print("4. Fixed super.setUp() and super.tearDown() calls to use await")