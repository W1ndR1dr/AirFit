#!/bin/bash

echo "📝 Updating project.yml with new test paths..."

cd "/Users/Brian/Coding Projects/AirFit"

# Backup original
cp project.yml project.yml.backup

# Update the paths using sed
sed -i '' 's|AirFit/AirFitTests/AI/ContextAnalyzerTests.swift|AirFit/AirFitTests/Modules/AI/ContextAnalyzerTests.swift|g' project.yml
sed -i '' 's|AirFit/AirFitTests/Health/HealthKitManagerTests.swift|AirFit/AirFitTests/Services/Health/HealthKitManagerTests.swift|g' project.yml
sed -i '' 's|AirFit/AirFitTests/Workouts/WorkoutViewModelTests.swift|AirFit/AirFitTests/Modules/Workouts/WorkoutViewModelTests.swift|g' project.yml
sed -i '' 's|AirFit/AirFitTests/Workouts/WorkoutCoordinatorTests.swift|AirFit/AirFitTests/Modules/Workouts/WorkoutCoordinatorTests.swift|g' project.yml
sed -i '' 's|AirFit/AirFitTests/FoodTracking/|AirFit/AirFitTests/Modules/FoodTracking/|g' project.yml

# Remove the exclude for Context tests since it's moved
sed -i '' '/Context\/ContextAssemblerTests.swift/d' project.yml

# Add new line for Context test in Services
sed -i '' '/- AirFit\/AirFitTests\/Services\/TestHelpers.swift/a\
      - AirFit/AirFitTests/Services/Context/ContextAssemblerTests.swift' project.yml

echo "✅ Updated project.yml with new test paths"
echo ""
echo "Changes made:"
echo "- Moved AI tests to Modules/AI/"
echo "- Moved Context tests to Services/Context/"
echo "- Moved FoodTracking tests to Modules/FoodTracking/"
echo "- Moved Health tests to Services/Health/"
echo "- Moved Workouts tests to Modules/Workouts/"
echo ""
echo "Next: Run 'xcodegen generate'"