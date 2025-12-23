#!/bin/bash
# AirFit Remote Deploy Script
# Run this from Claude Code to build and deploy to your iPhone
# Always does a CLEAN INSTALL to avoid stale data issues

set -e

PROJECT_DIR="$(dirname "$0")/.."
cd "$PROJECT_DIR"

BUNDLE_ID="com.airfit.app"

# Find iPhone first (we need it for uninstall)
echo "📱 Finding your iPhone..."
DEVICE_INFO=$(xcrun devicectl list devices 2>/dev/null | grep -i "iphone" | head -1)
DEVICE_ID=$(echo "$DEVICE_INFO" | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9A-F-]{36}$/) print $i}')
DEVICE_NAME=$(echo "$DEVICE_INFO" | awk '{print $1, $2}' | sed 's/^ *//;s/ *$//')

if [ -z "$DEVICE_ID" ]; then
  echo "❌ No iPhone found. Make sure:"
  echo "   1. iPhone is unlocked"
  echo "   2. Tailscale is connected on iPhone"
  echo "   3. iPhone was previously paired via USB"
  exit 1
fi

echo "✅ Found: $DEVICE_NAME ($DEVICE_ID)"

# Always uninstall first for clean slate
echo ""
echo "🗑️  Uninstalling existing app (clean install)..."
xcrun devicectl device uninstall app --device "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || echo "   (No existing install found)"

# Clean derived data for fresh build
echo ""
echo "🧹 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/AirFit-* 2>/dev/null || true

# Build
echo ""
echo "🔨 Building AirFit (clean build)..."
xcodebuild -project AirFit.xcodeproj \
  -scheme AirFit \
  -sdk iphoneos \
  -configuration Debug \
  -derivedDataPath build \
  -allowProvisioningUpdates \
  clean build \
  | xcpretty || xcodebuild -project AirFit.xcodeproj -scheme AirFit -sdk iphoneos -configuration Debug -derivedDataPath build -allowProvisioningUpdates clean build

# Find and install
echo ""
echo "📲 Installing AirFit..."

APP_PATH=$(find build -name "AirFit.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Could not find built app"
  exit 1
fi

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo ""
echo "🎉 Clean install complete!"
echo "   App data has been reset - you'll go through onboarding again."
echo "   (HealthKit data syncs automatically, only persona needs re-setup)"
