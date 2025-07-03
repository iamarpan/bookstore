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

### 1. Database Structure (Current Implementation)
```
bookstore-db/
├── users/
│   ├── {userId}/
│   │   ├── name: String
│   │   ├── email: String? (optional)
│   │   ├── phoneNumber: String
│   │   ├── societyId: String
│   │   ├── societyName: String
│   │   ├── blockName: String
│   │   ├── flatNumber: String
│   │   ├── profileImageURL: String? (optional)
│   │   ├── isActive: Boolean
│   │   ├── createdAt: Timestamp
│   │   ├── lastLoginAt: Timestamp? (optional)
│   │   ├── fcmToken: String? (optional - for push notifications)
│   │   └── lastTokenUpdate: Timestamp? (optional)
│   
├── books/
│   ├── {bookId}/
│   │   ├── title: String
│   │   ├── author: String
│   │   ├── genre: String
│   │   ├── description: String
│   │   ├── imageURL: String (Firebase Storage URL)
│   │   ├── isAvailable: Boolean
│   │   ├── ownerId: String
│   │   ├── ownerName: String
│   │   ├── ownerFlatNumber: String
│   │   ├── societyId: String
│   │   ├── createdAt: Timestamp
│   │   └── updatedAt: Timestamp? (optional)
│   
├── bookRequests/
│   ├── {requestId}/
│   │   ├── bookId: String
│   │   ├── borrowerId: String
│   │   ├── borrowerName: String
│   │   ├── borrowerFlatNumber: String
│   │   ├── ownerId: String
│   │   ├── societyId: String
│   │   ├── requestDate: Timestamp
│   │   ├── status: String (pending, approved, rejected, returned, overdue)
│   │   ├── responseDate: Timestamp? (optional)
│   │   ├── returnDate: Timestamp? (optional)
│   │   ├── dueDate: Timestamp? (optional)
│   │   └── notes: String? (optional)
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
│   │   └── createdAt: Timestamp
│   
└── notifications/
    ├── {notificationId}/
    │   ├── userId: String
    │   ├── type: String (book_request, request_approved, request_rejected, return_reminder, overdue, book_returned)
    │   ├── title: String
    │   ├── message: String
    │   ├── isRead: Boolean
    │   ├── relatedId: String? (bookId or requestId)
    │   ├── createdAt: Timestamp
    │   └── societyId: String
```

### 2. Firestore Service Implementation (Current)
```swift
// Services/FirestoreService.swift
import FirebaseFirestore
import FirebaseAuth
import Foundation

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Books Management
    func addBook(_ book: Book) async throws -> String {
        let docRef = try await db.collection("books").addDocument(data: book.toDictionary())
        return docRef.documentID
    }
    
    func updateBook(_ book: Book) async throws {
        guard let id = book.id else {
            throw NSError(domain: "FirestoreService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Book ID is missing"])
        }
        
        try await db.collection("books").document(id).updateData(book.toDictionary())
    }
    
    func deleteBook(with id: String) async throws {
        try await db.collection("books").document(id).delete()
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
    
    // MARK: - Book Requests Management
    func addBookRequest(_ request: BookRequest) async throws -> String {
        let docRef = try await db.collection("bookRequests").addDocument(data: request.toDictionary())
        return docRef.documentID
    }
    
    func updateBookRequest(_ request: BookRequest) async throws {
        guard let id = request.id else {
            throw NSError(domain: "FirestoreService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Request ID is missing"])
        }
        
        try await db.collection("bookRequests").document(id).updateData(request.toDictionary())
    }
    
    func listenToRequests(for userId: String, completion: @escaping ([BookRequest]) -> Void) -> ListenerRegistration {
        return db.collection("bookRequests")
            .whereField("borrowerId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let requests = documents.compactMap { document in
                    BookRequest.fromDictionary(document.data(), id: document.documentID)
                }
                
                completion(requests)
            }
    }
    
    // MARK: - Notifications Management
    func addNotification(_ notification: BookNotification) async throws -> String {
        let docRef = try await db.collection("notifications").addDocument(data: notification.toDictionary())
        return docRef.documentID
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - User Management
    func getUser(by id: String) async throws -> User? {
        let document = try await db.collection("users").document(id).getDocument()
        
        guard let data = document.data() else {
            return nil
        }
        
        return User.fromDictionary(data, id: document.documentID)
    }
    
    func updateUser(_ user: User) async throws {
        guard let id = user.id else {
            throw NSError(domain: "FirestoreService", code: 1003, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])
        }
        
        try await db.collection("users").document(id).updateData(user.toDictionary())
    }
    
    // MARK: - Society Management
    func getSocieties() async throws -> [Society] {
        let snapshot = try await db.collection("societies").getDocuments()
        
        return snapshot.documents.compactMap { document in
            Society.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func addSociety(_ society: Society) async throws -> String {
        let docRef = try await db.collection("societies").addDocument(data: society.toDictionary())
        return docRef.documentID
    }
    
    // MARK: - Real-time Listeners
    func listenToBooks(for societyId: String, completion: @escaping ([Book]) -> Void) -> ListenerRegistration {
        return db.collection("books")
            .whereField("societyId", isEqualTo: societyId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let books = documents.compactMap { document in
                    Book.fromDictionary(document.data(), id: document.documentID)
                }
                
                completion(books)
            }
    }
}
```

