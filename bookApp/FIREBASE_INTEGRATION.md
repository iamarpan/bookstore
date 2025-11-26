# Firebase Integration Guide

This guide explains how the Bookstore App is integrated with Firebase and how to set it up.

## Prerequisites

1.  **Firebase Project**: You need a Firebase project created in the [Firebase Console](https://console.firebase.google.com/).
2.  **iOS App Registration**: Register an iOS app in your Firebase project.
3.  **GoogleService-Info.plist**: Download this file from the Firebase Console and add it to the `bookApp/bookApp` directory (where `Info.plist` is located).

## Architecture

The app uses a service-oriented architecture for Firebase:

-   **FirebaseConfiguration**: Handles initialization and validation of the configuration.
-   **FirestoreService**: Handles all database operations (Books, Users, Requests).
-   **FirebaseAuthService**: Handles authentication (Google Sign-In, User Registration).
-   **StorageService**: Handles image uploads (Book covers, Profile pictures).

## Setup Instructions

1.  **Add GoogleService-Info.plist**:
    -   Go to Project Settings in Firebase Console.
    -   Download `GoogleService-Info.plist`.
    -   Drag and drop it into the Xcode project navigator under the `bookApp` group.
    -   **Important**: Ensure "Copy items if needed" is checked and the target `bookApp` is selected.

2.  **Enable Authentication**:
    -   In Firebase Console -> Authentication -> Sign-in method.
    -   Enable **Google**.
    -   (Optional) Enable **Email/Password** if you plan to support it.

3.  **Create Firestore Database**:
    -   In Firebase Console -> Firestore Database.
    -   Create a database (start in **Test Mode** for development).
    -   Choose a location (e.g., `asia-south1` for India).

4.  **Setup Storage**:
    -   In Firebase Console -> Storage.
    -   Get started (start in **Test Mode**).

## Troubleshooting

### "GoogleService-Info.plist not found"
If you see this error in the console:
1.  Verify the file is actually in the project folder.
2.  Verify it is included in the "Copy Bundle Resources" build phase in Xcode.

### "Google Sign-In failed"
1.  Check if the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` is added to the URL Types in Xcode (Info tab).
2.  Ensure the custom URL scheme matches the reversed client ID.

## Code Overview

### Initialization
Firebase is initialized in `AppDelegate.swift` using `FirebaseConfiguration.shared.configure()`. This ensures that the app doesn't crash if the configuration is missing, but instead logs a helpful error.

### Data Flow
-   **HomeViewModel**: Listens to the `books` collection in real-time.
-   **MyLibraryViewModel**: Fetches `books` owned by the user and `bookRequests` where the user is involved.
-   **AuthViewModel**: Manages user session and registration state.
