#!/bin/bash
# AirFit Remote Deploy Script
# Run this from Claude Code to build and deploy to your iPhone

set -e

PROJECT_DIR="$(dirname "$0")/.."
cd "$PROJECT_DIR"

echo "🔨 Building AirFit..."
xcodebuild -project AirFit.xcodeproj \
  -scheme AirFit \
  -sdk iphoneos \
  -configuration Release \
  -derivedDataPath build \
  clean build \
  CODE_SIGN_IDENTITY="Apple Development" \
  | xcpretty || xcodebuild -project AirFit.xcodeproj -scheme AirFit -sdk iphoneos build

echo ""
echo "📱 Finding your iPhone..."
DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep -i "iphone" | head -1 | awk '{print $NF}' | tr -d '()')

if [ -z "$DEVICE_ID" ]; then
  echo "❌ No iPhone found. Make sure:"
  echo "   1. iPhone is unlocked"
  echo "   2. Tailscale is connected on iPhone"
  echo "   3. iPhone was previously paired via USB"
  exit 1
fi

echo "✅ Found iPhone: $DEVICE_ID"
echo ""
echo "📲 Installing AirFit..."

APP_PATH=$(find build -name "AirFit.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Could not find built app"
  exit 1
fi

xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo ""
echo "🎉 Done! AirFit has been installed on your iPhone."
echo "   Open the app to see your changes!"
