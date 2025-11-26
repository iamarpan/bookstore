# iOS-Backend API Contract

## Base Configuration

- **Base URL (Development)**: `http://localhost:3000/api/v1`
- **Base URL (Staging)**: `https://staging-api.bookshare.com/api/v1`
- **Base URL (Production)**: `https://api.bookshare.com/api/v1`

## Authentication

All authenticated endpoints require a JWT token in the header:
```
Authorization: Bearer <access_token>
```

---

## 1. Authentication Endpoints

### POST /auth/send-otp
Send OTP to phone number

**Request:**
```json
{
  "phoneNumber": "+919876543210"
}
```

**Response (200):**
```json
{
  "message": "OTP sent successfully",
  "expiresIn": 600
}
```

---

### POST /auth/verify-otp
Verify OTP and login/register

**Request:**
```json
{
  "phoneNumber": "+919876543210",
  "otp": "1234",
  "name": "John Doe",  // Required for first-time registration
  "bio": "Book lover" // Optional
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": {
    "id": "usr_123",
    "phoneNumber": "+919876543210",
    "name": "John Doe",
    "bio": "Book lover",
    "profileImageUrl": null,
    "stats": {
      "booksShared": 0,
      "successfulLends": 0,
      "booksBorrowed": 0,
      "totalEarned": 0,
      "averageRating": 0
    },
    "createdAt": "2025-01-15T10:30:00Z"
  }
}
```

---

### POST /auth/refresh
Refresh access token

**Request:**
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**Response (200):**
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

---

### GET /users/me
Get current user profile *(Authenticated)*

**Response (200):**
```json
{
  "id": "usr_123",
  "phoneNumber": "+919876543210",
  "name": "John Doe",
  "bio": "Book lover",
  "profileImageUrl": "https://cdn.bookshare.com/profiles/usr_123.jpg",
  "stats": {
    "booksShared": 12,
    "successfulLends": 45,
    "booksBorrowed": 23,
    "totalEarned": 2450,
    "averageRating": 4.8
  },
  "privacySettings": {
    "phoneVisibility": "AFTER_APPROVAL"
  },
  "createdAt": "2025-01-15T10:30:00Z"
}
```

---

### PUT /users/me
Update profile *(Authenticated)*

**Request:**
```json
{
  "name": "John Smith",
  "bio": "Updated bio",
  "profileImageUrl": "https://cdn.bookshare.com/profiles/new.jpg"
}
```

---

## 2. Group Endpoints

### GET /groups/my
Get user's groups *(Authenticated)*

**Response (200):**
```json
{
  "groups": [
    {
      "id": "grp_123",
      "name": "Office Book Club",
      "description": "Share books among colleagues",
      "coverImageUrl": "https://cdn.bookshare.com/groups/grp_123.jpg",
      "category": "OFFICE",
      "privacy": "PRIVATE",
      "role": "ADMIN",
      "memberCount": 15,
      "bookCount": 47,
      "createdAt": "2025-01-10T08:00:00Z"
    }
  ]
}
```

---

### GET /groups/discover
Discover public groups *(Authenticated)*

**Query Params:**
- `category` (optional): FRIENDS, OFFICE, NEIGHBORHOOD, BOOK_CLUB, SCHOOL
- `search` (optional): Search query

**Response (200):**
```json
{
  "groups": [
    {
      "id": "grp_456",
      "name": "Hyderabad Book Lovers",
      "description": "Public book sharing community",
      "coverImageUrl": "https://cdn.bookshare.com/groups/grp_456.jpg",
      "category": "BOOK_CLUB",
      "privacy": "PUBLIC",
      "memberCount": 150,
      "bookCount": 320
    }
  ]
}
```

---

### POST /groups
Create new group *(Authenticated)*

**Request:**
```json
{
  "name": "My Book Club",
  "description": "Friends sharing books",
  "category": "FRIENDS",
  "privacy": "PRIVATE",
  "rules": "Be respectful and return books on time",
  "coverImageUrl": "https://cdn.bookshare.com/groups/new.jpg"
}
```

