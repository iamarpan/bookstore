# Firebase Integration Testing Guide

## Overview
This guide covers how to test your BookstoreApp's Firebase integration using local emulators and production systems.

## 🚀 Quick Start Testing

### 1. Start Emulators
```bash
# Export Java to PATH (required each terminal session)
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# Start Firebase emulators
firebase emulators:start --only firestore,storage,ui
```

### 2. Open Emulator UI
- **URL**: http://127.0.0.1:4000/
- **Firestore**: http://127.0.0.1:4000/firestore
- **Storage**: http://127.0.0.1:4000/storage

### 3. Configure iOS App
Your iOS app is already configured to use emulators in DEBUG mode.
When you run the app, look for these console logs:
```
🧪 Firebase emulators configured for local testing
🔥 Firestore: 127.0.0.1:8080
📁 Storage: 127.0.0.1:9199
🔐 Auth: Production (not emulated)
```

---

## 📋 Manual Testing Checklist

### **Authentication Testing** 🔐

#### Test Cases:
- [ ] **Phone Number OTP Flow**
  1. Enter phone number in app
  2. Receive OTP (production SMS)
  3. Verify OTP works
  4. Check user creation in Firestore Emulator UI

- [ ] **User Registration**
  1. Complete OTP verification
  2. Fill out user profile (name, society, etc.)
  3. Verify user document created in `users` collection
  4. Check FCM token is saved

- [ ] **Session Persistence**
  1. Close and reopen app
  2. Verify user stays logged in
  3. Check authentication state restoration

#### Expected Results:
```json
// In Firestore Emulator UI -> users collection
{
  "id": "user_uid",
  "name": "Test User",
  "phoneNumber": "+1234567890",
  "societyId": "society_123",
  "societyName": "Test Society",
  "blockName": "A",
  "flatNumber": "101",
  "isActive": true,
  "createdAt": "timestamp",
  "fcmToken": "fcm_token_here"
}
```

### **Firestore Database Testing** 🔥

#### Test Cases:

**Books Management:**
- [ ] **Add Book**
  1. Navigate to Add Book screen
  2. Fill in book details
  3. Upload book cover image
  4. Save book
  5. Verify in Firestore UI: `books` collection

- [ ] **View Books**
  1. Check HomeView shows books from your society
  2. Verify only available books are visible
  3. Check real-time updates (add a book in Emulator UI)

- [ ] **Update Book**
  1. Edit book details in MyLibrary
  2. Change availability status
  3. Verify changes in Firestore UI

**Book Requests:**
- [ ] **Create Request**
  1. Request a book from another user
  2. Verify request in Firestore UI: `bookRequests` collection
  3. Check notification created: `notifications` collection

- [ ] **Approve/Reject Request**
  1. As book owner, respond to request
  2. Verify status change in Firestore UI
  3. Check notification sent to borrower

#### Expected Results:
```json
// Books collection
{
  "title": "Test Book",
  "author": "Test Author",
  "genre": "Fiction",
  "description": "Test description",
  "imageURL": "gs://bucket/book_covers/bookId.jpg",
  "isAvailable": true,
  "ownerId": "user_uid",
  "ownerName": "Test User",
  "societyId": "society_123",
  "createdAt": "timestamp"
}

// Book Requests collection
{
  "bookId": "book_id",
  "borrowerId": "borrower_uid",
  "borrowerName": "Borrower Name",
  "ownerId": "owner_uid",
  "societyId": "society_123",
  "status": "pending",
  "requestDate": "timestamp"
}
```

### **Storage Testing** 📁

#### Test Cases:
- [ ] **Book Cover Upload**
  1. Add a book with image
  2. Verify image uploaded to `book_covers/` in Storage UI
  3. Check image URL in Firestore document

- [ ] **Profile Image Upload**
  1. Update profile with image
  2. Verify image in `profile_images/` in Storage UI
  3. Check image compression worked (file size)

- [ ] **Upload Progress**
  1. Upload large image
  2. Verify progress indicator works
  3. Check upload completes successfully

#### Expected Results:
- **Storage Structure**:
  ```
  /book_covers/
    ├── bookId1.jpg
    └── bookId2.jpg
  /profile_images/
    └── userId.jpg
  ```

### **Security Rules Testing** 🛡️

#### Test Cases:

**Firestore Security:**
- [ ] **Society Isolation**
  1. Create users in different societies
  2. Verify each user only sees their society's books
  3. Test cross-society access is blocked

- [ ] **Owner Permissions**
  1. Try to edit another user's book
  2. Verify permission denied
  3. Check owner can edit their own books

- [ ] **Request Permissions**
  1. Try to approve someone else's request as non-owner
  2. Verify permission denied
  3. Check only book owner can approve

