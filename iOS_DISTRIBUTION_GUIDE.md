# iOS App Distribution Guide

## Overview
This guide explains how to build and distribute the Book Club iOS app for production.

## Prerequisites

### 1. Apple Developer Account
- Enroll in the Apple Developer Program ($99/year)
- Visit: https://developer.apple.com/programs/
- Complete enrollment and verify your account

### 2. Development Environment
- macOS with Xcode 16.4 or later
- Valid Apple ID signed in to Xcode
- Command Line Tools installed

## App Configuration

### Current Settings
- **Bundle Identifier**: `com.zenithTechsphere.bookApp`
- **Display Name**: Book Club
- **Version**: 1.0
- **Build Number**: 1
- **Minimum iOS**: 16.0
- **Production API**: `https://bookapp-iota-nine.vercel.app/api/v1`

### Build Configurations

**Debug Build** (Development):
- Mock login button visible
- API request/response logging enabled
- Development environment banner shown
- Optimizations disabled for debugging

**Release Build** (Production):
- Mock login button hidden
- API logging disabled
- No debug features visible
- Full optimizations enabled
- Production API URL enforced

## Building for Distribution

### Step 1: Configure Code Signing

1. Open Xcode
2. Select the `bookApp` project in the navigator
3. Select the `bookApp` target
4. Go to "Signing & Capabilities" tab
5. Check "Automatically manage signing"
6. Select your Team from the dropdown
7. Xcode will automatically create provisioning profiles

### Step 2: Archive the App

```bash
# From terminal
cd /Users/ayushyachitransh/development/bookstore/bookApp/bookApp

# Clean build folder
xcodebuild clean -scheme bookApp -configuration Release

# Create archive
xcodebuild archive \
  -scheme bookApp \
  -configuration Release \
  -archivePath ./build/bookApp.xcarchive
```

**Or use Xcode GUI:**
1. Select "Any iOS Device" as the destination
2. Product → Archive
3. Wait for archive to complete
4. Organizer window will open automatically

### Step 3: Prepare for App Store

#### A. TestFlight (Recommended First Step)

1. In Xcode Organizer, select your archive
2. Click "Distribute App"
3. Select "App Store Connect"
4. Click "Upload"
5. Select distribution certificate and provisioning profile
6. Click "Upload"

Once uploaded:
1. Go to https://appstoreconnect.apple.com
2. Navigate to your app
3. Go to TestFlight tab
4. Add internal testers (up to 100)
5. Add external testers (requires beta review)
6. Distribute to testers

#### B. App Store Submission

1. In App Store Connect, create a new app:
   - Name: Book Club
   - Primary Language: English
   - Bundle ID: com.zenithTechsphere.bookApp
   - SKU: bookapp-001

2. Fill in App Information:
   - **Category**: Social Networking or Books
   - **Privacy Policy URL**: (Required - create one)
   - **Support URL**: (Required)

3. Prepare App Store Assets:
   - App Icon (1024x1024px)
   - Screenshots (various device sizes)
   - App Preview videos (optional)
   - Description and keywords
   - What's New text

4. Submit for Review:
   - Select your build from TestFlight
   - Fill in all required metadata
   - Submit for review
   - Wait 1-3 days for approval

## Pre-Submission Checklist

### Code Quality
- [ ] No debug code in Release builds
- [ ] All API endpoints tested
- [ ] Error handling works correctly
- [ ] Token refresh works properly
- [ ] App doesn't crash on common scenarios

### App Store Requirements
- [ ] App icon added (1024x1024)
- [ ] Launch screen configured
- [ ] Privacy policy created and linked
- [ ] Support URL provided
- [ ] Screenshots prepared (all required sizes)
- [ ] App description written
- [ ] Keywords selected

### Testing
- [ ] Tested on physical device
- [ ] Tested on multiple iOS versions (16.0+)
- [ ] Tested on different screen sizes
- [ ] Tested offline behavior
- [ ] Tested authentication flow end-to-end
- [ ] Tested all major features

### Legal & Privacy
- [ ] Privacy policy covers data collection
- [ ] Terms of service created
- [ ] Age rating appropriate
- [ ] Export compliance answered
- [ ] Content rights verified

## Quick Build Commands

### Debug Build (for testing)
```bash
cd /Users/ayushyachitransh/development/bookstore/bookApp/bookApp

# Build for simulator
xcodebuild -scheme bookApp \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Run on simulator
open -a Simulator
xcrun simctl install booted ./build/Debug-iphonesimulator/bookApp.app
xcrun simctl launch booted com.zenithTechsphere.bookApp
```

### Release Build (for distribution)
```bash
cd /Users/ayushyachitransh/development/bookstore/bookApp/bookApp

# Build for device
xcodebuild -scheme bookApp \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build
```

## Troubleshooting

### Code Signing Issues
**Problem**: "No signing certificate found"
**Solution**: 
1. Open Xcode Preferences → Accounts
2. Add your Apple ID
3. Download manual profiles
4. Or enable "Automatically manage signing"

### Build Failures
**Problem**: Build fails with Swift errors
**Solution**:
1. Clean build folder: Product → Clean Build Folder
2. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. Restart Xcode

### Archive Not Showing
**Problem**: Archive doesn't appear in Organizer
**Solution**:
1. Ensure "Generic iOS Device" is selected (not simulator)
2. Check Skip Install is set to NO
3. Verify scheme is set to Release configuration

## Post-Launch

### Monitoring
- Monitor crash reports in App Store Connect
- Check user reviews and ratings
- Track download statistics
- Monitor backend API logs

### Updates
1. Increment build number for each submission
2. Increment version number for feature updates
3. Provide "What's New" description
4. Submit update through same process

## Resources

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

## Support

For technical issues with the app:
- Check backend logs: https://vercel.com/dashboard
- Review iOS app logs in Xcode Console
- Test API endpoints using the test scripts in `/backend`

---

**Last Updated**: 2026-02-07
**App Version**: 1.0
**Minimum iOS**: 16.0