**Response (201):**
```json
{
  "id": "grp_789",
  "name": "My Book Club",
  "inviteCode": "ABC123XYZ",
  "inviteUrl": "https://bookshare.app/join/ABC123XYZ",
  ...
}
```

---

### GET /groups/:id
Get group details *(Authenticated, must be member)*

**Response (200):**
```json
{
  "id": "grp_123",
  "name": "Office Book Club",
  "description": "Share books among colleagues",
  "category": "OFFICE",
  "privacy": "PRIVATE",
  "rules": "Be respectful",
  "members": [
    {
      "userId": "usr_123",
      "name": "John Doe",
      "profileImageUrl": "...",
      "role": "ADMIN",
      "joinedAt": "2025-01-10T08:00:00Z"
    }
  ],
  "bookCount": 47,
  "createdAt": "2025-01-10T08:00:00Z"
}
```

---

### POST /groups/:id/join
Join public group or request to join private *(Authenticated)*

**Response (200):**
```json
{
  "status": "JOINED"  // or "PENDING_APPROVAL" for private groups
}
```

---

### POST /groups/:id/leave
Leave group *(Authenticated)*

---

### POST /groups/:id/invite
Generate invite link *(Authenticated, admin/moderator only)*

**Request:**
```json
{
  "expiryDays": 7  // Optional, null for no expiry
}
```

**Response (200):**
```json
{
  "inviteCode": "DEF456GHI",
  "inviteUrl": "https://bookshare.app/join/DEF456GHI",
  "expiresAt": "2025-01-22T10:00:00Z"
}
```

---

### POST /groups/join-invite/:code
Join via invite code *(Authenticated)*

**Response (200):**
```json
{
  "group": {
    "id": "grp_123",
    "name": "Office Book Club",
    ...
  }
}
```

---

## 3. Book Endpoints

### GET /books/feed
Get books feed with filters *(Authenticated)*

**Query Params:**
- `groupIds[]` (optional): Array of group IDs
- `availability` (optional): AVAILABLE, LENT, ALL
- `genres[]` (optional): Array of genres
- `minPrice` (optional): Minimum lending price
- `maxPrice` (optional): Maximum lending price
- `sortBy` (optional): RECENT, PRICE_LOW_HIGH, POPULAR
- `search` (optional): Search query
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response (200):**
```json
{
  "books": [
    {
      "id": "bk_123",
      "title": "Clean Code",
      "author": "Robert C. Martin",
      "genre": "TECHNOLOGY",
      "description": "A handbook of agile software craftsmanship",
      "imageUrl": "https://covers.openlibrary.org/b/id/6999792-L.jpg",
      "isbn": "9780132350884",
      "publisher": "Prentice Hall",
      "year": 2008,
      "pages": 464,
      "language": "English",
      "condition": "LIKE_NEW",
      "lendingPricePerWeek": 50,
      "isAvailable": true,
      "ownerId": "usr_456",
      "ownerName": "Alex Rodriguez",
      "ownerRating": 4.8,
      "visibleInGroups": ["grp_123", "grp_456"],
      "currentTransactionId": null,
      "createdAt": "2025-01-12T14:20:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalPages": 5,
    "totalItems": 97
  }
}
```

---

### GET /books/:id
Get book details *(Authenticated)*

**Response (200):**
```json
{
  "id": "bk_123",
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "genre": "TECHNOLOGY",
  "description": "A handbook of agile software craftsmanship",
  "personalNotes": "Great condition, no markings",
  "imageUrl": "https://covers.openlibrary.org/b/id/6999792-L.jpg",
  "isbn": "9780132350884",
  "publisher": "Prentice Hall",
  "year": 2008,
  "pages": 464,
  "language": "English",
  "condition": "LIKE_NEW",
  "lendingPricePerWeek": 50,
  "isAvailable": true,
  "ownerId": "usr_456",
  "ownerName": "Alex Rodriguez",
  "ownerProfileImageUrl": "...",
  "ownerRating": 4.8,
  "ownerBooksCount": 12,
  "visibleInGroups": ["grp_123", "grp_456"],
  "currentTransactionId": null,
  "createdAt": "2025-01-12T14:20:00Z"
}
```