### 3. Model Serialization Examples

#### User Model with FCM Support
```swift
// Models/User.swift
func toDictionary() -> [String: Any] {
    return [
        "name": name,
        "email": email ?? "",
        "phoneNumber": phoneNumber,
        "societyId": societyId,
        "societyName": societyName,
        "blockName": blockName,
        "flatNumber": flatNumber,
        "profileImageURL": profileImageURL ?? "",
        "isActive": isActive,
        "createdAt": Timestamp(date: createdAt),
        "lastLoginAt": lastLoginAt != nil ? Timestamp(date: lastLoginAt!) : NSNull(),
        "fcmToken": fcmToken ?? "",
        "lastTokenUpdate": lastTokenUpdate != nil ? Timestamp(date: lastTokenUpdate!) : NSNull()
    ]
}
```

#### Book Model with Storage Integration
```swift
// Models/Book.swift
func toDictionary() -> [String: Any] {
    return [
        "title": title,
        "author": author,
        "genre": genre,
        "description": description,
        "imageURL": imageURL, // Firebase Storage URL
        "isAvailable": isAvailable,
        "ownerId": ownerId,
        "ownerName": ownerName,
        "ownerFlatNumber": ownerFlatNumber,
        "societyId": societyId,
        "createdAt": Timestamp(date: createdAt),
        "updatedAt": updatedAt != nil ? Timestamp(date: updatedAt!) : FieldValue.serverTimestamp()
    ]
}
```

#### BookRequest Model with Status Management
```swift
// Models/BookRequest.swift
func toDictionary() -> [String: Any] {
    var dict: [String: Any] = [
        "bookId": bookId,
        "borrowerId": borrowerId,
        "borrowerName": borrowerName,
        "borrowerFlatNumber": borrowerFlatNumber,
        "ownerId": ownerId,
        "societyId": societyId,
        "requestDate": Timestamp(date: requestDate),
        "status": status.rawValue // RequestStatus enum
    ]
    
    // Optional fields
    if let responseDate = responseDate {
        dict["responseDate"] = Timestamp(date: responseDate)
    }
    
    if let returnDate = returnDate {
        dict["returnDate"] = Timestamp(date: returnDate)
    }
    
    if let dueDate = dueDate {
        dict["dueDate"] = Timestamp(date: dueDate)
    }
    
    if let notes = notes {
        dict["notes"] = notes
    }
    
    return dict
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

## File Storage

### 1. StorageService Implementation (Production Ready)
```swift
// Services/StorageService.swift
import Foundation
import FirebaseStorage
import UIKit