**Storage Security:**
- [ ] **Upload Permissions**
  1. Try to upload to another user's profile folder
  2. Verify permission denied
  3. Check users can upload to their own folders

#### How to Test:
1. In Emulator UI, go to Firestore tab
2. Click "Start collection"
3. Try to create documents that violate rules
4. Check for permission denied errors

### **Real-time Features Testing** ⚡

#### Test Cases:
- [ ] **Real-time Book Updates**
  1. Open app on one device/simulator
  2. Add book via Emulator UI
  3. Verify new book appears instantly in app

- [ ] **Real-time Request Updates**
  1. Create book request
  2. Approve via Emulator UI
  3. Verify status updates in app immediately

- [ ] **Notification Updates**
  1. Add notification via Emulator UI
  2. Check notification appears in app
  3. Verify unread count updates

---

## 🤖 Automated Testing

### **Unit Tests**

Create test files to verify Firebase services:

```swift
// Tests/FirebaseServiceTests.swift
import XCTest
@testable import bookApp

class FirebaseServiceTests: XCTestCase {
    var firestoreService: FirestoreService!
    var storageService: StorageService!
    
    override func setUp() {
        super.setUp()
        firestoreService = FirestoreService()
        storageService = StorageService()
    }
    
    func testAddBook() async throws {
        let book = Book(
            title: "Test Book",
            author: "Test Author",
            genre: "Fiction",
            description: "Test Description",
            condition: "Good",
            ownerId: "test_user",
            ownerName: "Test User",
            societyId: "test_society",
            isAvailable: true
        )
        
        let bookId = try await firestoreService.addBook(book)
        XCTAssertFalse(bookId.isEmpty)
    }
    
    func testImageUpload() async throws {
        let image = UIImage(systemName: "book.fill")!
        let imageURL = try await storageService.uploadBookCover(image, bookId: "test_book")
        XCTAssertTrue(imageURL.contains("127.0.0.1:9199"))
    }
}
```

### **Integration Tests**

```swift
// Tests/IntegrationTests.swift
class IntegrationTests: XCTestCase {
    func testCompleteBookFlow() async throws {
        // 1. Create user
        // 2. Add book
        // 3. Upload image
        // 4. Create request
        // 5. Approve request
        // 6. Verify all data in Firestore
    }
}
```

---

## 🐛 Common Issues & Solutions

### **Emulator Connection Issues**
```
Error: Could not connect to Firestore emulator
```
**Solution**: Verify emulators are running and Java is in PATH

### **Security Rules Violations**
```
Missing or insufficient permissions
```
**Solution**: Check Firestore Rules tab in Emulator UI for violation details

### **Image Upload Failures**
```
Storage upload failed
```
**Solution**: Check Storage emulator is running on port 9199

### **Real-time Not Working**
```
Documents not updating in real-time
```
**Solution**: Verify Firestore listeners are properly configured

---

## 📊 Performance Testing

### **Load Testing**
1. Create multiple users
2. Add 100+ books
3. Create 50+ requests
4. Monitor performance in Emulator UI

### **Network Testing**
1. Test with slow network
2. Test offline functionality
3. Verify data synchronization

---

## 🚀 Production Testing

### **Deploy Rules**
```bash
# Deploy security rules to production
firebase deploy --only firestore:rules,storage:rules

# Deploy cloud functions
firebase deploy --only functions
```

### **Production Smoke Tests**
1. Create test user account
2. Add one book
3. Create one request
4. Verify all data appears correctly
5. Clean up test data

---

## 📝 Test Data Templates

### **Sample Users**
```json
{
  "name": "Alice Johnson",
  "phoneNumber": "+1234567890",
  "societyId": "greenpark_towers",
  "societyName": "Green Park Towers",
  "blockName": "A",
  "flatNumber": "101"
}
```

### **Sample Books**
```json
{
  "title": "The Great Gatsby",
  "author": "F. Scott Fitzgerald",
  "genre": "Classic Literature",
  "description": "A classic American novel",
  "condition": "Good",
  "isAvailable": true
}
```

### **Sample Societies**
```json
{
  "name": "Green Park Towers",
  "address": "123 Main Street",
  "city": "New York",
  "state": "NY",
  "pincode": "10001",
  "totalBlocks": ["A", "B", "C"],
  "amenities": ["Gym", "Pool", "Garden"]
}
```

---

## ✅ Testing Completion Checklist

- [ ] All authentication flows work
- [ ] Books CRUD operations function
- [ ] Image upload/download works
- [ ] Security rules are enforced
- [ ] Real-time updates work
- [ ] Notifications are created
- [ ] Performance is acceptable
- [ ] Error handling works
- [ ] Offline functionality works
- [ ] Production deployment successful

**Your Firebase integration is ready when all items are checked! 🎉** 