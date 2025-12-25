#!/bin/bash
# AirFit TestFlight Deployment Script
# Automates: Archive → Export → Upload to TestFlight → Auto-Generate Release Notes
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
#   ./scripts/deploy-to-testflight.sh --skip-notes       # Skip changelog generation
#
# FEATURES:
#   - Auto-generates friendly release notes using Claude CLI
#   - Pushes "What's New" to TestFlight via App Store Connect API
#   - Warm, humorous tone that keeps testers informed and delighted
#
# PREREQUISITES:
#   - Valid distribution certificate (Xcode handles with Automatic Signing)
#   - App must exist in App Store Connect
#   - Claude CLI installed (for changelog generation)

set -e

# ============================================================================
# Configuration
# ============================================================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

SCHEME="AirFit-iOS"
PROJECT="AirFit.xcodeproj"
BUNDLE_ID="com.airfit.app"
TEAM_ID="2H43Q8Y3CR"
APP_APPLE_ID="6756983116"  # From App Store Connect API

BUILD_DIR="$PROJECT_DIR/build/testflight"
ARCHIVE_PATH="$BUILD_DIR/AirFit.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS_PATH="$PROJECT_DIR/scripts/ExportOptions.plist"

# ============================================================================
# Helper Functions
# ============================================================================

# Check if Python cryptography library is available for JWT signing
check_jwt_deps() {
    python3 -c "from cryptography.hazmat.primitives import hashes" 2>/dev/null
}

# Generate JWT for App Store Connect API using Python
# Uses ES256 algorithm as required by Apple
generate_jwt() {
    local key_id="$1"
    local issuer_id="$2"
    local key_path="$3"

    if ! check_jwt_deps; then
        echo ""  # Return empty - caller will handle fallback
        return 1
    fi

    python3 << EOF
import json
import time
import base64
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature
from cryptography.hazmat.backends import default_backend

def base64url_encode(data):
    if isinstance(data, str):
        data = data.encode('utf-8')
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

# Load the private key
with open("$key_path", "rb") as f:
    private_key = serialization.load_pem_private_key(f.read(), password=None, backend=default_backend())

# Create header and payload
header = {"alg": "ES256", "kid": "$key_id", "typ": "JWT"}
now = int(time.time())
payload = {"iss": "$issuer_id", "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}

# Encode header and payload
header_b64 = base64url_encode(json.dumps(header, separators=(',', ':')))
payload_b64 = base64url_encode(json.dumps(payload, separators=(',', ':')))
message = f"{header_b64}.{payload_b64}".encode('utf-8')

# Sign with ES256
signature_der = private_key.sign(message, ec.ECDSA(hashes.SHA256()))
r, s = decode_dss_signature(signature_der)

# Convert to fixed-size R||S format (32 bytes each for P-256)
r_bytes = r.to_bytes(32, byteorder='big')
s_bytes = s.to_bytes(32, byteorder='big')
signature_b64 = base64url_encode(r_bytes + s_bytes)

print(f"{header_b64}.{payload_b64}.{signature_b64}")
EOF
}

# Generate friendly changelog using Claude CLI
generate_changelog() {
    local previous_tag="$1"

    # Get commits since last tag (or last 15 commits if no tag)
    local commits
    if [[ -n "$previous_tag" ]]; then
        commits=$(git log --oneline "$previous_tag"..HEAD 2>/dev/null | head -20)
    else
        commits=$(git log --oneline -15 2>/dev/null)
    fi

    if [[ -z "$commits" ]]; then
        echo "• Bug fixes and performance improvements"
        return
    fi

    # Check if Claude CLI is available
    if ! command -v claude &> /dev/null; then
        echo "• Various improvements and bug fixes"
        return
    fi

    # Generate changelog with Claude
    local prompt="You are writing TestFlight release notes for AirFit, an AI fitness coach app.

Based on these git commits, write 2-4 bullet points for users. Be:
- Warm and friendly (like a fitness buddy)
- Slightly humorous but professional
- Focus on user benefits, not technical details
- Keep each bullet under 80 characters
- Use emoji sparingly (1-2 max)

Format: Just the bullet points, no intro text.

Example style:
• Voice input now understands 'chicken breast' without the existential crisis
• Workout sync is 40% faster (your gains data arrives sooner!)
• Fixed that pesky bug where macros played hide-and-seek

Commits:
$commits"

    local changelog
    changelog=$(echo "$prompt" | claude --print 2>/dev/null | head -10)

    if [[ -z "$changelog" ]]; then
        echo "• Bug fixes and performance improvements"
    else
        echo "$changelog"
    fi
}

# Update TestFlight build notes via App Store Connect API
update_build_notes() {
    local jwt="$1"
    local app_id="$2"
    local version="$3"
    local build="$4"
    local notes="$5"

    echo "📝 Updating TestFlight release notes..."

    # First, find the build ID
    local builds_response
    builds_response=$(curl -s -X GET \
        "https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$app_id&filter[version]=$build&filter[preReleaseVersion.version]=$version&limit=1" \
        -H "Authorization: Bearer $jwt" \
        -H "Content-Type: application/json")

    local build_id
    build_id=$(echo "$builds_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [[ -z "$build_id" ]]; then
        echo "⚠️  Could not find build ID (build may still be processing)"
        echo "   You can manually add notes in App Store Connect"
        return 1
    fi

    # Check for existing localization
    local loc_response
    loc_response=$(curl -s -X GET \
        "https://api.appstoreconnect.apple.com/v1/builds/$build_id/betaBuildLocalizations" \
        -H "Authorization: Bearer $jwt" \
        -H "Content-Type: application/json")

    local loc_id
    loc_id=$(echo "$loc_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Escape notes for JSON
    local escaped_notes
    escaped_notes=$(echo "$notes" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/  */ /g')

    if [[ -n "$loc_id" ]]; then
        # Update existing localization
        curl -s -X PATCH \
            "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations/$loc_id" \
            -H "Authorization: Bearer $jwt" \
            -H "Content-Type: application/json" \
            -d '{
                "data": {
                    "type": "betaBuildLocalizations",
                    "id": "'"$loc_id"'",
                    "attributes": {
                        "whatsNew": "'"$escaped_notes"'"
                    }
                }
            }' > /dev/null
    else
        # Create new localization
        curl -s -X POST \
            "https://api.appstoreconnect.apple.com/v1/betaBuildLocalizations" \
            -H "Authorization: Bearer $jwt" \
            -H "Content-Type: application/json" \
            -d '{
                "data": {
                    "type": "betaBuildLocalizations",
                    "attributes": {
                        "locale": "en-US",
                        "whatsNew": "'"$escaped_notes"'"
                    },
                    "relationships": {
                        "build": {
                            "data": {
                                "type": "builds",
                                "id": "'"$build_id"'"
                            }
                        }
                    }
                }
            }' > /dev/null
    fi

    echo "✅ Release notes updated!"
}

# ============================================================================
# Parse Arguments
# ============================================================================

BUMP_BUILD=false
NEW_VERSION=""
SKIP_NOTES=false

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
        --skip-notes)
            SKIP_NOTES=true
            shift
            ;;
        --help)
            head -40 "$0" | tail -37
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

