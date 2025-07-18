# Google Sign-In Authentication Setup Guide

## 🎯 Overview

Your app now uses **Google Sign-In** for authentication instead of Twilio SMS. This provides:

- ✅ **Seamless OAuth flow** with Google accounts
- ✅ **Works on iOS Simulator** (development)
- ✅ **Cross-platform compatibility**
- ✅ **Secure Firebase integration**
- ✅ **Additional user profile collection**

## 🚀 Quick Start

### Current Setup
Your app includes Google Sign-In integration with Firebase:
1. **Tap "Continue with Google"** 
2. **Sign in with your Google account**
3. **Complete registration** with additional details (mobile, society, floor, flat)
4. **Start using the app**

## 📱 Setup Requirements

### 1. Firebase Console Configuration

1. **Go to [Firebase Console](https://console.firebase.com/)**
2. **Select your project**
3. **Enable Authentication**:
   - Go to **Authentication** → **Sign-in method**
   - **Enable Google** as a sign-in provider
   - **Download updated `GoogleService-Info.plist`**

### 2. Google Cloud Console Setup

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**
2. **Select your project**
3. **Enable Google Sign-In API**:
   - Go to **APIs & Services** → **Library**
   - Search for **"Google Sign-In API"**
   - **Enable** the API

### 3. iOS Configuration

1. **Add GoogleService-Info.plist**:
   - Download from Firebase Console
   - Add to `bookApp/bookApp/bookApp/` directory
   - **Add to main app target** in Xcode

2. **Configure URL Scheme**:
   - Open `bookApp.xcodeproj` in Xcode
   - Go to **Project Settings** → **Info** → **URL Types**
   - **Add New URL Type**:
     - **Identifier**: `com.googleusercontent.apps.YOUR_CLIENT_ID`
     - **URL Schemes**: `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - Replace `YOUR_CLIENT_ID` with the value from `GoogleService-Info.plist`

## 🔄 Authentication Flow

### New User Flow:
```
1. User taps "Continue with Google"
2. Google Sign-In OAuth flow opens
3. User signs in with Google account
4. App checks if user exists in Firestore
5. If new user: Show registration form
6. User fills additional details:
   - Mobile number
   - Society selection
   - Floor and flat number
7. User profile created in Firestore
8. User signed in successfully
```

### Returning User Flow:
```
1. User taps "Continue with Google"
2. Google Sign-In OAuth flow opens
3. User signs in with Google account
4. App loads existing user profile
5. User signed in successfully
```

## 📊 User Data Structure

### Updated User Model:
```swift
struct User {
    var id: String?           // Firebase Auth UID
    let name: String          // From Google profile
    let email: String?        // From Google profile
    let mobile: String        // User input (required)
    let societyId: String     // Selected society
    let societyName: String   // Selected society name
    let floor: String         // User input (required)
    let flat: String          // User input (required)
    let profileImageURL: String? // From Google profile
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?
    let fcmToken: String?
    let lastTokenUpdate: Date?
}
```

### Required Fields:
- ✅ **Name**: Auto-populated from Google
- ✅ **Email**: Auto-populated from Google
- ✅ **Mobile**: User must provide
- ✅ **Society**: User must select
- ✅ **Floor**: User must provide
- ✅ **Flat**: User must provide

## 🔧 Development Setup

### 1. Add Google Sign-In SDK to Xcode

**IMPORTANT**: Google Sign-In is a separate SDK from Firebase and must be added manually:

1. **Open Xcode project**:
   ```bash
   open bookApp/bookApp/bookApp.xcodeproj
   ```

2. **Add Package Dependency**:
   - Go to **File** → **Add Package Dependencies...**
   - Enter URL: `https://github.com/google/GoogleSignIn-iOS`
   - Choose **Up to Next Major Version** (7.0.0)
   - Add to **bookApp** target
   - Click **Add Package**

3. **Verify Installation**:
   ```swift
   import GoogleSignIn  // Should work without errors
   ```

### 2. Configure Xcode Project
- **Add GoogleService-Info.plist** to main target
- **Configure URL scheme** for OAuth callbacks
- **Enable Google Sign-In** in Firebase Console

### 3. Test Authentication
```swift
// In your app, the flow works like this:
await authViewModel.signInWithGoogle()
```

## 🧪 Testing

### Development Testing:
1. **Use iOS Simulator** or physical device
2. **Test with real Google account**
3. **Verify registration flow** for new users
4. **Test sign-in flow** for returning users

### Production Testing:
1. **Test with multiple Google accounts**
2. **Verify Firebase user creation**
3. **Test offline/online scenarios**
4. **Verify FCM token handling**

## 🔒 Security Features

### Firebase Integration:
- ✅ **Secure OAuth 2.0** flow
- ✅ **Firebase Auth** user management
- ✅ **Firestore** user data storage
- ✅ **FCM token** management
- ✅ **Session persistence**

### Privacy Protection:
- ✅ **Google account permissions** clearly displayed
- ✅ **Minimal data collection** (only required fields)
- ✅ **Secure token storage**
- ✅ **Proper sign-out** handling

## 📱 App Integration

### Your App Structure:
```
Services/
├── FirebaseAuthService.swift   # Google Sign-In + Firebase Auth
└── FirestoreService.swift      # User data storage (unchanged)

ViewModels/
└── AuthViewModel.swift         # UI binding (updated for Google Sign-In)

Views/
├── AuthenticationView.swift    # Google Sign-In UI
├── GoogleSignInView.swift      # Sign-in interface
└── RegistrationView.swift      # Additional profile fields
```

### What Changed:
- ✅ **Authentication**: Twilio SMS → Google Sign-In
- ✅ **User Model**: phoneNumber → mobile, blockName → floor, flatNumber → flat
- ✅ **UI Flow**: OTP verification → Google OAuth + Registration
- ✅ **Security**: SMS-based → OAuth 2.0-based
- ❌ **User data**: Still in Firestore
- ❌ **App features**: All other features unchanged

## 🚀 Production Deployment

### Before Releasing:

1. **Test Authentication Flow:**
   - [ ] Google Sign-In with new account
   - [ ] Registration form completion
   - [ ] Sign-in with existing account
   - [ ] Error handling scenarios

2. **Verify Firebase Setup:**
   - [ ] Google Sign-In enabled in Firebase Console
   - [ ] GoogleService-Info.plist updated
   - [ ] URL scheme configured
   - [ ] API quotas sufficient

3. **Security Checklist:**
   - [ ] GoogleService-Info.plist in main target
   - [ ] URL scheme matches CLIENT_ID
   - [ ] Production vs development config
   - [ ] Error handling for auth failures

4. **User Experience:**
   - [ ] Smooth OAuth flow
   - [ ] Clear registration requirements
   - [ ] Proper error messages
   - [ ] Offline handling

## 🔧 Troubleshooting

### Common Issues:

#### 1. "GoogleService-Info.plist not found"
**Solution:**
- Download latest plist from Firebase Console
- Add to `bookApp/bookApp/bookApp/` directory
- Add to main app target in Xcode

#### 2. "URL scheme not configured"
**Solution:**
- Open project in Xcode
- Add URL scheme from CLIENT_ID in plist
- Format: `com.googleusercontent.apps.YOUR_CLIENT_ID`

#### 3. "Google Sign-In failed"
**Check:**
- ✅ Internet connection
- ✅ Google Sign-In enabled in Firebase
- ✅ Valid GoogleService-Info.plist
- ✅ URL scheme configured correctly

#### 4. "User not found after sign-in"
**This is normal for new users:**
- App will show registration form
- User completes additional profile fields
- Account created in Firestore

### Debug Commands:
```swift
// Check Firebase Auth state
print("Current user: \(Auth.auth().currentUser?.uid)")

// Check Google Sign-In config
print("Google Client ID: \(GIDSignIn.sharedInstance.configuration?.clientID)")

// Check user in Firestore
let user = try await Firestore.firestore().collection("users").document(uid).getDocument()
print("User exists: \(user.exists)")
```

## 📞 Support

### Getting Help:
- **Firebase Issues**: [Firebase Support](https://firebase.google.com/support)
- **Google Sign-In**: [Google Sign-In Docs](https://developers.google.com/identity/sign-in/ios)
- **App Integration**: Check console logs and debug output

### Useful Links:
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Google Sign-In for iOS](https://developers.google.com/identity/sign-in/ios)

---

**🎯 Current Status**: Ready for testing! Configure Firebase and Google Sign-In in the consoles, then test the authentication flow with real Google accounts.

**🔄 Migration**: Successfully migrated from Twilio SMS to Google Sign-In with additional user profile fields (mobile, society, floor, flat). 