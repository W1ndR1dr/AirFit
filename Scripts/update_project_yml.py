#!/usr/bin/env python3

import os
import yaml

# Base test directory
test_dir = "/Users/Brian/Coding Projects/AirFit/AirFit/AirFitTests"

# Old paths that need updating
old_to_new_mappings = {
    "AirFit/AirFitTests/AI/ContextAnalyzerTests.swift": "AirFit/AirFitTests/Modules/AI/ContextAnalyzerTests.swift",
    "AirFit/AirFitTests/Context/ContextAssemblerTests.swift": "AirFit/AirFitTests/Services/Context/ContextAssemblerTests.swift",
    "AirFit/AirFitTests/FoodTracking/": "AirFit/AirFitTests/Modules/FoodTracking/",
    "AirFit/AirFitTests/Health/HealthKitManagerTests.swift": "AirFit/AirFitTests/Services/Health/HealthKitManagerTests.swift",
    "AirFit/AirFitTests/Workouts/": "AirFit/AirFitTests/Modules/Workouts/",
}

# Read project.yml
with open("/Users/Brian/Coding Projects/AirFit/project.yml", "r") as f:
    content = f.read()

# Replace old paths with new paths
for old_path, new_path in old_to_new_mappings.items():
    content = content.replace(old_path, new_path)

# Write updated project.yml
with open("/Users/Brian/Coding Projects/AirFit/project.yml.updated", "w") as f:
    f.write(content)

print("✅ Created updated project.yml at project.yml.updated")
print("Review the changes and then run:")
print("  mv project.yml.updated project.yml")
print("  xcodegen generate")