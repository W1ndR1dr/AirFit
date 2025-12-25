#!/bin/bash
# AirFit TestFlight Deployment Script
# Automates: Archive → Export → Upload to TestFlight
#
# CREDENTIALS SETUP (one-time):
#   1. Create API key at: https://appstoreconnect.apple.com/access/integrations/api
#   2. Download the .p8 file to ~/.appstore/AuthKey_XXXXXX.p8
#   3. Create ~/.appstore/credentials:
#        export APP_STORE_CONNECT_API_KEY_ID="your-key-id"
#        export APP_STORE_CONNECT_API_ISSUER_ID="your-issuer-id"
#        export APP_STORE_CONNECT_API_KEY_PATH="$HOME/.appstore/AuthKey_XXXXXX.p8"
#   4. Secure: chmod 700 ~/.appstore && chmod 600 ~/.appstore/*
#
# The script auto-sources ~/.appstore/credentials if it exists.
#
# USAGE:
#   ./scripts/deploy-to-testflight.sh                    # Deploy current version
#   ./scripts/deploy-to-testflight.sh --bump-build       # Auto-increment build number
#   ./scripts/deploy-to-testflight.sh --version 1.2.0    # Set specific version
#
# PREREQUISITES:
#   - Valid distribution certificate (Xcode handles with Automatic Signing)
#   - App must exist in App Store Connect

set -e

# ============================================================================
# Configuration
# ============================================================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

SCHEME="AirFit"
PROJECT="AirFit.xcodeproj"
BUNDLE_ID="com.airfit.app"
TEAM_ID="2H43Q8Y3CR"

BUILD_DIR="$PROJECT_DIR/build/testflight"
ARCHIVE_PATH="$BUILD_DIR/AirFit.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS_PATH="$PROJECT_DIR/scripts/ExportOptions.plist"

# ============================================================================
# Parse Arguments
# ============================================================================

BUMP_BUILD=false
NEW_VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --bump-build)
            BUMP_BUILD=true
            shift
            ;;
        --version)
            NEW_VERSION="$2"
            shift 2
            ;;
        --help)
            head -35 "$0" | tail -32
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Validate Prerequisites
# ============================================================================

echo "🚀 AirFit TestFlight Deployment"
echo "================================"
echo ""

# Auto-source credentials from ~/.appstore/credentials if available
CREDENTIALS_FILE="$HOME/.appstore/credentials"
if [[ -f "$CREDENTIALS_FILE" ]]; then
    echo "🔐 Loading credentials from ~/.appstore/credentials"
    source "$CREDENTIALS_FILE"
fi

# Check for API key credentials
if [[ -z "$APP_STORE_CONNECT_API_KEY_ID" ]] || \
   [[ -z "$APP_STORE_CONNECT_API_ISSUER_ID" ]] || \
   [[ -z "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
    echo "⚠️  App Store Connect API credentials not found."
    echo ""
    echo "Quick setup:"
    echo "  1. Create ~/.appstore/credentials with:"
    echo "     export APP_STORE_CONNECT_API_KEY_ID=\"your-key-id\""
    echo "     export APP_STORE_CONNECT_API_ISSUER_ID=\"your-issuer-id\""
    echo "     export APP_STORE_CONNECT_API_KEY_PATH=\"\$HOME/.appstore/AuthKey_XXX.p8\""
    echo ""
    echo "  2. Secure it: chmod 600 ~/.appstore/credentials"
    echo ""
    echo "Get credentials at: https://appstoreconnect.apple.com/access/integrations/api"
    exit 1
fi

if [[ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
    echo "❌ API key file not found: $APP_STORE_CONNECT_API_KEY_PATH"
    exit 1
fi

echo "✅ API credentials configured"

# Check for ExportOptions.plist
if [[ ! -f "$EXPORT_OPTIONS_PATH" ]]; then
    echo "❌ ExportOptions.plist not found at: $EXPORT_OPTIONS_PATH"
    echo "   Run: xcodebuild -exportArchive -help for format"
    exit 1
fi

echo "✅ ExportOptions.plist found"

# ============================================================================
# Version/Build Management
# ============================================================================

INFO_PLIST="$PROJECT_DIR/AirFit/Info.plist"

if [[ -n "$NEW_VERSION" ]]; then
    echo ""
    echo "📝 Setting version to $NEW_VERSION..."
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" "$INFO_PLIST"
fi

if [[ "$BUMP_BUILD" == true ]]; then
    CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "0")
    NEW_BUILD=$((CURRENT_BUILD + 1))
    echo ""
    echo "📝 Bumping build number: $CURRENT_BUILD → $NEW_BUILD"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_BUILD" "$INFO_PLIST"
fi

CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "1.0")
CURRENT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "1")

echo ""
echo "📦 Version: $CURRENT_VERSION ($CURRENT_BUILD)"

# ============================================================================
# Clean & Prepare
# ============================================================================

echo ""
echo "🧹 Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Regenerate Xcode project from project.yml if XcodeGen is available
if command -v xcodegen &> /dev/null && [[ -f "$PROJECT_DIR/project.yml" ]]; then
    echo ""
    echo "🔧 Regenerating Xcode project..."
    xcodegen generate --spec "$PROJECT_DIR/project.yml" --project "$PROJECT_DIR"
fi

# ============================================================================
# Archive
# ============================================================================

echo ""
echo "📦 Creating archive..."
echo "   This may take a few minutes..."

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS' \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    | xcpretty || xcodebuild archive \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'generic/platform=iOS' \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="$TEAM_ID"

if [[ ! -d "$ARCHIVE_PATH" ]]; then
    echo "❌ Archive failed"
    exit 1
fi

echo "✅ Archive created"

# ============================================================================
# Export IPA
# ============================================================================

echo ""
echo "📤 Exporting IPA for App Store..."

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates \
    | xcpretty || xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
        -allowProvisioningUpdates

IPA_PATH=$(find "$EXPORT_PATH" -name "*.ipa" -type f | head -1)

if [[ -z "$IPA_PATH" ]]; then
    echo "❌ Export failed - no IPA found"
    exit 1
fi

echo "✅ IPA exported: $(basename "$IPA_PATH")"

# ============================================================================
# Upload to TestFlight
# ============================================================================

echo ""
echo "☁️  Uploading to TestFlight..."
echo "   This may take several minutes depending on app size..."

xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID"

echo ""
echo "============================================"
echo "🎉 SUCCESS! Uploaded to TestFlight"
echo "============================================"
echo ""
echo "Version: $CURRENT_VERSION ($CURRENT_BUILD)"
echo "Bundle:  $BUNDLE_ID"
echo ""
echo "Next steps:"
echo "  1. Wait for processing (~5-15 minutes)"
echo "  2. Check App Store Connect for build status"
echo "  3. Add testers or submit for review"
echo ""
echo "App Store Connect: https://appstoreconnect.apple.com"