@MainActor
class StorageService: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    
    private let storage = Storage.storage()
    
    // MARK: - Book Cover Upload
    
    /// Uploads a book cover image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - bookId: The unique book identifier
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: The download URL string
    func uploadBookCover(_ image: UIImage, bookId: String, compressionQuality: CGFloat = 0.7) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // Validate and compress image
            guard let imageData = prepareImageForUpload(image, 
                                                      maxSizeKB: 2048, 
                                                      maxDimension: 1024, 
                                                      compressionQuality: compressionQuality) else {
                throw StorageError.invalidImage
            }
            
            let storageRef = storage.reference().child("book_covers/\(bookId).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.customMetadata = [
                "bookId": bookId,
                "uploadedAt": ISO8601DateFormatter().string(from: Date()),
                "imageSize": "\(imageData.count)"
            ]
            
            // Upload with progress tracking
            let uploadTask = storageRef.putData(imageData, metadata: metadata)
            
            // Observe upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / 
                                   Double(snapshot.progress?.totalUnitCount ?? 1)
                Task { @MainActor in
                    self?.uploadProgress = percentComplete
                }
            }
            
            // Wait for upload completion
            let _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            
            uploadProgress = 1.0
            return downloadURL.absoluteString
            
        } catch {
            uploadError = error.localizedDescription
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Profile Image Upload
    
    /// Uploads a profile image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The unique user identifier
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: The download URL string
    func uploadProfileImage(_ image: UIImage, userId: String, compressionQuality: CGFloat = 0.8) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // Validate and compress image
            guard let imageData = prepareImageForUpload(image, 
                                                      maxSizeKB: 1024, 
                                                      maxDimension: 512, 
                                                      compressionQuality: compressionQuality) else {
                throw StorageError.invalidImage
            }
            
            let storageRef = storage.reference().child("profile_images/\(userId).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.customMetadata = [
                "userId": userId,
                "uploadedAt": ISO8601DateFormatter().string(from: Date()),
                "imageSize": "\(imageData.count)"
            ]
            
            // Upload with progress tracking
            let uploadTask = storageRef.putData(imageData, metadata: metadata)
            
            // Observe upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                let percentComplete = Double(snapshot.progress?.completedUnitCount ?? 0) / 
                                   Double(snapshot.progress?.totalUnitCount ?? 1)
                Task { @MainActor in
                    self?.uploadProgress = percentComplete
                }
            }
            
            // Wait for upload completion
            let _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            
            uploadProgress = 1.0
            return downloadURL.absoluteString
            
        } catch {
            uploadError = error.localizedDescription
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Multiple Image Upload (for books with multiple photos)
    
    /// Uploads multiple images for a book
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - bookId: The unique book identifier
    /// - Returns: Array of download URL strings
    func uploadMultipleBookImages(_ images: [UIImage], bookId: String) async throws -> [String] {
        var downloadURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            let fileName = "\(bookId)_\(index).jpg"
            let url = try await uploadBookImage(image, fileName: fileName)
            downloadURLs.append(url)
        }
        
        return downloadURLs
    }
    
    // MARK: - Image Download
    
    /// Downloads an image from Firebase Storage
    /// - Parameter url: The download URL string
    /// - Returns: The downloaded UIImage
    func downloadImage(from url: String) async throws -> UIImage {
        guard let downloadURL = URL(string: url) else {
            throw StorageError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: downloadURL)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.invalidImageData
        }
        
        return image
    }
    
    // MARK: - Image Deletion
    
    /// Deletes a book cover image from Firebase Storage
    /// - Parameter bookId: The unique book identifier
    func deleteBookCover(bookId: String) async throws {
        let storageRef = storage.reference().child("book_covers/\(bookId).jpg")
        try await storageRef.delete()
    }
    
    /// Deletes a profile image from Firebase Storage
    /// - Parameter userId: The unique user identifier
    func deleteProfileImage(userId: String) async throws {
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        try await storageRef.delete()
    }
    
    // MARK: - Private Helper Methods
    
    private func uploadBookImage(_ image: UIImage, fileName: String) async throws -> String {
        guard let imageData = prepareImageForUpload(image, 
                                                  maxSizeKB: 2048, 
                                                  maxDimension: 1024, 
                                                  compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }
        
        let storageRef = storage.reference().child("book_covers/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putData(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func prepareImageForUpload(_ image: UIImage, maxSizeKB: Int, maxDimension: CGFloat, compressionQuality: CGFloat) -> Data? {
        // Resize image if needed
        let resizedImage = resizeImage(image, maxDimension: maxDimension)
        
        // Compress image
        guard var imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        // Ensure image is under size limit
        let maxSizeBytes = maxSizeKB * 1024
        var currentQuality = compressionQuality
        
        while imageData.count > maxSizeBytes && currentQuality > 0.1 {
            currentQuality -= 0.1
            guard let compressedData = resizedImage.jpegData(compressionQuality: currentQuality) else {
                break
            }
            imageData = compressedData
        }
        
        return imageData.count <= maxSizeBytes ? imageData : nil
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let ratio = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
        
        if ratio >= 1.0 {
            return image // No need to resize
        }
        
        let newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidImageData
    case uploadFailed(String)
    case downloadFailed(String)
    case deletionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or couldn't be processed."
        case .invalidURL:
            return "The download URL is invalid."
        case .invalidImageData:
            return "The downloaded data doesn't represent a valid image."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .deletionFailed(let message):
            return "Deletion failed: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidImage:
            return "Please try selecting a different image or ensure the image is in a supported format."
        case .invalidURL:
            return "Please check your internet connection and try again."
        case .invalidImageData:
            return "The image file may be corrupted. Please try a different image."
        case .uploadFailed(_):
            return "Please check your internet connection and try uploading again."
        case .downloadFailed(_):
            return "Please check your internet connection and try downloading again."
        case .deletionFailed(_):
            return "Please try again or contact support if the problem persists."
        }
    }
}
```

### 2. Storage Configuration and Best Practices

#### Upload Configuration Presets
```swift
// Upload configurations for different content types
extension StorageService {
    static let bookCoverConfig = UploadConfig(
        maxSizeKB: 2048,        // 2MB
        maxDimension: 1024,      // 1024px
        compressionQuality: 0.7,
        allowedFormats: [.jpeg, .png]
    )
    
