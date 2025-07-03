# Firebase Integration Guide for BookstoreApp

## Table of Contents
1. [Firebase Setup & Configuration](#firebase-setup--configuration)
2. [Authentication Integration](#authentication-integration)
3. [Firestore Database Integration](#firestore-database-integration)
4. [Real-time Features](#real-time-features)
5. [Push Notifications](#push-notifications)
6. [File Storage](#file-storage)
7. [Cloud Functions](#cloud-functions)
8. [Security Rules](#security-rules)
9. [Implementation Steps](#implementation-steps)
10. [Code Examples](#code-examples)

---

## Firebase Setup & Configuration

### 1. Create Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project
firebase init
```

### 2. iOS Project Setup
1. **Add iOS app** to Firebase console
2. **Download `GoogleService-Info.plist`**
3. **Add to Xcode project** (drag to project root)
4. **Configure Bundle ID** to match your app

### 3. Add Firebase Dependencies
```swift
// Package.swift or Xcode Package Manager
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
]

// Required Firebase products:
- FirebaseAuth
- FirebaseFirestore
- FirebaseStorage
- FirebaseMessaging
- FirebaseFunctions
- FirebaseAnalytics
```

### 4. Initialize Firebase in App
```swift
// bookAppApp.swift
import SwiftUI
import FirebaseCore

@main
struct BookstoreApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ThemeManager())
        }
    }
}
```

---

## Authentication Integration

### 1. Replace Mock Authentication

#### Create Firebase Auth Service
```swift
// Services/FirebaseAuthService.swift
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        // Listen for auth state changes
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.loadUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Phone Authentication
    func sendOTP(phoneNumber: String) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(phoneNumber, uiDelegate: nil)
        
        return verificationID
    }
    
    func verifyOTP(verificationID: String, verificationCode: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let credential = PhoneAuthProvider.provider()
            .credential(withVerificationID: verificationID,
                       verificationCode: verificationCode)
        
        let result = try await auth.signIn(with: credential)
        
        // Check if user exists in Firestore
        let userExists = try await checkUserExists(uid: result.user.uid)
        if !userExists {
            throw AuthError.userNotFound
        }
    }
    
    // MARK: - User Management
    func createUser(_ userData: UserData) async throws {
        guard let currentAuthUser = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let user = User(
            id: currentAuthUser.uid,
            name: userData.name,
            email: userData.email,
            phoneNumber: userData.phoneNumber,
            societyId: userData.societyId,
            societyName: userData.societyName,
            blockName: userData.blockName,
            flatNumber: userData.flatNumber
        )
        
        try await db.collection("users")
            .document(currentAuthUser.uid)
            .setData(user.toDictionary())
        
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    func signOut() async throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func loadUserData(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            if let data = document.data() {
                self.currentUser = User.fromDictionary(data, id: uid)
                self.isAuthenticated = true
            }
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    private func checkUserExists(uid: String) async throws -> Bool {
        let document = try await db.collection("users").document(uid).getDocument()
        return document.exists
    }
}

enum AuthError: LocalizedError {
    case userNotFound
    case notAuthenticated
    case invalidOTP
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please sign up first."
        case .notAuthenticated:
            return "User not authenticated."
        case .invalidOTP:
            return "Invalid OTP. Please try again."
        }
    }
}
```

#### Update AuthViewModel
```swift
// ViewModels/AuthViewModel.swift
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authService = FirebaseAuthService()
    @Published var showOTPVerification = false
    @Published var verificationID: String?
    @Published var pendingPhoneNumber = ""
    
    var currentUser: User? { authService.currentUser }
    var isAuthenticated: Bool { authService.isAuthenticated }
    var isLoading: Bool { authService.isLoading }
    var errorMessage: String? { authService.errorMessage }
    
    func sendOTP(phoneNumber: String) async {
        do {
            let verificationID = try await authService.sendOTP(phoneNumber: phoneNumber)
            self.verificationID = verificationID
            self.pendingPhoneNumber = phoneNumber
            self.showOTPVerification = true
        } catch {
            // Handle error
        }
    }
    
    func verifyOTP(_ code: String) async {
        guard let verificationID = verificationID else { return }
        
        do {
            try await authService.verifyOTP(verificationID: verificationID, 
                                          verificationCode: code)
        } catch AuthError.userNotFound {
            // Show signup form
        } catch {
            // Handle other errors
        }
    }
    
    func signOut() async {
        try? await authService.signOut()
    }
}
```

---

## Firestore Database Integration

### 1. Database Structure
```
bookstore-db/
├── users/
│   ├── {userId}/
│   │   ├── name: String
│   │   ├── email: String?
│   │   ├── phoneNumber: String
│   │   ├── societyId: String
│   │   ├── societyName: String
│   │   ├── blockName: String
│   │   ├── flatNumber: String
│   │   ├── isActive: Boolean
│   │   ├── createdAt: Timestamp
│   │   └── lastLoginAt: Timestamp
│   
├── books/
│   ├── {bookId}/
│   │   ├── title: String
│   │   ├── author: String
│   │   ├── isbn: String?
│   │   ├── genre: String
│   │   ├── description: String
│   │   ├── condition: String
│   │   ├── coverImageUrl: String?
│   │   ├── ownerId: String
│   │   ├── ownerName: String
│   │   ├── societyId: String
│   │   ├── isAvailable: Boolean
│   │   ├── borrowedBy: String?
│   │   ├── borrowedAt: Timestamp?
│   │   ├── dueDate: Timestamp?
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp
│   
├── bookRequests/
│   ├── {requestId}/
│   │   ├── bookId: String
│   │   ├── bookTitle: String
│   │   ├── requesterId: String
│   │   ├── requesterName: String
│   │   ├── ownerId: String
│   │   ├── ownerName: String
│   │   ├── status: String (pending, approved, rejected, completed)
│   │   ├── requestedAt: Timestamp
│   │   ├── respondedAt: Timestamp?
│   │   ├── borrowedAt: Timestamp?
│   │   ├── returnedAt: Timestamp?
│   │   ├── message: String?
│   │   └── societyId: String
│   
├── societies/
│   ├── {societyId}/
│   │   ├── name: String
│   │   ├── address: String
│   │   ├── city: String
│   │   ├── state: String
│   │   ├── pincode: String
│   │   ├── totalBlocks: Array<String>
│   │   ├── amenities: Array<String>
│   │   ├── isActive: Boolean
│   │   └── createdAt: Timestamp
│   
├── notifications/
│   ├── {notificationId}/
│   │   ├── userId: String
│   │   ├── type: String (request, approval, reminder, return)
│   │   ├── title: String
│   │   ├── message: String
│   │   ├── isRead: Boolean
│   │   ├── relatedId: String? (bookId or requestId)
│   │   ├── createdAt: Timestamp
│   │   └── societyId: String
│   
└── categories/
    ├── {categoryId}/
    │   ├── name: String
    │   ├── description: String
    │   ├── iconName: String
    │   ├── color: String
    │   └── isActive: Boolean
```

### 2. Firestore Service Implementation
```swift
// Services/FirestoreService.swift
import FirebaseFirestore
import FirebaseAuth

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Books
    func addBook(_ book: Book) async throws {
        try await db.collection("books").document(book.id!).setData(book.toDictionary())
    }
    
    func getBooks(for societyId: String) async throws -> [Book] {
        let snapshot = try await db.collection("books")
            .whereField("societyId", isEqualTo: societyId)
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Book.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func getUserBooks(userId: String) async throws -> [Book] {
        let snapshot = try await db.collection("books")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Book.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func updateBookAvailability(bookId: String, isAvailable: Bool) async throws {
        try await db.collection("books").document(bookId).updateData([
            "isAvailable": isAvailable,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Book Requests
    func createBookRequest(_ request: BookRequest) async throws {
        try await db.collection("bookRequests").document(request.id!).setData(request.toDictionary())
    }
    
    func getBookRequests(for userId: String) async throws -> [BookRequest] {
        let snapshot = try await db.collection("bookRequests")
            .whereField("requesterId", isEqualTo: userId)
            .order(by: "requestedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            BookRequest.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func getLendingRequests(for userId: String) async throws -> [BookRequest] {
        let snapshot = try await db.collection("bookRequests")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "requestedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            BookRequest.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func updateRequestStatus(requestId: String, status: RequestStatus) async throws {
        try await db.collection("bookRequests").document(requestId).updateData([
            "status": status.rawValue,
            "respondedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Real-time Listeners
    func listenToBooks(for societyId: String, completion: @escaping ([Book]) -> Void) -> ListenerRegistration {
        return db.collection("books")
            .whereField("societyId", isEqualTo: societyId)
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let books = documents.compactMap { document in
                    Book.fromDictionary(document.data(), id: document.documentID)
                }
                completion(books)
            }
    }
    
    func listenToRequests(for userId: String, completion: @escaping ([BookRequest]) -> Void) -> ListenerRegistration {
        return db.collection("bookRequests")
            .whereField("ownerId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let requests = documents.compactMap { document in
                    BookRequest.fromDictionary(document.data(), id: document.documentID)
                }
                completion(requests)
            }
    }
}
```

---

## Real-time Features

### 1. Real-time Book Updates
```swift
// ViewModels/HomeViewModel.swift
class HomeViewModel: ObservableObject {
    @Published var books: [Book] = []
    private var booksListener: ListenerRegistration?
    private let firestoreService = FirestoreService()
    
    func startListening(for societyId: String) {
        booksListener = firestoreService.listenToBooks(for: societyId) { [weak self] books in
            DispatchQueue.main.async {
                self?.books = books
            }
        }
    }
    
    func stopListening() {
        booksListener?.remove()
    }
    
    deinit {
        stopListening()
    }
}
```

### 2. Real-time Notifications
```swift
// ViewModels/NotificationViewModel.swift
class NotificationViewModel: ObservableObject {
    @Published var notifications: [BookNotification] = []
    @Published var unreadCount = 0
    
    private var notificationsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(for userId: String) {
        notificationsListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let notifications = documents.compactMap { document in
                    BookNotification.fromDictionary(document.data(), id: document.documentID)
                }
                
                DispatchQueue.main.async {
                    self?.notifications = notifications
                    self?.unreadCount = notifications.filter { !$0.isRead }.count
                }
            }
    }
}
```

---

## Push Notifications

### 1. Setup FCM
```swift
// Add to bookAppApp.swift
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
        }
        
        application.registerForRemoteNotifications()
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "")")
        // Send token to your server
        if let token = fcmToken {
            saveFCMToken(token)
        }
    }
    
    private func saveFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }
}
```

### 2. Send Notifications via Cloud Functions
```javascript
// Firebase Cloud Functions
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendBookRequestNotification = functions.firestore
    .document('bookRequests/{requestId}')
    .onCreate(async (snap, context) => {
        const request = snap.data();
        
        // Get owner's FCM token
        const ownerDoc = await admin.firestore()
            .collection('users')
            .doc(request.ownerId)
            .get();
        
        const fcmToken = ownerDoc.data().fcmToken;
        
        if (fcmToken) {
            const message = {
                notification: {
                    title: 'New Book Request',
                    body: `${request.requesterName} wants to borrow "${request.bookTitle}"`
                },
                data: {
                    requestId: context.params.requestId,
                    type: 'book_request'
                },
                token: fcmToken
            };
            
            await admin.messaging().send(message);
        }
    });
```

---

## File Storage

### 1. Book Cover Upload
```swift
// Services/StorageService.swift
import FirebaseStorage

class StorageService {
    private let storage = Storage.storage()
    
    func uploadBookCover(_ imageData: Data, bookId: String) async throws -> String {
        let storageRef = storage.reference().child("book_covers/\(bookId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
}
```

---

## Cloud Functions

### 1. Book Request Processing
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Auto-approve requests after 24 hours
exports.autoApproveRequests = functions.pubsub
    .schedule('0 0 * * *') // Daily at midnight
    .onRun(async (context) => {
        const db = admin.firestore();
        const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
        
        const pendingRequests = await db.collection('bookRequests')
            .where('status', '==', 'pending')
            .where('requestedAt', '<=', yesterday)
            .get();
        
        const batch = db.batch();
        
        pendingRequests.forEach(doc => {
            batch.update(doc.ref, {
                status: 'auto_approved',
                respondedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });
        
        await batch.commit();
    });

// Send return reminders
exports.sendReturnReminders = functions.pubsub
    .schedule('0 9 * * *') // Daily at 9 AM
    .onRun(async (context) => {
        const db = admin.firestore();
        const today = new Date();
        
        const overdueBooks = await db.collection('bookRequests')
            .where('status', '==', 'approved')
            .where('dueDate', '<=', today)
            .get();
        
        const notifications = [];
        
        overdueBooks.forEach(doc => {
            const request = doc.data();
            notifications.push({
                userId: request.requesterId,
                type: 'return_reminder',
                title: 'Book Return Reminder',
                message: `Please return "${request.bookTitle}" to ${request.ownerName}`,
                isRead: false,
                relatedId: doc.id,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                societyId: request.societyId
            });
        });
        
        // Batch write notifications
        const batch = db.batch();
        notifications.forEach(notification => {
            const ref = db.collection('notifications').doc();
            batch.set(ref, notification);
        });
        
        await batch.commit();
    });
```

---

## Security Rules

### 1. Firestore Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Books are readable by society members, writable by owner
    match /books/{bookId} {
      allow read: if request.auth != null && 
        request.auth.uid != null &&
        resource.data.societyId == getUserSocietyId(request.auth.uid);
      allow create: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;
      allow update: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;
    }
    
    // Book requests
    match /bookRequests/{requestId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.requesterId || 
         request.auth.uid == resource.data.ownerId);
      allow create: if request.auth != null &&
        request.auth.uid == resource.data.requesterId;
      allow update: if request.auth != null &&
        request.auth.uid == resource.data.ownerId;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }
    
    // Societies are read-only for users
    match /societies/{societyId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admin can modify
    }
    
    // Helper function
    function getUserSocietyId(userId) {
      return get(/databases/$(database)/documents/users/$(userId)).data.societyId;
    }
  }
}
```

### 2. Storage Security Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Book covers
    match /book_covers/{bookId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.uid == getBookOwnerId(bookId);
    }
    
    // Profile images
    match /profile_images/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    function getBookOwnerId(bookId) {
      return firestore.get(/databases/(default)/documents/books/$(bookId)).data.ownerId;
    }
  }
}
```

---

## Implementation Steps

### Phase 1: Basic Setup (Week 1)
1. **Firebase Project Setup**
   - Create Firebase project
   - Add iOS app configuration
   - Install Firebase SDK dependencies

2. **Authentication Migration**
   - Replace mock authentication with Firebase Auth
   - Implement phone number verification
   - Update UI to handle real OTP flow

3. **Basic Firestore Integration**
   - Set up Firestore database
   - Implement user creation and retrieval
   - Basic security rules

### Phase 2: Core Features (Week 2-3)
1. **Books Management**
   - Implement book CRUD operations
   - Add real-time book listing
   - Integrate image upload for book covers

2. **Request System**
   - Book request creation and management
   - Real-time request notifications
   - Status updates and approval flow

3. **User Experience**
   - Real-time updates throughout the app
   - Error handling and loading states
   - Offline support with Firestore caching

### Phase 3: Advanced Features (Week 4)
1. **Push Notifications**
   - FCM integration
   - Cloud Functions for notification triggers
   - In-app notification system

2. **Analytics and Monitoring**
   - Firebase Analytics integration
   - Crashlytics for error tracking
   - Performance monitoring

3. **Testing and Optimization**
   - Unit tests for Firebase services
   - Integration tests
   - Performance optimization

---

## Code Examples

### 1. Updated Book Model
```swift
// Models/Book.swift
import Foundation
import FirebaseFirestore

struct Book: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let author: String
    let isbn: String?
    let genre: String
    let description: String
    let condition: String
    let coverImageUrl: String?
    let ownerId: String
    let ownerName: String
    let societyId: String
    let isAvailable: Bool
    let borrowedBy: String?
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
    
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "author": author,
            "isbn": isbn ?? "",
            "genre": genre,
            "description": description,
            "condition": condition,
            "coverImageUrl": coverImageUrl ?? "",
            "ownerId": ownerId,
            "ownerName": ownerName,
            "societyId": societyId,
            "isAvailable": isAvailable,
            "borrowedBy": borrowedBy ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> Book? {
        guard let title = data["title"] as? String,
              let author = data["author"] as? String,
              let genre = data["genre"] as? String,
              let description = data["description"] as? String,
              let condition = data["condition"] as? String,
              let ownerId = data["ownerId"] as? String,
              let ownerName = data["ownerName"] as? String,
              let societyId = data["societyId"] as? String,
              let isAvailable = data["isAvailable"] as? Bool else {
            return nil
        }
        
        return Book(
            id: id,
            title: title,
            author: author,
            isbn: data["isbn"] as? String,
            genre: genre,
            description: description,
            condition: condition,
            coverImageUrl: data["coverImageUrl"] as? String,
            ownerId: ownerId,
            ownerName: ownerName,
            societyId: societyId,
            isAvailable: isAvailable,
            borrowedBy: data["borrowedBy"] as? String,
            createdAt: data["createdAt"] as? Timestamp,
            updatedAt: data["updatedAt"] as? Timestamp
        )
    }
}
```

### 2. Updated HomeViewModel
```swift
// ViewModels/HomeViewModel.swift
import Foundation
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestoreService = FirestoreService()
    private var booksListener: ListenerRegistration?
    
    func loadBooks(for societyId: String) {
        isLoading = true
        
        // Start real-time listening
        booksListener = firestoreService.listenToBooks(for: societyId) { [weak self] books in
            DispatchQueue.main.async {
                self?.books = books
                self?.isLoading = false
            }
        }
    }
    
    func refreshBooks() {
        // Refresh is handled automatically by real-time listener
    }
    
    deinit {
        booksListener?.remove()
    }
}
```

---

## Testing Strategy

### 1. Unit Tests
```swift
// Tests/FirebaseServiceTests.swift
import XCTest
@testable import BookstoreApp

class FirebaseServiceTests: XCTestCase {
    func testUserCreation() async throws {
        let authService = FirebaseAuthService()
        let userData = UserData(
            name: "Test User",
            email: "test@example.com",
            phoneNumber: "+1234567890",
            societyId: "test-society",
            societyName: "Test Society",
            blockName: "A",
            flatNumber: "101"
        )
        
        try await authService.createUser(userData)
        XCTAssertNotNil(authService.currentUser)
    }
}
```

### 2. Integration Tests
```swift
// Tests/IntegrationTests.swift
import XCTest
@testable import BookstoreApp

class IntegrationTests: XCTestCase {
    func testBookCreationAndRetrieval() async throws {
        let firestoreService = FirestoreService()
        
        let book = Book(
            title: "Test Book",
            author: "Test Author",
            genre: "Fiction",
            description: "Test Description",
            condition: "Good",
            ownerId: "test-owner",
            ownerName: "Test Owner",
            societyId: "test-society",
            isAvailable: true
        )
        
        try await firestoreService.addBook(book)
        let books = try await firestoreService.getBooks(for: "test-society")
        
        XCTAssertTrue(books.contains { $0.title == "Test Book" })
    }
}
```

---

## Performance Optimization

### 1. Pagination
```swift
// Implement pagination for large datasets
func loadMoreBooks() async {
    let query = db.collection("books")
        .whereField("societyId", isEqualTo: societyId)
        .order(by: "createdAt", descending: true)
        .limit(to: 20)
    
    if let lastDocument = lastDocument {
        query = query.start(afterDocument: lastDocument)
    }
    
    let snapshot = try await query.getDocuments()
    // Process results
}
```

### 2. Offline Support
```swift
// Enable offline persistence
let settings = FirestoreSettings()
settings.isPersistenceEnabled = true
db.settings = settings
```

### 3. Image Optimization
```swift
// Compress images before upload
func compressImage(_ image: UIImage, quality: CGFloat = 0.7) -> Data? {
    return image.jpegData(compressionQuality: quality)
}
```

---

## Monitoring and Analytics

### 1. Firebase Analytics
```swift
// Track user interactions
Analytics.logEvent("book_requested", parameters: [
    "book_id": bookId,
    "book_title": bookTitle,
    "requester_id": requesterId
])
```

### 2. Crashlytics
```swift
// Custom crash reporting
Crashlytics.crashlytics().record(error: error)
Crashlytics.crashlytics().setCustomValue(userId, forKey: "user_id")
```

---

This comprehensive guide covers all aspects of Firebase integration for the BookstoreApp. Follow the implementation phases and use the provided code examples to migrate from the current mock implementation to a fully functional Firebase backend. 