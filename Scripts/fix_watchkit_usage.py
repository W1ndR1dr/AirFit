#!/usr/bin/env python3
"""Fix WatchKit usage in WatchWorkoutManager.swift"""

import re

# Read the file
file_path = '/Users/Brian/Coding Projects/AirFit/AirFitWatchApp/Services/WatchWorkoutManager.swift'
with open(file_path, 'r') as f:
    content = f.read()

# Replace all WKInterfaceDevice calls with platform-specific code
watchkit_calls = [
    (r'(\s+)WKInterfaceDevice\.current\(\)\.play\(([^)]+)\)', r'\1#if os(watchOS)\n\1WKInterfaceDevice.current().play(\2)\n\1#endif'),
]

for pattern, replacement in watchkit_calls:
    content = re.sub(pattern, replacement, content)

# Write the fixed content back
with open(file_path, 'w') as f:
    f.write(content)

print("Fixed WatchWorkoutManager.swift")
print("Wrapped all WKInterfaceDevice calls in #if os(watchOS) blocks")