    static let profileImageConfig = UploadConfig(
        maxSizeKB: 1024,        // 1MB
        maxDimension: 512,       // 512px
        compressionQuality: 0.8,
        allowedFormats: [.jpeg, .png]
    )
}

struct UploadConfig {
    let maxSizeKB: Int
    let maxDimension: CGFloat
    let compressionQuality: CGFloat
    let allowedFormats: [ImageFormat]
}

enum ImageFormat {
    case jpeg, png, heic
}
```

### 3. Integration with UI
```swift
// Usage in ViewModels
class AddBookViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isUploadingImage = false
    @Published var uploadProgress: Double = 0.0
    
    private let storageService = StorageService()
    
    func uploadBookCover(for bookId: String) async {
        guard let image = selectedImage else { return }
        
        do {
            let imageURL = try await storageService.uploadBookCover(image, bookId: bookId)
            // Update book record with image URL
            await updateBookImageURL(bookId: bookId, imageURL: imageURL)
        } catch {
            // Handle upload error
            print("Failed to upload image: \(error)")
        }
    }
    
    private func updateBookImageURL(bookId: String, imageURL: String) async {
        // Update Firestore document with image URL
        let db = Firestore.firestore()
        try? await db.collection("books").document(bookId).updateData([
            "imageURL": imageURL
        ])
    }
}
```

### 4. Storage Optimization Features
```swift
// Advanced storage features
extension StorageService {
    
    // Cache management
    func clearImageCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    // Batch upload with progress
    func uploadImagesWithProgress(_ images: [(UIImage, String)], 
                                 progressCallback: @escaping (Double) -> Void) async throws -> [String] {
        var urls: [String] = []
        let totalImages = images.count
        
        for (index, (image, fileName)) in images.enumerated() {
            let url = try await uploadBookImage(image, fileName: fileName)
            urls.append(url)
            
            let progress = Double(index + 1) / Double(totalImages)
            await MainActor.run {
                progressCallback(progress)
            }
        }
        
        return urls
    }
    
