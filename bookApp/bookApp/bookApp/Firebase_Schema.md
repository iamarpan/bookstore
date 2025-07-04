# Firebase Firestore Schema for Book Club

## Overview
This document outlines the complete Firebase Firestore database schema for the apartment society Book Club app, including collections, document structures, relationships, and security considerations.

## Collections Structure

### 1. Users Collection
**Collection Path:** `/users/{userId}`

```json
{
  "userId": "string (document ID)",
  "name": "string",
  "phoneNumber": "string",
  "flatNumber": "string",
  "email": "string (optional)",
  "profileImageURL": "string (optional)",
  "isActive": "boolean",
  "joinedAt": "timestamp",
  "lastActiveAt": "timestamp",
  "preferences": {
    "notifications": "boolean",
    "darkMode": "boolean"
  },
  "stats": {
    "booksAdded": "number",
    "booksBorrowed": "number",
    "booksLent": "number",
    "pendingRequests": "number"
  }
}
```

### 2. Books Collection
**Collection Path:** `/books/{bookId}`

```json
{
  "bookId": "string (document ID)",
  "title": "string",
  "author": "string",
  "genre": "string",
  "description": "string",
  "isbn": "string (optional)",
  "imageURL": "string",
  "isAvailable": "boolean",
  "condition": "string", // "new", "good", "fair", "poor"
  "language": "string", // "english", "hindi", etc.
  "ownerId": "string (reference to users)",
  "ownerName": "string",
  "ownerFlatNumber": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "tags": ["array of strings"],
  "metadata": {
    "totalRequests": "number",
    "totalBorrows": "number",
    "averageRating": "number",
    "viewCount": "number"
  }
}
```

### 3. Book Requests Collection
**Collection Path:** `/bookRequests/{requestId}`

```json
{
  "requestId": "string (document ID)",
  "bookId": "string (reference to books)",
  "bookTitle": "string",
  "borrowerId": "string (reference to users)",
  "borrowerName": "string",
  "borrowerFlatNumber": "string",
  "borrowerPhone": "string",
  "ownerId": "string (reference to users)",
  "ownerName": "string",
  "ownerFlatNumber": "string",
  "status": "string", // "pending", "approved", "rejected", "returned", "overdue"
  "requestDate": "timestamp",
  "approvedDate": "timestamp (optional)",
  "borrowedDate": "timestamp (optional)",
  "expectedReturnDate": "timestamp (optional)",
  "actualReturnDate": "timestamp (optional)",
  "requestMessage": "string (optional)",
  "rejectionReason": "string (optional)",
  "rating": "number (optional)", // 1-5 stars after return
  "review": "string (optional)"
}
```

### 4. Notifications Collection
**Collection Path:** `/notifications/{notificationId}`

```json
{
  "notificationId": "string (document ID)",
  "userId": "string (reference to users)",
  "type": "string", // "request", "approval", "rejection", "reminder", "return"
  "title": "string",
  "message": "string",
  "isRead": "boolean",
  "createdAt": "timestamp",
  "relatedBookId": "string (optional)",
  "relatedRequestId": "string (optional)",
  "actionRequired": "boolean",
  "metadata": {
    "bookTitle": "string (optional)",
    "requesterName": "string (optional)",
    "ownerName": "string (optional)"
  }
}
```

### 5. Categories Collection (Optional)
**Collection Path:** `/categories/{categoryId}`

```json
{
  "categoryId": "string (document ID)",
  "name": "string",
  "description": "string",
  "iconName": "string",
  "color": "string",
  "bookCount": "number",
  "isActive": "boolean",
  "createdAt": "timestamp"
}
```

### 6. Society Settings Collection
**Collection Path:** `/settings/societyConfig`

```json
{
  "societyName": "string",
  "address": "string",
  "rules": {
    "maxBorrowDays": "number",
    "maxBooksPerUser": "number",
    "penaltyPerDay": "number",
    "allowRatings": "boolean"
  },
  "features": {
    "isbnScanning": "boolean",
    "notifications": "boolean",
    "bookConditionTracking": "boolean"
  },
  "adminUsers": ["array of userIds"],
  "updatedAt": "timestamp"
}
```

## Subcollections

### User's Personal Library
**Collection Path:** `/users/{userId}/personalLibrary/{bookId}`

```json
{
  "bookId": "string (reference to books)",
  "status": "string", // "owned", "borrowed", "lent"
  "addedAt": "timestamp",
  "notes": "string (optional)"
}
```

### User's Notifications (Alternative Structure)
**Collection Path:** `/users/{userId}/notifications/{notificationId}`

