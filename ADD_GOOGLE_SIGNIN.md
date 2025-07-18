# Adding Google Sign-In SDK to Xcode Project

## Quick Fix for "No such module 'GoogleSignIn'" Error

### Step 1: Add Package Dependency

1. **Open Xcode project**:
   ```bash
   open bookApp/bookApp/bookApp.xcodeproj
   ```

2. **Add Google Sign-In Package**:
   - In Xcode: **File** → **Add Package Dependencies...**
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Version: **Up to Next Major Version** (7.0.0)
   - Target: **bookApp** (main app target)

### Step 2: Verify Installation

After adding the package, you should see:
- `GoogleSignIn-iOS` in your **Package Dependencies**
- No more "No such module" errors when building

### Step 3: Clean and Rebuild

If you still get errors:
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)

### Alternative: Manual Package.swift Addition

If Swift Package Manager UI doesn't work, you can also add it by editing the project manually, but the UI method above is recommended.

## Verification

After adding the package, this import should work without errors:
```swift
import GoogleSignIn
```

## Next Steps

Once the package is added successfully:
1. Follow the setup in `GOOGLE_SIGNIN_SETUP_GUIDE.md`
2. Configure Firebase Console
3. Add GoogleService-Info.plist
4. Set up URL schemes
5. Test the authentication flow 