    // Image format conversion
    func convertToJPEG(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    func convertToPNG(_ image: UIImage) -> Data? {
        return image.pngData()
    }
}
```

---

## Cloud Functions

### 1. Book Request Processing (Production Ready)
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Trigger when a new book request is created
exports.onBookRequestCreated = functions.firestore
    .document('bookRequests/{requestId}')
    .onCreate(async (snap, context) => {
        const request = snap.data();
        const requestId = context.params.requestId;
        
        try {
            // Get owner's FCM token and user data
            const ownerDoc = await admin.firestore()
                .collection('users')
                .doc(request.ownerId)
                .get();
            
            if (!ownerDoc.exists) {
                console.log('Owner not found:', request.ownerId);
                return;
            }
            
            const ownerData = ownerDoc.data();
            const fcmToken = ownerData.fcmToken;
            
            // Create notification in Firestore
            const notification = {
                userId: request.ownerId,
                type: 'book_request',
                title: 'New Book Request',
                message: `${request.borrowerName} (${request.borrowerFlatNumber}) wants to borrow your book`,
                isRead: false,
                relatedId: requestId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                societyId: request.societyId
            };
            
            await admin.firestore()
                .collection('notifications')
                .add(notification);
            
            // Send FCM notification if token exists
            if (fcmToken) {
                const message = {
                    notification: {
                        title: 'New Book Request',
                        body: `${request.borrowerName} wants to borrow your book`
                    },
                    data: {
                        requestId: requestId,
                        type: 'book_request',
                        navigationTarget: 'requests'
                    },
                    token: fcmToken
                };
                
                await admin.messaging().send(message);
                console.log('FCM notification sent to owner:', request.ownerId);
            }
            
        } catch (error) {
            console.error('Error processing book request:', error);
        }
    });

// Trigger when book request status is updated
exports.onBookRequestUpdated = functions.firestore
    .document('bookRequests/{requestId}')
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const requestId = context.params.requestId;
        
        // Only process if status changed
        if (beforeData.status === afterData.status) {
            return;
        }
        
        try {
            // Get borrower's FCM token and user data
            const borrowerDoc = await admin.firestore()
                .collection('users')
                .doc(afterData.borrowerId)
                .get();
            
            if (!borrowerDoc.exists) {
                console.log('Borrower not found:', afterData.borrowerId);
                return;
            }
            
            const borrowerData = borrowerDoc.data();
            const fcmToken = borrowerData.fcmToken;
            
            let notificationType, title, message;
            
            switch (afterData.status) {
                case 'approved':
                    notificationType = 'request_approved';
                    title = 'Request Approved!';
                    message = 'Your book request has been approved. You can now collect the book.';
                    
                    // Set due date (7 days from approval)
                    const dueDate = new Date();
                    dueDate.setDate(dueDate.getDate() + 7);
                    
                    await change.after.ref.update({
                        dueDate: admin.firestore.Timestamp.fromDate(dueDate)
                    });
                    break;
                    
                case 'rejected':
                    notificationType = 'request_rejected';
                    title = 'Request Declined';
                    message = 'Your book request has been declined by the owner.';
                    break;
                    
                case 'returned':
                    notificationType = 'book_returned';
                    title = 'Book Returned';
                    message = 'Thank you for returning the book on time!';
                    break;
                    
                case 'overdue':
                    notificationType = 'overdue';
                    title = 'Book Overdue';
                    message = 'Your borrowed book is overdue. Please return it as soon as possible.';
                    break;
                    
                default:
                    return; // Don't process other status changes
            }
            
            // Create notification in Firestore
            const notification = {
                userId: afterData.borrowerId,
                type: notificationType,
                title: title,
                message: message,
                isRead: false,
                relatedId: requestId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                societyId: afterData.societyId
            };
            
            await admin.firestore()
                .collection('notifications')
                .add(notification);
            
            // Send FCM notification if token exists
            if (fcmToken) {
                const fcmMessage = {
                    notification: {
                        title: title,
                        body: message
                    },
                    data: {
                        requestId: requestId,
                        type: notificationType,
                        navigationTarget: 'myLibrary'
                    },
                    token: fcmToken
                };
                
                await admin.messaging().send(fcmMessage);
                console.log('FCM notification sent to borrower:', afterData.borrowerId);
            }
            
        } catch (error) {
            console.error('Error processing request status update:', error);
        }
    });

// Daily function to check for overdue books
exports.checkOverdueBooks = functions.pubsub
    .schedule('0 9 * * *') // Daily at 9 AM
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
        const today = new Date();
        today.setHours(0, 0, 0, 0); // Start of today
        
        try {
            // Find all approved requests where due date has passed
            const overdueQuery = await admin.firestore()
                .collection('bookRequests')
                .where('status', '==', 'approved')
                .where('dueDate', '<=', admin.firestore.Timestamp.fromDate(today))
                .get();
            
            const batch = admin.firestore().batch();
            const notifications = [];
            
            for (const doc of overdueQuery.docs) {
                const request = doc.data();
                
                // Update request status to overdue
                batch.update(doc.ref, {
                    status: 'overdue'
                });
                
                // Prepare overdue notification
                notifications.push({
                    userId: request.borrowerId,
                    type: 'overdue',
                    title: 'Book Overdue',
                    message: `Your borrowed book is overdue. Please return it to ${request.ownerName} immediately.`,
                    isRead: false,
                    relatedId: doc.id,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    societyId: request.societyId
                });
            }
            
            // Commit batch update
            await batch.commit();
            
            // Create notifications
            const notificationBatch = admin.firestore().batch();
            notifications.forEach(notification => {
                const ref = admin.firestore().collection('notifications').doc();
                notificationBatch.set(ref, notification);
            });
            
            await notificationBatch.commit();
            
            console.log(`Processed ${overdueQuery.size} overdue books`);
            
        } catch (error) {
            console.error('Error checking overdue books:', error);
        }
    });

// Clean up old notifications (older than 30 days)
exports.cleanupOldNotifications = functions.pubsub
    .schedule('0 2 * * 0') // Weekly at 2 AM on Sunday
    .onRun(async (context) => {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        
        try {
            const oldNotifications = await admin.firestore()
                .collection('notifications')
                .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
                .get();
            
            const batch = admin.firestore().batch();
            
            oldNotifications.docs.forEach(doc => {
                batch.delete(doc.ref);
            });
            
            await batch.commit();
            
            console.log(`Deleted ${oldNotifications.size} old notifications`);
            
        } catch (error) {
            console.error('Error cleaning up notifications:', error);
        }
    });

// Send return reminders (2 days before due date)
exports.sendReturnReminders = functions.pubsub
    .schedule('0 10 * * *') // Daily at 10 AM
    .timeZone('Asia/Kolkata')
    .onRun(async (context) => {
        const twoDaysFromNow = new Date();
        twoDaysFromNow.setDate(twoDaysFromNow.getDate() + 2);
        twoDaysFromNow.setHours(23, 59, 59, 999); // End of day
        
        const oneDayFromNow = new Date();
        oneDayFromNow.setDate(oneDayFromNow.getDate() + 2);
        oneDayFromNow.setHours(0, 0, 0, 0); // Start of day
        
        try {
            // Find approved requests due in 2 days
            const dueSoonQuery = await admin.firestore()
                .collection('bookRequests')
                .where('status', '==', 'approved')
                .where('dueDate', '>=', admin.firestore.Timestamp.fromDate(oneDayFromNow))
                .where('dueDate', '<=', admin.firestore.Timestamp.fromDate(twoDaysFromNow))
                .get();
            
            const notifications = [];
            const fcmMessages = [];
            
            for (const doc of dueSoonQuery.docs) {
                const request = doc.data();
                
                // Get borrower's FCM token
                const borrowerDoc = await admin.firestore()
                    .collection('users')
                    .doc(request.borrowerId)
                    .get();
                
                if (borrowerDoc.exists) {
                    const borrowerData = borrowerDoc.data();
                    
                    // Create reminder notification
                    notifications.push({
                        userId: request.borrowerId,
                        type: 'return_reminder',
                        title: 'Return Reminder',
                        message: `Don't forget to return your book to ${request.ownerName} in 2 days.`,
                        isRead: false,
                        relatedId: doc.id,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                        societyId: request.societyId
                    });
                    
                    // Prepare FCM message if token exists
                    if (borrowerData.fcmToken) {
                        fcmMessages.push({
                            notification: {
                                title: 'Return Reminder',
                                body: `Don't forget to return your book in 2 days`
                            },
                            data: {
                                requestId: doc.id,
                                type: 'return_reminder',
                                navigationTarget: 'myLibrary'
                            },
                            token: borrowerData.fcmToken
                        });
                    }
                }
            }
            
            // Create notifications in batch
            const batch = admin.firestore().batch();
            notifications.forEach(notification => {
                const ref = admin.firestore().collection('notifications').doc();
                batch.set(ref, notification);
            });
            
            await batch.commit();
            
            // Send FCM notifications
            if (fcmMessages.length > 0) {
                await admin.messaging().sendAll(fcmMessages);
            }
            
            console.log(`Sent ${notifications.length} return reminders`);
            
        } catch (error) {
            console.error('Error sending return reminders:', error);
        }
    });