---

### POST /books
Create book *(Authenticated)*

**Request:**
```json
{
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "genre": "TECHNOLOGY",
  "description": "A handbook of agile software craftsmanship",
  "personalNotes": "Great condition",
  "imageUrl": "https://...",
  "isbn": "9780132350884",
  "publisher": "Prentice Hall",
  "year": 2008,
  "pages": 464,
  "language": "English",
  "condition": "LIKE_NEW",
  "lendingPricePerWeek": 50,
  "visibleInGroups": ["grp_123", "grp_456"]
}
```

**Response (201):**
```json
{
  "id": "bk_789",
  "title": "Clean Code",
  ...
}
```

---

### PUT /books/:id
Update book *(Authenticated, owner only)*

**Request:**
Same as POST /books

---

### DELETE /books/:id
Delete book *(Authenticated, owner only)*

---

### POST /books/upload-image
Upload book cover image *(Authenticated)*

**Request:** `multipart/form-data`
- `image`: Image file (max 5MB)

**Response (200):**
```json
{
  "imageUrl": "https://cdn.bookshare.com/books/img_123.jpg"
}
```

---

### POST /books/scan-isbn
Lookup book by ISBN *(Authenticated)*

**Request:**
```json
{
  "isbn": "9780132350884"
}
```

**Response (200):**
```json
{
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "publisher": "Prentice Hall",
  "year": 2008,
  "pages": 464,
  "imageUrl": "https://covers.openlibrary.org/...",
  "description": "...",
  "isbn": "9780132350884"
}
```

---

## 4. Transaction Endpoints

### GET /transactions/my
Get user's transactions *(Authenticated)*

**Query Params:**
- `role` (optional): BORROWER, OWNER, ALL
- `status` (optional): PENDING, APPROVED, ACTIVE, RETURNED, REJECTED, CANCELLED
- `page`, `limit`

**Response (200):**
```json
{
  "transactions": [
    {
      "id": "txn_123",
      "bookId": "bk_123",
      "bookTitle": "Clean Code",
      "bookImageUrl": "...",
      "borrowerId": "usr_789",
      "borrowerName": "Jane Smith",
      "ownerId": "usr_456",
      "ownerName": "Alex Rodriguez",
      "groupId": "grp_123",
      "status": "ACTIVE",
      "duration": "2_WEEKS",
      "durationDays": 14,
      "lendingFee": 100,
      "requestedAt": "2025-01-15T10:00:00Z",
      "approvedAt": "2025-01-15T11:00:00Z",
      "handoverAt": "2025-01-15T15:00:00Z",
      "dueDate": "2025-01-29T15:00:00Z",
      "isOverdue": false,
      "paymentStatus": {
        "borrowerConfirmed": true,
        "ownerConfirmed": false
      }
    }
  ]
}
```

---

### POST /transactions/request
Create borrow request *(Authenticated)*

**Request:**
```json
{
  "bookId": "bk_123",
  "duration": "2_WEEKS",  // 1_WEEK, 2_WEEKS, 1_MONTH, CUSTOM
  "durationDays": 14,  // Required if duration is CUSTOM
  "message": "I'd love to read this book!"
}
```

**Response (201):**
```json
{
  "id": "txn_456",
  "status": "PENDING",
  ...
}
```

---

### POST /transactions/:id/approve
Approve borrow request *(Authenticated, owner only)*

**Response (200):**
```json
{
  "id": "txn_456",
  "status": "APPROVED",
  ...
}
```

---

### POST /transactions/:id/reject
Reject borrow request *(Authenticated, owner only)*

**Request:**
```json
{
  "reason": "Book not available right now"  // Optional
}
```

---

### POST /transactions/:id/confirm-handover
Confirm book handover with OTP *(Authenticated, owner only)*

**Request:**
```json
{
  "otp": "1234"  // OTP generated by borrower on client side
}
```