```json
{
  "notificationId": "string",
  "type": "string",
  "title": "string",
  "message": "string",
  "isRead": "boolean",
  "createdAt": "timestamp",
  "relatedBookId": "string (optional)",
  "relatedRequestId": "string (optional)"
}
```

## Indexes Required

### Composite Indexes
```javascript
// Books collection
books: [
  { fields: ["isAvailable", "createdAt"], order: "desc" },
  { fields: ["genre", "isAvailable", "createdAt"], order: "desc" },
  { fields: ["ownerId", "createdAt"], order: "desc" },
  { fields: ["title", "author"] }, // for search
]

// BookRequests collection
bookRequests: [
  { fields: ["borrowerId", "status", "requestDate"], order: "desc" },
  { fields: ["ownerId", "status", "requestDate"], order: "desc" },
  { fields: ["bookId", "status", "requestDate"], order: "desc" },
  { fields: ["status", "expectedReturnDate"], order: "asc" },
]

// Notifications collection
notifications: [
  { fields: ["userId", "isRead", "createdAt"], order: "desc" },
  { fields: ["userId", "type", "createdAt"], order: "desc" },
]
```

## Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users' basic info
    }
    
    // Books rules
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
                   request.auth.uid == resource.data.ownerId;
      allow update: if request.auth != null && 
                   request.auth.uid == resource.data.ownerId;
      allow delete: if request.auth != null && 
                   request.auth.uid == resource.data.ownerId;
    }
    
    // Book requests rules
    match /bookRequests/{requestId} {
      allow read: if request.auth != null && 
                 (request.auth.uid == resource.data.borrowerId || 
                  request.auth.uid == resource.data.ownerId);
      allow create: if request.auth != null && 
                   request.auth.uid == request.resource.data.borrowerId;
      allow update: if request.auth != null && 
                   (request.auth.uid == resource.data.ownerId || 
                    request.auth.uid == resource.data.borrowerId);
    }
    
    // Notifications rules
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
                        request.auth.uid == resource.data.userId;
    }
    
    // User subcollections
    match /users/{userId}/notifications/{notificationId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /users/{userId}/personalLibrary/{bookId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Settings (admin only)
    match /settings/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                  request.auth.uid in get(/databases/$(database)/documents/settings/societyConfig).data.adminUsers;
    }
  }
}
```

## Cloud Functions Triggers

### Recommended Cloud Functions
```javascript
// Update book availability when request status changes
exports.updateBookAvailability = functions.firestore
  .document('bookRequests/{requestId}')
  .onUpdate(async (change, context) => {
    // Update book isAvailable status based on request status
  });

// Create notification when book request is made
exports.createRequestNotification = functions.firestore
  .document('bookRequests/{requestId}')
  .onCreate(async (snap, context) => {
    // Send notification to book owner
  });

// Update user stats when book is added/borrowed/returned
exports.updateUserStats = functions.firestore
  .document('books/{bookId}')
  .onCreate(async (snap, context) => {
    // Increment user's booksAdded count
  });

// Send reminder notifications for overdue books
exports.overdueReminders = functions.pubsub
  .schedule('0 9 * * *') // Daily at 9 AM
  .onRun(async (context) => {
    // Check for overdue books and send notifications
  });
```

## Usage Examples

### Swift Code Examples

#### Initialize Firebase
```swift
// In App.swift
import Firebase

@main
struct BookClubApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### Book Service Example
```swift
import FirebaseFirestore
import FirebaseAuth

class BookService: ObservableObject {
    private let db = Firestore.firestore()
    
    func addBook(_ book: Book) async throws {
        try await db.collection("books").addDocument(data: [
            "title": book.title,
            "author": book.author,
            "genre": book.genre,
            "description": book.description,
            "imageURL": book.imageURL,
            "isAvailable": true,
            "ownerId": Auth.auth().currentUser?.uid ?? "",
            "ownerName": book.ownerName,
            "ownerFlatNumber": book.ownerFlatNumber,
            "createdAt": Timestamp(date: Date())
        ])
    }
    
    func fetchAvailableBooks() async throws -> [Book] {
        let snapshot = try await db.collection("books")
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Book.self)
        }
    }
}
```

## Performance Considerations

1. **Pagination**: Implement pagination for book lists using `limit()` and `startAfter()`
2. **Offline Support**: Enable Firestore offline persistence
3. **Image Storage**: Use Firebase Storage for book cover images
4. **Search**: Consider using Algolia or implement client-side search for better performance
5. **Caching**: Implement proper caching strategies for frequently accessed data

## Backup Strategy

1. **Automated Backups**: Set up daily Firestore backups
2. **Export Critical Data**: Regular exports of users and books data
3. **Version Control**: Track schema changes and migrations

This schema provides a robust foundation for your Book Club app with proper relationships, security, and scalability considerations. 