```

### 2. Deployment Configuration
```bash
# Initialize Firebase Functions
firebase init functions

# Install dependencies
cd functions
npm install firebase-admin

# Deploy functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:onBookRequestCreated
```

### 3. Environment Variables
```bash
# Set Firebase project configuration
firebase functions:config:set app.name="BookStore" app.version="1.0.0"

# For production
firebase functions:config:set env.mode="production"
```

---

## Security Rules

### 1. Firestore Security Rules (Current Implementation)
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserId() {
      return request.auth.uid;
    }
    
    function getUserSocietyId(userId) {
      return get(/databases/$(database)/documents/users/$(userId)).data.societyId;
    }
    
    function isOwner(userId) {
      return getUserId() == userId;
    }
    
    function isSameSociety(societyId) {
      return getUserSocietyId(getUserId()) == societyId;
    }
    
    // Users collection - users can only access their own data
    match /users/{userId} {
      allow read, write: if isAuthenticated() && isOwner(userId);
      
      // Allow reading basic user info for society members
      allow read: if isAuthenticated() && 
                     isSameSociety(resource.data.societyId);
    }
    
    // Books collection - society-based access control
    match /books/{bookId} {
      // Anyone in the society can read available books
      allow read: if isAuthenticated() && 
                     isSameSociety(resource.data.societyId);
      
      // Only book owner can create, update, or delete their books
      allow create: if isAuthenticated() &&
                       getUserId() == request.resource.data.ownerId &&
                       isSameSociety(request.resource.data.societyId);
      
      allow update: if isAuthenticated() &&
                       getUserId() == resource.data.ownerId;
      
      allow delete: if isAuthenticated() &&
                       getUserId() == resource.data.ownerId;
    }
    
    // Book requests collection
    match /bookRequests/{requestId} {
      // Borrowers can read their own requests
      allow read: if isAuthenticated() && 
                     (getUserId() == resource.data.borrowerId || 
                      getUserId() == resource.data.ownerId);
      
      // Only borrowers can create requests for themselves
      allow create: if isAuthenticated() &&
                       getUserId() == request.resource.data.borrowerId &&
                       isSameSociety(request.resource.data.societyId);
      
      // Only book owners can update request status
      allow update: if isAuthenticated() &&
                       getUserId() == resource.data.ownerId &&
                       // Ensure only specific fields can be updated
                       (request.resource.data.diff(resource.data).affectedKeys()
                        .hasOnly(['status', 'responseDate', 'dueDate', 'returnDate', 'notes']));
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      // Users can only read and update their own notifications
      allow read, update: if isAuthenticated() &&
                             getUserId() == resource.data.userId;
      
      // Only system (cloud functions) can create notifications
      // Users cannot create notifications directly
      allow create: if false;
      allow delete: if false;
    }
    
    // Societies collection - read-only for users
    match /societies/{societyId} {
      // All authenticated users can read society information
      allow read: if isAuthenticated();
      
      // Only admins can write (controlled via admin SDK in functions)
      allow write: if false;
    }
  }
}
```