**Response (200):**
```json
{
  "id": "txn_456",
  "status": "ACTIVE",
  "handoverAt": "2025-01-15T15:00:00Z",
  "dueDate": "2025-01-29T15:00:00Z"
}
```

---

### POST /transactions/:id/confirm-return
Confirm book return with OTP *(Authenticated, borrower only)*

**Request:**
```json
{
  "otp": "5678"  // OTP generated by owner on client side
}
```

**Response (200):**
```json
{
  "id": "txn_456",
  "status": "RETURNED",
  "returnedAt": "2025-01-28T10:00:00Z"
}
```

---

### POST /transactions/:id/rate
Rate transaction *(Authenticated, after return)*

**Request:**
```json
{
  "rating": 5,
  "comment": "Great experience, book was in perfect condition!",
  "bookConditionRating": 5  // Only for owner
}
```

---

### POST /transactions/:id/mark-payment
Mark payment as complete *(Authenticated, borrower or owner)*

**Request:**
```json
{
  "role": "BORROWER"  // or "OWNER"
}
```

**Response (200):**
```json
{
  "paymentStatus": {
    "borrowerConfirmed": true,
    "ownerConfirmed": false
  }
}
```

---

## 5. Notification Endpoints

### GET /notifications
Get user notifications *(Authenticated)*

**Query Params:**
- `unreadOnly` (optional): boolean
- `page`, `limit`

**Response (200):**
```json
{
  "notifications": [
    {
      "id": "ntf_123",
      "type": "BORROW_REQUEST",
      "title": "New borrow request",
      "message": "Jane Smith wants to borrow Clean Code",
      "data": {
        "transactionId": "txn_456",
        "bookId": "bk_123"
      },
      "isRead": false,
      "createdAt": "2025-01-15T10:00:00Z"
    }
  ]
}
```

**Notification Types:**
- `BORROW_REQUEST` - New borrow request received
- `REQUEST_APPROVED` - Your request was approved
- `REQUEST_REJECTED` - Your request was rejected
- `DUE_SOON` - Book due in 24 hours
- `OVERDUE` - Book is overdue
- `RETURN_REQUESTED` - Borrower wants to return
- `NEW_BOOK_IN_GROUP` - New book added to group

---

### PUT /notifications/:id/read
Mark notification as read *(Authenticated)*

---

### POST /notifications/register
Register device token for push notifications *(Authenticated)*

**Request:**
```json
{
  "deviceToken": "apns_token_here",
  "platform": "IOS"
}
```

---

## Error Responses

All endpoints may return these error responses:

### 400 Bad Request
```json
{
  "error": "VALIDATION_ERROR",
  "message": "Invalid phone number format",
  "fields": {
    "phoneNumber": "Must include country code"
  }
}
```

### 401 Unauthorized
```json
{
  "error": "UNAUTHORIZED",
  "message": "Invalid or expired token"
}
```

### 403 Forbidden
```json
{
  "error": "FORBIDDEN",
  "message": "You don't have permission to access this resource"
}
```

### 404 Not Found
```json
{
  "error": "NOT_FOUND",
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "INTERNAL_ERROR",
  "message": "An unexpected error occurred"
}
```

---

## Enums Reference

### GroupCategory
- `FRIENDS`
- `OFFICE`
- `NEIGHBORHOOD`
- `BOOK_CLUB`
- `SCHOOL`

### PrivacySetting
- `PUBLIC`
- `PRIVATE`

### MemberRole
- `MEMBER`
- `MODERATOR`
- `ADMIN`
- `CREATOR`

### BookCondition
- `NEW`
- `LIKE_NEW`
- `GOOD`
- `FAIR`
- `POOR`

### TransactionStatus
- `PENDING`
- `APPROVED`
- `ACTIVE`
- `RETURNED`
- `REJECTED`
- `CANCELLED`

### BorrowDuration
- `1_WEEK`
- `2_WEEKS`
- `1_MONTH`
- `CUSTOM`

### PhoneVisibility
- `AFTER_APPROVAL`
- `GROUP_MEMBERS`
- `PUBLIC`
