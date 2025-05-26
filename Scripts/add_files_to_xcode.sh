#!/bin/bash

# Script to automatically add new Swift files to Xcode project
# Usage: ./Scripts/add_files_to_xcode.sh [directory_to_scan]

set -e

PROJECT_FILE="AirFit.xcodeproj"
TARGET_NAME="AirFit"
SCAN_DIR="${1:-AirFit}"

# Ensure pbxproj is available
if ! command -v pbxproj &> /dev/null; then
    echo "Installing pbxproj..."
    if command -v pipx &> /dev/null; then
        pipx install pbxproj
        export PATH="/Users/$(whoami)/.local/bin:$PATH"
    else
        echo "Please install pipx first: brew install pipx"
        exit 1
    fi
fi

# Add PATH for pbxproj
export PATH="/Users/$(whoami)/.local/bin:$PATH"

echo "Scanning for Swift files in $SCAN_DIR..."

# Find all Swift files not already in project
find "$SCAN_DIR" -name "*.swift" -type f | while read -r file; do
    # Check if file is already in project
    if ! grep -q "$(basename "$file")" "$PROJECT_FILE/project.pbxproj" 2>/dev/null; then
        echo "Adding $file to project..."
        pbxproj file -t "$TARGET_NAME" "$PROJECT_FILE" "$file" || echo "Failed to add $file"
    else
        echo "File $(basename "$file") already in project"
    fi
done

echo "Done! All Swift files have been added to the Xcode project."
echo "You may need to clean and rebuild the project." 