### 2. Storage Security Rules (Current Implementation)
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function getUserId() {
      return request.auth.uid;
    }
    
    function isValidImageFile() {
      return request.resource.contentType.matches('image/.*') &&
             request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
    
    function getBookOwnerId(bookId) {
      return firestore.get(/databases/(default)/documents/books/$(bookId)).data.ownerId;
    }
    
    // Book cover images
    match /book_covers/{bookId}/{imageFile} {
      // Anyone can read book covers (for browsing)
      allow read: if true;
      
      // Only book owner can upload/update book covers
      allow write: if isAuthenticated() &&
                      isValidImageFile() &&
                      getUserId() == getBookOwnerId(bookId);
      
      // Only book owner can delete book covers
      allow delete: if isAuthenticated() &&
                       getUserId() == getBookOwnerId(bookId);
    }
    
    // Alternative path for book covers (direct bookId as filename)
    match /book_covers/{bookId} {
      allow read: if true;
      allow write: if isAuthenticated() &&
                      isValidImageFile() &&
                      getUserId() == getBookOwnerId(bookId);
      allow delete: if isAuthenticated() &&
                       getUserId() == getBookOwnerId(bookId);
    }
    
    // Profile images
    match /profile_images/{userId} {
      // Users can read any profile image (for social features)
      allow read: if isAuthenticated();
      
      // Users can only upload/update their own profile image
      allow write: if isAuthenticated() &&
                      isValidImageFile() &&
                      getUserId() == userId;
      
      // Users can only delete their own profile image
      allow delete: if isAuthenticated() &&
                       getUserId() == userId;
    }
    
    // Profile images with file extensions
    match /profile_images/{userId}/{imageFile} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() &&
                      isValidImageFile() &&
                      getUserId() == userId;
      allow delete: if isAuthenticated() &&
                       getUserId() == userId;
    }
    
    // Temporary uploads folder (for processing)
    match /temp/{userId}/{allPaths=**} {
      // Users can only access their own temp folder
      allow read, write, delete: if isAuthenticated() &&
                                    getUserId() == userId;
      
      // Auto-delete temp files older than 1 day (handled by cloud function)
    }
    
    // Deny all other paths
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. Security Best Practices Implemented

