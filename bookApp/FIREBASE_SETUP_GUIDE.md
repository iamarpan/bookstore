    # Firebase Integration Guide for Book Club App

This guide provides step-by-step instructions to set up Firebase for the Book Club App. Follow these steps to ensure all features (Auth, Firestore, Storage) work correctly.

## Phase 1: Firebase Console Setup

1.  **Create a Project**
    *   Go to [console.firebase.google.com](https://console.firebase.google.com/).
    *   Click **"Add project"**.
    *   Name it (e.g., `BookClubApp`) and follow the setup steps.
    *   *Optional:* Disable Google Analytics for now to simplify setup.

2.  **Add iOS App**
    *   In the project overview, click the **iOS+** icon to add an iOS app.
    *   **Apple Bundle ID**: Enter `bookStoreApp` (This MUST match the Bundle Identifier in Xcode).
    *   **App Nickname**: `Book Club App` (optional).
    *   Click **Register app**.

3.  **Download Configuration File**
    *   Download `GoogleService-Info.plist`.
    *   **IMPORTANT**: Do not rename this file. It must be exactly `GoogleService-Info.plist`.

## Phase 2: App Configuration

1.  **Add Config File to Xcode**
    *   Drag and drop the downloaded `GoogleService-Info.plist` into the `bookApp` folder in Xcode (where `AppDelegate.swift` is located).
    *   **CRITICAL**: In the dialog that appears:
        *   Check **"Copy items if needed"**.
        *   Select **"Create groups"**.
        *   Ensure **"bookApp"** is checked under "Add to targets".

2.  **Verify URL Types (for Google Sign-In)**
    *   Open `GoogleService-Info.plist` in Xcode.
    *   Copy the value of `REVERSED_CLIENT_ID` (e.g., `com.googleusercontent.apps.YOUR-ID`).
    *   Go to your **Project Target** > **Info** tab > **URL Types**.
    *   Click **+** to add a new URL Type.
    *   Paste the `REVERSED_CLIENT_ID` into the **URL Schemes** field.

## Phase 3: Authentication Setup

1.  **Enable Authentication**
    *   In Firebase Console, go to **Build** > **Authentication**.
    *   Click **Get Started**.

2.  **Enable Sign-in Providers**
    *   **Email/Password**: Click "Email/Password", enable it, and click **Save**.
    *   Click **Save**.

3.  **IMPORTANT: Re-download Configuration File**
    *   **Crucial Step**: Now that you have enabled Google Sign-In, your `GoogleService-Info.plist` has changed (it now has the `CLIENT_ID`).
    *   Go to **Project Settings** > **General** > **Your Apps**.
    *   Download `GoogleService-Info.plist` **AGAIN**.
    *   Replace the old file in your Xcode project with this new one.

## Phase 4: Firestore Database Setup

1.  **Create Database**
    *   Go to **Build** > **Firestore Database**.
    *   Click **Create database**.
    *   Select a location (e.g., `nam5 (us-central)` or one close to you).
    *   **Start in Test Mode**: Select "Start in test mode" for development.
        *   *Note: This allows open access for 30 days. We will secure this later.*

2.  **Deploy Security Rules (Optional but Recommended)**
    *   Go to the **Rules** tab in Firestore.
    *   Paste the following rules to allow authenticated access:
    ```javascript
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        match /{document=**} {
          allow read, write: if request.auth != null;
        }
      }
    }
    ```
    *   Click **Publish**.

## Phase 5: Storage Setup

1.  **Enable Storage**
    *   Go to **Build** > **Storage**.
    *   Click **Get Started**.
    *   Start in **Test Mode**.
    *   Click **Done**.

2.  **Storage Rules**
    *   Go to the **Rules** tab.
    *   Ensure rules allow read/write for authenticated users:
    ```javascript
    rules_version = '2';
    service firebase.storage {
      match /b/{bucket}/o {
        match /{allPaths=**} {
          allow read, write: if request.auth != null;
        }
      }
    }
    ```

## Phase 6: App Check (Simulator Fix)

Since you are running on the Simulator, App Check (which verifies the app's integrity) will fail by default. We have already configured the code to use a "Debug Provider".

1.  **Run the App**
    *   Build and run the app in the Simulator.
    *   Watch the Xcode Console logs for a line like:
        `Firebase App Check Debug Token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

2.  **Register Debug Token**
    *   In Firebase Console, go to **Build** > **App Check**.
    *   Click **Apps** tab.
    *   Expand your iOS app.
    *   Click the **three dots menu** > **Manage debug tokens**.
    *   Click **Add debug token**.
    *   Paste the token from your logs and name it "Simulator".
    *   Click **Save**.

## Troubleshooting

*   **"Google Sign-In Error"**: Check that `REVERSED_CLIENT_ID` in URL Types matches the plist exactly.
*   **"Missing or insufficient permissions"**: Ensure you are logged in and your Firestore Rules allow access.
*   **Crash on Launch**: Ensure `GoogleService-Info.plist` is added to the **Target Membership** in Xcode (File Inspector > Target Membership).