# ============================================================================
# Generate & Push Release Notes
# ============================================================================

if [[ "$SKIP_NOTES" == false ]]; then
    echo ""
    echo "✍️  Generating release notes with Claude..."

    # Find the previous build tag (format: build-X or v1.0-X)
    PREVIOUS_TAG=$(git tag -l "build-*" --sort=-version:refname | head -1)
    if [[ -z "$PREVIOUS_TAG" ]]; then
        PREVIOUS_TAG=$(git tag -l "v*" --sort=-version:refname | head -1)
    fi

    CHANGELOG=$(generate_changelog "$PREVIOUS_TAG")

    echo ""
    echo "📋 Release Notes:"
    echo "─────────────────────────────────────────"
    echo "$CHANGELOG"
    echo "─────────────────────────────────────────"

    # Tag this build for future reference
    git tag -f "build-$CURRENT_BUILD" HEAD 2>/dev/null || true

    # Try to push notes to App Store Connect
    if check_jwt_deps; then
        echo ""
        echo "⏳ Waiting 30 seconds for Apple to process the build..."
        sleep 30

        # Generate JWT and update build notes
        JWT=$(generate_jwt "$APP_STORE_CONNECT_API_KEY_ID" "$APP_STORE_CONNECT_API_ISSUER_ID" "$APP_STORE_CONNECT_API_KEY_PATH")

        if [[ -n "$JWT" ]] && update_build_notes "$JWT" "$APP_APPLE_ID" "$CURRENT_VERSION" "$CURRENT_BUILD" "$CHANGELOG"; then
            echo ""
            echo "🔔 Testers will see these notes in their TestFlight update notification!"
        else
            echo ""
            echo "📋 Copy these notes to App Store Connect → TestFlight → Build $CURRENT_BUILD:"
            echo ""
            echo "$CHANGELOG"
        fi
    else
        echo ""
        echo "💡 To auto-push notes to TestFlight, install: pip3 install cryptography"
        echo ""
        echo "📋 For now, copy these notes to App Store Connect → TestFlight → Build $CURRENT_BUILD:"
        echo ""
        echo "$CHANGELOG"
    fi
else
    echo ""
    echo "⏭️  Skipping release notes (--skip-notes)"
fi

echo ""
echo "Next steps:"
echo "  1. Wait for processing (~5-15 minutes)"
echo "  2. Check App Store Connect for build status"
echo "  3. Testers with auto-update will receive the build automatically"
echo ""
echo "App Store Connect: https://appstoreconnect.apple.com"