#### Data Validation
```javascript
// Example of field validation in Firestore rules
function isValidBookData(data) {
  return data.keys().hasAll(['title', 'author', 'genre', 'description', 'ownerId', 'societyId']) &&
         data.title is string && data.title.size() > 0 &&
         data.author is string && data.author.size() > 0 &&
         data.genre is string && data.genre.size() > 0 &&
         data.ownerId is string && data.ownerId.size() > 0 &&
         data.societyId is string && data.societyId.size() > 0 &&
         data.isAvailable is bool;
}

function isValidRequestStatus(status) {
  return status in ['pending', 'approved', 'rejected', 'returned', 'overdue'];
}
```

#### Rate Limiting (Cloud Functions)
```javascript
// Add to cloud functions for rate limiting
const rateLimit = require('express-rate-limit');

const createRequestLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each user to 5 requests per windowMs
  message: 'Too many book requests created, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
```

#### Input Sanitization (Client Side)
```swift
// Add to iOS app for input validation
extension String {
    var sanitized: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
                  .components(separatedBy: .controlCharacters)
                  .joined()
    }
    
    var isValidBookTitle: Bool {
        let sanitized = self.sanitized
        return sanitized.count > 0 && sanitized.count <= 100
    }
    
    var isValidDescription: Bool {
        let sanitized = self.sanitized
        return sanitized.count > 0 && sanitized.count <= 1000
    }
}
```

### 4. Monitoring and Alerts
```javascript
// Cloud Function for monitoring suspicious activity
exports.monitorSuspiciousActivity = functions.firestore
    .document('{collection}/{docId}')
    .onWrite(async (change, context) => {
        const userId = context.auth?.uid;
        const collection = context.params.collection;
        
        if (!userId) return;
        
        // Track rapid writes from same user
        const recentWrites = await admin.firestore()
            .collection('activityLog')
            .where('userId', '==', userId)
            .where('timestamp', '>', new Date(Date.now() - 60000)) // Last minute
            .get();
        
        if (recentWrites.size > 10) {
            // Log suspicious activity
            await admin.firestore()
                .collection('securityAlerts')
                .add({
                    userId: userId,
                    type: 'rapid_writes',
                    count: recentWrites.size,
                    collection: collection,
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });
        }
    });
```

### 5. Testing Security Rules
```bash
# Install Firebase emulator
npm install -g firebase-tools

# Start Firestore emulator with security rules
firebase emulators:start --only firestore

# Run security rules tests
firebase emulators:exec --only firestore "npm test"
```

```javascript
// Example security rules test
const firebase = require('@firebase/rules-unit-testing');

describe('BookStore Security Rules', () => {
  let testEnv;
  
  beforeEach(async () => {
    testEnv = await firebase.initializeTestEnvironment({
      projectId: 'bookstore-test',
      firestore: {
        rules: await fs.readFile('firestore.rules', 'utf8'),
      },
    });
  });
  
  test('users can only read their own data', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    
    await firebase.assertSucceeds(
      alice.firestore().collection('users').doc('alice').get()
    );
    
    await firebase.assertFails(
      alice.firestore().collection('users').doc('bob').get()
    );
  });
  
  test('only book owners can update their books', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const bob = testEnv.authenticatedContext('bob');
    
    // Alice creates a book
    await firebase.assertSucceeds(
      alice.firestore().collection('books').doc('book1').set({
        title: 'Test Book',
        author: 'Test Author',
        ownerId: 'alice',
        societyId: 'society1'
      })
    );
    
    // Alice can update her book
    await firebase.assertSucceeds(
      alice.firestore().collection('books').doc('book1').update({
        isAvailable: false
      })
    );
    
    // Bob cannot update Alice's book
    await firebase.assertFails(
      bob.firestore().collection('books').doc('book1').update({
        isAvailable: false
      })
    );
  });
});
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