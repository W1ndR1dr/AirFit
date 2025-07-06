# TestFlight Deployment Guide

This guide explains how to build and deploy AirFit to TestFlight for family distribution.

## Prerequisites

1. **Apple Developer Account**: Ensure you have an active Apple Developer account
2. **Xcode**: Version 16.0 or later installed
3. **Certificates & Provisioning**: Automatic signing is configured (DEVELOPMENT_TEAM: 2H43Q8Y3CR)

## Building for TestFlight

### 1. Generate Xcode Project
```bash
xcodegen generate
```

### 2. Build Using TestFlight Scheme
```bash
# Open Xcode
open AirFit.xcodeproj

# Or build from command line
xcodebuild -scheme "AirFit-TestFlight" -configuration Release archive -archivePath ./build/AirFit.xcarchive
```

The AirFit-TestFlight scheme automatically:
- Uses Release configuration
- Increments build number based on timestamp (format: YYYYMMDDHHMM)
- Optimizes for production deployment

### 3. Export for App Store
```bash
xcodebuild -exportArchive \
  -archivePath ./build/AirFit.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

## App Store Connect Setup

### 1. Create App
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to "My Apps" → "+" → "New App"
3. Configure:
   - **Platform**: iOS
   - **Bundle ID**: com.airfit.app
   - **SKU**: AIRFIT001 (or any unique identifier)
   - **Name**: AirFit

### 2. TestFlight Configuration
1. Navigate to your app → TestFlight tab
2. Create Internal Testing Group:
   - Name: "Family"
   - Add family members as testers (they need Apple IDs)

### 3. Upload Build
Option 1: Using Xcode Organizer
- In Xcode: Window → Organizer
- Select your archive → Distribute App
- Choose "App Store Connect" → "Upload"

Option 2: Using Transporter app
- Download [Transporter](https://apps.apple.com/app/transporter/id1450874784)
- Drag the .ipa file to upload

## Inviting Family Members

### For Internal Testers (Immediate Access)
1. In App Store Connect → TestFlight → Internal Testing
2. Click "+" to add testers
3. Enter their Apple ID email addresses
4. They'll receive an email invitation immediately

### For External Testers (Requires Review)
1. TestFlight → External Testing → Add External Testers
2. Add up to 10,000 testers
3. Submit for Beta App Review (usually 24-48 hours)

## TestFlight App Installation

Family members should:
1. Download [TestFlight](https://apps.apple.com/app/testflight/id899247664) from App Store
2. Accept the email invitation
3. Open TestFlight app → tap "Install"

## Build Updates

To push updates:
1. Increment version in project.yml if needed
2. Build with AirFit-TestFlight scheme (build number auto-increments)
3. Upload to App Store Connect
4. New build appears automatically in TestFlight

## Troubleshooting

### "Invalid Bundle ID" Error
- Verify Bundle ID matches exactly: com.airfit.app
- Check Apple Developer account has this Bundle ID registered

### TestFlight Not Showing Build
- Ensure build processing is complete (can take 5-30 minutes)
- Check email for any processing issues
- Verify all app capabilities match provisioning profile

### Testers Can't Install
- Confirm they accepted the invitation
- Check device compatibility (iOS 18.0+)
- Verify TestFlight app is installed

## Required App Information

Before first TestFlight deployment, prepare:
- **App Description**: Brief description for testers
- **What to Test**: Notes for testers about new features
- **Privacy Policy URL**: Required even for family apps (can use GitHub page)

## Privacy Considerations

Since this is a family-only app:
- No App Store listing needed
- No public privacy policy required
- Keep Internal Testing group private
- Don't use External Testing unless needed

## Quick Command Reference

```bash
# Clean, build, and archive
xcodebuild clean archive \
  -scheme "AirFit-TestFlight" \
  -archivePath ./build/AirFit.xcarchive

# View archive details
xcodebuild -exportArchive \
  -archivePath ./build/AirFit.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist \
  -DVTAllowServerCertificates=YES
```

## ExportOptions.plist Template

Create this file for command-line exports:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>2H43Q8Y3CR</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```